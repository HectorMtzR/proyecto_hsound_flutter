import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:uuid/uuid.dart';

import '../../main.dart' show rootScaffoldMessengerKey;
import '../models/models.dart';
import '../services/oci_upload_service.dart';
import '../utils/app_logger.dart';

/// Repositorio principal de la aplicación.
///
/// Actúa como la única fuente de la verdad (Single Source of Truth) conectando
/// la interfaz de usuario con los servicios de Firebase (Auth, Firestore) y Oracle Cloud (OCI).
/// Gestiona el estado global de reproducción de audio usando [just_audio].
class MockRepository extends ChangeNotifier {
  static const String _tag = 'MockRepository';

  User? currentUser;
  Track? currentTrack;
  bool isPlaying = false;
  
  // --- Estados de Reproducción ---
  bool isShuffle = false;
  List<Track> currentQueue = [];
  int currentQueueIndex = -1;
  String? currentPlaylistContextId; 
  List<Track> upNextQueue = []; 

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Instancias de Firebase
  final _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Servicio de subida (inyectable para tests)
  final OciUploadService _uploadService;

  /// Muestra un SnackBar accionable usando la llave global del messenger.
  /// No-op si la app aún no montó el messenger.
  void _notify(String message) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Duration get currentDuration => _audioPlayer.duration ?? Duration.zero;

  // --- Datos del Catálogo ---
  List<Track> allTracks = []; 
  late List<Playlist> userPlaylists;
  List<String> likedTrackIds = []; 
  bool isLoadingTracks = false; 

