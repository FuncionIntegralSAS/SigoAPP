import '../models/transfer_request.dart';
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
}
