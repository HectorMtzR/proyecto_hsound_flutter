import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa a un usuario autenticado en la aplicación.
class User {
  /// Identificador único del usuario (UID de Firebase).
  final String id;

  /// Nombre para mostrar del usuario en la interfaz.
  final String displayName;

  /// Correo electrónico asociado a la cuenta.
  final String email;

  User({
    required this.id,
    required this.displayName,
    required this.email,
  });
}

/// Modelo que representa una canción o pista de audio en el catálogo.
class Track {
  /// Identificador único de la canción en la base de datos (Firestore).
  final String id;

  /// Título principal de la canción.
  final String title;

  /// Nombre del artista o banda.
  final String artist;

  /// Nombre del álbum al que pertenece la pista.
  final String album;

  /// URL pública de la imagen de portada almacenada en la nube.
  final String coverUrl;

  /// URL pública del archivo de audio (MP3, WAV, etc.) para streaming.
  final String audioUrl;

  /// Duración pre-formateada de la canción (ej. "3:45").
  final String duration;

  /// Género musical (ej. "Son Jarocho", "Cumbia", "Banda").
  final String? genre;

  /// Región geográfica asociada (ej. "Oaxaca", "Veracruz").
  final String? region;

  /// Idioma de la letra (ej. "Español", "Zapoteco", "Instrumental").
  final String? language;

  /// Código ISRC para integración futura con servicios de reconocimiento.
  final String? isrc;

  /// Año de lanzamiento.
  final int? releaseYear;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.coverUrl,
    required this.audioUrl,
    required this.duration,
    this.genre,
    this.region,
    this.language,
    this.isrc,
    this.releaseYear,
  });

  /// Crea una copia con campos individuales reemplazados. Útil para
  /// decorar tracks existentes con metadata regional sin reconstruir todo.
  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? coverUrl,
    String? audioUrl,
    String? duration,
    String? genre,
    String? region,
    String? language,
    String? isrc,
    int? releaseYear,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverUrl: coverUrl ?? this.coverUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      genre: genre ?? this.genre,
      region: region ?? this.region,
      language: language ?? this.language,
      isrc: isrc ?? this.isrc,
      releaseYear: releaseYear ?? this.releaseYear,
    );
  }

  /// Deserializa un [Track] desde un documento de Firestore aplicando
  /// los mismos defaults que la versión histórica de `fetchTracks()`.
  factory Track.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Track.fromMap(doc.data() ?? const {}, doc.id);
  }

  /// Deserializa un [Track] desde un `Map<String, dynamic>` arbitrario
  /// (Hive, Firestore, snapshots de prueba). Los campos regionales son
  /// opcionales — un map sin ellos produce un Track válido sin metadata.
  factory Track.fromMap(Map<String, dynamic> data, String id) {
    return Track(
      id: id,
      title: (data['title'] as String?) ?? 'Sin título',
      artist: (data['artist'] as String?) ?? 'Artista desconocido',
      album: (data['album'] as String?) ?? 'Sencillo',
      coverUrl: (data['coverUrl'] as String?) ?? '',
      audioUrl: (data['audioUrl'] as String?) ?? '',
      duration: (data['duration'] as String?) ?? '0:00',
      genre: data['genre'] as String?,
      region: data['region'] as String?,
      language: data['language'] as String?,
      isrc: data['isrc'] as String?,
      releaseYear: (data['releaseYear'] as num?)?.toInt(),
    );
  }

  /// Serializa el track para Firestore. Los campos regionales solo se
  /// incluyen si tienen valor, evitando contaminar documentos antiguos
  /// con `null`s al re-cachear.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'coverUrl': coverUrl,
      'audioUrl': audioUrl,
      'duration': duration,
      if (genre != null) 'genre': genre,
      if (region != null) 'region': region,
      if (language != null) 'language': language,
      if (isrc != null) 'isrc': isrc,
      if (releaseYear != null) 'releaseYear': releaseYear,
    };
  }

  /// Serializa el track para Hive (incluye `id` porque no hay
  /// `DocumentSnapshot` que lo provea por separado).
  Map<String, dynamic> toMap() {
    return {'id': id, ...toFirestore()};
  }
}

/// Modelo que representa una lista de reproducción.
///
/// Puede ser una lista creada por el usuario o una lista generada
/// por el sistema (como "Tus me gusta" o "Mi Mix").
class Playlist {
  /// Identificador único de la lista de reproducción.
  final String id;

  /// Nombre visible de la lista.
  final String name;

  /// Colección de canciones ([Track]) que pertenecen a esta lista.
  final List<Track> tracks;

  /// URL de la imagen de portada de la lista. Puede estar vacía si no se asignó.
  final String coverUrl;

  Playlist({
    required this.id,
    required this.name,
    required this.tracks,
    this.coverUrl = '',
  });
}
