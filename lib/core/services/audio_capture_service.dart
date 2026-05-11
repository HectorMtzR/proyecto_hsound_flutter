import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../utils/app_logger.dart';

/// Excepción legible para mostrar en la UI cuando la captura del micrófono falla.
class AudioCaptureException implements Exception {
  final String message;
  AudioCaptureException(this.message);

  @override
  String toString() => message;
}

/// Wrapper delgado sobre `package:record` para capturar muestras de audio
/// destinadas a reconocimiento (estilo Shazam).
///
/// Es stateless por instancia pero mantiene una grabación activa entre llamadas
/// a [start] y [stop]. Para flujos simples conviene usar [capture] que abre,
/// graba durante un [duration] fijo y devuelve el archivo resultante.
class AudioCaptureService {
  AudioCaptureService({AudioRecorder? recorder, Uuid? uuid})
      : _recorder = recorder ?? AudioRecorder(),
        _uuid = uuid ?? const Uuid();

  final AudioRecorder _recorder;
  final Uuid _uuid;

  static const _tag = 'AudioCaptureService';

  /// `true` si el sistema ya concedió el permiso de micrófono.
  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e, s) {
      AppLogger.warn('Fallo consultando permiso de micro', error: e, stack: s, tag: _tag);
      return false;
    }
  }

  /// Solicita el permiso de micrófono. Devuelve `true` si quedó concedido.
  /// Usa [permission_handler] para poder distinguir entre denegado y
  /// permanentemente denegado.
  Future<PermissionStatus> requestPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return status;
    final result = await Permission.microphone.request();
    AppLogger.info('Permiso de micro: $result', tag: _tag);
    return result;
  }

  /// Graba [duration] (por defecto 8s) y devuelve el archivo M4A resultante
  /// en el directorio temporal del SO. Lanza [AudioCaptureException] si
  /// falla la grabación o el archivo no termina existiendo.
  Future<File> capture({
    Duration duration = const Duration(seconds: 8),
  }) async {
    final path = await _tempPath();

    try {
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      );
      await _recorder.start(config, path: path);
    } catch (e, s) {
      AppLogger.error('No se pudo iniciar la grabación', error: e, stack: s, tag: _tag);
      throw AudioCaptureException('No se pudo iniciar la grabación.');
    }

    await Future<void>.delayed(duration);

    String? finalPath;
    try {
      finalPath = await _recorder.stop();
    } catch (e, s) {
      AppLogger.error('Fallo al detener la grabación', error: e, stack: s, tag: _tag);
      throw AudioCaptureException('No se pudo finalizar la grabación.');
    }

    final outPath = finalPath ?? path;
    final file = File(outPath);
    if (!await file.exists() || await file.length() == 0) {
      throw AudioCaptureException('La grabación quedó vacía.');
    }
    return file;
  }

  /// Stream de amplitud (en dB normalizados a 0..1) emitido cada ~100ms
  /// mientras hay una grabación activa. Útil para animaciones de pulso.
  Stream<double> amplitudeStream() {
    return _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .map((a) {
      // record emite current en dB (negativo). Normalizamos -45..0 a 0..1.
      final db = a.current;
      if (db.isNaN || db.isInfinite) return 0;
      final clamped = db.clamp(-45.0, 0.0);
      return (clamped + 45.0) / 45.0;
    });
  }

  Future<void> dispose() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {
      // best-effort
    }
    await _recorder.dispose();
  }

  Future<String> _tempPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}${Platform.pathSeparator}recognize_${_uuid.v4()}.m4a';
  }
}
