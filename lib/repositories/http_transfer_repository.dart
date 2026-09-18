import 'dart:convert';
import 'package:dio/dio.dart';
import '../exceptions/transfer_business_exception.dart';
import '../models/employee_result.dart';
import '../models/transfer_request.dart';
import '../models/transfer_create_request.dart';
import '../models/transfer_delivery_request.dart';
import '../models/transfer_person_model.dart';
import '../models/transfer_asset_model.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/transfer_repository.dart';
import '../utils/app_logger.dart';
import '../utils/dialog_utils.dart';

/// Implementación HTTP real del [TransferRepository] adaptada a la especificación
/// del backend Spring Boot refactorizado.
class HttpTransferRepository implements TransferRepository {
  final Dio dio;
  final CatalogRepository? catalogRepository;

  HttpTransferRepository(this.dio, {this.catalogRepository});

  void _checkResponseCode(dynamic data, String fallbackError, {String? endpoint}) {
    if (data is Map<String, dynamic> && data.containsKey('code')) {
      final code = data['code'];
      if (code != null && code != 0) {
        final rawMsg = data['msg']?.toString() ?? fallbackError;
        final friendlyMsg = DialogUtils.extractFriendlyMessage(rawMsg);
        final techDetails = [
          if (endpoint != null) 'Endpoint: $endpoint',
          'Código de negocio: $code',
          'Detalle del servidor:\n$rawMsg',
        ].join('\n');

        throw TransferBusinessException(
          friendlyMsg,
          statusCode: code is int ? code : null,
          endpoint: endpoint,
          technicalDetails: techDetails,
        );
      }
    }
  }

  TransferBusinessException _mapDioException(
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
      userMsg = DialogUtils.extractFriendlyMessage(serverMsg.trim());
    } else if (statusCode == 500) {
      userMsg = 'Error interno en el servidor al procesar el traspaso.';
    } else if (statusCode == 404) {
      userMsg = 'No se encontró el recurso de traspaso especificado.';
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
        'Respuesta del servidor:\n$serverMsg',
      if (e.message != null && e.message!.isNotEmpty)
        'Detalle Dio: ${e.message}',
    ].join('\n');

