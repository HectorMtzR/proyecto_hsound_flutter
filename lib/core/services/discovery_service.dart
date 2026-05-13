import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../data/local_db.dart';
import '../models/models.dart';
import '../models/recognition_result.dart';

/// Busca canciones relacionadas con los géneros de la biblioteca usando la
/// iTunes Search API (pública, sin autenticación). Los resultados se cachean
/// en Hive durante 24 h para evitar llamadas repetidas.
class DiscoveryService {
  static const _cacheKey = 'cache';
  static const _cacheTtlHours = 24;

  Future<List<RecognitionResult>> fetchRelatedTracks(
    List<String> genres,
    List<Track> libraryTracks,
  ) async {
    try {
      final cached = _readCache();
      if (cached != null) return cached;

      if (genres.isEmpty) return [];

      final results = <RecognitionResult>[];

      for (final genre in genres.take(3)) {
        final uri = Uri.https('itunes.apple.com', '/search', {
          'term': genre,
          'media': 'music',
          'entity': 'song',
          'limit': '5',
        });
        final response =
            await http.get(uri).timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) continue;
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        for (final item in (body['results'] as List? ?? [])) {
          final r = _fromItunes(item as Map<String, dynamic>);
          if (r != null) results.add(r);
        }
      }

      final libIsrcs =
          libraryTracks.map((t) => t.isrc).whereType<String>().toSet();
      final libKeys = libraryTracks
          .map((t) => '${t.title}|${t.artist}'.toLowerCase())
          .toSet();
      final seen = <String>{};
      final filtered = results.where((r) {
        final key = '${r.title}|${r.artist}'.toLowerCase();
        if (!seen.add(key)) return false;
        if (r.isrc != null && libIsrcs.contains(r.isrc)) return false;
        if (libKeys.contains(key)) return false;
        return true;
      }).take(10).toList();

      // Solo cacheamos si hay resultados para no bloquear reintentos 24 h.
      if (filtered.isNotEmpty) _writeCache(filtered);
      return filtered;
    } catch (_) {
      return [];
    }
  }

  /// Convierte un item de la iTunes Search API en [RecognitionResult].
  static RecognitionResult? _fromItunes(Map<String, dynamic> json) {
    final title = json['trackName'] as String?;
    final artist = json['artistName'] as String?;
    if (title == null || title.isEmpty || artist == null || artist.isEmpty) {
      return null;
    }
    // artworkUrl100 viene en 100×100; subimos a 600×600.
    final rawCover = json['artworkUrl100'] as String?;
    final coverUrl = rawCover?.replaceAll('100x100bb', '600x600bb');

    final trackId = json['trackId'];
    final appleMusicId = trackId?.toString();

    return RecognitionResult(
      title: title,
      artist: artist,
      album: json['collectionName'] as String?,
      coverUrl: coverUrl,
      appleMusicId: appleMusicId,
      source: RecognitionSource.external,
    );
  }

  List<RecognitionResult>? _readCache() {
    final box = Hive.box(LocalDb.discoveryBox);
    final entry = box.get(_cacheKey) as Map?;
    if (entry == null) return null;
    final cachedAt = DateTime.tryParse(entry['cachedAt'] as String? ?? '');
    if (cachedAt == null) return null;
    if (DateTime.now().difference(cachedAt).inHours >= _cacheTtlHours) {
      return null;
    }
    final rawList = entry['results'] as List? ?? [];
    return rawList.map((r) => RecognitionResult.fromMap(r as Map)).toList();
  }

  void _writeCache(List<RecognitionResult> results) {
    Hive.box(LocalDb.discoveryBox).put(_cacheKey, {
      'cachedAt': DateTime.now().toIso8601String(),
      'results': results.map((r) => r.toMap()).toList(),
    });
  }
}
