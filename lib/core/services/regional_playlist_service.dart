import '../models/models.dart';
import '../models/regional_playlist.dart';

/// Servicio sin estado que agrupa tracks por metadata regional y produce
/// playlists destacadas. Los métodos son puros: dado el mismo catálogo,
/// devuelven el mismo resultado, lo que facilita pruebas unitarias futuras.
class RegionalPlaylistService {
  /// Idiomas indígenas reconocidos. Los grupos que contengan al menos un
  /// track en alguno de estos idiomas se priorizan al armar la lista
  /// destacada.
  static const Set<String> _indigenousLanguages = {
    'Zapoteco',
    'Náhuatl',
    'Mixteco',
    'Mixe',
    'Triqui',
    'Chinanteco',
  };

  /// Máximo de playlists destacadas que se muestran en Inicio.
  static const int _maxFeatured = 6;

  /// Agrupa tracks por `genre`. Ignora tracks sin género o con género vacío.
  /// Solo conserva grupos con al menos 2 tracks.
  Map<String, List<Track>> getPlaylistsByGenre(List<Track> catalog) {
    return _groupBy(catalog, (t) => t.genre);
  }

  /// Agrupa tracks por `region`. Ignora tracks sin región o con región vacía.
  /// Solo conserva grupos con al menos 2 tracks.
  Map<String, List<Track>> getPlaylistsByRegion(List<Track> catalog) {
    return _groupBy(catalog, (t) => t.region);
  }

  /// Devuelve hasta 6 playlists destacadas combinando agrupaciones por
  /// género y región. Prioriza:
  /// 1. Grupos con al menos un track en idioma indígena.
  /// 2. Grupos con más tracks.
  List<RegionalPlaylist> getFeaturedRegionalPlaylists(List<Track> catalog) {
    final byGenre = getPlaylistsByGenre(catalog);
    final byRegion = getPlaylistsByRegion(catalog);

    final candidates = <RegionalPlaylist>[
      for (final entry in byGenre.entries)
        RegionalPlaylist(
          id: 'regional_genre_${RegionalPlaylist.slugify(entry.key)}',
          name: entry.key,
          type: RegionalPlaylistType.genre,
          tracks: entry.value,
        ),
      for (final entry in byRegion.entries)
        RegionalPlaylist(
          id: 'regional_region_${RegionalPlaylist.slugify(entry.key)}',
          name: entry.key,
          type: RegionalPlaylistType.region,
          tracks: entry.value,
        ),
    ];

    candidates.sort((a, b) {
      final aIndigenous = _hasIndigenous(a.tracks) ? 0 : 1;
      final bIndigenous = _hasIndigenous(b.tracks) ? 0 : 1;
      if (aIndigenous != bIndigenous) return aIndigenous - bIndigenous;
      return b.tracks.length.compareTo(a.tracks.length);
    });

    return candidates.take(_maxFeatured).toList();
  }

  Map<String, List<Track>> _groupBy(
    List<Track> catalog,
    String? Function(Track) keyOf,
  ) {
    final groups = <String, List<Track>>{};
    for (final t in catalog) {
      final key = keyOf(t);
      if (key == null || key.isEmpty) continue;
      groups.putIfAbsent(key, () => []).add(t);
    }
    groups.removeWhere((_, tracks) => tracks.length < 2);
    return groups;
  }

  bool _hasIndigenous(List<Track> tracks) {
    for (final t in tracks) {
      if (t.language != null && _indigenousLanguages.contains(t.language)) {
        return true;
      }
    }
    return false;
  }
}
