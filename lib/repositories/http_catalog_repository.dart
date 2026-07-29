import 'package:dio/dio.dart';
import '../models/employee_result.dart';
import '../models/warehouse_model.dart';
import 'catalog_repository.dart';

/// Implementación HTTP real de [CatalogRepository] usando [Dio].
///
/// Conecta con los endpoints del backend Spring Boot para la carga en cascada
/// del formulario de creación de traspasos:
/// - `GET /api/v1/personal/buscar?cedula=<query>` → Busca empleado.
/// - `GET /api/v1/bodegas/division/<divisionId>` → Lista bodegas por división.
class HttpCatalogRepository implements CatalogRepository {
  final Dio _dio;

  HttpCatalogRepository(this._dio);

  @override
  Future<EmployeeResult> findEmployee(String query) async {
    try {
      final response = await _dio.get(
        '/api/v1/personal/buscar',
        queryParameters: {'cedula': query.trim()},
      );

      final data = response.data;

      // El endpoint puede devolver un objeto único o una lista de un elemento
      final Map<String, dynamic> json;
      if (data is List && data.isNotEmpty) {
        json = data.first as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        json = data;
      } else {
        throw Exception('Empleado no encontrado para el código: $query');
      }

      return EmployeeResult.fromJson(json);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Empleado no encontrado para el código: $query');
      }
      if (e.response?.statusCode == 400) {
        final msg =
            e.response?.data?['message'] as String? ??
            'Código de empleado inválido';
        throw Exception(msg);
      }
      throw Exception(
        'Error de red al buscar empleado: ${e.message ?? 'sin detalle'}',
      );
    }
  }

  @override
  Future<List<WarehouseModel>> getWarehousesByDivision(
    String divisionId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/bodegas/division/$divisionId',
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => WarehouseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Error al cargar bodegas de la división $divisionId: ${e.message ?? 'sin detalle'}',
      );
    }
  }
}
