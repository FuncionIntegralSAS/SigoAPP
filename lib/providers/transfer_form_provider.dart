import 'package:flutter/material.dart';
import '../models/warehouse_model.dart';
import '../repositories/catalog_repository.dart'; 

class TransferFormProvider extends ChangeNotifier {
  final CatalogRepository catalogRepository;
  TransferFormProvider(this.catalogRepository);

  // --- ESTADO DEL EMPLEADO ---
  bool _isSearchingEmployee = false;
  String? _employeeName;
  String? _divisionId;
  String? _employeeError;

  // --- ESTADO DE BODEGAS ---
  bool _isLoadingWarehouses = false;
  List<WarehouseModel> _warehouses = [];
  String? _selectedWarehouseId;
  String? _warehouseError;

  // Getters para la UI
  bool get isSearchingEmployee => _isSearchingEmployee;
  String? get employeeName => _employeeName;
  String? get employeeError => _employeeError;
  bool get isLoadingWarehouses => _isLoadingWarehouses;
  List<WarehouseModel> get warehouses => _warehouses;
  String? get selectedWarehouseId => _selectedWarehouseId;
  String? get warehouseError => _warehouseError;

  Future<void> searchEmployee(String query) async {
    if (query.isEmpty) return;

    _isSearchingEmployee = true;
    _employeeError = null;
    _employeeName = null;
    _divisionId = null;
    
    _warehouses = [];
    _selectedWarehouseId = null;
    notifyListeners();

    try {
      final employee = await catalogRepository.findEmployee(query);
      _employeeName = employee.name;
      _divisionId = employee.divisionId;

      notifyListeners();

      // Si encontramos al empleado y tenemos su división, disparamos el Paso 2 automáticamente
      if (_divisionId != null) {
        await _fetchWarehousesForDivision(_divisionId!);
      }
    } catch (e) {
      _employeeError = e.toString().replaceAll('Exception: ', '');
      _isSearchingEmployee = false;
      notifyListeners();
    }
  }

  Future<void> _fetchWarehousesForDivision(String divisionId) async {
    _isLoadingWarehouses = true;
    _warehouseError = null;
    notifyListeners();

    try {
      _warehouses = await catalogRepository.getWarehousesByDivision(divisionId);
    } catch (e) {
      _warehouseError = 'Error al cargar bodegas: $e';
    } finally {
      _isSearchingEmployee = false; 
      _isLoadingWarehouses = false;
      notifyListeners();
    }
  }

  void selectWarehouse(String? warehouseId) {
    _selectedWarehouseId = warehouseId;
    notifyListeners();
  }
}