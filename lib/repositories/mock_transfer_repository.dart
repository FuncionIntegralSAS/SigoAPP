import '../models/transfer_request.dart';
import '../repositories/transfer_repository.dart';
import '../services/mock_inventory_service.dart';

class MockTransferRepository implements TransferRepository {
  final MockInventoryService inventoryService;

  MockTransferRepository(this.inventoryService);

  // ============================
  // CREAR SOLICITUD
  // ============================

  @override
  void create(TransferRequest request) {
    inventoryService.createTransferRequest(request);
  }

  // ============================
  // OBTENER TODAS
  // ============================

  @override
  List<TransferRequest> getAllTransfers() {
    return inventoryService.transferRequests;
  }

  // ============================
  // APROBAR
  // ============================

  @override
  void approveTransfer(String requestId) {
    inventoryService.approveTransferRequest(requestId);
  }

  // ============================
  // RECHAZAR
  // ============================

  @override
  void rejectTransfer({
    required String requestId,
    required String rejectionReason,
  }) {
    inventoryService.rejectTransferRequest(
      requestId: requestId,
      rejectionReason: rejectionReason,
    );
  }

  // ============================
  // APLICAR TRASPASO
  // ============================

  @override
  void applyTransfer(TransferRequest request) {
    inventoryService.applyApprovedTransfer(request);
  }
}