  MockRepository({OciUploadService? uploadService})
      : _uploadService = uploadService ?? OciUploadService() {
    userPlaylists = [
      Playlist(id: 'p_likes', name: 'Tus me gusta', tracks: []),
      Playlist(id: 'p_1', name: 'Mi Mix', tracks: []), 
    ];

    // Escucha de estado de reproducción nativa
    _audioPlayer.playerStateStream.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
    });

    // Escucha de cambio de pista (app o background)
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && currentQueue.isNotEmpty && index < currentQueue.length) {
        currentQueueIndex = index;
        currentTrack = currentQueue[index];
        notifyListeners();
      }
    });

    _checkAuthState();
  }

  /// Agrupa las pistas del catálogo actual por el nombre de su álbum.
  /// 
  /// Retorna un mapa donde la llave es el nombre del álbum y el valor es la lista de [Track].
  Map<String, List<Track>> get groupedByAlbum {
    final Map<String, List<Track>> albumMap = {};
    for (var track in allTracks) {
      if (!albumMap.containsKey(track.album)) {
        albumMap[track.album] = [];
      }
      albumMap[track.album]!.add(track);
    }
    return albumMap;
  }

  /// Descarga el catálogo global de canciones desde Firestore.
  /// 
  /// Falla silenciosamente en caso de error de red para usar la caché de Firebase,
  /// evitando que la aplicación se cierre inesperadamente en el inicio.
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
          album: data['album'] ?? 'Sencillo',
          coverUrl: data['coverUrl'] ?? '',
          audioUrl: data['audioUrl'] ?? '',
          duration: data['duration'] ?? '0:00',
        ));
      }

      if (allTracks.isNotEmpty) {
        final miMix = userPlaylists.firstWhere((p) => p.id == 'p_1');
        miMix.tracks.clear();
        miMix.tracks.addAll(allTracks.take(10));
      }
    } catch (e, s) {
      // Firestore intentará servir desde caché; sólo registramos.
      AppLogger.warn(
        'No se pudo descargar el catálogo, usando caché',
        error: e,
        stack: s,
        tag: _tag,
      );
    } finally {
      isLoadingTracks = false;
      notifyListeners();
    }
  }

  /// Descarga las listas de reproducción creadas por el usuario autenticado.
  Future<void> fetchUserPlaylists() async {
    if (currentUser == null) return;

    try {
      final snapshot = await _firestore
          .collection('playlists')
          .where('ownerId', isEqualTo: currentUser!.id)
          .get();

      final likesPlaylist = userPlaylists.firstWhere((p) => p.id == 'p_likes');
      final miMix = userPlaylists.firstWhere((p) => p.id == 'p_1');

      userPlaylists.clear();
      userPlaylists.add(likesPlaylist);
      userPlaylists.add(miMix);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        List<dynamic> dbTrackIds = data['trackIds'] ?? [];
        List<Track> playlistTracks = [];

        for (var trackId in dbTrackIds) {
          try {
            final track = allTracks.firstWhere((t) => t.id == trackId.toString());
            playlistTracks.add(track);
          } catch (_) {
            AppLogger.info(
              'Referencia huérfana ignorada en playlist: trackId=$trackId',
              tag: _tag,
            );
          }
        }

        userPlaylists.add(Playlist(
          id: doc.id,
          name: data['name'] ?? 'Playlist',
          coverUrl: data['coverUrl'] ?? '',
          tracks: playlistTracks,
        ));
      }
      notifyListeners();
    } catch (e, s) {
      AppLogger.warn(
        'No se pudieron cargar las playlists, usando caché',
        error: e,
        stack: s,
        tag: _tag,
      );
    }
  }

  /// Monitorea el estado de autenticación de Firebase en tiempo real.
  void _checkAuthState() {
    _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        try {
          final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
          if (doc.exists) {
            currentUser = User(
              id: firebaseUser.uid, 
              displayName: doc.data()?['displayName'] ?? 'Usuario', 
              email: firebaseUser.email!
            );

            List<dynamic> dbLikes = doc.data()?['liked_tracks'] ?? [];
            likedTrackIds = dbLikes.map((e) => e.toString()).toList();

            await fetchTracksFromFirebase();
            await fetchUserPlaylists();
            _syncLikesPlaylist();

            notifyListeners();
          }
        } catch (e, s) {
          AppLogger.warn(
            'Falló la carga inicial de sesión, usando caché si existe',
            error: e,
            stack: s,
            tag: _tag,
          );
        }
      } else {
        currentUser = null;
        likedTrackIds.clear(); 
        allTracks.clear(); 
        _syncLikesPlaylist();
        notifyListeners();
      }
    });
  }

  /// Sincroniza la lista virtual de "Me Gusta" con el catálogo local.
  void _syncLikesPlaylist() {
    final likesPlaylist = userPlaylists.firstWhere((p) => p.id == 'p_likes');
    likesPlaylist.tracks.clear();
    likesPlaylist.tracks.addAll(allTracks.where((t) => likedTrackIds.contains(t.id)));
  }

  // --- MÉTODOS DE AUTENTICACIÓN (Con manejo de red) ---

  /// Registra un nuevo usuario en Firebase Auth y crea su documento en Firestore.
  /// 
  /// Lanza excepciones formateadas listas para ser mostradas en la interfaz.
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
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code.contains('network') || e.code == 'unknown') {
        throw Exception('Sin conexión a internet. Revisa tu red.');
      }
      throw Exception(e.message ?? 'Error al registrar.');
    } catch (_) {
      throw Exception('Ocurrió un error inesperado al registrar.');
    }
  }

  /// Inicia sesión con un usuario existente en Firebase Auth.
  Future<void> login(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code.contains('network') || e.code == 'unknown') {
        throw Exception('Sin conexión a internet. Revisa tu red.');
      }
      throw Exception(e.message ?? 'Credenciales incorrectas.');
    } catch (_) {
      throw Exception('Ocurrió un error inesperado al iniciar sesión.');
    }
  }

  /// Cierra la sesión del usuario actual y detiene el reproductor.
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    currentTrack = null;
    _audioPlayer.stop();
    notifyListeners(); 
  }
  
  // --- MÉTODOS DE REPRODUCCIÓN ---
  
  /// Inicia la reproducción de una pista en un contexto específico (Lista global o Playlist).
  Future<void> playTrackContext(Track track, List<Track> contextQueue, {String? playlistId}) async {
    currentQueue = List.from(contextQueue);
    currentQueueIndex = currentQueue.indexWhere((t) => t.id == track.id);
    currentPlaylistContextId = playlistId;

    currentTrack = track;
    notifyListeners(); 

    try {
      final audioSources = currentQueue.map((t) => AudioSource.uri(
        Uri.parse(t.audioUrl),
        tag: MediaItem(
          id: t.id,
          title: t.title,
          artist: t.artist,
          artUri: t.coverUrl.isNotEmpty ? Uri.parse(t.coverUrl) : null,
        ),
      )).toList();

      final playlist = ConcatenatingAudioSource(children: audioSources);

      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: currentQueueIndex, 
        initialPosition: Duration.zero,
      );
      
      _audioPlayer.play();
    } catch (e, s) {
      AppLogger.error(
        'No se pudo iniciar la reproducción',
        error: e,
        stack: s,
        tag: _tag,
      );
      _notify('No se pudo reproducir la canción. Revisa tu conexión.');
    }
  }

  void togglePlay() {
    _audioPlayer.playing ? _audioPlayer.pause() : _audioPlayer.play();
  }

  void playNext() {
    if (_audioPlayer.hasNext) _audioPlayer.seekToNext();
  }

  void playPrevious() {
    if (_audioPlayer.hasPrevious) _audioPlayer.seekToPrevious();
  }

  Future<void> toggleShuffle() async {
    isShuffle = !isShuffle;
    await _audioPlayer.setShuffleModeEnabled(isShuffle);
    if (isShuffle) await _audioPlayer.shuffle();
    notifyListeners();
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  /// Agrega una pista a la cola de reproducción inmediatamente después de la actual.
  void addToQueueNext(Track track) async {
    if (_audioPlayer.audioSource is ConcatenatingAudioSource) {
      final playlist = _audioPlayer.audioSource as ConcatenatingAudioSource;
      final nextIndex = (_audioPlayer.currentIndex ?? 0) + 1;
      
      final newSource = AudioSource.uri(
        Uri.parse(track.audioUrl),
        tag: MediaItem(id: track.id, title: track.title, artist: track.artist, artUri: track.coverUrl.isNotEmpty ? Uri.parse(track.coverUrl) : null),
      );
      
      await playlist.insert(nextIndex, newSource);
      currentQueue.insert(nextIndex, track); 
      notifyListeners();
    }
  }

  // --- MÉTODOS DE LIKES Y PLAYLISTS ---

  bool isLiked(Track track) => likedTrackIds.contains(track.id);

  /// Alterna el estado de "Me Gusta" de una pista y sincroniza con Firestore.
  Future<void> toggleLike(Track track) async {
    if (currentUser == null) return; 

    final uid = currentUser!.id;
    final userRef = _firestore.collection('users').doc(uid);

    if (isLiked(track)) {
      likedTrackIds.remove(track.id);
      _syncLikesPlaylist();
      notifyListeners();
      try {
        await userRef.update({'liked_tracks': FieldValue.arrayRemove([track.id])});
      } catch (e, s) {
        AppLogger.error(
          'Falló al quitar like de track ${track.id}',
          error: e,
          stack: s,
          tag: _tag,
        );
        // Revertimos el estado optimista
        likedTrackIds.add(track.id);
        _syncLikesPlaylist();
        notifyListeners();
        _notify('No se pudo guardar el like, reintenta cuando tengas conexión.');
      }
    } else {
      likedTrackIds.add(track.id);
      _syncLikesPlaylist();
      notifyListeners();
      try {
        await userRef.update({'liked_tracks': FieldValue.arrayUnion([track.id])});
      } catch (e, s) {
        AppLogger.error(
          'Falló al guardar like de track ${track.id}',
          error: e,
          stack: s,
          tag: _tag,
        );
        // Revertimos el estado optimista
        likedTrackIds.remove(track.id);
        _syncLikesPlaylist();
        notifyListeners();
        _notify('No se pudo guardar el like, reintenta cuando tengas conexión.');
      }
    }
  }

  Future<void> addTrackToPlaylist(String playlistId, Track track) async {
    final playlist = userPlaylists.firstWhere((p) => p.id == playlistId);

    if (!playlist.tracks.any((t) => t.id == track.id)) {
      playlist.tracks.add(track);
      notifyListeners();

      try {
        await _firestore.collection('playlists').doc(playlistId).update({
          'trackIds': FieldValue.arrayUnion([track.id])
        });
      } catch (e, s) {
        AppLogger.error(
          'Falló al agregar track ${track.id} a playlist $playlistId',
          error: e,
          stack: s,
          tag: _tag,
        );
        // Revertimos el estado optimista
        playlist.tracks.removeWhere((t) => t.id == track.id);
        notifyListeners();
        _notify('No se pudo agregar la canción a la playlist. Reintenta cuando tengas conexión.');
      }
    }
  }

  Future<void> removeTrackFromPlaylist(String playlistId, Track track) async {
    final playlist = userPlaylists.firstWhere((p) => p.id == playlistId);

    playlist.tracks.removeWhere((t) => t.id == track.id);
    notifyListeners();

    try {
      await _firestore.collection('playlists').doc(playlistId).update({
        'trackIds': FieldValue.arrayRemove([track.id])
      });
    } catch (e, s) {
      AppLogger.error(
        'Falló al quitar track ${track.id} de playlist $playlistId',
        error: e,
        stack: s,
        tag: _tag,
      );
      // Revertimos el estado optimista
      if (!playlist.tracks.any((t) => t.id == track.id)) {
        playlist.tracks.add(track);
      }
      notifyListeners();
      _notify('No se pudo quitar la canción de la playlist. Reintenta cuando tengas conexión.');
    }
  }

  /// Crea una nueva playlist subiendo primero su portada a OCI mediante una
  /// URL firmada generada por Firebase Functions.
  Future<String> createPlaylistWithImage(String name, File? imageFile) async {
    if (currentUser == null) throw Exception('No user');

    String finalCoverUrl = '';
    final playlistId = const Uuid().v4();

    try {
      if (imageFile != null) {
        finalCoverUrl = await _uploadService.uploadPlaylistCover(imageFile);
      }

      final newPlaylistRef = _firestore.collection('playlists').doc(playlistId);

      await newPlaylistRef.set({
        'name': name,
        'ownerId': currentUser!.id,
        'coverUrl': finalCoverUrl,
        'trackIds': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      userPlaylists.add(Playlist(
        id: playlistId,
        name: name,
        tracks: [],
        coverUrl: finalCoverUrl,
      ));

      notifyListeners();

      return playlistId;
    } on UploadException catch (e, s) {
      AppLogger.error('Falló subida de portada', error: e, stack: s, tag: _tag);
      throw Exception(e.message);
    } catch (e, s) {
      AppLogger.error('Falló crear playlist', error: e, stack: s, tag: _tag);
      throw Exception('Fallo al crear la playlist. Revisa tu conexión.');
    }
  }

  /// Elimina una playlist de Firestore y de la memoria local.
  Future<void> deletePlaylist(String playlistId) async {
    if (playlistId == 'p_likes' || playlistId == 'p_1') return;

    try {
      await _firestore.collection('playlists').doc(playlistId).delete();
      userPlaylists.removeWhere((p) => p.id == playlistId);
      notifyListeners();
    } catch (e, s) {
      AppLogger.error(
        'Falló eliminar playlist $playlistId',
        error: e,
        stack: s,
        tag: _tag,
      );
      throw Exception('No se pudo eliminar la playlist por problemas de red.');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}