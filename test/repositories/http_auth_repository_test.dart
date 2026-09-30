import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/exceptions/auth_business_exception.dart';
import 'package:sigo_app/modules/auth/models/auth_model.dart';
import 'package:sigo_app/modules/auth/repositories/http_auth_repository.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    throw UnimplementedError();
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late MockHttpClientAdapter adapter;
  late HttpAuthRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    adapter = MockHttpClientAdapter();
    dio.httpClientAdapter = adapter;
    repository = HttpAuthRepository(dio);
  });

  group('HttpAuthRepository Tests', () {
    test('login() con HTTP 200 retorna AuthResponse exitosamente', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          '{"token": "fake-jwt-token", "username": "admin", "documento": "123456", "expiresIn": 3600}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final response = await repository.login(
        const LoginRequest(username: 'admin', password: 'password'),
      );

      expect(response.token, 'fake-jwt-token');
      expect(response.username, 'admin');
      expect(response.documento, '123456');
    });

    test('login() ante HTTP 400 con SIGAPP_401 lanza AuthBusinessException con mensaje limpio', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          '{"success": false, "code": "SIGAPP_401", "message": "Usuario o contraseña incorrectos"}',
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      try {
        await repository.login(
          const LoginRequest(username: 'admin', password: 'wrong_password'),
        );
        fail('Se esperaba que lanzara AuthBusinessException');
      } on AuthBusinessException catch (e) {
        expect(e.message, 'Usuario o contraseña incorrectos');
        expect(e.code, 'SIGAPP_401');
        expect(e.statusCode, 400);
        expect(e.endpoint, 'POST /api/v1/auth/login');
        expect(e.technicalDetails, contains('POST /api/v1/auth/login'));
        expect(e.technicalDetails, contains('Código HTTP: 400'));
        expect(e.technicalDetails, contains('Código de Negocio: SIGAPP_401'));
        expect(e.technicalDetails, contains('Usuario o contraseña incorrectos'));
      }
    });

    test('login() ante HTTP 400 con SIGAPP_405 ("Usuario no autorizado") propaga mensaje limpio', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          '{"success": false, "code": "SIGAPP_405", "message": "Usuario no autorizado"}',
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      try {
        await repository.login(
          const LoginRequest(username: 'inexistente', password: 'pwd'),
        );
        fail('Se esperaba que lanzara AuthBusinessException');
      } on AuthBusinessException catch (e) {
        expect(e.message, 'Usuario no autorizado');
        expect(e.code, 'SIGAPP_405');
        expect(e.statusCode, 400);
      }
    });

    test('loginContador() ante HTTP 400 con SIGAPP_407 ("Usuario bloqueado") lanza AuthBusinessException', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          '{"success": false, "code": "SIGAPP_407", "message": "Usuario bloqueado"}',
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      try {
        await repository.loginContador(
          const LoginContadorRequest(documento: '12345678', codigoTemporal: '0000'),
        );
        fail('Se esperaba que lanzara AuthBusinessException');
      } on AuthBusinessException catch (e) {
        expect(e.message, 'Usuario bloqueado');
        expect(e.code, 'SIGAPP_407');
        expect(e.statusCode, 400);
        expect(e.endpoint, 'POST /api/v1/auth/login/contador');
      }
    });

    test('login() ante error de timeout de conexión lanza AuthBusinessException amigable de red', () async {
      adapter.handler = (options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
          error: 'Connection timed out',
        );
      };

      try {
        await repository.login(
          const LoginRequest(username: 'admin', password: 'password'),
        );
        fail('Se esperaba que lanzara AuthBusinessException');
      } on AuthBusinessException catch (e) {
        expect(
          e.message,
          'Error de conexión con el servidor. Verifique su red o la configuración del dominio.',
        );
      }
    });

    test('login() ante HTTP 500 sin cuerpo lanza mensaje amigable de error interno', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          '',
          500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      try {
        await repository.login(
          const LoginRequest(username: 'admin', password: 'password'),
        );
        fail('Se esperaba que lanzara AuthBusinessException');
      } on AuthBusinessException catch (e) {
        expect(e.message, 'Error interno en el servidor al intentar autenticar.');
        expect(e.statusCode, 500);
      }
    });
  });
}
