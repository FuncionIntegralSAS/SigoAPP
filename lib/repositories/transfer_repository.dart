import '../models/transfer_request.dart';
import '../models/transfer_delivery_request.dart';

/// Contrato único de acceso a datos para el módulo de Traspasos.
///
/// Define las operaciones asíncronas que tanto la implementación mock
/// ([MockTransferRepository]) como la implementación HTTP real
/// ([HttpTransferRepository]) deben cumplir.
///
/// El uso de [Future] permite que el contrato sea agnóstico a la fuente
/// de datos: datos locales simulados o peticiones reales al backend.
abstract class TransferRepository {
  /// Crea una nueva solicitud de traspaso.
  Future<void> create(TransferRequest request);

  /// Obtiene todas las solicitudes de traspaso.
  Future<List<TransferRequest>> getAllTransfers();

  /// Aprueba una solicitud de traspaso identificada por [requestId].
  Future<void> approveTransfer(String requestId);

  /// Rechaza una solicitud de traspaso con una [motivoRechazo] obligatoria.
  Future<void> rejectTransfer({
    required String requestId,
    required String motivoRechazo,
  });

  /// Aplica un traspaso previamente aprobado.
  Future<void> applyTransfer(TransferRequest request);

  /// Aplica el paso intermedio de entrega y recepción con firmas.
  Future<void> applyTransferDelivery(TransferDeliveryRequest request);
}
