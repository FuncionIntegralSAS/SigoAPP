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
  String? get divisionId => _divisionId;
  bool get isLoadingWarehouses => _isLoadingWarehouses;
  List<WarehouseModel> get warehouses => _warehouses;
  String? get selectedWarehouseId => _selectedWarehouseId;
  String? get warehouseError => _warehouseError;

  Future<void> searchEmployee(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    _isSearchingEmployee = true;
    _employeeError = null;
    _employeeName = null;
    _divisionId = null;
    
    _warehouses = [];
    _selectedWarehouseId = null;
    notifyListeners();

    try {
      final employee = await catalogRepository.findEmployee(cleanQuery);
      _employeeName = employee.nombre;
      _divisionId = employee.divisionId;

      notifyListeners();

      // Si encontramos al empleado y tenemos su división, cargamos sus bodegas
      if (_divisionId != null && _divisionId!.isNotEmpty) {
        await _fetchWarehousesForDivision(_divisionId!);
      } else {
        _isSearchingEmployee = false;
        notifyListeners();
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

  void selectWarehouse(String? idBodega) {
    _selectedWarehouseId = idBodega;
    notifyListeners();
  }

  void resetForm() {
    _isSearchingEmployee = false;
    _employeeName = null;
    _divisionId = null;
    _employeeError = null;
    _isLoadingWarehouses = false;
    _warehouses = [];
    _selectedWarehouseId = null;
    _warehouseError = null;
    notifyListeners();
  }
}