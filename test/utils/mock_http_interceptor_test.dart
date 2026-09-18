import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/utils/auth_interceptor.dart';
import 'package:sigo_app/utils/mock_http_interceptor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MockHttpInterceptor', () {
    late Dio dio;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://api.test.com'));
      dio.interceptors.add(MockHttpInterceptor());
    });

    test('Debe resolver localmente con 200 cuando Authorization contiene mock-token', () async {
      final response = await dio.get(
        '/api/v1/empresas/getAll',
        options: Options(headers: {'Authorization': 'Bearer mock-token-operator'}),
      );

      expect(response.statusCode, 200);
      expect(response.data, isA<List>());
      expect((response.data as List).first['codigo'], '01');
    });

    test('Debe resolver bodegas simuladas tipo FI para /api/v1/bodegas/empresa/01/FI', () async {
      final response = await dio.get(
        '/api/v1/bodegas/empresa/01/FI',
        options: Options(headers: {'Authorization': 'Bearer mock-token-operator'}),
      );

      expect(response.statusCode, 200);
      expect(response.data, isA<List>());
      expect((response.data as List).length, greaterThanOrEqualTo(2));
    });

    test('Debe resolver bodegas simuladas tipo PE para /api/v1/bodegas/empresa/01/PE', () async {
      final response = await dio.get(
        '/api/v1/bodegas/empresa/01/PE',
        options: Options(headers: {'Authorization': 'Bearer mock-token-operator'}),
      );

      expect(response.statusCode, 200);
      expect(response.data, isA<List>());
      expect((response.data as List).length, greaterThanOrEqualTo(2));
    });

    test('Debe resolver bandeja de traspasos para /api/v1/traspasos/list', () async {
      final response = await dio.get(
        '/api/v1/traspasos/list',
        options: Options(headers: {'Authorization': 'Bearer mock-token-operator'}),
      );

      expect(response.statusCode, 200);
      expect(response.data, isA<List>());
      expect((response.data as List).first['id'], 'TR-MOCK-101');
    });

    test('Debe responder code 0 para operaciones transaccionales POST en modo mock', () async {
      final response = await dio.post(
        '/api/v1/traspasos/crear',
        data: {'articulo': 'PC001'},
        options: Options(headers: {'Authorization': 'Bearer mock-token-operator'}),
      );

      expect(response.statusCode, 200);
      expect(response.data['code'], 0);
      expect(response.data['msg'], contains('Entorno Mock'));
    });

    test('Debe pasar la petición al network adapter si el token NO es mock', () async {
      var reachedAdapter = false;

      dio.httpClientAdapter = _TrackingAdapter(onFetch: () {
        reachedAdapter = true;
      });

      await dio.get(
        '/api/v1/empresas/getAll',
        options: Options(headers: {'Authorization': 'Bearer real_jwt_token_456'}),
      );

      expect(reachedAdapter, isTrue);
    });
  });

  group('AuthInterceptor con Mock Token', () {
    test('NO debe expulsar (handleSessionExpired) si llega un 401 con token mock', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'Bearer mock-token-operator',
      });

      final dio = Dio(BaseOptions(baseUrl: 'https://api.test.com'));
      dio.interceptors.add(AuthInterceptor());
      dio.httpClientAdapter = _MockErrorAdapter(401);

      try {
        await dio.get('/api/v1/articulos/asignados/BOG01/01');
      } on DioException catch (_) {}

      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      // No debe haberse borrado el token de storage porque es sesión mock
      expect(token, 'Bearer mock-token-operator');
    });
  });
}

class _TrackingAdapter implements HttpClientAdapter {
  final void Function() onFetch;
  _TrackingAdapter({required this.onFetch});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onFetch();
    return ResponseBody.fromString('[]', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

class _MockErrorAdapter implements HttpClientAdapter {
  final int statusCode;
  _MockErrorAdapter(this.statusCode);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('{"error":"unauthorized"}', statusCode, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}
