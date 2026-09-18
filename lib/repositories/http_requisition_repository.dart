import 'package:dio/dio.dart';
import '../exceptions/requisition_business_exception.dart';
import '../models/company_model.dart';
import '../models/requisition_model.dart';
import '../repositories/requisition_repository.dart';
import '../utils/app_logger.dart';

/// Implementación HTTP real de [RequisitionRepository] que conecta con Spring Boot.
///
/// Consume los endpoints bajo `/api/v1/requisiciones` utilizando la instancia unificada de [Dio].
class HttpRequisitionRepository implements RequisitionRepository {
  final Dio dio;
  static const String basePath = '/api/v1/requisiciones';

  HttpRequisitionRepository(this.dio);

  void _checkResponseCode(dynamic data, String fallbackError, {String? endpoint}) {
    if (data is Map<String, dynamic> && data.containsKey('code')) {
      final code = data['code'];
      if (code != null && code != 0) {
        final msg = data['msg']?.toString() ?? fallbackError;
        throw RequisitionBusinessException(
          msg,
          statusCode: code is int ? code : null,
          endpoint: endpoint,
          technicalDetails:
              'Código de negocio: $code\nMensaje: $msg${endpoint != null ? '\nEndpoint: $endpoint' : ''}',
        );
      }
    }
  }

  RequisitionBusinessException _mapDioException(
    DioException e,
    String endpoint,
    String defaultUserMsg,
  ) {
    AppLogger.e('Error en $endpoint', e);
    final statusCode = e.response?.statusCode;
    final serverMsg = (e.response?.data is Map)
        ? (e.response?.data['msg'] ??
                e.response?.data['message'] ??
                e.response?.data['error'])
            ?.toString()
        : (e.response?.data is String ? e.response?.data as String : null);

    final String userMsg;
    if (serverMsg != null && serverMsg.trim().isNotEmpty) {
      userMsg = serverMsg.trim();
    } else if (statusCode == 500) {
      userMsg = 'Error interno en el servidor al procesar la requisición.';
    } else if (statusCode == 404) {
      userMsg = 'No se encontró el recurso de requisición especificado.';
    } else if (statusCode == 403) {
      userMsg = 'No tiene permisos suficientes para operar sobre requisiciones.';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      userMsg = 'Error de conexión con el servidor. Verifique su red.';
    } else {
      userMsg = defaultUserMsg;
    }

    final techDetails = [
      'Endpoint: $endpoint',
      if (statusCode != null) 'Código HTTP: $statusCode',
      if (serverMsg != null && serverMsg.trim().isNotEmpty)
        'Respuesta del servidor: $serverMsg',
      if (e.message != null && e.message!.isNotEmpty)
        'Detalle Dio: ${e.message}',
    ].join('\n');

    return RequisitionBusinessException(
      userMsg,
      technicalDetails: techDetails,
      statusCode: statusCode,
      endpoint: endpoint,
    );
  }

