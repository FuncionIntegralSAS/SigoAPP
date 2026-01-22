import 'package:flutter/foundation.dart';

import '../models/transfer_request.dart';
import '../services/mock_inventory_service.dart';

class TransferRequestProvider extends ChangeNotifier {
  final MockInventoryService _inventoryService;

  TransferRequestProvider(this._inventoryService);

  // ============================
  // FUENTE ÚNICA DE DATOS
  // ============================
  List<TransferRequest> get requests =>
      _inventoryService.transferRequests;

  // ============================
  // CREAR SOLICITUD DE TRASPASO
  // ============================
  void createRequest({
    required String articleId,
    required String articleName,
    required String currentResponsible,
    required String proposedResponsible,
    required String currentWarehouse,
    required String proposedWarehouse,
    required String requestReason,
  }) {
    try {
      // Regla de negocio: no permitir mismo responsable y bodega
      final sameResponsible =
          currentResponsible.trim() == proposedResponsible.trim();
      final sameWarehouse =
          currentWarehouse.trim() == proposedWarehouse.trim();

      if (sameResponsible && sameWarehouse) {
        throw Exception(
          'No se permite que el responsable y la bodega destino sean iguales al origen.',
        );
      }

      final request = TransferRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        articleId: articleId,
        articleName: articleName,
        currentResponsible: currentResponsible,
        proposedResponsible: proposedResponsible,
        currentWarehouse: currentWarehouse,
        proposedWarehouse: proposedWarehouse,
        requestReason: requestReason,
        requestDate: DateTime.now(),
        status: TransferStatus.pending,
      );

      _inventoryService.createTransferRequest(request);

      debugPrint('TransferRequest creada: ${request.id}');
      notifyListeners(); // clave para refrescar UI
    } catch (e) {
      debugPrint('Error al crear solicitud de traspaso: $e');
      rethrow; // permite que el widget capture el error
    }
  }

  // ============================
  // CONSULTAS ÚTILES
  // ============================
  List<TransferRequest> getPendingRequests() =>
      _inventoryService.getPendingTransferRequests();

  List<TransferRequest> getApprovedRequests() =>
      requests.where((r) => r.status == TransferStatus.approved).toList();

  List<TransferRequest> getRejectedRequests() =>
      requests.where((r) => r.status == TransferStatus.rejected).toList();

  List<TransferRequest> getCompletedRequests() =>
      requests.where((r) => r.status == TransferStatus.completed).toList();
}
