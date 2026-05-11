import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../models/recognition_result.dart';
import '../../utils/app_logger.dart';
import 'recognition_service.dart';

/// Implementación de [RecognitionService] que llama a la Cloud Function HTTP
/// `recognizeAudio` para mantener el `api_token` de AudD fuera del cliente.
///
/// Usamos HTTP directo (no callable) porque la stack callable del SDK choca
/// con la ausencia de App Check y termina devolviendo `unauthenticated`. La
/// function verifica el ID token manualmente desde el header
/// `Authorization: Bearer <id_token>`.
class AuddRecognitionService implements RecognitionService {
  AuddRecognitionService({
    http.Client? httpClient,
    FirebaseAuth? auth,
    Uri? endpoint,
  })  : _http = httpClient ?? http.Client(),
        _auth = auth ?? FirebaseAuth.instance,
        _endpoint = endpoint ?? _defaultEndpoint;

  static final Uri _defaultEndpoint = Uri.parse(
    'https://us-central1-hsound-4c7c4.cloudfunctions.net/recognizeAudio',
  );

  final http.Client _http;
  final FirebaseAuth _auth;
  final Uri _endpoint;

  static const _tag = 'AuddRecognitionService';

  @override
  Future<RecognitionResult?> identify(File audio) async {
    final bytes = await audio.readAsBytes();
    if (bytes.isEmpty) {
      throw RecognitionException('El audio capturado está vacío.');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw RecognitionException('Debes iniciar sesión para reconocer canciones.');
    }

    final String? idToken;
    try {
      idToken = await user.getIdToken();
    } catch (e, s) {
      AppLogger.error('No se pudo obtener el ID token', error: e, stack: s, tag: _tag);
      throw RecognitionException('No se pudo verificar tu sesión. Vuelve a iniciar sesión.');
    }
    if (idToken == null || idToken.isEmpty) {
      throw RecognitionException('No se pudo verificar tu sesión. Vuelve a iniciar sesión.');
    }

    final http.Response response;
    try {
      response = await _http.post(
        _endpoint,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $idToken',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode({
          'audioBase64': base64Encode(bytes),
          'contentType': 'audio/mp4',
        }),
      );
    } on SocketException catch (e, s) {
      AppLogger.warn('Sin red al llamar recognizeAudio', error: e, stack: s, tag: _tag);
      throw RecognitionException(
        'No se pudo contactar al servicio. Revisa tu conexión e inténtalo de nuevo.',
      );
    } catch (e, s) {
      AppLogger.error('Fallo HTTP a recognizeAudio', error: e, stack: s, tag: _tag);
      throw RecognitionException(
        'No se pudo identificar la canción. Inténtalo de nuevo en unos segundos.',
      );
    }

    if (response.statusCode == 401) {
      AppLogger.warn('recognizeAudio respondió 401: ${response.body}', tag: _tag);
      throw RecognitionException('Tu sesión expiró. Vuelve a iniciar sesión.');
    }
    if (response.statusCode >= 500) {
      AppLogger.error(
        'recognizeAudio respondió ${response.statusCode}: ${response.body}',
        tag: _tag,
      );
      throw RecognitionException(
        'El servicio de reconocimiento no está disponible. Inténtalo más tarde.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      AppLogger.warn(
        'recognizeAudio respondió ${response.statusCode}: ${response.body}',
        tag: _tag,
      );
      throw RecognitionException(
        'No se pudo identificar la canción. Inténtalo de nuevo en unos segundos.',
      );
    }

    final Map<String, dynamic> data;
    try {
      data = (jsonDecode(response.body) as Map).cast<String, dynamic>();
    } catch (e, s) {
      AppLogger.error('JSON inválido de recognizeAudio', error: e, stack: s, tag: _tag);
      throw RecognitionException('Respuesta inesperada del servidor.');
    }

    if (data['status'] != 'success') {
      AppLogger.warn('Respuesta inesperada: $data', tag: _tag);
      throw RecognitionException('Respuesta inesperada del servidor.');
    }

    final payload = data['result'];
    if (payload == null) {
      AppLogger.info('AudD: sin coincidencia', tag: _tag);
      return null;
    }
    if (payload is! Map) {
      AppLogger.warn('payload inesperado: $payload', tag: _tag);
      throw RecognitionException('Respuesta inesperada del servidor.');
    }

    final parsed = RecognitionResult.fromAudd(payload.cast<String, dynamic>());
    if (parsed == null) {
      AppLogger.warn('AudD devolvió un result incompleto: $payload', tag: _tag);
      return null;
    }
    return parsed;
  }
}
