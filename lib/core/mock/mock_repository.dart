import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/models.dart';

class MockRepository extends ChangeNotifier {
  User? currentUser;
  Track? currentTrack;
  bool isPlaying = false;
  
  // --- NUEVO: Lógica de Reproducción ---
  bool isShuffle = false;
  List<Track> currentQueue = [];
  int currentQueueIndex = -1;
  String? currentPlaylistContextId; // Para saber si estamos en una playlist o en el Home

  List<Track> upNextQueue = []; //Lista para la cola

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Exponemos los streams para la barra de progreso
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Duration get currentDuration => _audioPlayer.duration ?? Duration.zero;

  // Lista de prueba simulada
  final List<Map<String, dynamic>> _mockDatabaseResponse = [
    {'id': 't_0', 'title': '4:44', 'artist': 'Yan Block', 'coverUrl': 'https://d18au5kb13bfls.cloudfront.net/444_cover.jpg', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/444.mp3', 'duration': '4:44'},
    {'id': 't_1', 'title': 'Beat It', 'artist': 'Michael Jackson', 'coverUrl': 'https://picsum.photos/seed/1/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/beatit.mp3', 'duration': '4:18'},
    {'id': 't_2', 'title': 'Besos al Aire', 'artist': '3BallMTY, América Sierra, Smoky', 'coverUrl': 'https://picsum.photos/seed/2/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/besosalaire.mp3', 'duration': '3:15'},
    {'id': 't_3', 'title': 'Big Ass Bracelet', 'artist': 'Westside Gunn', 'coverUrl': 'https://picsum.photos/seed/3/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/bigassbracelet.mp3', 'duration': '3:20'},
    {'id': 't_4', 'title': 'C.R.E.A.M.', 'artist': 'Wu-Tang Clan', 'coverUrl': 'https://picsum.photos/seed/4/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/cream.mp3', 'duration': '4:12'},
    {'id': 't_5', 'title': 'Cuando No Era Cantante', 'artist': 'El Bogueto, Yung Beef', 'coverUrl': 'https://picsum.photos/seed/5/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/cuandonoeracantante.mp3', 'duration': '3:45'},
    {'id': 't_6', 'title': 'Cult of Personality', 'artist': 'Living Colour', 'coverUrl': 'https://picsum.photos/seed/6/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/cultofpersonality.mp3', 'duration': '4:54'},
    {'id': 't_7', 'title': 'Dale Fuego', 'artist': 'Cartel De Santa, bigman', 'coverUrl': 'https://picsum.photos/seed/7/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/dalefuego.mp3', 'duration': '3:05'},
    {'id': 't_8', 'title': 'Daytona', 'artist': 'Cris MJ', 'coverUrl': 'https://picsum.photos/seed/8/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/daytona.mp3', 'duration': '3:10'},
    {'id': 't_9', 'title': 'Deseo', 'artist': 'Los Yaguarú', 'coverUrl': 'https://picsum.photos/seed/9/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/deseo.mp3', 'duration': '4:30'},
    {'id': 't_10', 'title': 'El Sinaloense', 'artist': 'Valentín Elizalde', 'coverUrl': 'https://picsum.photos/seed/10/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/elsinaloense.mp3', 'duration': '2:55'},
    {'id': 't_11', 'title': 'Energy', 'artist': 'Midnight Generation', 'coverUrl': 'https://picsum.photos/seed/11/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/energy.mp3', 'duration': '3:01'},
    {'id': 't_12', 'title': 'Eva Maria', 'artist': 'Banda Maguey', 'coverUrl': 'https://picsum.photos/seed/12/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/evamaria.mp3', 'duration': '2:45'},
    {'id': 't_13', 'title': 'Guitarras Blancas', 'artist': 'Enanitos Verdes', 'coverUrl': 'https://picsum.photos/seed/13/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/guitarrasblancas.mp3', 'duration': '4:26'},
    {'id': 't_14', 'title': 'Indomable', 'artist': 'Junior Klan', 'coverUrl': 'https://picsum.photos/seed/14/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/indomable.mp3', 'duration': '3:15'},
    {'id': 't_15', 'title': 'Karigan Time', 'artist': 'Karigan', 'coverUrl': 'https://picsum.photos/seed/15/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/karigantime.mp3', 'duration': '3:00'},
    {'id': 't_16', 'title': 'La Brujita', 'artist': 'Patrulla 81', 'coverUrl': 'https://picsum.photos/seed/16/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/labrujita.mp3', 'duration': '3:20'},
    {'id': 't_17', 'title': 'La Mesa Del Rincón', 'artist': 'Los Tigres del Norte', 'coverUrl': 'https://picsum.photos/seed/17/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/lamesadelrincon.mp3', 'duration': '3:40'},
    {'id': 't_18', 'title': 'Life\'s a Bitch', 'artist': 'Nas ft. AZ', 'coverUrl': 'https://picsum.photos/seed/18/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/lifesabitch.mp3', 'duration': '3:30'},
    {'id': 't_19', 'title': 'Miénteme', 'artist': 'Los Primos MX, 3BallMTY', 'coverUrl': 'https://picsum.photos/seed/19/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/mienteme.mp3', 'duration': '2:45'},
    {'id': 't_20', 'title': 'Mil Horas', 'artist': 'La Sonora Dinamita', 'coverUrl': 'https://picsum.photos/seed/20/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/milhoras.mp3', 'duration': '3:25'},
    {'id': 't_21', 'title': 'Nuthin\' But A "G" Thang', 'artist': 'Dr. Dre ft. Snoop Dogg', 'coverUrl': 'https://picsum.photos/seed/21/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/nuthinbutagthang.mp3', 'duration': '3:58'},
    {'id': 't_22', 'title': 'Oh Que Será', 'artist': 'Willie Colón', 'coverUrl': 'https://picsum.photos/seed/22/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/ohquesera.mp3', 'duration': '4:10'},
    {'id': 't_23', 'title': 'Ojos Negros', 'artist': 'Musica Sonidera Inc', 'coverUrl': 'https://picsum.photos/seed/23/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/ojosnegros.mp3', 'duration': '3:05'},
    {'id': 't_24', 'title': 'Playas Marinas', 'artist': 'Super Pegue', 'coverUrl': 'https://picsum.photos/seed/24/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/playasmarinas.mp3', 'duration': '3:10'},
    {'id': 't_25', 'title': 'Psychosocial', 'artist': 'Slipknot', 'coverUrl': 'https://picsum.photos/seed/25/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/psychosocial.mp3', 'duration': '4:43'},
    {'id': 't_26', 'title': 'Rebel Yell', 'artist': 'Billy Idol', 'coverUrl': 'https://picsum.photos/seed/26/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/rebelyell.mp3', 'duration': '4:45'},
    {'id': 't_27', 'title': 'Recordándote', 'artist': 'Javier Solís', 'coverUrl': 'https://picsum.photos/seed/27/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/recordandote.mp3', 'duration': '4:15'},
    {'id': 't_28', 'title': 'Si Tu No Estás', 'artist': 'Banda Maguey', 'coverUrl': 'https://picsum.photos/seed/28/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/situnoestas.mp3', 'duration': '4:00'},
    {'id': 't_29', 'title': 'The Unforgiven', 'artist': 'Metallica', 'coverUrl': 'https://picsum.photos/seed/29/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/theunforgiven.mp3', 'duration': '6:27'},
    {'id': 't_30', 'title': 'Timeless', 'artist': 'The Weeknd', 'coverUrl': 'https://picsum.photos/seed/30/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/timeless.mp3', 'duration': '3:15'},
    {'id': 't_31', 'title': 'Un Coco', 'artist': 'Bad Bunny', 'coverUrl': 'https://picsum.photos/seed/31/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/uncoco.mp3', 'duration': '3:16'},
    {'id': 't_32', 'title': 'Unforgettable', 'artist': 'French Montana', 'coverUrl': 'https://picsum.photos/seed/32/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/unforgettable.mp3', 'duration': '3:53'},
    {'id': 't_33', 'title': 'Un Loco Solitario', 'artist': 'Banda Pequeños Musical', 'coverUrl': 'https://picsum.photos/seed/33/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/unlocosolitario.mp3', 'duration': '2:50'},
    {'id': 't_34', 'title': 'Urge', 'artist': 'Vicente Fernández', 'coverUrl': 'https://picsum.photos/seed/34/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/urge.mp3', 'duration': '3:22'},
    {'id': 't_35', 'title': 'Vestido Blanco', 'artist': 'Cardenales De Nuevo León', 'coverUrl': 'https://picsum.photos/seed/35/200', 'audioUrl': 'https://d18au5kb13bfls.cloudfront.net/vestidoblanco.mp3', 'duration': '3:10'},
  ];

  late final List<Track> allTracks;
  late List<Playlist> userPlaylists;

  MockRepository() {
    allTracks = _mockDatabaseResponse.map((data) => Track(
      id: data['id'], title: data['title'], artist: data['artist'],
      coverUrl: data['coverUrl'], audioUrl: data['audioUrl'], duration: data['duration'],
    )).toList();

    userPlaylists = [
      // NUEVO: Playlist por defecto
      Playlist(id: 'p_likes', name: 'Tus me gusta', tracks: []),
      Playlist(id: 'p_1', name: 'Mi Mix', tracks: allTracks.sublist(0, 2)),
    ];

    // Escuchamos el estado real del reproductor
    _audioPlayer.playerStateStream.listen((state) {
      isPlaying = state.playing;
      // NUEVO: Si la canción termina, pasar a la siguiente
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
      notifyListeners();
    });
  }

  // --- NUEVOS MÉTODOS DE REPRODUCCIÓN ---
  
  // Inicia la música con su contexto (toda la biblioteca o una playlist específica)
  Future<void> playTrackContext(Track track, List<Track> contextQueue, {String? playlistId}) async {
    currentQueue = List.from(contextQueue);
    currentQueueIndex = currentQueue.indexWhere((t) => t.id == track.id);
    currentPlaylistContextId = playlistId;
    
    // Opcional: Al iniciar una nueva playlist desde cero, borramos la cola manual acumulada
    upNextQueue.clear(); 
    
    await _playDirectTrack(track);
  }

  // Método centralizado para reproducir y actualizar UI
  Future<void> _playDirectTrack(Track track) async {
    currentTrack = track;
    notifyListeners(); 

    try {
      await _audioPlayer.setUrl(track.audioUrl);
      _audioPlayer.play();
    } catch (e) {
      debugPrint("Error al reproducir audio: $e");
    }
  }

  void togglePlay() {
    _audioPlayer.playing ? _audioPlayer.pause() : _audioPlayer.play();
  }

  // Lógica inteligente para "Siguiente"
  void playNext() {
    // 1. Revisar si hay canciones en la Fila de Reproducción Manual (Alta prioridad)
    if (upNextQueue.isNotEmpty) {
      // Saca la primera canción que se agregó a la cola (FIFO) y la reproduce
      final nextManualTrack = upNextQueue.removeAt(0);
      _playDirectTrack(nextManualTrack);
      return; // Salimos para no avanzar en el index de la playlist base
    }

    // 2. Si no hay fila manual, seguimos con la playlist normal
    if (currentQueue.isEmpty) return;

    if (isShuffle) {
      currentQueueIndex = Random().nextInt(currentQueue.length);
    } else {
      currentQueueIndex = (currentQueueIndex + 1) % currentQueue.length;
    }
    
    _playDirectTrack(currentQueue[currentQueueIndex]);
  }

  void playPrevious() {
    if (currentQueue.isEmpty) return;
    
    // Al regresar una canción, ignoramos la fila manual
    if (isShuffle) {
      currentQueueIndex = Random().nextInt(currentQueue.length);
    } else {
      currentQueueIndex = (currentQueueIndex - 1) < 0 ? currentQueue.length - 1 : currentQueueIndex - 1;
    }
    _playDirectTrack(currentQueue[currentQueueIndex]);
  }

  void toggleShuffle() {
    isShuffle = !isShuffle;
    notifyListeners();
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  // Corrección de la Fila de Reproducción
  void addToQueueNext(Track track) {
    upNextQueue.add(track); // Las enfila en orden real (la primera en entrar, primera en salir)
    notifyListeners();
  }

  // --- NUEVOS MÉTODOS DE PLAYLISTS Y LIKES ---

  bool isLiked(Track track) {
    return userPlaylists.firstWhere((p) => p.id == 'p_likes').tracks.any((t) => t.id == track.id);
  }

  void toggleLike(Track track) {
    final likes = userPlaylists.firstWhere((p) => p.id == 'p_likes');
    if (isLiked(track)) {
      likes.tracks.removeWhere((t) => t.id == track.id);
    } else {
      likes.tracks.add(track);
    }
    notifyListeners();
  }

  void addTrackToPlaylist(String playlistId, Track track) {
    final playlist = userPlaylists.firstWhere((p) => p.id == playlistId);
    // Evitar repetidos
    if (!playlist.tracks.any((t) => t.id == track.id)) {
      playlist.tracks.add(track);
      notifyListeners();
    }
  }

  void removeTrackFromPlaylist(String playlistId, Track track) {
    final playlist = userPlaylists.firstWhere((p) => p.id == playlistId);
    playlist.tracks.removeWhere((t) => t.id == track.id);
    notifyListeners();
  }

  void createPlaylist(String name) {
    userPlaylists.add(Playlist(id: 'p_${DateTime.now().millisecondsSinceEpoch}', name: name, tracks: []));
    notifyListeners();
  }

  void login(String email, String password) {
    currentUser = User(id: 'u_1', displayName: 'Hector', email: email);
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    currentTrack = null;
    _audioPlayer.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}