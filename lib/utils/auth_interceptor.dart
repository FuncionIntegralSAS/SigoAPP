import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sigo_app/utils/app_logger.dart';
import 'package:sigo_app/utils/auth_utils.dart';

/// Interceptor centralizado de autenticación para [Dio].
///
/// Inyecta automáticamente la cabecera `Authorization: Bearer <token>`
/// en todas las peticiones a endpoints protegidos leyendo el token activo
/// almacenado en [FlutterSecureStorage].
///
/// Excluye rutas públicas de autenticación (ej. `/api/v1/auth/`).
/// Intercepta respuestas HTTP 401 en endpoints protegidos disparando
/// automáticamente el flujo de expiración de sesión y expulsión controlada.
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  AuthInterceptor({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Si la ruta pertenece a autenticación pública, continuar sin cabecera Authorization
    if (_isPublicEndpoint(options.path)) {
      return handler.next(options);
    }

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token != null && token.trim().isNotEmpty) {
        final trimmedToken = token.trim();
        final authHeader = trimmedToken.startsWith('Bearer ')
            ? trimmedToken
            : 'Bearer $trimmedToken';
        options.headers['Authorization'] = authHeader;
      }
    } catch (e) {
      AppLogger.w('AuthInterceptor: no se pudo leer el token de secure storage: $e');
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;
    final authHeader = err.requestOptions.headers['Authorization']?.toString() ?? '';
    final isMock = authHeader.contains('mock-token');

    if (statusCode == 401) {
      AppLogger.w('AuthInterceptor: Error 401 (No autorizado) en $path');
      // No expulsar en endpoints públicos de autenticación (login, etc.) para permitir
      // mostrar al usuario el mensaje de credenciales incorrectas.
      // Tampoco expulsar si la sesión activa es una sesión simulada de pruebas (Mock).
      if (!_isPublicEndpoint(path) && !isMock) {
        AuthUtils.handleSessionExpired();
      }
    } else if (statusCode == 403) {
      AppLogger.w('AuthInterceptor: Error 403 (Acceso prohibido) en $path');
    }

    super.onError(err, handler);
  }

  /// Determina si un endpoint es público y no debe requerir token.
  bool _isPublicEndpoint(String path) {
    return path.contains('/api/v1/auth/');
  }
}
