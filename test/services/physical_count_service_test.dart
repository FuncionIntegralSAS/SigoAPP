import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/services/physical_count_service.dart';
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
  group('PhysicalCountService.getArticles Tests', () {
    test('Should return mock articles when companyId is null', () async {
      final dio = Dio();
      final service = PhysicalCountService(dio);

      final articles = await service.getArticles('W1', null);
      expect(articles.length, 3);
      expect(articles.first.id, 'All');
      expect(articles.first.name, 'Todos');
    });

    test('Should return mock articles when companyId is empty', () async {
      final dio = Dio();
      final service = PhysicalCountService(dio);

      final articles = await service.getArticles('W1', '');
      expect(articles.length, 3);
      expect(articles.first.id, 'All');
      expect(articles.first.name, 'Todos');
    });

    test('Should return mock articles when backend call throws DioException (fallback)', () async {
      final fakeDio = FakeDio((options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'Connection failed',
        );
      });
      final service = PhysicalCountService(fakeDio);

      final articles = await service.getArticles('W1', 'C1');
      expect(articles.length, 3);
      expect(articles.first.id, 'All');
      expect(articles[1].id, 'A1');
    });

    test('Should return parsed backend articles prepended with Todos when backend call succeeds', () async {
      final fakeDio = FakeDio((options) {
        expect(options.path, '/api/v1/articulos/asignados/W1/C1');
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: [
            {
              'id': 'A100',
              'name': 'Articulo Backend',
              'licensePlate:': 'PL-99',
              'warehouse': 'W1',
            }
          ],
        );
      });
      final service = PhysicalCountService(fakeDio);

      final articles = await service.getArticles('W1', 'C1');
      expect(articles.length, 2);
      expect(articles[0].id, 'All');
      expect(articles[0].name, 'Todos');
      expect(articles[1].id, 'A100');
      expect(articles[1].name, 'Articulo Backend');
    });
  });
}
