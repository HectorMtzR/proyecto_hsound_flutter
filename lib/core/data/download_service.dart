import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';
import '../utils/app_logger.dart';

/// Excepción legible para mostrar en la UI cuando falla la descarga.
class DownloadException implements Exception {
  final String message;
  DownloadException(this.message);

  @override
  String toString() => message;
}

/// Servicio de descarga de pistas a almacenamiento local.
///
/// Usa el cliente `http` ya presente en el proyecto (sin plugins nativos
/// adicionales) y `path_provider` para resolver el directorio privado de la
/// app. La escritura es atómica: descarga a `.tmp` y renombra al terminar.
class DownloadService {
  DownloadService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _tag = 'DownloadService';

  /// Descarga el audio del [track] y devuelve la ruta absoluta al archivo
  /// final. Lanza [DownloadException] si la URL es inválida, el servidor
  /// responde error o falla la red.
  Future<String> downloadTrack(Track track) async {
    if (track.audioUrl.isEmpty) {
      throw DownloadException('La pista no tiene URL de audio.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/audio');
    if (!audioDir.existsSync()) {
      audioDir.createSync(recursive: true);
    }

    final finalPath = '${audioDir.path}/${track.id}.mp3';
    final tmpPath = '$finalPath.tmp';
    final tmpFile = File(tmpPath);

    final request = http.Request('GET', Uri.parse(track.audioUrl));
    final http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } catch (e, s) {
      AppLogger.error('Falló petición de descarga', error: e, stack: s, tag: _tag);
      throw DownloadException('No se pudo iniciar la descarga. Revisa tu conexión.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      AppLogger.error(
        'Descarga rechazada: ${response.statusCode}',
        tag: _tag,
      );
      throw DownloadException(
        'El servidor rechazó la descarga (${response.statusCode}).',
      );
    }

    final sink = tmpFile.openWrite();
    try {
      await response.stream.pipe(sink);
    } catch (e, s) {
      AppLogger.error('Falló escritura de descarga', error: e, stack: s, tag: _tag);
      try {
        await sink.close();
        if (tmpFile.existsSync()) await tmpFile.delete();
      } catch (_) {}
      throw DownloadException('Se interrumpió la descarga. Inténtalo de nuevo.');
    }

    await tmpFile.rename(finalPath);
    AppLogger.info('Descarga completada: ${track.id}', tag: _tag);
    return finalPath;
  }
}
