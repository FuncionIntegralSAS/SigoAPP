import 'package:flutter/material.dart';
import '../models/requisition_model.dart';
import '../repositories/requisition_repository.dart';

class RequisitionApprovalProvider extends ChangeNotifier {
  final RequisitionRepository _repository;

  RequisitionApprovalProvider(this._repository);

  List<RequisitionModel> _pendingRequisitions = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Estado para las selecciones en bloque: { ID : Cantidad }
  final Map<String, int> _selectedItems = {};

  List<RequisitionModel> get pendingRequisitions => _pendingRequisitions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedCount => _selectedItems.length; // Para la UI del botón

  Future<void> loadRequisitions(String status) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedItems.clear(); // Limpiamos selecciones previas al cambiar de tab
    notifyListeners();

    try {
      _pendingRequisitions = await _repository.getRequisitionsByStatus(status);
    } catch (e) {
      _errorMessage = 'Error al cargar requisiciones: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para agregar o quitar items de la selección actual
  void toggleSelection(String id, bool isSelected, int quantity) {
    if (isSelected) {
      _selectedItems[id] = quantity;
    } else {
      _selectedItems.remove(id);
    }
    notifyListeners();
  }

  // Método que ejecuta el envío masivo
  Future<bool> processBatchSelection(String currentTabStatus) async {
    if (_selectedItems.isEmpty) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {

      String targetStatus = currentTabStatus == 'in' ? 'ap' : 'en';

      final success = await _repository.processBatch(_selectedItems, targetStatus);
      
      if (success) {
        _selectedItems.clear();
        // Recargamos la lista actual para que desaparezcan las ya procesadas
        await loadRequisitions(currentTabStatus);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Error procesando el lote: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}