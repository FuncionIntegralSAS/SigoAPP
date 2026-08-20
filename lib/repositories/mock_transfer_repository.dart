import '../models/transfer_request.dart';
import '../models/transfer_delivery_request.dart';
import '../repositories/transfer_repository.dart';
import '../services/mock_inventory_service.dart';

/// Implementación mock del [TransferRepository].
///
/// Utiliza [MockInventoryService] como fuente de datos en memoria
/// para desarrollo y pruebas offline. Las operaciones son síncronas
/// internamente pero se envuelven en [Future] para cumplir el contrato.
class MockTransferRepository implements TransferRepository {
  final MockInventoryService inventoryService;

  MockTransferRepository(this.inventoryService);

  // ============================
  // CREAR SOLICITUD
  // ============================

  @override
  Future<void> create(TransferRequest request) async {
    inventoryService.createTransferRequest(request);
  }

  // ============================
  // OBTENER TODAS
  // ============================

  @override
  Future<List<TransferRequest>> getAllTransfers() async {
    return inventoryService.transferRequests;
  }

  // ============================
  // APROBAR
  // ============================

  @override
  Future<void> approveTransfer(String requestId) async {
    inventoryService.approveTransferRequest(requestId);
  }

  // ============================
  // RECHAZAR
  // ============================

  @override
  Future<void> rejectTransfer({
    required String requestId,
    required String rejectionReason,
  }) async {
    inventoryService.rejectTransferRequest(
      requestId: requestId,
      rejectionReason: rejectionReason,
    );
  }

  // ============================
  // APLICAR TRASPASO
  // ============================

  @override
  Future<void> applyTransfer(TransferRequest request) async {
    inventoryService.applyApprovedTransfer(request);
  }

  // ============================
  // APLICAR ENTREGA/RECEPCIÓN
  // ============================

  @override
  Future<void> applyTransferDelivery(TransferDeliveryRequest request) async {
    // Simula una latencia y actualiza el estado local del mock
    await Future.delayed(const Duration(seconds: 1));
    final index = inventoryService.transferRequests.indexWhere((t) => t.id == request.transferId);
    if (index != -1) {
      final transfer = inventoryService.transferRequests[index];
      
      final dispatcherBase64 = request.dispatcherSignatureBase64 ?? transfer.dispatcherSignatureBase64;
      final receiverBase64 = request.receiverSignatureBase64 ?? transfer.receiverSignatureBase64;

      // Si ambos ya firmaron, pasamos el estado a completado
      final bool bothSigned = dispatcherBase64 != null && receiverBase64 != null;

      inventoryService.transferRequests[index] = transfer.copyWith(
        dispatcherSignatureBase64: dispatcherBase64,
        receiverSignatureBase64: receiverBase64,
        status: bothSigned ? TransferStatus.completed : transfer.status,
      );
    }
  }
}
