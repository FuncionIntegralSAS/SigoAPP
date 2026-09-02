import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_logger.dart';

/// Interceptor centralizado de autenticación para [Dio].
///
/// Inyecta automáticamente la cabecera `Authorization: Bearer <token>`
/// en todas las peticiones a endpoints protegidos leyendo el token activo
/// almacenado en [FlutterSecureStorage].
///
/// Excluye rutas públicas de autenticación (ej. `/api/v1/auth/`).
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
    if (statusCode == 401 || statusCode == 403) {
      AppLogger.w(
        'AuthInterceptor: Error de autenticación ($statusCode) en ${err.requestOptions.path}',
      );
    }
    super.onError(err, handler);
  }

  /// Determina si un endpoint es público y no debe requerir token.
  bool _isPublicEndpoint(String path) {
    return path.contains('/api/v1/auth/');
  }
}
