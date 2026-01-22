import 'package:flutter/material.dart';

import '../models/transfer_filter.dart';
import '../models/transfer_request.dart';
import '../services/mock_inventory_service.dart';

class TransferApprovalProvider extends ChangeNotifier {
  final MockInventoryService inventoryService;

  TransferApprovalProvider(this.inventoryService);

  TransferFilter _filter = const TransferFilter();

  TransferFilter get filter => _filter;

  // ============================
  // FUENTE DE DATOS
  // ============================
  List<TransferRequest> get allTransfers =>
      inventoryService.transferRequests;

  // ============================
  // BODEGAS DISPONIBLES
  // ============================
  List<String> get availableWarehouses {
    return allTransfers
        .map((r) => r.proposedWarehouse)
        .toSet()
        .toList()
      ..sort();
  }

  // ============================
  // LISTA FILTRADA PARA LA UI
  // ============================
  List<TransferRequest> get filteredTransfers {
    return allTransfers.where(_applyFilter).toList();
  }

  bool _applyFilter(TransferRequest request) {
    if (_filter.status != null && request.status != _filter.status) {
      return false;
    }

    if (_filter.proposedWarehouse != null &&
        request.proposedWarehouse != _filter.proposedWarehouse) {
      return false;
    }

    if (_filter.responsibleQuery != null &&
        !request.proposedResponsible
            .toLowerCase()
            .contains(_filter.responsibleQuery!.toLowerCase())) {
      return false;
    }

    if (_filter.fromDate != null &&
        request.requestDate.isBefore(_filter.fromDate!)) {
      return false;
    }

    if (_filter.toDate != null &&
        request.requestDate.isAfter(_filter.toDate!)) {
      return false;
    }

    return true;
  }

  // ============================
  // ACTUALIZAR FILTROS
  // ============================
  void updateFilter(TransferFilter newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  // ============================
  // APROBAR SOLICITUD
  // ============================
  void approveTransfer(String requestId) {
    try {
      inventoryService.approveTransferRequest(requestId);

      debugPrint('Transfer aprobada: $requestId');
      notifyListeners();
    } catch (e) {
      debugPrint('Error al aprobar traspaso: $e');
      rethrow;
    }
  }

  // ============================
  // RECHAZAR SOLICITUD
  // ============================
  void rejectTransfer(String requestId, String reason) {
    try {
      inventoryService.rejectTransferRequest(
        requestId: requestId,
        rejectionReason: reason,
      );

      debugPrint('Transfer rechazada: $requestId');
      notifyListeners();
    } catch (e) {
      debugPrint('Error al rechazar traspaso: $e');
      rethrow;
    }
  }

  // ============================
  // APLICAR TRASPASO APROBADO
  // ============================
  void applyTransfer(TransferRequest request) {
    try {
      inventoryService.applyApprovedTransfer(request);

      debugPrint('Transfer aplicada: ${request.id}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error al aplicar traspaso: $e');
      rethrow;
    }
  }

  // ============================
  // UTILIDAD
  // ============================
  void refresh() {
    notifyListeners();
  }
}
