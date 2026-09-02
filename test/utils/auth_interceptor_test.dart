import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/utils/auth_interceptor.dart';

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
