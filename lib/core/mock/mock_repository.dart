import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:uuid/uuid.dart';

import '../../main.dart' show rootScaffoldMessengerKey;
import '../data/connectivity_watcher.dart';
import '../data/download_service.dart';
import '../data/local_db.dart';
import '../data/local_repository.dart';
import '../data/remote_repository.dart';
import '../models/models.dart';
import '../models/regional_playlist.dart';
import '../services/oci_upload_service.dart';
import '../services/regional_playlist_service.dart';
import '../utils/app_logger.dart';

/// Fachada offline-first sobre [LocalRepository] (Hive),
/// [RemoteRepository] (Firestore/Auth) y [ConnectivityWatcher].
///
/// Conserva el nombre y las firmas históricas para no romper imports en las
/// pantallas. Internamente:
/// - Hidrata el estado desde Hive antes de pedir nada a la red.
/// - Aplica cambios optimistas y los persiste en Hive de inmediato.
/// - Si una escritura falla, encola la operación en `pending_writes` y la
///   drena cuando vuelve la conexión, en orden FIFO.
class MockRepository extends ChangeNotifier {
  static const String _tag = 'MockRepository';

  // --- Estado público (mismo shape que la versión previa) ---
  User? currentUser;
  Track? currentTrack;
  bool isPlaying = false;

  bool isShuffle = false;
  List<Track> currentQueue = [];
  int currentQueueIndex = -1;
  String? currentPlaylistContextId;
  List<Track> upNextQueue = [];

  List<Track> allTracks = [];
  late List<Playlist> userPlaylists;
  List<String> likedTrackIds = [];
  bool isLoadingTracks = false;

  // --- Reproductor ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Duration get currentDuration => _audioPlayer.duration ?? Duration.zero;

  // --- Capas internas ---
  final LocalRepository _local;
  final RemoteRepository _remote;
  final ConnectivityWatcher _connectivity;
  final DownloadService _downloads;
  final RegionalPlaylistService _regionalService = RegionalPlaylistService();

