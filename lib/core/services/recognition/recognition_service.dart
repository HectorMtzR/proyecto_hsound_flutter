import 'dart:io';

import '../../models/recognition_result.dart';

/// Excepción legible para fallos durante el reconocimiento.
class RecognitionException implements Exception {
  final String message;
  RecognitionException(this.message);

  @override
  String toString() => message;
}

/// Contrato del servicio de reconocimiento de audio. Las implementaciones
/// concretas hablan con un proveedor externo (AudD en fase 1) o con un
/// matcher contra el catálogo propio (fase 2).
abstract class RecognitionService {
  /// Identifica la canción contenida en [audio]. Devuelve `null` cuando el
  /// proveedor responde "sin coincidencia". Lanza [RecognitionException] si
  /// ocurre cualquier otro fallo (red, servidor, parsing).
  Future<RecognitionResult?> identify(File audio);
}