    return TransferBusinessException(
      userMsg,
      technicalDetails: techDetails,
      statusCode: statusCode,
      endpoint: endpoint,
    );
  }

  // --- 1. CREAR SOLICITUD (POST /api/v1/traspasos/crear) ---
  @override
  Future<void> create(dynamic request) async {
    const endpoint = 'POST /api/v1/traspasos/crear';
    try {
      final Map<String, dynamic> payload;
      if (request is TransferCreateRequest) {
        payload = request.toJson();
      } else if (request is TransferRequest) {
        payload = {
          'empresa': request.empresaDocumento ?? '01',
          'personaFuente': request.responsableActual,
          'personaDestino': request.responsablePropuesto,
          'articulos': request.articulos.isNotEmpty
              ? request.articulos.map((a) => a.toJson()).toList()
              : [
                  {
                    'articulo': request.idArticulo,
                    if (request.placa != null) 'placa': request.placa,
                  }
                ],
          'observacion': request.motivoSolicitud,
          'tipoMovimiento': null,
        };
      } else if (request is Map<String, dynamic>) {
        payload = request;
      } else {
        throw const TransferBusinessException(
          'Payload de creación de traspaso inválido',
        );
      }

      final prettyPayload = const JsonEncoder.withIndent('  ').convert(payload);
      AppLogger.i('POST /api/v1/traspasos/crear payload:\n$prettyPayload');

      final response = await dio.post(
        '/api/v1/traspasos/crear',
        data: payload,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
      );

      _checkResponseCode(response.data, 'Error al crear solicitud de traspaso',
          endpoint: endpoint);
    } on DioException catch (e) {
      throw _mapDioException(
          e, endpoint, 'Error de red al crear la solicitud de traspaso');
    }
  }

  // --- 2. OBTENER TODOS / BANDEJA (GET /api/v1/traspasos/list) ---
  @override
  Future<List<TransferRequest>> getAllTransfers({
    String? estado,
    String? empresa,
    String? bodega,
    bool fetchDetails = true,
  }) async {
    const endpoint = 'GET /api/v1/traspasos/list';
    try {
      final Map<String, dynamic> qParams = {};
      if (estado != null && estado.isNotEmpty) qParams['estado'] = estado;
      if (empresa != null && empresa.isNotEmpty) qParams['empresa'] = empresa;
      if (bodega != null && bodega.isNotEmpty) qParams['bodega'] = bodega;

      final response = await dio.get(
        '/api/v1/traspasos/list',
        queryParameters: qParams.isNotEmpty ? qParams : null,
        options: Options(headers: {'Accept': 'application/json'}),
      );

      _checkResponseCode(response.data, 'Error al listar traspasos',
          endpoint: endpoint);

      dynamic extracted = response.data;
      if (extracted is Map) {
        extracted = extracted['data'] ??
            extracted['list'] ??
            extracted['object'] ??
            extracted['content'] ??
            extracted;
      }
      if (extracted is Map) {
        extracted = extracted['data'] ??
            extracted['list'] ??
            extracted['content'] ??
            extracted['object'] ??
            [];
      }

      final List<dynamic> dataList = extracted is List ? extracted : [];
      final basicList = dataList
          .whereType<Map>()
          .map((json) =>
              TransferRequest.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      // Enriquecimiento concurrente de detalles si está habilitado
      if (fetchDetails && basicList.isNotEmpty) {
        final enriched = await Future.wait(basicList.map((item) async {
          try {
            final detail = await getTransferById(item.id);
            return detail ?? item;
          } catch (e) {
            AppLogger.w('No fue posible enriquecer trámite ID="${item.id}": $e');
            return item;
          }
        }));
        return enriched;
      }

      return basicList;
    } on DioException catch (e) {
      throw _mapDioException(
          e, endpoint, 'Error al obtener la lista de traspasos');
    }
  }

  // --- 3. OBTENER DETALLE POR ID (GET /api/v1/traspasos/get/{id}) ---
  @override
  Future<TransferRequest?> getTransferById(String id) async {
    final endpoint = 'GET /api/v1/traspasos/get/$id';
    // ignore: avoid_print
    print('>>> [HttpTransferRepository] Consultando firmas y detalle -> Enviando trámite ID: "$id" ($endpoint)');
    try {
      final response = await dio.get(
        '/api/v1/traspasos/get/$id',
        options: Options(headers: {'Accept': 'application/json'}),
      );

      _checkResponseCode(
          response.data, 'Error al consultar detalle del traspaso',
          endpoint: endpoint);

      final dynamic rawObject = response.data is Map
          ? (response.data['data'] ??
              response.data['object'] ??
              response.data['item'] ??
              response.data)
          : response.data;

      if (rawObject == null || rawObject is! Map) {
        return null;
      }

      final parsed = TransferRequest.fromJson(Map<String, dynamic>.from(rawObject));

      if (catalogRepository != null) {
        return _enrichTransferDetail(parsed);
      }
      return parsed;
    } on DioException catch (e) {
      throw _mapDioException(
          e, endpoint, 'Error al consultar el detalle del traspaso $id');
    }
  }

  Future<TransferRequest> _enrichTransferDetail(TransferRequest transfer) async {
    try {
      final sourceQuery = transfer.codigoFuente;
      final destQuery = transfer.codigoDestino;

      final results = await Future.wait([
        _resolvePersonName(sourceQuery, transfer.responsableActual),
        _resolvePersonName(destQuery, transfer.responsablePropuesto),
        getAssetsByPerson(
          persona: sourceQuery,
          empresa: transfer.empresaDocumento,
        ).catchError((_) => <TransferAssetModel>[]),
      ]);

      final String fuente = results[0] as String;
      final String destino = results[1] as String;
      final List<TransferAssetModel> assets =
          results[2] as List<TransferAssetModel>;

      final enrichedArticles = transfer.articulos.map((art) {
        if (art.nombre != null && art.nombre!.trim().isNotEmpty) return art;
        try {
          final found = assets.firstWhere(
            (a) =>
                a.articulo.trim().toLowerCase() ==
                art.articulo.trim().toLowerCase(),
          );
          if (found.nombre.trim().isNotEmpty) {
            return art.copyWith(nombre: found.nombre.trim());
          }
        } catch (_) {}
        return art;
      }).toList();

      return transfer.copyWith(
        responsableActual: fuente,
        responsablePropuesto: destino,
        personaFuente: transfer.personaFuente,
        personaDestino: transfer.personaDestino,
        articulos: enrichedArticles,
      );
    } catch (_) {
      return transfer;
    }
  }

  Future<String> _resolvePersonName(String personQuery, [String? fallbackName]) async {
    final clean = personQuery.trim();
    if (clean.isEmpty || clean == 'Sin responsable') return fallbackName ?? personQuery;
    if (catalogRepository == null) return fallbackName ?? personQuery;

    try {
      final isNumeric = RegExp(r'^\d+$').hasMatch(clean);
      List<EmployeeResult> candidates = [];
      if (isNumeric) {
        candidates = await catalogRepository!.searchEmployees(cedula: clean);
      } else {
        candidates = await catalogRepository!.searchEmployees(cedula: clean);
        if (candidates.isEmpty) {
          candidates = await catalogRepository!.searchEmployees(nombre: clean);
        }
      }

      if (candidates.isNotEmpty) {
        final emp = candidates.first;
        final fullName = emp.nombre.trim();
        if (fullName.isNotEmpty) {
          final cedula = emp.cedula?.trim() ?? clean;
          return (cedula.isNotEmpty &&
                  cedula.toLowerCase() != fullName.toLowerCase())
              ? '$fullName ($cedula)'
              : fullName;
        }
      }
    } catch (_) {}

    return (fallbackName != null && fallbackName.trim().isNotEmpty)
        ? fallbackName
        : clean;
  }

  // --- 4. APROBAR (POST /api/v1/traspasos/process/{id} con estado='ap') ---
  @override
  Future<void> approveTransfer(String requestId, {String? observacion}) async {
    final endpoint = 'POST /api/v1/traspasos/process/$requestId';
    try {
      final response = await dio.post(
        '/api/v1/traspasos/process/$requestId',
        data: {
          'estado': 'ap',
          'observacion': observacion ?? 'Aprobado para entrega física',
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      _checkResponseCode(response.data, 'Error al aprobar traspaso',
          endpoint: endpoint);
    } on DioException catch (e) {
      throw _mapDioException(
          e, endpoint, 'Error al aprobar la solicitud de traspaso');
    }
  }

  // --- 5. RECHAZAR (POST /api/v1/traspasos/process/{id} con estado='na') ---
  @override
  Future<void> rejectTransfer(
      {required String requestId, required String motivoRechazo}) async {
    final endpoint = 'POST /api/v1/traspasos/process/$requestId';
    try {
      final response = await dio.post(
        '/api/v1/traspasos/process/$requestId',
        data: {
          'estado': 'na',
          'observacion': motivoRechazo,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      _checkResponseCode(response.data, 'Error al rechazar traspaso',
          endpoint: endpoint);
    } on DioException catch (e) {
      throw _mapDioException(
          e, endpoint, 'Error al rechazar la solicitud de traspaso');
    }
  }

  // --- 6. REGISTRAR FIRMA (PUT /api/v1/traspasos/sign/{id}) ---
  @override
  Future<void> signTransfer({
    required String transferId,
    required String tipoFirma,
    required String firmaBase64,
  }) async {
    final endpoint = 'PUT /api/v1/traspasos/sign/$transferId';
    try {
      final response = await dio.put(
        '/api/v1/traspasos/sign/$transferId',
        data: {
          'tipoFirma': tipoFirma,
          'firma': firmaBase64,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      _checkResponseCode(
          response.data, 'Error al registrar firma ($tipoFirma)',
          endpoint: endpoint);
    } on DioException catch (e) {
      throw _mapDioException(
          e, endpoint, 'Error al registrar la firma del traspaso');
    }
  }

  // --- 7. CONCRETAR RECEPCIÓN (PUT /api/v1/traspasos/recibir/{id}) ---
  @override
  Future<void> receiveTransfer(String transferId) async {
    final endpoint = 'PUT /api/v1/traspasos/recibir/$transferId';
    try {
      final response = await dio.put(
        '/api/v1/traspasos/recibir/$transferId',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      _checkResponseCode(
          response.data, 'Error al confirmar recepción del traspaso',
          endpoint: endpoint);
    } on DioException catch (e) {
      throw _mapDioException(
          e, endpoint, 'Error al confirmar la recepción del traspaso');
    }
  }

  // --- 8. APLICAR TRASPASO (Compatibilidad) ---
  @override
  Future<void> applyTransfer(TransferRequest request) async {
    return Future.value();
  }

  // --- 9. APLICAR ENTREGA/RECEPCIÓN (Flujo compuesto para retrocompatibilidad) ---
  @override
  Future<void> applyTransferDelivery(TransferDeliveryRequest request) async {
    if (request.firmaDespachadorBase64 != null &&
        request.firmaDespachadorBase64!.isNotEmpty) {
      await signTransfer(
        transferId: request.transferId,
        tipoFirma: 'FU',
        firmaBase64: request.firmaDespachadorBase64!,
      );
    }

    if (request.firmaReceptorBase64 != null &&
        request.firmaReceptorBase64!.isNotEmpty) {
      await signTransfer(
        transferId: request.transferId,
        tipoFirma: 'DE',
        firmaBase64: request.firmaReceptorBase64!,
      );
    }
  }

  // --- 10. OBTENER PERSONAS POR BODEGA (GET /api/v1/traspasos/personas) ---
  @override
  Future<List<TransferPersonModel>> getPersonsByWarehouse({
    required String bodega,
    required String empresa,
  }) async {
    const endpoint = 'GET /api/v1/traspasos/personas';
    try {
      final response = await dio.get(
        '/api/v1/traspasos/personas',
        queryParameters: {
          'bodega': bodega,
          'empresa': empresa,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      _checkResponseCode(response.data, 'Error al consultar colaboradores de la bodega',
          endpoint: endpoint);

      final dynamic rawList = response.data is Map<String, dynamic>
          ? (response.data['list'] ?? response.data['data'] ?? [])
          : (response.data is List ? response.data : []);

      final List<dynamic> dataList = rawList as List<dynamic>;
      return dataList
          .whereType<Map<String, dynamic>>()
          .map((json) => TransferPersonModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(
          e, endpoint, 'Error de red al consultar colaboradores de la bodega');
    }
  }

  // --- 11. OBTENER ACTIVOS POR RESPONSABLE (GET /api/v1/traspasos/activos) ---
  @override
  Future<List<TransferAssetModel>> getAssetsByPerson({
    required String persona,
    String? empresa,
  }) async {
    const endpoint = 'GET /api/v1/traspasos/activos';
    try {
      final Map<String, dynamic> qParams = {'persona': persona};
      if (empresa != null && empresa.isNotEmpty) {
        qParams['empresa'] = empresa;
      }

      final response = await dio.get(
        '/api/v1/traspasos/activos',
        queryParameters: qParams,
        options: Options(headers: {'Accept': 'application/json'}),
      );

      _checkResponseCode(response.data, 'Error al consultar activos del colaborador',
          endpoint: endpoint);

      final dynamic rawList = response.data is Map<String, dynamic>
          ? (response.data['list'] ?? response.data['data'] ?? [])
          : (response.data is List ? response.data : []);

      final List<dynamic> dataList = rawList as List<dynamic>;
      return dataList
          .whereType<Map<String, dynamic>>()
          .map((json) => TransferAssetModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(
          e, endpoint, 'Error de red al consultar los activos asignados al colaborador');
    }
  }
}