import 'package:sigo_app/models/company_model.dart';
import 'package:sigo_app/models/warehouse_model.dart';
import 'package:sigo_app/models/article_model.dart';
import 'package:sigo_app/models/person_model.dart';
import 'package:sigo_app/models/physical_count_model.dart';
import 'package:dio/dio.dart'; // Asegúrate de omitir si tu proyecto usa http en vez de dio. Si es necesario quita la dependencia.

class PhysicalCountService {
  final Dio _dio;

  PhysicalCountService(this._dio);

  Future<List<CompanyModel>> getCompanies() async {
    final response = await _dio.get('/api/v1/empresas/getAll');
    final List<dynamic> data = response.data;
    return data.map((json) => CompanyModel.fromJson(json)).toList();
  }

  Future<List<WarehouseModel>> getWarehouses(String companyId) async {
    final response = await _dio.get('/api/v1/bodegas/empresa/$companyId');
    final List<dynamic> data = response.data;
    return data.map((json) => WarehouseModel.fromJson(json)).toList();
  }

  Future<List<ArticleModel>> getArticles(String warehouseId) async {
    await Future.delayed(const Duration(seconds: 1));
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

  Future<List<PersonModel>> searchPersons({
    String? nombre,
    String? apellido,
    String? cedula,
  }) async {
    // Regla de Validación Importante
    final hasNombre = nombre != null && nombre.trim().isNotEmpty;
    final hasApellido = apellido != null && apellido.trim().isNotEmpty;
    final hasCedula = cedula != null && cedula.trim().isNotEmpty;

    if (!hasNombre && !hasApellido && !hasCedula) {
      // Rechazo del servidor 400 Bad Request
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
    return data.map((json) => PersonModel.fromJson(json)).toList();
  }

  Future<void> createPhysicalCount(PhysicalCountRequest request) async {
    await _dio.post('/api/v1/conteo-fisico/registrar', data: request.toJson());
  }
}
