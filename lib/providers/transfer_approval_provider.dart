import 'package:flutter/material.dart';

import '../models/transfer_request.dart';
import '../models/transfer_filter.dart';
import '../repositories/transfer_repository.dart';

class TransferApprovalProvider extends ChangeNotifier {
  final TransferRepository repository;

  TransferApprovalProvider(this.repository) {
    loadTransfers();
  }

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

  List<TransferRequest> _transfers = [];
  List<TransferRequest> get allTransfers => _transfers;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  /// Carga las solicitudes de traspaso desde el repositorio.
  Future<void> loadTransfers() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _transfers = await repository.getAllTransfers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ============================
  // LISTA FILTRADA PARA LA UI
  // ============================

  List<TransferRequest> get filteredTransfers {
    return allTransfers.where(_applyFilter).toList();
  }

  bool _applyFilter(TransferRequest request) {
    if (request.status != _filter.status) {
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

  Future<void> approveTransfer(String requestId) async {
    try {
      await repository.approveTransfer(requestId);
      await loadTransfers(); // Recarga la lista tras la acción
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ============================
  // RECHAZAR SOLICITUD
  // ============================

  Future<void> rejectTransfer(String requestId, String reason) async {
    try {
      await repository.rejectTransfer(
        requestId: requestId,
        rejectionReason: reason,
      );
      await loadTransfers(); // Recarga la lista tras la acción
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ============================
  // APLICAR TRASPASO
  // ============================

  Future<void> applyTransfer(TransferRequest request) async {
    try {
      await repository.applyTransfer(request);
      await loadTransfers(); // Recarga la lista tras la acción
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ============================
  // UTILIDAD
  // ============================

  void refresh() {
    loadTransfers();
  }
}
