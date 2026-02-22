import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'; // <-- Importamos just_audio
import '../models/models.dart';

class MockRepository extends ChangeNotifier {
  User? currentUser;
  Track? currentTrack;
  bool isPlaying = false;

  // 1. Instanciamos el reproductor real
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 2. Arreglo con tus URLs de CloudFront
  static const List<String> cloudFrontUrls = [
  'https://d18au5kb13bfls.cloudfront.net/444.mp3',
  'https://d18au5kb13bfls.cloudfront.net/beatit.mp3',
  'https://d18au5kb13bfls.cloudfront.net/besosalaire.mp3',
  'https://d18au5kb13bfls.cloudfront.net/bigassbracelet.mp3',
  'https://d18au5kb13bfls.cloudfront.net/cream.mp3',
  'https://d18au5kb13bfls.cloudfront.net/cuandonoeracantante.mp3',
  'https://d18au5kb13bfls.cloudfront.net/cultofpersonality.mp3',
  'https://d18au5kb13bfls.cloudfront.net/dalefuego.mp3',
  'https://d18au5kb13bfls.cloudfront.net/daytona.mp3',
  'https://d18au5kb13bfls.cloudfront.net/deseo.mp3',
  'https://d18au5kb13bfls.cloudfront.net/elsinaloense.mp3',
  'https://d18au5kb13bfls.cloudfront.net/energy.mp3',
  'https://d18au5kb13bfls.cloudfront.net/evamaria.mp3',
  'https://d18au5kb13bfls.cloudfront.net/guitarrasblancas.mp3',
  'https://d18au5kb13bfls.cloudfront.net/indomable.mp3',
  'https://d18au5kb13bfls.cloudfront.net/karigantime.mp3',
  'https://d18au5kb13bfls.cloudfront.net/labrujita.mp3',
  'https://d18au5kb13bfls.cloudfront.net/lamesadelrincon.mp3',
  'https://d18au5kb13bfls.cloudfront.net/lifesabitch.mp3',
  'https://d18au5kb13bfls.cloudfront.net/mienteme.mp3',
  'https://d18au5kb13bfls.cloudfront.net/milhoras.mp3',
  'https://d18au5kb13bfls.cloudfront.net/nuthinbutagthang.mp3',
  'https://d18au5kb13bfls.cloudfront.net/ohquesera.mp3',
  'https://d18au5kb13bfls.cloudfront.net/ojosnegros.mp3',
  'https://d18au5kb13bfls.cloudfront.net/playasmarinas.mp3',
  'https://d18au5kb13bfls.cloudfront.net/psychosocial.mp3',
  'https://d18au5kb13bfls.cloudfront.net/rebelyell.mp3',
  'https://d18au5kb13bfls.cloudfront.net/recordandote.mp3',
  'https://d18au5kb13bfls.cloudfront.net/situnoestas.mp3',
  'https://d18au5kb13bfls.cloudfront.net/theunforgiven.mp3',
  'https://d18au5kb13bfls.cloudfront.net/timeless.mp3',
  'https://d18au5kb13bfls.cloudfront.net/uncoco.mp3',
  'https://d18au5kb13bfls.cloudfront.net/unforgettable.mp3',
  'https://d18au5kb13bfls.cloudfront.net/unlocosolitario.mp3',
  'https://d18au5kb13bfls.cloudfront.net/urge.mp3',
  'https://d18au5kb13bfls.cloudfront.net/vestidoblanco.mp3',
];

  int longitud = cloudFrontUrls.length;

  late final List<Track> allTracks;
  late List<Playlist> userPlaylists;

  MockRepository() {
    // 3. Generamos los tracks usando el índice para asignar la URL del arreglo
    allTracks = List.generate(
      longitud,
      (index) {
        // Usamos el operador módulo (%) para repetir las canciones si hay más tracks que URLs
        final urlIndex = index % cloudFrontUrls.length; 
        
        return Track(
          id: 't_$index',
          title: 'Canción ${index + 1}',
          artist: 'Artista ${index + 1}',
          coverUrl: 'https://picsum.photos/seed/$index/200',
          audioUrl: cloudFrontUrls[urlIndex], // Asignamos la URL real
          duration: '3:00',
        );
      },
    );

    userPlaylists = [
      Playlist(id: 'p_1', name: 'Favoritas', tracks: allTracks.sublist(0, 5)),
      Playlist(id: 'p_2', name: 'Chamba', tracks: allTracks.sublist(5, 12)),
    ];

    // 4. Escuchamos los cambios de estado del reproductor real para actualizar la UI
    _audioPlayer.playerStateStream.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
    });
  }

  void login(String email, String password) {
    currentUser = User(id: 'u_1', displayName: 'Hector', email: email);
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    currentTrack = null;
    _audioPlayer.stop(); // Detenemos la música al salir
    notifyListeners();
  }

  void createPlaylist(String name) {
    userPlaylists.add(Playlist(id: 'p_${DateTime.now().millisecondsSinceEpoch}', name: name, tracks: []));
    notifyListeners();
  }

  // 5. Lógica real de reproducción
  Future<void> playTrack(Track track) async {
    currentTrack = track;
    notifyListeners(); // Actualiza la UI para mostrar el mini-player

    try {
      // Carga la URL de CloudFront y le da play
      await _audioPlayer.setUrl(track.audioUrl);
      _audioPlayer.play();
    } catch (e) {
      debugPrint("Error al reproducir audio: $e");
    }
  }

  void togglePlay() {
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  // Es buena práctica liberar recursos cuando ya no se usa
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}