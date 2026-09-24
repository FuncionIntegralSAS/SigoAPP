import 'package:dio/dio.dart';
import 'package:sigo_app/exceptions/catalog_business_exception.dart';
import 'package:sigo_app/modules/inventory/models/employee_result.dart';
import 'package:sigo_app/shared/models/warehouse_model.dart';
import 'package:sigo_app/utils/app_logger.dart';
import 'package:sigo_app/modules/inventory/repositories/catalog_repository.dart';

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
  Future<List<EmployeeResult>> searchEmployees({
    String? nombre,
    String? apellido,
    String? cedula,
  }) async {
    try {
      final Map<String, dynamic> qParams = {};
      if (nombre != null && nombre.trim().isNotEmpty) {
        qParams['nombre'] = nombre.trim();
      }
      if (apellido != null && apellido.trim().isNotEmpty) {
        qParams['apellido'] = apellido.trim();
      }
      if (cedula != null && cedula.trim().isNotEmpty) {
        qParams['cedula'] = cedula.trim();
      }

      final response = await _dio.get(
        '/api/v1/personal/buscar',
        queryParameters: qParams.isNotEmpty ? qParams : null,
        options: Options(headers: {'Accept': 'application/json'}),
      );

      final data = response.data;
      final List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        if (data.containsKey('list') && data['list'] is List) {
          list = data['list'];
        } else if (data.containsKey('data') && data['data'] is List) {
          list = data['data'];
        } else {
          list = [data];
        }
      } else {
        list = [];
      }

      return list
          .map((item) => EmployeeResult.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 204) {
        return [];
      }
      AppLogger.e('Error al consultar personal en /api/v1/personal/buscar', e);

      final statusCode = e.response?.statusCode;
      final serverMsg = (e.response?.data is Map)
          ? (e.response?.data['message'] ??
                  e.response?.data['msg'] ??
                  e.response?.data['error'])
              ?.toString()
          : (e.response?.data is String ? e.response?.data as String : null);

      if (statusCode == 400) {
        throw CatalogBusinessException(
          serverMsg ?? 'Parámetros de búsqueda de personal inválidos.',
          technicalDetails:
              'GET /api/v1/personal/buscar [HTTP 400]\n${serverMsg ?? ''}',
          statusCode: 400,
          endpoint: '/api/v1/personal/buscar',
        );
      }

      final String userMsg;
      if (statusCode == 500) {
        userMsg =
            'Error interno en el servidor al buscar personal. Intente más tarde.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        userMsg = 'Error de conexión con el servidor al buscar personal.';
      } else {
        userMsg = 'No fue posible consultar el personal en el sistema.';
      }

      final techDetails = [
        'Endpoint: GET /api/v1/personal/buscar',
        if (statusCode != null) 'Código HTTP: $statusCode',
        if (serverMsg != null && serverMsg.trim().isNotEmpty)
          'Respuesta del servidor: $serverMsg',
        if (e.message != null && e.message!.isNotEmpty)
          'Detalle Dio: ${e.message}',
      ].join('\n');

      throw CatalogBusinessException(
        userMsg,
        technicalDetails: techDetails,
        statusCode: statusCode,
        endpoint: '/api/v1/personal/buscar',
      );
    }
  }

  @override
  Future<EmployeeResult> findEmployee(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      throw Exception('El criterio de búsqueda no puede estar vacío');
    }

    List<EmployeeResult> results = [];

    // Si el query es exclusivamente numérico, buscar prioritariamente por cédula
    final isNumeric = RegExp(r'^\d+$').hasMatch(cleanQuery);
    if (isNumeric) {
      results = await searchEmployees(cedula: cleanQuery);
    } else {
      // Si contiene palabras, intentar separar por nombre y apellido
      final parts = cleanQuery.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        results = await searchEmployees(
          nombre: parts.first,
          apellido: parts.sublist(1).join(' '),
        );
      }
      
      // Si no hubo resultados o era una sola palabra, buscar por nombre
      if (results.isEmpty) {
        results = await searchEmployees(nombre: cleanQuery);
      }

      // Si no hubo resultados por nombre, buscar por apellido
      if (results.isEmpty) {
        results = await searchEmployees(apellido: cleanQuery);
      }
    }

    // Si aún no hay resultados, intentar como cédula o código
    if (results.isEmpty && !isNumeric) {
      results = await searchEmployees(cedula: cleanQuery);
    }

    if (results.isEmpty) {
      throw Exception('Empleado no encontrado para el código: $query');
    }

    return results.first;
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
      AppLogger.e(
        'Error al consultar bodegas para división $divisionId en /api/v1/bodegas/division/$divisionId',
        e,
      );

      final statusCode = e.response?.statusCode;
      final serverMsg = (e.response?.data is Map)
          ? (e.response?.data['message'] ??
                  e.response?.data['msg'] ??
                  e.response?.data['error'])
              ?.toString()
          : (e.response?.data is String ? e.response?.data as String : null);

      final String userMsg;
      if (statusCode == 500) {
        userMsg =
            'Error interno en el servidor al consultar las bodegas de la división.';
      } else if (statusCode == 404) {
        userMsg = 'No se encontraron bodegas asociadas a la división $divisionId.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        userMsg = 'Error de conexión con el servidor al cargar bodegas.';
      } else {
        userMsg = 'No fue posible obtener las bodegas asociadas a la división.';
      }

      final techDetails = [
        'Endpoint: GET /api/v1/bodegas/division/$divisionId',
        if (statusCode != null) 'Código HTTP: $statusCode',
        if (serverMsg != null && serverMsg.trim().isNotEmpty)
          'Respuesta del servidor: $serverMsg',
        if (e.message != null && e.message!.isNotEmpty)
          'Detalle Dio: ${e.message}',
      ].join('\n');

      throw CatalogBusinessException(
        userMsg,
        technicalDetails: techDetails,
        statusCode: statusCode,
        endpoint: '/api/v1/bodegas/division/$divisionId',
      );
    }
  }
}
