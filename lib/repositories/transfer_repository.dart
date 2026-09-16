import '../models/transfer_request.dart';
import '../models/transfer_delivery_request.dart';
import '../models/transfer_create_request.dart';
import '../models/transfer_person_model.dart';
import '../models/transfer_asset_model.dart';

/// Contrato único de acceso a datos para el módulo de Traspasos.
///
/// Define las operaciones asíncronas que tanto la implementación mock
/// ([MockTransferRepository]) como la implementación HTTP real
/// ([HttpTransferRepository]) deben cumplir.
abstract class TransferRepository {
  /// Obtiene los colaboradores asociados a una [bodega] en una [empresa].
  Future<List<TransferPersonModel>> getPersonsByWarehouse({
    required String bodega,
    required String empresa,
  });

  /// Obtiene los activos fijos asignados a un colaborador identificado por [persona].
  Future<List<TransferAssetModel>> getAssetsByPerson({
    required String persona,
    String? empresa,
  });

  /// Crea una nueva solicitud de traspaso (soporta multi-artículo).
  /// Acepta tanto [TransferCreateRequest] como [TransferRequest].
  Future<void> create(dynamic request);

  /// Obtiene las solicitudes de traspaso, con filtros opcionales de estado, empresa o bodega.
  /// Si [fetchDetails] es true (por defecto), enriquece las cabeceras ligeras consultando
  /// concurrentemente su detalle para obtener los artículos y responsables.
  Future<List<TransferRequest>> getAllTransfers({
    String? estado,
    String? empresa,
    String? bodega,
    bool fetchDetails = true,
  });

  /// Obtiene el detalle completo de un traspaso por su identificador (número de trámite).
  Future<TransferRequest?> getTransferById(String id);

  /// Aprueba una solicitud de traspaso identificada por su número de trámite [requestId].
  Future<void> approveTransfer(String requestId, {String? observacion});

  /// Rechaza una solicitud de traspaso con una [motivoRechazo] obligatoria.
  Future<void> rejectTransfer({
    required String requestId,
    required String motivoRechazo,
  });

  /// Registra la firma individual ('FU' para fuente o 'DE' para destino).
  /// No requiere orden específico de precedencia.
  Future<void> signTransfer({
    required String transferId,
    required String tipoFirma,
    required String firmaBase64,
  });

  /// Concreta la recepción final del traspaso en el backend y asienta los
  /// movimientos de inventario en el ERP una vez firmadas ambas partes.
  Future<void> receiveTransfer(String transferId);

  /// Aplica un traspaso previamente aprobado (mantenido por compatibilidad).
  Future<void> applyTransfer(TransferRequest request);

  /// Aplica el flujo de entrega y recepción con firmas.
  Future<void> applyTransferDelivery(TransferDeliveryRequest request);
}
