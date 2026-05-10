import 'package:hive_flutter/hive_flutter.dart';

/// Bootstrap centralizado de Hive para la persistencia offline.
///
/// Se inicializa una sola vez desde [main] antes de [runApp]. Define los
/// nombres de las cajas como constantes y las abre todas en paralelo.
class LocalDb {
  LocalDb._();

  /// Catálogo global de pistas: `Map<String, Map<String, dynamic>>` indexado por trackId.
  static const tracksBox = 'tracks';

  /// Playlists del usuario actual: `Map<String, Map<String, dynamic>>` por playlistId.
  static const playlistsBox = 'playlists';

  /// IDs de pistas marcadas como "Me gusta": `List<String>` bajo la llave `'ids'`.
  static const likedTracksBox = 'liked_track_ids';

  /// Cola FIFO de operaciones que no pudieron sincronizarse con el servidor:
  /// `List<Map<String, dynamic>>` bajo la llave `'queue'`.
  static const pendingWritesBox = 'pending_writes';

  /// Mapa `trackId → ruta absoluta del archivo MP3 descargado`.
  static const downloadsBox = 'downloads';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(tracksBox),
      Hive.openBox(playlistsBox),
      Hive.openBox(likedTracksBox),
      Hive.openBox(pendingWritesBox),
      Hive.openBox(downloadsBox),
    ]);
  }

  /// Limpia datos asociados al usuario que cierra sesión. El catálogo global
  /// y las descargas se conservan deliberadamente para no obligar a re-bajar.
  static Future<void> clearUserScoped() async {
    await Future.wait([
      Hive.box(playlistsBox).clear(),
      Hive.box(likedTracksBox).clear(),
      Hive.box(pendingWritesBox).clear(),
    ]);
  }
}
