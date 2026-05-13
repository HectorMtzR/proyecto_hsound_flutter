import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/models.dart';
import '../services/oci_upload_service.dart';
import '../utils/app_logger.dart';

/// Capa de I/O contra Firebase (Auth + Firestore) y servicios remotos.
///
/// Sin estado y sin notificadores: cada método recibe lo que necesita y
/// devuelve un [Future]. Lanza [SocketException] / [FirebaseException] crudas
/// para que la fachada decida si encolar o revertir.
class RemoteRepository {
  RemoteRepository({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    OciUploadService? uploadService,
  })  : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _uploadService = uploadService ?? OciUploadService();

  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final OciUploadService _uploadService;

  static const _tag = 'RemoteRepository';

  Stream<firebase_auth.User?> authStateChanges() => _auth.authStateChanges();

  // --- Auth ---

  Future<void> register(String email, String password, String displayName) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;
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

  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code.contains('network') || e.code == 'unknown') {
        throw Exception('Sin conexión a internet. Revisa tu red.');
      }
      throw Exception(e.message ?? 'Credenciales incorrectas.');
    } catch (_) {
      throw Exception('Ocurrió un error inesperado al iniciar sesión.');
    }
  }

  Future<void> logout() => _auth.signOut();

  // --- Lecturas ---

  /// Devuelve `(displayName, likedTrackIds)` o `null` si no existe el doc.
  Future<({String displayName, List<String> likedTrackIds})?> fetchUserDoc(
    String uid,
  ) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data() ?? const {};
    final likes = (data['liked_tracks'] as List?) ?? const [];
    return (
      displayName: (data['displayName'] as String?) ?? 'Usuario',
      likedTrackIds: likes.map((e) => e.toString()).toList(),
    );
  }

  Future<List<Track>> fetchTracks() async {
    final snapshot = await _firestore.collection('tracks').get();
    return snapshot.docs.map(Track.fromFirestore).toList();
  }

  Future<List<Playlist>> fetchUserPlaylists(
    String uid,
    List<Track> allTracks,
  ) async {
    final snapshot = await _firestore
        .collection('playlists')
        .where('ownerId', isEqualTo: uid)
        .get();

    final byId = {for (final t in allTracks) t.id: t};
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final ids = (data['trackIds'] as List?) ?? const [];
      final tracks = <Track>[];
      for (final id in ids) {
        final t = byId[id.toString()];
        if (t != null) tracks.add(t);
      }
      return Playlist(
        id: doc.id,
        name: (data['name'] as String?) ?? 'Playlist',
        coverUrl: (data['coverUrl'] as String?) ?? '',
        tracks: tracks,
      );
    }).toList();
  }

  // --- Escrituras (drenables desde la cola FIFO) ---

  Future<void> addLikedTrack(String uid, String trackId) {
    return _firestore.collection('users').doc(uid).update({
      'liked_tracks': FieldValue.arrayUnion([trackId]),
    });
  }

  Future<void> removeLikedTrack(String uid, String trackId) {
    return _firestore.collection('users').doc(uid).update({
      'liked_tracks': FieldValue.arrayRemove([trackId]),
    });
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId) {
    return _firestore.collection('playlists').doc(playlistId).update({
      'trackIds': FieldValue.arrayUnion([trackId]),
    });
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) {
    return _firestore.collection('playlists').doc(playlistId).update({
      'trackIds': FieldValue.arrayRemove([trackId]),
    });
  }

  Future<void> createPlaylist({
    required String playlistId,
    required String name,
    required String ownerId,
    required String coverUrl,
  }) {
    return _firestore.collection('playlists').doc(playlistId).set({
      'name': name,
      'ownerId': ownerId,
      'coverUrl': coverUrl,
      'trackIds': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePlaylist(String playlistId) {
    return _firestore.collection('playlists').doc(playlistId).delete();
  }

  Future<String> uploadPlaylistCover(File file) async {
    try {
      return await _uploadService.uploadPlaylistCover(file);
    } on UploadException {
      rethrow;
    } catch (e, s) {
      AppLogger.error('Falló subida de portada', error: e, stack: s, tag: _tag);
      throw UploadException('No se pudo subir la portada. Intenta de nuevo.');
    }
  }
}
