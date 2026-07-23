import 'package:flutter/foundation.dart';

/// Logger centralizado para SigoAPP.
///
/// Garantiza que los logs solo se impriman en modo debug,
/// evitando la fuga de información sensible en builds de producción.
class AppLogger {
  AppLogger._();

  /// Log de depuración general. Solo se ejecuta en modo debug.
  static void d(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  /// Log de información. Solo se ejecuta en modo debug.
  static void i(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  /// Log de advertencia. Solo se ejecuta en modo debug.
  static void w(String message) {
    if (kDebugMode) {
      debugPrint('[WARN] $message');
    }
  }

  /// Log de error. Solo se ejecuta en modo debug.
  static void e(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) {
        debugPrint('[ERROR] $error');
      }
    }
  }
}
