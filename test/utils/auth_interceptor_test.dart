import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/utils/auth_interceptor.dart';
import 'package:sigo_app/utils/auth_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthInterceptor', () {
    late Dio dio;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'Bearer test_token_123',
      });

      dio = Dio(BaseOptions(baseUrl: 'https://api.test.com'));
      dio.interceptors.add(AuthInterceptor());

      // Mock adapter to capture request headers
      dio.httpClientAdapter = _MockAdapter();
    });

    test('Debe inyectar Authorization Bearer en endpoints protegidos', () async {
      final response = await dio.get('/api/v1/empresas/getAll');
      expect(response.statusCode, 200);

      final authHeader = response.requestOptions.headers['Authorization'];
      expect(authHeader, 'Bearer test_token_123');
    });

    test('NO debe inyectar Authorization en endpoints públicos (/api/v1/auth/)', () async {
      final response = await dio.post('/api/v1/auth/login');
      expect(response.statusCode, 200);

      final authHeader = response.requestOptions.headers['Authorization'];
      expect(authHeader, isNull);
    });

    test('Debe anteponer Bearer si el token guardado no lo tiene', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'raw_jwt_token_without_prefix',
      });

      final response = await dio.get('/api/v1/bodegas/empresa/1');
      expect(response.statusCode, 200);

      final authHeader = response.requestOptions.headers['Authorization'];
      expect(authHeader, 'Bearer raw_jwt_token_without_prefix');
    });

    test('No debe fallar si no hay token en storage', () async {
      FlutterSecureStorage.setMockInitialValues({});

      final response = await dio.get('/api/v1/articulos/1');
      expect(response.statusCode, 200);

      final authHeader = response.requestOptions.headers['Authorization'];
      expect(authHeader, isNull);
    });

    test('Debe disparar limpieza de storage ante 401 en endpoint protegido', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'Bearer test_token_123',
        'auth_username': 'usuario_prueba',
      });

      dio.httpClientAdapter = _MockStatusAdapter(401);

      try {
        await dio.get('/api/v1/articulos/1');
      } on DioException catch (_) {}

      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      expect(token, isNull);
      final username = await storage.read(key: 'auth_username');
      expect(username, isNull);
    });

    test('NO debe disparar expiración ni borrar storage ante 401 en endpoint público (/api/v1/auth/login)', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'Bearer token_persistente',
      });

      dio.httpClientAdapter = _MockStatusAdapter(401);

      try {
        await dio.post('/api/v1/auth/login');
      } on DioException catch (_) {}

      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      expect(token, 'Bearer token_persistente');
    });

    test('Control de concurrencia: múltiples 401 concurrentes no duplican ejecuciones', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'Bearer token_concurrente',
      });

      dio.httpClientAdapter = _MockStatusAdapter(401);

      // Disparamos 5 peticiones simultáneas con 401
      await Future.wait([
        dio.get('/api/v1/articulos/1').catchError((_) => Response(requestOptions: RequestOptions())),
        dio.get('/api/v1/articulos/2').catchError((_) => Response(requestOptions: RequestOptions())),
        dio.get('/api/v1/articulos/3').catchError((_) => Response(requestOptions: RequestOptions())),
        dio.get('/api/v1/articulos/4').catchError((_) => Response(requestOptions: RequestOptions())),
        dio.get('/api/v1/articulos/5').catchError((_) => Response(requestOptions: RequestOptions())),
      ]);

      // Esperar a que la operación asíncrona de logout termine completamente
      await Future.delayed(const Duration(milliseconds: 50));

      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      expect(token, isNull);
      expect(AuthUtils.isLoggingOut, isFalse);
    });

    test('Llamadas paralelas directas a handleSessionExpired descartan duplicados', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'Bearer concurrent_test',
      });

      // Disparamos 3 llamadas concurrentes a nivel de microtarea
      final futures = [
        AuthUtils.handleSessionExpired(),
        AuthUtils.handleSessionExpired(),
        AuthUtils.handleSessionExpired(),
      ];

      await Future.wait(futures);
      expect(AuthUtils.isLoggingOut, isFalse);
    });
  });
}

class _MockAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '[]',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MockStatusAdapter implements HttpClientAdapter {
  final int statusCode;
  _MockStatusAdapter(this.statusCode);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"error": "Unauthorized"}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