  MockRepository({
    OciUploadService? uploadService,
    LocalRepository? local,
    RemoteRepository? remote,
    ConnectivityWatcher? connectivity,
    DownloadService? downloads,
  })  : _local = local ?? LocalRepository(),
        _remote = remote ?? RemoteRepository(uploadService: uploadService),
        _connectivity = connectivity ?? ConnectivityWatcher(),
        _downloads = downloads ?? DownloadService() {
    userPlaylists = _systemPlaylists();

    _audioPlayer.playerStateStream.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && currentQueue.isNotEmpty && index < currentQueue.length) {
        currentQueueIndex = index;
        currentTrack = currentQueue[index];
        notifyListeners();
      }
    });

    _connectivity.start(onReconnect: _drainPending);
    _checkAuthState();
  }

  List<Playlist> _systemPlaylists() => [
        Playlist(id: 'p_likes', name: 'Tus me gusta', tracks: []),
        Playlist(id: 'p_1', name: 'Mi Mix', tracks: []),
      ];

  void _notify(String message) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  Map<String, List<Track>> get groupedByAlbum {
    final Map<String, List<Track>> albumMap = {};
    for (var track in allTracks) {
      albumMap.putIfAbsent(track.album, () => []).add(track);
    }
    return albumMap;
  }

  /// Playlists regionales destacadas, generadas en runtime a partir del
  /// catálogo actual. Vacía si ningún track tiene metadata regional.
  List<RegionalPlaylist> get regionalPlaylists =>
      _regionalService.getFeaturedRegionalPlaylists(allTracks);

  /// Decora los primeros tracks del catálogo con metadata regional para que
  /// la sección "Música Regional" sea visible sin tocar Firestore. Cada par
  /// comparte género/región para que cumpla el mínimo de 2 tracks por grupo.
  List<Track> _withRegionalSeed(List<Track> fetched) {
    if (fetched.length < 4) return fetched;
    const seed = <Map<String, String>>[
      {'genre': 'Son Jarocho', 'region': 'Veracruz', 'language': 'Español'},
      {'genre': 'Son Jarocho', 'region': 'Veracruz', 'language': 'Español'},
      {'genre': 'Música Zapoteca', 'region': 'Oaxaca', 'language': 'Zapoteco'},
      {'genre': 'Música Zapoteca', 'region': 'Oaxaca', 'language': 'Zapoteco'},
    ];
    return [
      for (var i = 0; i < fetched.length; i++)
        if (i < seed.length)
          fetched[i].copyWith(
            genre: seed[i]['genre'],
            region: seed[i]['region'],
            language: seed[i]['language'],
          )
        else
          fetched[i],
    ];
  }

  // --- Estado de autenticación ---

  void _checkAuthState() {
    _remote.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        _hydrateFromLocal(uid: firebaseUser.uid, email: firebaseUser.email ?? '');
        notifyListeners();

        if (await _connectivity.isOnline()) {
          await _refreshFromRemote(firebaseUser);
          await _drainPending();
        }
      } else {
        currentUser = null;
        likedTrackIds = [];
        allTracks = [];
        userPlaylists = _systemPlaylists();
        await LocalDb.clearUserScoped();
        await _audioPlayer.stop();
        currentTrack = null;
        notifyListeners();
      }
    });
  }

  void _hydrateFromLocal({required String uid, required String email}) {
    likedTrackIds = _local.getLikedIds();
    allTracks = _local.getCachedTracks();
    final cached = _local.getCachedPlaylists(allTracks);
    userPlaylists = [..._systemPlaylists(), ...cached];
    if (allTracks.isNotEmpty) {
      final miMix = userPlaylists.firstWhere((p) => p.id == 'p_1');
      miMix.tracks
        ..clear()
        ..addAll(allTracks.take(10));
    }
    _syncLikesPlaylist();
    currentUser = User(id: uid, displayName: 'Usuario', email: email);
  }

  Future<void> _refreshFromRemote(firebase_auth.User firebaseUser) async {
    isLoadingTracks = true;
    notifyListeners();

    try {
      final userDoc = await _remote.fetchUserDoc(firebaseUser.uid);
      if (userDoc != null) {
        currentUser = User(
          id: firebaseUser.uid,
          displayName: userDoc.displayName,
          email: firebaseUser.email ?? '',
        );
        likedTrackIds = userDoc.likedTrackIds;
        await _local.setLikedIds(likedTrackIds);
      }

      final fetched = await _remote.fetchTracks();
      if (fetched.isNotEmpty) {
        allTracks = _withRegionalSeed(fetched);
        await _local.cacheTracks(allTracks);
        final miMix = userPlaylists.firstWhere((p) => p.id == 'p_1');
        miMix.tracks
          ..clear()
          ..addAll(allTracks.take(10));
      }

      final remote = await _remote.fetchUserPlaylists(firebaseUser.uid, allTracks);
      final likes = userPlaylists.firstWhere((p) => p.id == 'p_likes');
      final mix = userPlaylists.firstWhere((p) => p.id == 'p_1');
      userPlaylists = [likes, mix, ...remote];
      await _local.cachePlaylists(remote);
      _syncLikesPlaylist();
    } catch (e, s) {
      AppLogger.warn(
        'Falló refresh remoto, se mantiene el caché local',
        error: e,
        stack: s,
        tag: _tag,
      );
    } finally {
      isLoadingTracks = false;
      notifyListeners();
    }
  }

  /// Refresco manual del catálogo (mantiene firma original para compatibilidad).
  Future<void> fetchTracksFromFirebase() async {
    if (!await _connectivity.isOnline()) return;
    try {
      final fetched = await _remote.fetchTracks();
      if (fetched.isNotEmpty) {
        allTracks = _withRegionalSeed(fetched);
        await _local.cacheTracks(allTracks);
        final miMix = userPlaylists.firstWhere((p) => p.id == 'p_1');
        miMix.tracks
          ..clear()
          ..addAll(allTracks.take(10));
        _syncLikesPlaylist();
        notifyListeners();
      }
    } catch (e, s) {
      AppLogger.warn('Falló refresco de catálogo', error: e, stack: s, tag: _tag);
    }
  }

  /// Refresco manual de playlists (mantiene firma original).
  Future<void> fetchUserPlaylists() async {
    if (currentUser == null) return;
    if (!await _connectivity.isOnline()) return;
    try {
      final remote = await _remote.fetchUserPlaylists(currentUser!.id, allTracks);
      final likes = userPlaylists.firstWhere((p) => p.id == 'p_likes');
      final mix = userPlaylists.firstWhere((p) => p.id == 'p_1');
      userPlaylists = [likes, mix, ...remote];
      await _local.cachePlaylists(remote);
      notifyListeners();
    } catch (e, s) {
      AppLogger.warn('Falló refresco de playlists', error: e, stack: s, tag: _tag);
    }
  }

  void _syncLikesPlaylist() {
    final likesPlaylist = userPlaylists.firstWhere((p) => p.id == 'p_likes');
    likesPlaylist.tracks.clear();
    likesPlaylist.tracks.addAll(allTracks.where((t) => likedTrackIds.contains(t.id)));
  }

  // --- Auth ---

  Future<void> register(String email, String password, String displayName) =>
      _remote.register(email, password, displayName);

  Future<void> login(String email, String password) =>
      _remote.login(email, password);

  Future<void> logout() async {
    await _remote.logout();
    currentTrack = null;
    await _audioPlayer.stop();
    notifyListeners();
  }

  // --- Reproducción ---

  Future<void> playTrackContext(
    Track track,
    List<Track> contextQueue, {
    String? playlistId,
  }) async {
    currentQueue = List.from(contextQueue);
    currentQueueIndex = currentQueue.indexWhere((t) => t.id == track.id);
    currentPlaylistContextId = playlistId;
    currentTrack = track;
    notifyListeners();

    try {
      final audioSources = currentQueue.map(_buildAudioSource).toList();
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

  AudioSource _buildAudioSource(Track t) {
    final tag = MediaItem(
      id: t.id,
      title: t.title,
      artist: t.artist,
      artUri: t.coverUrl.isNotEmpty ? Uri.parse(t.coverUrl) : null,
    );
    if (_local.isDownloadedAndPresent(t.id)) {
      return AudioSource.file(_local.getDownloadPath(t.id)!, tag: tag);
    }
    return AudioSource.uri(Uri.parse(t.audioUrl), tag: tag);
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

  void seek(Duration position) => _audioPlayer.seek(position);

  void addToQueueNext(Track track) async {
    if (_audioPlayer.audioSource is ConcatenatingAudioSource) {
      final playlist = _audioPlayer.audioSource as ConcatenatingAudioSource;
      final nextIndex = (_audioPlayer.currentIndex ?? 0) + 1;
      final newSource = _buildAudioSource(track);
      await playlist.insert(nextIndex, newSource);
      currentQueue.insert(nextIndex, track);
      notifyListeners();
    }
  }

  // --- Likes ---

  bool isLiked(Track track) => likedTrackIds.contains(track.id);

  Future<void> toggleLike(Track track) async {
    if (currentUser == null) return;
    final uid = currentUser!.id;
    final wasLiked = isLiked(track);

    if (wasLiked) {
      likedTrackIds.remove(track.id);
    } else {
      likedTrackIds.add(track.id);
    }
    _syncLikesPlaylist();
    await _local.setLikedIds(likedTrackIds);
    notifyListeners();

    try {
      if (wasLiked) {
        await _remote.removeLikedTrack(uid, track.id);
      } else {
        await _remote.addLikedTrack(uid, track.id);
      }
    } catch (e, s) {
      AppLogger.warn('Like sin red, encolando', error: e, stack: s, tag: _tag);
      await _local.enqueuePending(PendingWrite(
        type: wasLiked ? 'like_remove' : 'like_add',
        payload: {'uid': uid, 'trackId': track.id},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      _notify('Cambio guardado, se sincronizará al volver la conexión.');
    }
  }

  // --- Playlists ---

  Future<void> addTrackToPlaylist(String playlistId, Track track) async {
    final playlist = userPlaylists.firstWhere((p) => p.id == playlistId);
    if (playlist.tracks.any((t) => t.id == track.id)) return;

    playlist.tracks.add(track);
    if (playlistId != 'p_likes' && playlistId != 'p_1') {
      await _local.upsertPlaylist(playlist);
    }
    notifyListeners();

    try {
      await _remote.addTrackToPlaylist(playlistId, track.id);
    } catch (e, s) {
      AppLogger.warn('addToPlaylist sin red, encolando', error: e, stack: s, tag: _tag);
      await _local.enqueuePending(PendingWrite(
        type: 'add_to_playlist',
        payload: {'playlistId': playlistId, 'trackId': track.id},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      _notify('Cambio guardado, se sincronizará al volver la conexión.');
    }
  }

  Future<void> removeTrackFromPlaylist(String playlistId, Track track) async {
    final playlist = userPlaylists.firstWhere((p) => p.id == playlistId);
    playlist.tracks.removeWhere((t) => t.id == track.id);
    if (playlistId != 'p_likes' && playlistId != 'p_1') {
      await _local.upsertPlaylist(playlist);
    }
    notifyListeners();

    try {
      await _remote.removeTrackFromPlaylist(playlistId, track.id);
    } catch (e, s) {
      AppLogger.warn('removeFromPlaylist sin red, encolando', error: e, stack: s, tag: _tag);
      await _local.enqueuePending(PendingWrite(
        type: 'remove_from_playlist',
        payload: {'playlistId': playlistId, 'trackId': track.id},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      _notify('Cambio guardado, se sincronizará al volver la conexión.');
    }
  }

  Future<String> createPlaylistWithImage(String name, File? imageFile) async {
    if (currentUser == null) throw Exception('No user');
    final playlistId = const Uuid().v4();

    String coverUrl = '';
    if (imageFile != null) {
      // La subida requiere conexión (Cloud Function + OCI); si falla, propaga
      // la excepción para que la pantalla la muestre y NO se cree la playlist.
      coverUrl = await _remote.uploadPlaylistCover(imageFile);
    }

    final newPlaylist = Playlist(
      id: playlistId,
      name: name,
      tracks: [],
      coverUrl: coverUrl,
    );
    userPlaylists.add(newPlaylist);
    await _local.upsertPlaylist(newPlaylist);
    notifyListeners();

    try {
      await _remote.createPlaylist(
        playlistId: playlistId,
        name: name,
        ownerId: currentUser!.id,
        coverUrl: coverUrl,
      );
    } catch (e, s) {
      AppLogger.warn('createPlaylist sin red, encolando', error: e, stack: s, tag: _tag);
      await _local.enqueuePending(PendingWrite(
        type: 'create_playlist',
        payload: {
          'playlistId': playlistId,
          'name': name,
          'ownerId': currentUser!.id,
          'coverUrl': coverUrl,
        },
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      _notify('Playlist guardada, se sincronizará al volver la conexión.');
    }

    return playlistId;
  }

  Future<void> deletePlaylist(String playlistId) async {
    if (playlistId == 'p_likes' || playlistId == 'p_1') return;

    userPlaylists.removeWhere((p) => p.id == playlistId);
    await _local.removePlaylist(playlistId);
    notifyListeners();

    try {
      await _remote.deletePlaylist(playlistId);
    } catch (e, s) {
      AppLogger.warn('deletePlaylist sin red, encolando', error: e, stack: s, tag: _tag);
      await _local.enqueuePending(PendingWrite(
        type: 'delete_playlist',
        payload: {'playlistId': playlistId},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      _notify('Cambio guardado, se sincronizará al volver la conexión.');
    }
  }

  // --- Descargas locales ---

  bool isDownloaded(Track track) => _local.isDownloadedAndPresent(track.id);

  Future<void> downloadTrack(Track track) async {
    if (isDownloaded(track)) return;
    try {
      final path = await _downloads.downloadTrack(track);
      await _local.setDownloadPath(track.id, path);
      notifyListeners();
      _notify('Descargada: ${track.title}');
    } on DownloadException catch (e) {
      _notify(e.message);
    } catch (e, s) {
      AppLogger.error('Falló descarga inesperada', error: e, stack: s, tag: _tag);
      _notify('No se pudo descargar la canción.');
    }
  }

  Future<void> removeDownload(Track track) async {
    await _local.removeDownload(track.id);
    notifyListeners();
    _notify('Descarga eliminada de tu dispositivo.');
  }

  // --- Drenado FIFO de pendientes ---

  Future<void> _drainPending() async {
    while (true) {
      final queue = _local.getPendingWrites();
      if (queue.isEmpty) break;
      final op = queue.first;
      try {
        await _applyRemote(op);
        await _local.removeFirstPending();
      } catch (e, s) {
        AppLogger.warn(
          'Drenado interrumpido en ${op.type}, se reintentará',
          error: e,
          stack: s,
          tag: _tag,
        );
        break;
      }
    }
  }

  Future<void> _applyRemote(PendingWrite op) async {
    switch (op.type) {
      case 'like_add':
        await _remote.addLikedTrack(
          op.payload['uid'] as String,
          op.payload['trackId'] as String,
        );
        return;
      case 'like_remove':
        await _remote.removeLikedTrack(
          op.payload['uid'] as String,
          op.payload['trackId'] as String,
        );
        return;
      case 'add_to_playlist':
        await _remote.addTrackToPlaylist(
          op.payload['playlistId'] as String,
          op.payload['trackId'] as String,
        );
        return;
      case 'remove_from_playlist':
        await _remote.removeTrackFromPlaylist(
          op.payload['playlistId'] as String,
          op.payload['trackId'] as String,
        );
        return;
      case 'create_playlist':
        await _remote.createPlaylist(
          playlistId: op.payload['playlistId'] as String,
          name: op.payload['name'] as String,
          ownerId: op.payload['ownerId'] as String,
          coverUrl: (op.payload['coverUrl'] as String?) ?? '',
        );
        return;
      case 'delete_playlist':
        await _remote.deletePlaylist(op.payload['playlistId'] as String);
        return;
      default:
        AppLogger.warn('Operación pendiente desconocida: ${op.type}', tag: _tag);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _connectivity.dispose();
    super.dispose();
  }
}
