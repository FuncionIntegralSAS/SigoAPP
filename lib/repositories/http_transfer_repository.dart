import 'package:dio/dio.dart';
import '../exceptions/transfer_business_exception.dart';
import '../models/transfer_request.dart';
import '../models/transfer_delivery_request.dart';
import '../repositories/transfer_repository.dart';

/// Implementación HTTP real del [TransferRepository].
///
/// Conecta con los endpoints del backend Spring Boot utilizando [Dio].
/// Lanza [TransferBusinessException] cuando ocurren errores de red o
/// respuestas no exitosas del servidor.
class HttpTransferRepository implements TransferRepository {
  final Dio dio;

  HttpTransferRepository(this.dio);

  // --- 1. CREAR
  @override
  Future<void> create(TransferRequest request) async {
    try {
      await dio.post(
        '/api/v1/traspasos',
        data: request.toJson(),
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
      );
    } on DioException catch (e) {
      throw TransferBusinessException(
        'Error al crear traspaso: ${e.response?.statusCode ?? e.message}',
      );
    }
  }

  // --- 2. OBTENER TODOS ---
  @override
  Future<List<TransferRequest>> getAllTransfers() async {
    try {
      final response = await dio.get(
        '/api/v1/traspasos',
        options: Options(headers: {'Accept': 'application/json'}),
      );

      final List<dynamic> dataList = response.data['data'] ?? [];
      return dataList.map((json) => TransferRequest.fromJson(json)).toList();
    } on DioException catch (e) {
      throw TransferBusinessException(
        'Error al obtener traspasos: ${e.response?.statusCode ?? e.message}',
      );
    }
  }

  // --- 3. APROBAR (Mapeado a PUT /procesar con 'ap') ---
  @override
  Future<void> approveTransfer(String transferId) async {
    try {
      await dio.put(
        '/api/v1/traspasos/$transferId/procesar',
        data: {
          'decision': 'ap', // Decisión 'ap' según backend
          'observacion': 'Aprobado vía App'
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } on DioException catch (e) {
      throw TransferBusinessException(
        'Error al aprobar traspaso: ${e.response?.statusCode ?? e.message}',
      );
    }
  }

  // --- 4. RECHAZAR (Mapeado a PUT /procesar con 'na') ---
  @override
  Future<void> rejectTransfer({required String requestId, required String motivoRechazo}) async {
    try {
      final response = await dio.put(
        '/api/v1/traspasos/$requestId/procesar',
        data: {
          'decision': 'na', // Decisión 'na' según backend
          'observacion': motivoRechazo // La observación es obligatoria en el rechazo
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode != 200) {
        throw TransferBusinessException(
          'Error del servidor al rechazar: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw TransferBusinessException(
        'Error de red al rechazar: ${e.response?.statusCode ?? e.message}',
      );
    }
  }

  // --- 5. APLICAR (El método redundante) ---
  @override
  Future<void> applyTransfer(TransferRequest request) async {
    // Como el backend actualiza ACTIFIJO automáticamente al aprobar ('ap'),
    // este método ya no necesita hacer una petición HTTP independiente.
    // Solo retornamos un Future exitoso para no romper el contrato/UI actual.
    // En el futuro, podríamos eliminar este método del abstract class.
    return Future.value(); 
  }

  // --- 6. APLICAR ENTREGA/RECEPCIÓN ---
  @override
  Future<void> applyTransferDelivery(TransferDeliveryRequest request) async {
    try {
      final response = await dio.post(
        '/api/v1/traspasos/${request.transferId}/entregar',
        data: request.toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw TransferBusinessException(
          'Error del servidor al registrar entrega: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw TransferBusinessException(
        'Error de red al registrar entrega: ${e.response?.statusCode ?? e.message}',
      );
    }
  }
}