import 'package:flutter/material.dart';
import '../models/requisition_model.dart';
import '../repositories/requisition_repository.dart';

class RequisitionApprovalProvider extends ChangeNotifier {
  final RequisitionRepository _repository;

  RequisitionApprovalProvider(this._repository);

  List<RequisitionModel> _pendingRequisitions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RequisitionModel> get pendingRequisitions => _pendingRequisitions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Añadir el parámetro 'status'
  Future<void> loadRequisitions(String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Inyectar el parámetro dinámico en la consulta
      _pendingRequisitions = await _repository.getRequisitionsByStatus(status);
    } catch (e) {
      _errorMessage = 'Error al cargar requisiciones: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}   