  @override
  Future<List<CompanyModel>> getCompanies() async {
    const endpoint = '/api/v1/empresas/getAll';
    try {
      AppLogger.i('[REQUISICIONES] Consultando catálogo de empresas: GET ${dio.options.baseUrl}$endpoint');
      final response = await dio.get(endpoint);
      AppLogger.i('[REQUISICIONES] Catálogo de empresas recibido - HTTP ${response.statusCode}');
      if (response.statusCode == 204 || response.data == null) {
        return [];
      }
      _checkResponseCode(response.data, 'Error al consultar catálogo de empresas', endpoint: endpoint);

      final dynamic rawData = (response.data is Map) ? response.data['data'] : response.data;
      if (rawData is List) {
        return rawData
            .map((e) => CompanyModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapDioException(e, endpoint, 'Error al consultar catálogo de empresas.');
    }
  }

  @override
  Future<List<RequisicionTipoDocumento>> getDocumentTypes() async {
    const endpoint = '$basePath/tipos';
    try {
      final response = await dio.get(endpoint);
      _checkResponseCode(response.data, 'Error al consultar tipos de requisición', endpoint: endpoint);

      final dynamic rawData = (response.data is Map) ? response.data['data'] : response.data;
      if (rawData is List) {
        return rawData
            .map((e) => RequisicionTipoDocumento.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapDioException(e, endpoint, 'Error al consultar tipos de requisición.');
    }
  }

  @override
  Future<List<RequisicionResumen>> getRequisitions({
    String? estado,
    String? empresa,
    String? tipoDocumento,
    String? bodega,
    String? desde,
  }) async {
    const endpoint = basePath;
    try {
      final queryParams = <String, dynamic>{};
      if (estado != null && estado.isNotEmpty) queryParams['estado'] = estado;
      if (empresa != null && empresa.isNotEmpty) queryParams['empresa'] = empresa;
      if (tipoDocumento != null && tipoDocumento.isNotEmpty) queryParams['tipoDocumento'] = tipoDocumento;
      if (bodega != null && bodega.isNotEmpty) queryParams['bodega'] = bodega;
      if (desde != null && desde.isNotEmpty) queryParams['desde'] = desde;

      final fullUrl = '${dio.options.baseUrl}$endpoint${queryParams.isNotEmpty ? '?${Uri(queryParameters: queryParams).query}' : ''}';
      AppLogger.i('================================================================');
      AppLogger.i('[REQUISICIONES] >> PETICIÓN HTTP GET ENVIADA AL BACKEND:');
      AppLogger.i('  Endpoint: $endpoint');
      AppLogger.i('  URL Base: ${dio.options.baseUrl}');
      AppLogger.i('  URL Completa: $fullUrl');
      AppLogger.i('  Query Parameters: $queryParams');
      AppLogger.i('================================================================');

      final response = await dio.get(endpoint, queryParameters: queryParams);
      AppLogger.i('[REQUISICIONES] << RESPUESTA RECIBIDA - HTTP ${response.statusCode}');
      _checkResponseCode(response.data, 'Error al consultar bandeja de requisiciones', endpoint: endpoint);

      final dynamic rawData = (response.data is Map) ? response.data['data'] : response.data;
      if (rawData is List) {
        return rawData
            .map((e) => RequisicionResumen.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapDioException(e, endpoint, 'Error al consultar la bandeja de requisiciones.');
    }
  }

  @override
  Future<RequisicionDetalle> getRequisitionDetail(
    String empresa,
    String tipoDocumento,
    String numero,
  ) async {
    final endpoint = '$basePath/$empresa/$tipoDocumento/$numero';
    try {
      AppLogger.i('[REQUISICIONES] Consultando detalle: GET ${dio.options.baseUrl}$endpoint');
      final response = await dio.get(endpoint);
      _checkResponseCode(response.data, 'Error al consultar detalle de requisición', endpoint: endpoint);

      final dynamic rawData = (response.data is Map) ? response.data['data'] : response.data;
      if (rawData is Map<String, dynamic>) {
        return RequisicionDetalle.fromJson(rawData);
      }
      throw RequisitionBusinessException(
        'El formato de detalle de requisición recibido no es válido.',
        endpoint: endpoint,
      );
    } on DioException catch (e) {
      throw _mapDioException(e, endpoint, 'Error al consultar el detalle de la requisición.');
    }
  }

  @override
  Future<List<RequisitionModel>> getRequisitionsByStatus(
    String status, {
    String? empresa,
    String? tipoDocumento,
    String? bodega,
    String? desde,
  }) async {
    try {
      final summaries = await getRequisitions(
        estado: status,
        empresa: empresa,
        tipoDocumento: tipoDocumento,
        bodega: bodega,
        desde: desde,
      );

      if (summaries.isEmpty) return [];

      // Concurrencia controlada para enriquecer las requisiciones con sus líneas detalladas
      final futures = summaries.map((summary) async {
        try {
          final detail = await getRequisitionDetail(
            summary.empresa,
            summary.tipoDocumento,
            summary.numero.toString(),
          );

          final lines = <RequisitionModel>[];
          for (final linea in detail.lineas) {
            // Filtrar líneas pertinentes al estado solicitado si vienen mezcladas
            if (linea.estado.isEmpty || linea.estado.toLowerCase() == status.toLowerCase()) {
              lines.add(RequisitionModel.fromDetalleLinea(detalle: detail, linea: linea));
            }
          }
          return lines;
        } catch (e) {
          AppLogger.w('No se pudo cargar detalle para terna (${summary.empresa}, ${summary.tipoDocumento}, ${summary.numero}): $e');
          return <RequisitionModel>[];
        }
      });

      final results = await Future.wait(futures);
      return results.expand((element) => element).toList();
    } catch (e) {
      if (e is RequisitionBusinessException) rethrow;
      throw RequisitionBusinessException(
        'Error al procesar la lista de requisiciones: $e',
      );
    }
  }

  @override
  Future<void> approveLines(
    String empresa,
    String tipoDocumento,
    String numero,
    List<RequisicionLineaItem> lineas,
  ) async {
    final endpoint = '$basePath/$empresa/$tipoDocumento/$numero/aprobar';
    try {
      final body = {
        'lineas': lineas.map((e) => e.toJson()).toList(),
      };
      AppLogger.i('================================================================');
      AppLogger.i('[REQUISICIONES] >> PETICIÓN HTTP PUT APROBAR ENVIADA AL BACKEND:');
      AppLogger.i('  Endpoint: ${dio.options.baseUrl}$endpoint');
      AppLogger.i('  Body: $body');
      AppLogger.i('================================================================');
      final response = await dio.put(endpoint, data: body);
      AppLogger.i('[REQUISICIONES] << Aprobación procesada - HTTP ${response.statusCode}');
      _checkResponseCode(response.data, 'Error al aprobar líneas de requisición', endpoint: endpoint);
    } on DioException catch (e) {
      throw _mapDioException(e, endpoint, 'Error al aprobar las líneas de la requisición.');
    }
  }

  @override
  Future<void> deliverLines(
    String empresa,
    String tipoDocumento,
    String numero,
    List<RequisicionLineaItem> lineas,
  ) async {
    final endpoint = '$basePath/$empresa/$tipoDocumento/$numero/entregar';
    try {
      final body = {
        'lineas': lineas.map((e) => e.toJson()).toList(),
      };
      AppLogger.i('================================================================');
      AppLogger.i('[REQUISICIONES] >> PETICIÓN HTTP PUT ENTREGAR ENVIADA AL BACKEND:');
      AppLogger.i('  Endpoint: ${dio.options.baseUrl}$endpoint');
      AppLogger.i('  Body: $body');
      AppLogger.i('================================================================');
      final response = await dio.put(endpoint, data: body);
      AppLogger.i('[REQUISICIONES] << Entrega procesada - HTTP ${response.statusCode}');
      _checkResponseCode(response.data, 'Error al entregar líneas de requisición', endpoint: endpoint);
    } on DioException catch (e) {
      throw _mapDioException(e, endpoint, 'Error al registrar la entrega de líneas de requisición.');
    }
  }

  @override
  Future<void> annulLines(
    String empresa,
    String tipoDocumento,
    String numero,
    List<RequisicionLineaKey> lineas,
  ) async {
    final endpoint = '$basePath/$empresa/$tipoDocumento/$numero/anular';
    try {
      final body = {
        'lineas': lineas.map((e) => e.toJson()).toList(),
      };
      final response = await dio.put(endpoint, data: body);
      _checkResponseCode(response.data, 'Error al anular líneas de requisición', endpoint: endpoint);
    } on DioException catch (e) {
      throw _mapDioException(e, endpoint, 'Error al anular las líneas de la requisición.');
    }
  }

  @override
  Future<void> signRequisition(
    String empresa,
    String tipoDocumento,
    String numero,
    RequisicionFirmaRequest request,
  ) async {
    final endpoint = '$basePath/$empresa/$tipoDocumento/$numero/firmar';
    try {
      final response = await dio.put(endpoint, data: request.toJson());
      _checkResponseCode(response.data, 'Error al registrar firma de requisición', endpoint: endpoint);
    } on DioException catch (e) {
      throw _mapDioException(e, endpoint, 'Error al registrar la firma de la requisición.');
    }
  }

  @override
  Future<Map<String, dynamic>> registerExit(
    String empresa,
    String tipoDocumento,
    String numero, {
    RequisicionRegistrarRequest? request,
  }) async {
    final endpoint = '$basePath/$empresa/$tipoDocumento/$numero/registrar';
    try {
      final body = request?.toJson() ?? {};
      final response = await dio.put(endpoint, data: body);
      _checkResponseCode(response.data, 'Error al registrar salida de inventario ERP', endpoint: endpoint);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'code': 0, 'msg': 'Salida registrada'};
    } on DioException catch (e) {
      throw _mapDioException(e, endpoint, 'Error al registrar la salida definitiva en el ERP.');
    }
  }

  @override
  Future<bool> processBatch(
    Map<String, int> selectedItems,
    String targetStatus, {
    List<RequisitionModel>? requisitions,
  }) async {
    if (selectedItems.isEmpty) return false;

    // Agrupamos los ítems seleccionados por terna (empresa, tipoDocumento, numero)
    final Map<String, List<RequisicionLineaItem>> groupedLines = {};

    for (final entry in selectedItems.entries) {
      final id = entry.key;
      final cantidad = entry.value.toDouble();
      if (cantidad <= 0) continue;

      // Intentamos localizar el modelo en la lista en memoria si fue provista
      RequisitionModel? match;
      if (requisitions != null) {
        for (final req in requisitions) {
          if (req.id == id || req.compositeId == id || req.lineKey == id) {
            match = req;
            break;
          }
        }
      }

      String empresa;
      String tipoDocumento;
      String numero;
      String articulo;
      String bodega;
      num secuencia;

      if (match != null) {
        empresa = match.empresa;
        tipoDocumento = match.tipoDocumento;
        numero = match.numero;
        // Si el artículo trae "CODIGO - NOMBRE", tomamos el código previo al separador
        articulo = match.articulo.contains(' - ')
            ? match.articulo.split(' - ').first.trim()
            : match.articulo;
        bodega = match.bodega;
        secuencia = match.secuencia;
      } else {
        // Fallback: parsear composite '${empresa}_${tipoDocumento}_${numero}_${bodega}_$articulo'
        final parts = id.split('_');
        if (parts.length >= 5) {
          empresa = parts[0];
          tipoDocumento = parts[1];
          numero = parts[2];
          bodega = parts[3];
          articulo = parts[4];
          secuencia = parts.length >= 6 ? (num.tryParse(parts[5]) ?? 1) : 1;
        } else {
          AppLogger.w('No se pudo determinar la terna para el id: $id');
          continue;
        }
      }

      final ternaKey = '$empresa|$tipoDocumento|$numero';
      groupedLines.putIfAbsent(ternaKey, () => []);
      groupedLines[ternaKey]!.add(
        RequisicionLineaItem(
          articulo: articulo,
          bodega: bodega,
          secuencia: secuencia,
          cantidad: cantidad,
        ),
      );
    }

    if (groupedLines.isEmpty) return false;

    // Ejecutar las operaciones por cada terna agrupada
    for (final entry in groupedLines.entries) {
      final ternaParts = entry.key.split('|');
      final empresa = ternaParts[0];
      final tipoDocumento = ternaParts[1];
      final numero = ternaParts[2];
      final lines = entry.value;

      if (targetStatus == 'ap') {
        await approveLines(empresa, tipoDocumento, numero, lines);
      } else if (targetStatus == 'en') {
        await deliverLines(empresa, tipoDocumento, numero, lines);
      } else {
        throw RequisitionBusinessException(
          'Estado destino no soportado para procesamiento en lote: $targetStatus',
        );
      }
    }

    return true;
  }
}
