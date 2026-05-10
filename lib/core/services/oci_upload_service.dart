import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

import '../utils/app_logger.dart';

/// Excepción legible para mostrar en la UI cuando falla la subida.
class UploadException implements Exception {
  final String message;
  UploadException(this.message);

  @override
  String toString() => message;
}

/// Servicio que orquesta la subida de portadas de playlist a OCI Object
/// Storage usando una URL firmada generada por una Cloud Function.
///
/// El cliente nunca conoce las credenciales OCI: pide a la function una URL
/// presigned PUT y sube los bytes directamente con http.
class OciUploadService {
  OciUploadService({FirebaseFunctions? functions, http.Client? httpClient})
      : _functions = functions ?? FirebaseFunctions.instance,
        _httpClient = httpClient ?? http.Client();

  final FirebaseFunctions _functions;
  final http.Client _httpClient;

  static const _tag = 'OciUploadService';
  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  /// Sube la portada y devuelve la URL pública. Lanza [UploadException] con
  /// un mensaje listo para SnackBar si algo falla.
  Future<String> uploadPlaylistCover(File file) async {
    final extension = _normalizeExtension(file.path);
    final contentType = _contentTypeFor(extension);

    final HttpsCallableResult result;
    try {
      final callable = _functions.httpsCallable('getPlaylistCoverUploadUrl');
      result = await callable.call<Map<String, dynamic>>({
        'contentType': contentType,
        'extension': extension,
      });
    } on FirebaseFunctionsException catch (e, s) {
      AppLogger.error(
        'Falló presign de portada (${e.code})',
        error: e,
        stack: s,
        tag: _tag,
      );
      throw UploadException(
        'No se pudo preparar la subida de la portada. Revisa tu conexión e inténtalo de nuevo.',
      );
    }

    final data = (result.data as Map?)?.cast<String, dynamic>();
    final uploadUrl = data?['uploadUrl'] as String?;
    final publicUrl = data?['publicUrl'] as String?;
    if (uploadUrl == null || publicUrl == null) {
      AppLogger.error('Respuesta inválida de la function: $data', tag: _tag);
      throw UploadException('Respuesta inesperada del servidor al subir la portada.');
    }

    final bytes = await file.readAsBytes();

    final http.Response response;
    try {
      response = await _httpClient.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: bytes,
      );
    } catch (e, s) {
      AppLogger.error('Falló PUT a OCI', error: e, stack: s, tag: _tag);
      throw UploadException(
        'No se pudo subir la portada. Revisa tu conexión e inténtalo de nuevo.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      AppLogger.error(
        'PUT a OCI respondió ${response.statusCode}: ${response.body}',
        tag: _tag,
      );
      throw UploadException(
        'El servidor rechazó la subida de la portada (${response.statusCode}).',
      );
    }

    return publicUrl;
  }

  String _normalizeExtension(String path) {
    final raw = path.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(raw)) {
      throw UploadException('Formato de imagen no soportado: $raw');
    }
    return raw;
  }

  String _contentTypeFor(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
    }
    throw UploadException('Formato de imagen no soportado: $extension');
  }
}
