import 'package:flutter/material.dart';

import '../models/transfer_request.dart';
import '../models/transfer_filter.dart';
import '../repositories/transfer_repository.dart';

class TransferApprovalProvider extends ChangeNotifier {
  final TransferRepository repository;

  TransferApprovalProvider(this.repository);

  // ============================
  // FILTROS
  // ============================

  TransferFilter _filter = const TransferFilter();

  TransferFilter get filter => _filter;

  void updateFilter(TransferFilter newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  // ============================
  // FUENTE DE DATOS
  // ============================

  List<TransferRequest> get allTransfers =>
      repository.getAllTransfers();

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

    return true;
  }

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
  // APROBAR SOLICITUD
  // ============================

  void approveTransfer(String requestId) {
    repository.approveTransfer(requestId);
    notifyListeners();
  }

  // ============================
  // RECHAZAR SOLICITUD
  // ============================

  void rejectTransfer(String requestId, String reason) {
    repository.rejectTransfer(
      requestId: requestId,
      rejectionReason: reason,
    );
    notifyListeners();
  }

  // ============================
  // APLICAR TRASPASO
  // ============================

  void applyTransfer(TransferRequest request) {
    repository.applyTransfer(request);
    notifyListeners();
  }

  // ============================
  // UTILIDAD
  // ============================

  void refresh() {
    notifyListeners();
  }
}
