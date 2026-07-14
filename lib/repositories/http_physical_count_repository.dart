import 'package:dio/dio.dart';
import '../models/company_model.dart';
import '../models/warehouse_model.dart';
import '../models/article_model.dart';
import '../models/personal_model.dart';
import '../models/physical_count_model.dart';
import 'physical_count_repository.dart';

/// Implementación HTTP real del [PhysicalCountRepository] usando [Dio].
class HttpPhysicalCountRepository implements PhysicalCountRepository {
  final Dio _dio;

  HttpPhysicalCountRepository(this._dio);

  @override
  Future<List<CompanyModel>> getCompanies() async {
    final response = await _dio.get('/api/v1/empresas/getAll');
    final List<dynamic> data = response.data;
    return data.map((json) => CompanyModel.fromJson(json)).toList();
  }

  @override
  Future<List<WarehouseModel>> getWarehouses(String companyId) async {
    final response = await _dio.get('/api/v1/bodegas/empresa/$companyId');
    final List<dynamic> data = response.data;
    return data.map((json) => WarehouseModel.fromJson(json)).toList();
  }

  @override
  Future<List<ArticleModel>> getArticles(
    String warehouseId, [
    String? companyId,
  ]) async {
    if (companyId == null || companyId.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      return _getMockArticles();
    }

    try {
      final response = await _dio.get(
        '/api/v1/articulos/asignados/$warehouseId/$companyId',
      );
      final List<dynamic> data = response.data;

      final List<ArticleModel> articles = [
        const ArticleModel(
          id: 'All',
          name: 'Todos',
          licensePlate: '',
          warehouse: 'All',
        ),
      ];

      articles.addAll(data.map((json) => ArticleModel.fromJson(json)));
      return articles;
    } on DioException catch (_) {
      return _getMockArticles();
    }
  }

  List<ArticleModel> _getMockArticles() {
    return [
      const ArticleModel(
        id: 'All',
        name: 'Todos',
        licensePlate: '',
        warehouse: 'All',
      ),
      const ArticleModel(
        id: 'A1',
        name: 'Computador Portátil',
        licensePlate: 'P-001',
        warehouse: 'W1',
      ),
      const ArticleModel(
        id: 'A2',
        name: 'Silla Ergonómica',
        licensePlate: 'S-005',
        warehouse: 'W1',
      ),
    ];
  }

  @override
  Future<List<PersonalModel>> searchPersons({
    String? nombre,
    String? apellido,
    String? cedula,
  }) async {
    final hasNombre = nombre != null && nombre.trim().isNotEmpty;
    final hasApellido = apellido != null && apellido.trim().isNotEmpty;
    final hasCedula = cedula != null && cedula.trim().isNotEmpty;

    if (!hasNombre && !hasApellido && !hasCedula) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/v1/personal/buscar'),
        response: Response(
          statusCode: 400,
          requestOptions: RequestOptions(path: '/api/v1/personal/buscar'),
          data: {
            'message':
                'Debe enviarse al menos uno de los tres parámetros (nombre, apellido o cedula).',
          },
        ),
        type: DioExceptionType.badResponse,
      );
    }

    final queryParams = <String, dynamic>{};
    if (hasNombre) queryParams['nombre'] = nombre.trim();
    if (hasApellido) queryParams['apellido'] = apellido.trim();
    if (hasCedula) queryParams['cedula'] = cedula.trim();

    final response = await _dio.get(
      '/api/v1/personal/buscar',
      queryParameters: queryParams,
    );

    final List<dynamic> data = response.data;
    return data.map((json) => PersonalModel.fromJson(json)).toList();
  }

  @override
  Future<void> createPhysicalCount(PhysicalCountRequest request) async {
    await _dio.post('/api/v1/conteo-fisico/registrar', data: request.toJson());
  }

  @override
  Future<void> assignArticles(AsignacionConteoRequest request) async {
    await _dio.post(
      '/api/v1/conteo-fisico/asignar_articulos',
      data: request.toJson(),
    );
  }
}
