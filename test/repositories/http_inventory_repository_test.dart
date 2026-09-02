import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/repositories/http_inventory_repository.dart';

void main() {
  group('HttpInventoryRepository', () {
    late Dio dio;
    late HttpInventoryRepository repository;
    int mockStatusCode = 200;
    String mockResponseBody = '[]';

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://test.sigo.com'));
      dio.httpClientAdapter = _MockHttpAdapter((options) {
        return ResponseBody.fromString(
          mockResponseBody,
          mockStatusCode,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      repository = HttpInventoryRepository(dio);
    });

    test('getCompanies() retorna lista de CompanyModel cuando backend responde 200 con datos', () async {
      mockStatusCode = 200;
      mockResponseBody = '''
      [
        {"codigo": "EMP1", "descripcion": "Empresa 1"},
        {"codigo": "EMP2", "descripcion": "Empresa 2"}
      ]
      ''';

      final companies = await repository.getCompanies();
      expect(companies.length, 2);
      expect(companies[0].codigo, 'EMP1');
      expect(companies[0].descripcion, 'Empresa 1');
      expect(companies[1].codigo, 'EMP2');
    });

    test('getCompanies() retorna lista vacía cuando backend responde 204 No Content', () async {
      mockStatusCode = 204;
      mockResponseBody = '';

      final companies = await repository.getCompanies();
      expect(companies, isEmpty);
    });

    test('getCompanies() retorna lista vacía si response.data es nulo', () async {
      mockStatusCode = 200;
      mockResponseBody = 'null';

      final companies = await repository.getCompanies();
      expect(companies, isEmpty);
    });

    test('getWarehouses() retorna lista vacía si status 204 o data nula', () async {
      mockStatusCode = 204;
      mockResponseBody = '';

      final warehouses = await repository.getWarehouses('EMP1');
      expect(warehouses, isEmpty);
    });

    test('getArticles() retorna lista vacía si companyId es nulo o vacío', () async {
      final articles = await repository.getArticles('BOD1', null);
      expect(articles, isEmpty);
    });

    test('getArticles() retorna lista vacía si status 204 No Content', () async {
      mockStatusCode = 204;
      mockResponseBody = '';

      final articles = await repository.getArticles('BOD1', 'EMP1');
      expect(articles, isEmpty);
    });
  });
}

class _MockHttpAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;

  _MockHttpAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
