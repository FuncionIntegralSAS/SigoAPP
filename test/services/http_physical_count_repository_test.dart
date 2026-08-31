import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/repositories/http_physical_count_repository.dart';
import 'package:dio/dio.dart';

import 'package:sigo_app/utils/json_interceptor.dart';

class FakeDio implements Dio {
  final Response Function(RequestOptions options) onGet;

  FakeDio(this.onGet);

  @override
  BaseOptions options = BaseOptions();

  @override
  late final Interceptors interceptors = Interceptors()..add(JsonInterceptor());

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    final reqOptions = RequestOptions(
      path: path,
      queryParameters: queryParameters,
      data: data,
    );
    final response = onGet(reqOptions);
    return Response<T>(
      data: response.data as T?,
      headers: response.headers,
      requestOptions: reqOptions,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('HttpPhysicalCountRepository.getArticles Tests', () {
    test('Should return mock articles when companyId is null', () async {
      final dio = Dio();
      final repository = HttpPhysicalCountRepository(dio);

      final articles = await repository.getArticles('W1', null);
      expect(articles.length, 3);
      expect(articles.first.codigoActivo, 'All');
      expect(articles.first.nombre, 'Todos');
    });

    test('Should return mock articles when companyId is empty', () async {
      final dio = Dio();
      final repository = HttpPhysicalCountRepository(dio);

      final articles = await repository.getArticles('W1', '');
      expect(articles.length, 3);
      expect(articles.first.codigoActivo, 'All');
      expect(articles.first.nombre, 'Todos');
    });

    test('Should return mock articles when backend call throws DioException (fallback)', () async {
      final fakeDio = FakeDio((options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'Connection failed',
        );
      });
      final repository = HttpPhysicalCountRepository(fakeDio);

      final articles = await repository.getArticles('W1', 'C1');
      expect(articles.length, 3);
      expect(articles.first.codigoActivo, 'All');
      expect(articles[1].codigoActivo, 'A1');
    });

    test('Should return parsed backend articles prepended with Todos when backend call succeeds', () async {
      final fakeDio = FakeDio((options) {
        expect(options.path, '/api/v1/articulos/asignados/W1/C1');
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: [
            {
              'id': 100,
              'artiCodi': 'A100',
              'name': 'Articulo Backend',
              'placa': 'PL-99',
              'bodega': 'W1',
            }
          ],
        );
      });
      final repository = HttpPhysicalCountRepository(fakeDio);

      final articles = await repository.getArticles('W1', 'C1');
      expect(articles.length, 2);
      expect(articles[0].codigoActivo, 'All');
      expect(articles[0].nombre, 'Todos');
      expect(articles[1].codigoActivo, 'A100');
      expect(articles[1].nombre, 'Articulo Backend');
    });
  });
}
