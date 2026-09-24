import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/exceptions/catalog_business_exception.dart';
import 'package:sigo_app/modules/inventory/repositories/http_catalog_repository.dart';

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
  late HttpCatalogRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    adapter = MockHttpClientAdapter();
    dio.httpClientAdapter = adapter;
    repository = HttpCatalogRepository(dio);
  });

  group('HttpCatalogRepository Tests', () {
    test('searchEmployees envía queryParameters correctos y mapea PersonResponse de backend', () async {
      RequestOptions? capturedOptions;
      adapter.handler = (options) {
        capturedOptions = options;
        return ResponseBody.fromString(
          '''
          [
            {
              "cedula": "1098765432",
              "nombre": "CARLOS ALBERTO",
              "apellido": "PEREZ GOMEZ",
              "correo": "cperez@funcionintegral.com",
              "division": "DIV-01",
              "estado": "ac"
            }
          ]
          ''',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final results = await repository.searchEmployees(
        nombre: 'Carlos',
        apellido: 'Perez',
        cedula: '1098765432',
      );

      expect(capturedOptions?.path, equals('/api/v1/personal/buscar'));
      expect(capturedOptions?.queryParameters['nombre'], equals('Carlos'));
      expect(capturedOptions?.queryParameters['apellido'], equals('Perez'));
      expect(capturedOptions?.queryParameters['cedula'], equals('1098765432'));

      expect(results.length, equals(1));
      final emp = results.first;
      expect(emp.cedula, equals('1098765432'));
      expect(emp.nombre, equals('CARLOS ALBERTO PEREZ GOMEZ'));
      expect(emp.correo, equals('cperez@funcionintegral.com'));
      expect(emp.divisionId, equals('DIV-01'));
      expect(emp.personaId, equals(1098765432));
    });

    test('searchEmployees sin parámetros consulta todo el personal activo', () async {
      RequestOptions? capturedOptions;
      adapter.handler = (options) {
        capturedOptions = options;
        return ResponseBody.fromString(
          '[]',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final results = await repository.searchEmployees();

      expect(capturedOptions?.path, equals('/api/v1/personal/buscar'));
      expect(capturedOptions?.queryParameters, anyOf(isNull, isEmpty));
      expect(results, isEmpty);
    });

    test('findEmployee con número busca directamente por cédula', () async {
      RequestOptions? capturedOptions;
      adapter.handler = (options) {
        capturedOptions = options;
        return ResponseBody.fromString(
          '''
          [
            {
              "cedula": "1098765432",
              "nombre": "CARLOS",
              "apellido": "PEREZ",
              "division": "DIV-01",
              "estado": "ac"
            }
          ]
          ''',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final employee = await repository.findEmployee('1098765432');

      expect(capturedOptions?.queryParameters['cedula'], equals('1098765432'));
      expect(employee.cedula, equals('1098765432'));
      expect(employee.nombre, equals('CARLOS PEREZ'));
    });

    test('getWarehousesByDivision consulta /api/v1/bodegas/division/{divisionId}', () async {
      RequestOptions? capturedOptions;
      adapter.handler = (options) {
        capturedOptions = options;
        return ResponseBody.fromString(
          '''
          [
            {
              "codigoBodega": "BOD-01",
              "descripcionBodega": "Bodega Principal",
              "estadoBodega": "A"
            }
          ]
          ''',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final warehouses = await repository.getWarehousesByDivision('DIV-01');

      expect(capturedOptions?.path, equals('/api/v1/bodegas/division/DIV-01'));
      expect(warehouses.length, equals(1));
      expect(warehouses.first.codigoBodega, equals('BOD-01'));
    });

    test('getWarehousesByDivision lanza CatalogBusinessException ante HTTP 500 con detalles para el desarrollador', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          '{"message": "ORA-00904: invalid identifier"}',
          500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      expect(
        () => repository.getWarehousesByDivision('DIV-01'),
        throwsA(
          isA<CatalogBusinessException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.userMessage, 'userMessage',
                  contains('Error interno en el servidor'))
              .having((e) => e.technicalDetails, 'technicalDetails',
                  contains('Código HTTP: 500'))
              .having((e) => e.endpoint, 'endpoint',
                  equals('/api/v1/bodegas/division/DIV-01')),
        ),
      );
    });
  });
}
