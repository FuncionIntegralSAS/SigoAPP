import '../models/transfer_request.dart';

abstract class TransferRepository {
  // Crear solicitud
  void create(TransferRequest request);

  // Lectura
  List<TransferRequest> getAllTransfers();

  // Acciones
  void approveTransfer(String requestId);

  void rejectTransfer({
    required String requestId,
    required String rejectionReason,
  });

  void applyTransfer(TransferRequest request);
}
