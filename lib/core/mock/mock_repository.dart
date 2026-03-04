import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../models/models.dart';

class MockRepository extends ChangeNotifier {
  User? currentUser;
  Track? currentTrack;
  bool isPlaying = false;
  
  // --- Lógica de Reproducción ---
  bool isShuffle = false;
  List<Track> currentQueue = [];
  int currentQueueIndex = -1;
  String? currentPlaylistContextId; 

  List<Track> upNextQueue = []; 

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Instancias reales de Firebase
  final _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Duration get currentDuration => _audioPlayer.duration ?? Duration.zero;

  // --- VARIABLES DE DATOS REALES ---
  List<Track> allTracks = []; // Ahora inicia vacía, se llenará desde Firebase
  late List<Playlist> userPlaylists;
  List<String> likedTrackIds = []; 
  bool isLoadingTracks = false; // Indicador de carga para la UI

  MockRepository() {
    // Inicializamos las playlists base (vacías por ahora)
    userPlaylists = [
      Playlist(id: 'p_likes', name: 'Tus me gusta', tracks: []),
      Playlist(id: 'p_1', name: 'Mi Mix', tracks: []), 
    ];

    _audioPlayer.playerStateStream.listen((state) {
      isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
      notifyListeners();
    });

    _checkAuthState();
  }

  // --- MÉTODO PARA DESCARGAR CANCIONES DESDE FIRESTORE ---
  Future<void> fetchTracksFromFirebase() async {
    isLoadingTracks = true;
    notifyListeners(); 

    try {
      final snapshot = await _firestore.collection('tracks').get();
      allTracks.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        allTracks.add(Track(
          id: doc.id, 
          title: data['title'] ?? 'Sin título',
          artist: data['artist'] ?? 'Artista desconocido',
          coverUrl: data['coverUrl'] ?? '',
          audioUrl: data['audioUrl'] ?? '',
          duration: data['duration'] ?? '0:00', // Agregamos un fallback por si falta
        ));
      }

      // Llenamos la playlist "Mi Mix" con las canciones recién descargadas (máximo 10)
      if (allTracks.isNotEmpty) {
        final miMix = userPlaylists.firstWhere((p) => p.id == 'p_1');
        miMix.tracks.clear();
        miMix.tracks.addAll(allTracks.take(10));
      }

    } catch (e) {
      debugPrint("Error al cargar canciones: $e");
    } finally {
      isLoadingTracks = false;
      notifyListeners(); 
    }
  }

  // --- LÓGICA DE SESIÓN Y SINCRONIZACIÓN ---
  void _checkAuthState() {
    _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          currentUser = User(
            id: firebaseUser.uid, 
            displayName: doc.data()?['displayName'] ?? 'Usuario', 
            email: firebaseUser.email!
          );

          List<dynamic> dbLikes = doc.data()?['liked_tracks'] ?? [];
          likedTrackIds = dbLikes.map((e) => e.toString()).toList();

          // 1. DESCARGAMOS EL CATÁLOGO DE CANCIONES
          await fetchTracksFromFirebase();

          // 2. SINCRONIZAMOS LOS LIKES (Ahora sí encontrará las canciones)
          _syncLikesPlaylist();

          notifyListeners();
        }
      } else {
        currentUser = null;
        likedTrackIds.clear(); 
        allTracks.clear(); // Limpiamos el catálogo por seguridad
        _syncLikesPlaylist();
        notifyListeners();
      }
    });
  }

  void _syncLikesPlaylist() {
    final likesPlaylist = userPlaylists.firstWhere((p) => p.id == 'p_likes');
    likesPlaylist.tracks.clear();
    likesPlaylist.tracks.addAll(allTracks.where((t) => likedTrackIds.contains(t.id)));
  }

  // --- MÉTODOS DE AUTENTICACIÓN ---
  Future<void> register(String email, String password, String displayName) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      final uid = userCredential.user!.uid;
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'displayName': displayName,
        'liked_tracks': [], 
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error al registrar: $e");
      rethrow; 
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint("Error al iniciar sesión: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    currentTrack = null;
    _audioPlayer.stop();
    notifyListeners(); 
  }
  
  // --- MÉTODOS DE REPRODUCCIÓN ---
  Future<void> playTrackContext(Track track, List<Track> contextQueue, {String? playlistId}) async {
    currentQueue = List.from(contextQueue);
    currentQueueIndex = currentQueue.indexWhere((t) => t.id == track.id);
    currentPlaylistContextId = playlistId;
    await _playDirectTrack(track);
  }

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

  void playNext() {
    if (upNextQueue.isNotEmpty) {
      final nextManualTrack = upNextQueue.removeAt(0);
      _playDirectTrack(nextManualTrack);
      return; 
    }
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

  void addToQueueNext(Track track) {
    upNextQueue.add(track); 
    notifyListeners();
  }

  // --- MÉTODOS DE LIKES Y PLAYLISTS ---
  bool isLiked(Track track) {
    return likedTrackIds.contains(track.id);
  }

  Future<void> toggleLike(Track track) async {
    if (currentUser == null) return; 

    final uid = currentUser!.id;
    final userRef = _firestore.collection('users').doc(uid);

    if (isLiked(track)) {
      likedTrackIds.remove(track.id);
      _syncLikesPlaylist();
      notifyListeners();
      await userRef.update({
        'liked_tracks': FieldValue.arrayRemove([track.id])
      });
    } else {
      likedTrackIds.add(track.id);
      _syncLikesPlaylist();
      notifyListeners();
      await userRef.update({
        'liked_tracks': FieldValue.arrayUnion([track.id])
      });
    }
  }

  void addTrackToPlaylist(String playlistId, Track track) {
    final playlist = userPlaylists.firstWhere((p) => p.id == playlistId);
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}