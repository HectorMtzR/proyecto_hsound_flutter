/// Origen del resultado de reconocimiento. La fase 1 sólo emite [external];
/// el enum existe para que la fase 2 (matching contra catálogo propio) pueda
/// reutilizar el mismo modelo sin tocar consumidores.
enum RecognitionSource { library, external }

/// Resultado normalizado de un reconocimiento de audio. Independiente del
/// proveedor (AudD, ACRCloud, etc.).
class RecognitionResult {
  final String title;
  final String artist;
  final String? album;
  final String? isrc;
  final String? spotifyId;
  final String? appleMusicId;
  final String? releaseDate;
  final String? coverUrl;
  final RecognitionSource source;

  const RecognitionResult({
    required this.title,
    required this.artist,
    required this.source,
    this.album,
    this.isrc,
    this.spotifyId,
    this.appleMusicId,
    this.releaseDate,
    this.coverUrl,
  });

  /// Construye un [RecognitionResult] a partir del objeto `result` que devuelve
  /// la API de AudD (https://docs.audd.io/). Devuelve `null` si los campos
  /// mínimos (`title` + `artist`) no están presentes.
  static RecognitionResult? fromAudd(Map<String, dynamic> json) {
    final title = (json['title'] as String?)?.trim();
    final artist = (json['artist'] as String?)?.trim();
    if (title == null || title.isEmpty || artist == null || artist.isEmpty) {
      return null;
    }

    final spotify = json['spotify'];
    final apple = json['apple_music'];

    return RecognitionResult(
      title: title,
      artist: artist,
      album: (json['album'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['album'] as String).trim(),
      isrc: json['isrc'] as String?,
      releaseDate: json['release_date'] as String?,
      coverUrl: _extractCover(spotify, apple),
      spotifyId: spotify is Map<String, dynamic> ? spotify['id'] as String? : null,
      appleMusicId: apple is Map<String, dynamic> ? apple['id'] as String? : null,
      source: RecognitionSource.external,
    );
  }

  /// Prefiere la portada de Spotify (más estable) sobre la de Apple Music.
  static String? _extractCover(dynamic spotify, dynamic apple) {
    if (spotify is Map<String, dynamic>) {
      final album = spotify['album'];
      if (album is Map<String, dynamic>) {
        final images = album['images'];
        if (images is List && images.isNotEmpty) {
          final first = images.first;
          if (first is Map<String, dynamic>) {
            final url = first['url'];
            if (url is String && url.isNotEmpty) return url;
          }
        }
      }
    }
    if (apple is Map<String, dynamic>) {
      final artwork = apple['artwork'];
      if (artwork is Map<String, dynamic>) {
        final url = artwork['url'];
        if (url is String && url.isNotEmpty) {
          return url
              .replaceAll('{w}', '600')
              .replaceAll('{h}', '600')
              .replaceAll('{f}', 'jpg');
        }
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'artist': artist,
        if (album != null) 'album': album,
        if (isrc != null) 'isrc': isrc,
        if (spotifyId != null) 'spotifyId': spotifyId,
        if (appleMusicId != null) 'appleMusicId': appleMusicId,
        if (releaseDate != null) 'releaseDate': releaseDate,
        if (coverUrl != null) 'coverUrl': coverUrl,
        'source': source.name,
      };

  factory RecognitionResult.fromMap(Map<dynamic, dynamic> data) =>
      RecognitionResult(
        title: data['title'] as String,
        artist: data['artist'] as String,
        album: data['album'] as String?,
        isrc: data['isrc'] as String?,
        spotifyId: data['spotifyId'] as String?,
        appleMusicId: data['appleMusicId'] as String?,
        releaseDate: data['releaseDate'] as String?,
        coverUrl: data['coverUrl'] as String?,
        source: RecognitionSource.values
            .byName((data['source'] as String?) ?? 'external'),
      );

  /// Año extraído de [releaseDate] si está disponible.
  String? get releaseYear {
    final d = releaseDate;
    if (d == null || d.isEmpty) return null;
    final match = RegExp(r'^(\d{4})').firstMatch(d);
    return match?.group(1);
  }
}
