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

  Track({
    required this.id, 
    required this.title, 
    required this.artist, 
    required this.album, 
    required this.coverUrl, 
    required this.audioUrl, 
    required this.duration,
  });
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