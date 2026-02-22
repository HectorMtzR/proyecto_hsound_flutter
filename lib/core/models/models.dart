class User {
  final String id;
  final String displayName;
  final String email;

  User({required this.id, required this.displayName, required this.email});
}

class Track {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String audioUrl;
  final String duration;

  Track({required this.id, required this.title, required this.artist, required this.coverUrl, required this.audioUrl, required this.duration});
}

class Playlist {
  final String id;
  final String name;
  final List<Track> tracks;

  Playlist({required this.id, required this.name, required this.tracks});
}