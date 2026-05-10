import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Logger ligero con niveles info/warn/error.
///
/// En debug usa [debugPrint]; en release delega en [developer.log] para que la
/// salida sea capturable por logcat o un futuro sink (Crashlytics, Sentry).
class AppLogger {
  AppLogger._();

  static const String _defaultTag = 'HSound';

  static void info(String message, {String? tag}) {
    final t = tag ?? _defaultTag;
    if (kDebugMode) {
      debugPrint('[$t][INFO] $message');
    } else {
      developer.log(message, name: t, level: 800);
    }
  }

  static void warn(
    String message, {
    Object? error,
    StackTrace? stack,
    String? tag,
  }) {
    final t = tag ?? _defaultTag;
    if (kDebugMode) {
      debugPrint('[$t][WARN] $message');
      if (error != null) debugPrint('  error: $error');
      if (stack != null) debugPrint(stack.toString());
    } else {
      developer.log(
        message,
        name: t,
        level: 900,
        error: error,
        stackTrace: stack,
      );
    }
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stack,
    String? tag,
  }) {
    final t = tag ?? _defaultTag;
    if (kDebugMode) {
      debugPrint('[$t][ERROR] $message');
      if (error != null) debugPrint('  error: $error');
      if (stack != null) debugPrint(stack.toString());
    } else {
      developer.log(
        message,
        name: t,
        level: 1000,
        error: error,
        stackTrace: stack,
      );
    }
  }
}
