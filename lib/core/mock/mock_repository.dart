import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../models/models.dart';
import 'dart:io'; // Para manejar el archivo de la foto
import 'package:minio/minio.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

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

  // --- NUEVA CREACIÓN DE PLAYLISTS CON CÁMARA (AWS S3) Y FIRESTORE ---
  Future<void> createPlaylistWithImage(String name, File? imageFile) async {
    if (currentUser == null) return;
    
    String finalCoverUrl = ''; 
    final playlistId = const Uuid().v4(); // Generamos un ID único

    try {
      // 1. SUBIDA A AWS S3
      if (imageFile != null) {
        // Inicializamos el cliente S3
        // Inicializamos el cliente S3 de forma segura
        final minio = Minio(
          endPoint: 's3.amazonaws.com', 
          region: dotenv.env['AWS_REGION'] ?? 'us-east-1', 
          accessKey: dotenv.env['AWS_ACCESS_KEY'] ?? '', 
          secretKey: dotenv.env['AWS_SECRET_KEY'] ?? '', 
        );

        final bucketName = dotenv.env['AWS_BUCKET_NAME'] ?? '';
        
        // Extraemos la extensión de la foto (.jpg, .png) y le damos un nombre único
        final extension = imageFile.path.split('.').last;
        final fileName = 'covers/${DateTime.now().millisecondsSinceEpoch}.$extension';

        // 1. Leemos el archivo físico y lo convertimos a bytes (Uint8List)
        final bytes = await imageFile.readAsBytes();
        
        // 2. Lo envolvemos en un Stream (que es lo que pide MinIO en Dart)
        final stream = Stream.value(bytes);

        // 3. Subimos el objeto a AWS S3 con 'putObject'
        await minio.putObject(
          bucketName, 
          fileName, 
          stream,
          size: bytes.length,
          // Opcional: Le decimos a S3 que es una imagen para que el navegador sepa cómo tratarla
          metadata: {'Content-Type': 'image/$extension'}, 
        );
        
        // 2. CONSTRUIMOS LA URL PÚBLICA USANDO TU CDN (CLOUDFRONT)
        final cloudFrontDomain = dotenv.env['AWS_CLOUDFRONT_DOMAIN'] ?? 'd18au5kb13bfls.cloudfront.net';
        
        // El fileName ya incluye la carpeta 'covers/', así que la URL queda perfecta:
        finalCoverUrl = 'https://$cloudFrontDomain/$fileName';
      }

      // 3. GUARDAMOS EN FIRESTORE
      final newPlaylistRef = _firestore.collection('playlists').doc(playlistId);
      
      await newPlaylistRef.set({
        'name': name,
        'ownerId': currentUser!.id,
        'coverUrl': finalCoverUrl,
        'trackIds': [], 
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. ACTUALIZACIÓN OPTIMISTA EN LA UI
      userPlaylists.add(Playlist(
        id: playlistId, 
        name: name, 
        tracks: [],
        coverUrl: finalCoverUrl
      ));
      
      notifyListeners();

    } catch (e) {
      debugPrint("Error al crear la playlist: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}