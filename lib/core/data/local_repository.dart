import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';
import 'local_db.dart';

/// Operación de escritura encolada para sincronizar al recuperar conexión.
class PendingWrite {
  /// Tipo discriminante: like_add | like_remove | add_to_playlist |
  /// remove_from_playlist | create_playlist | delete_playlist.
  final String type;

  /// Datos serializables (solo primitivos) necesarios para reproducir la
  /// operación contra Firestore.
  final Map<String, dynamic> payload;

  /// Marca temporal en milisegundos para depuración y orden FIFO estable.
  final int createdAt;

  PendingWrite({
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'payload': payload,
        'createdAt': createdAt,
      };

  static PendingWrite fromMap(Map raw) {
    return PendingWrite(
      type: raw['type'] as String,
      payload: (raw['payload'] as Map).cast<String, dynamic>(),
      createdAt: raw['createdAt'] as int,
    );
  }
}

/// Capa de persistencia local sobre Hive. Sin estado: cada llamada lee/escribe
/// directamente en las cajas inicializadas por [LocalDb.init].
///
/// La serialización de modelos se hace con `Map<String, dynamic>` de
/// primitivos para evitar TypeAdapters generados por codegen.
class LocalRepository {
  Box get _tracks => Hive.box(LocalDb.tracksBox);
  Box get _playlists => Hive.box(LocalDb.playlistsBox);
  Box get _liked => Hive.box(LocalDb.likedTracksBox);
  Box get _pending => Hive.box(LocalDb.pendingWritesBox);
  Box get _downloads => Hive.box(LocalDb.downloadsBox);

  // --- Catálogo de pistas ---

  List<Track> getCachedTracks() {
    return _tracks.values
        .whereType<Map>()
        .map((m) => _trackFromMap(m.cast<String, dynamic>()))
        .toList();
  }

  Future<void> cacheTracks(List<Track> tracks) async {
    await _tracks.clear();
    final entries = {for (final t in tracks) t.id: _trackToMap(t)};
    await _tracks.putAll(entries);
  }

  Track? getCachedTrack(String id) {
    final raw = _tracks.get(id);
    if (raw is! Map) return null;
    return _trackFromMap(raw.cast<String, dynamic>());
  }

  // --- Playlists ---

  /// Lee playlists desde Hive y las reconstruye usando el catálogo dado.
  /// Las pistas referenciadas que no estén en [allTracks] se omiten.
  List<Playlist> getCachedPlaylists(List<Track> allTracks) {
    final byId = {for (final t in allTracks) t.id: t};
    return _playlists.values.whereType<Map>().map((raw) {
      final m = raw.cast<String, dynamic>();
      final ids = (m['trackIds'] as List).cast<String>();
      final tracks = <Track>[];
      for (final id in ids) {
        final t = byId[id];
        if (t != null) tracks.add(t);
      }
      return Playlist(
        id: m['id'] as String,
        name: m['name'] as String,
        coverUrl: (m['coverUrl'] as String?) ?? '',
        tracks: tracks,
      );
    }).toList();
  }

  Future<void> cachePlaylists(List<Playlist> playlists) async {
    await _playlists.clear();
    final entries = {for (final p in playlists) p.id: _playlistToMap(p)};
    await _playlists.putAll(entries);
  }

  Future<void> upsertPlaylist(Playlist p) async {
    await _playlists.put(p.id, _playlistToMap(p));
  }

  Future<void> removePlaylist(String playlistId) async {
    await _playlists.delete(playlistId);
  }

  // --- Likes ---

  List<String> getLikedIds() {
    final raw = _liked.get('ids');
    if (raw is! List) return [];
    return raw.cast<String>().toList();
  }

  Future<void> setLikedIds(List<String> ids) async {
    await _liked.put('ids', List<String>.from(ids));
  }

  // --- Descargas ---

  String? getDownloadPath(String trackId) {
    final raw = _downloads.get(trackId);
    return raw is String ? raw : null;
  }

  /// Comprueba que el archivo realmente exista en disco; si no, lo desregistra.
  bool isDownloadedAndPresent(String trackId) {
    final path = getDownloadPath(trackId);
    if (path == null) return false;
    if (!File(path).existsSync()) {
      _downloads.delete(trackId);
      return false;
    }
    return true;
  }

  Future<void> setDownloadPath(String trackId, String path) async {
    await _downloads.put(trackId, path);
  }

  Future<void> removeDownload(String trackId) async {
    final path = getDownloadPath(trackId);
    if (path != null) {
      try {
        final f = File(path);
        if (f.existsSync()) await f.delete();
      } catch (_) {
        // Si falla el borrado físico, igual desregistramos para que la app
        // deje de considerar la pista como descargada.
      }
    }
    await _downloads.delete(trackId);
  }

  // --- Cola de escrituras pendientes (FIFO) ---

  List<PendingWrite> getPendingWrites() {
    final raw = _pending.get('queue');
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((m) => PendingWrite.fromMap(m))
        .toList();
  }

  Future<void> enqueuePending(PendingWrite op) async {
    final list = getPendingWrites().map((p) => p.toMap()).toList();
    list.add(op.toMap());
    await _pending.put('queue', list);
  }

  Future<void> removeFirstPending() async {
    final list = getPendingWrites().map((p) => p.toMap()).toList();
    if (list.isEmpty) return;
    list.removeAt(0);
    await _pending.put('queue', list);
  }

  Future<void> clearPending() async {
    await _pending.delete('queue');
  }

  // --- Helpers de serialización ---

  Map<String, dynamic> _trackToMap(Track t) => t.toMap();

  Track _trackFromMap(Map<String, dynamic> m) =>
      Track.fromMap(m, m['id'] as String);

  Map<String, dynamic> _playlistToMap(Playlist p) => {
        'id': p.id,
        'name': p.name,
        'coverUrl': p.coverUrl,
        'trackIds': p.tracks.map((t) => t.id).toList(),
      };
}
