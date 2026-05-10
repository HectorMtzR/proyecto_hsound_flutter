import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../utils/app_logger.dart';

/// Wrapper minimalista sobre `connectivity_plus` con un único callback de
/// reconexión. Centraliza la subscripción para evitar listeners duplicados
/// cuando varias pantallas o servicios necesitan saber que volvió la red.
class ConnectivityWatcher {
  ConnectivityWatcher({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _wasOnline = false;

  static const _tag = 'ConnectivityWatcher';

  /// Devuelve `true` si en este instante hay alguna interfaz de red activa.
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  /// Empieza a vigilar cambios. Llama a [onReconnect] cuando se detecta una
  /// transición de offline → online (no se llama si arrancamos online).
  Future<void> start({required Future<void> Function() onReconnect}) async {
    _wasOnline = await isOnline();
    AppLogger.info('Conectividad inicial: ${_wasOnline ? "online" : "offline"}', tag: _tag);

    _sub?.cancel();
    _sub = _connectivity.onConnectivityChanged.listen((results) async {
      final nowOnline = _hasConnection(results);
      if (nowOnline && !_wasOnline) {
        AppLogger.info('Reconexión detectada, drenando cola pendiente', tag: _tag);
        try {
          await onReconnect();
        } catch (e, s) {
          AppLogger.warn('Falló el drenado al reconectar', error: e, stack: s, tag: _tag);
        }
      }
      _wasOnline = nowOnline;
    });
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}
