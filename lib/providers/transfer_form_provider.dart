import 'package:flutter/material.dart';
import '../exceptions/catalog_business_exception.dart';
import '../exceptions/transfer_business_exception.dart';
import '../models/employee_result.dart';
import '../models/warehouse_model.dart';
import '../models/transfer_person_model.dart';
import '../models/transfer_asset_model.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/transfer_repository.dart';

/// Provider que orquesta el flujo dinámico de creación de traspasos en cascada:
/// Empresa -> Bodega Origen -> Colaboradores Fuente -> Activos Asignados
/// (con reglas de trámite y compatibilidad multi-artículo) ->
/// Bodega Destino -> Colaborador Destino -> Creación.
class TransferFormProvider extends ChangeNotifier {
  final TransferRepository transferRepository;
  final CatalogRepository? catalogRepository;

  TransferFormProvider(
    this.transferRepository, {
    this.catalogRepository,
  });

  // ==========================================
  // 1. EMPRESA Y BODEGA ORIGEN
  // ==========================================
  String? _selectedEmpresa = '01';
  String? get selectedEmpresa => _selectedEmpresa;

  String? _selectedOriginBodega;
  String? get selectedOriginBodega => _selectedOriginBodega;

  bool _isLoadingOriginPersons = false;
  bool get isLoadingOriginPersons => _isLoadingOriginPersons;

  List<TransferPersonModel> _originPersons = [];
  List<TransferPersonModel> get originPersons => _originPersons;

  String? _originPersonsError;
  String? get originPersonsError => _originPersonsError;

  TransferPersonModel? _selectedOriginPerson;
  TransferPersonModel? get selectedOriginPerson => _selectedOriginPerson;

  void setEmpresa(String? empresa) {
    if (_selectedEmpresa == empresa) return;
    _selectedEmpresa = empresa;
    _selectedOriginBodega = null;
    _originPersons = [];
    _selectedOriginPerson = null;
    _personAssets = [];
    _selectedAssets.clear();
    _selectedDestinationBodega = null;
    _destinationPersons = [];
    _selectedDestinationPerson = null;
    _destinationPersonValidationError = null;
    notifyListeners();
  }

  Future<void> selectOriginBodega(String? bodega, {String? empresa}) async {
    _selectedOriginBodega = bodega;
    _selectedOriginPerson = null;
    _personAssets = [];
    _selectedAssets.clear();
    _originPersons = [];
    _originPersonsError = null;
    notifyListeners();

    if (bodega != null && bodega.trim().isNotEmpty) {
      final activeEmpresa = empresa ?? _selectedEmpresa ?? '01';
      await loadOriginPersons(bodega.trim(), empresa: activeEmpresa);
    }
  }

  Future<void> loadOriginPersons(String bodega, {String? empresa}) async {
    _isLoadingOriginPersons = true;
    _originPersonsError = null;
    notifyListeners();

    final activeEmpresa = empresa ?? _selectedEmpresa ?? '01';
    try {
      _originPersons = await transferRepository.getPersonsByWarehouse(
        bodega: bodega,
        empresa: activeEmpresa,
      );
    } on TransferBusinessException catch (e) {
      _originPersonsError = e.message;
    } catch (e) {
      _originPersonsError = 'Error al consultar colaboradores de la bodega origen.';
    } finally {
      _isLoadingOriginPersons = false;
      notifyListeners();
    }
  }

  Future<void> selectOriginPerson(TransferPersonModel? person, {String? empresa}) async {
    _selectedOriginPerson = person;
    _personAssets = [];
    _selectedAssets.clear();
    _assetsError = null;

    // Validación si la persona destino actual coincide con la nueva persona origen
    if (_selectedDestinationPerson != null &&
        person != null &&
        _selectedDestinationPerson!.cedula == person.cedula) {
      _selectedDestinationPerson = null;
      _destinationPersonValidationError =
          'El responsable destino no puede ser igual al responsable origen.';
    } else {
      _destinationPersonValidationError = null;
    }
    notifyListeners();

    if (person != null && person.cedula.isNotEmpty) {
      final activeEmpresa = empresa ?? _selectedEmpresa ?? '01';
      await loadAssetsForPerson(person.cedula, empresa: activeEmpresa);
    }
  }

  // ==========================================
  // 2. ACTIVOS Y REGLAS DE COMPATIBILIDAD PL/SQL
  // ==========================================
  bool _isLoadingAssets = false;
  bool get isLoadingAssets => _isLoadingAssets;

  List<TransferAssetModel> _personAssets = [];
  List<TransferAssetModel> get personAssets => _personAssets;

  String? _assetsError;
  String? get assetsError => _assetsError;

  final List<TransferAssetModel> _selectedAssets = [];
  List<TransferAssetModel> get selectedAssets => List.unmodifiable(_selectedAssets);

  Future<void> loadAssetsForPerson(String cedula, {String? empresa}) async {
    _isLoadingAssets = true;
    _assetsError = null;
    _personAssets = [];
    _selectedAssets.clear();
    notifyListeners();

    final activeEmpresa = empresa ?? _selectedEmpresa ?? '01';
    try {
      _personAssets = await transferRepository.getAssetsByPerson(
        persona: cedula,
        empresa: activeEmpresa,
      );
    } on TransferBusinessException catch (e) {
      _assetsError = e.message;
    } catch (e) {
      _assetsError = 'Error al consultar activos asignados al colaborador.';
    } finally {
      _isLoadingAssets = false;
      notifyListeners();
    }
  }

  bool _isSameAsset(TransferAssetModel a, TransferAssetModel b) {
    if (a.articulo.trim().toLowerCase() != b.articulo.trim().toLowerCase()) {
      return false;
    }
    final placaA = a.placa?.trim().toLowerCase();
    final placaB = b.placa?.trim().toLowerCase();
    final hasA = placaA != null && placaA.isNotEmpty && placaA != 'n/a';
    final hasB = placaB != null && placaB.isNotEmpty && placaB != 'n/a';

    if (hasA || hasB) {
      return placaA == placaB;
    }
    return true;
  }

  bool isAssetSelected(TransferAssetModel asset) {
    return _selectedAssets.any((a) => _isSameAsset(a, asset));
  }

  /// Verifica si un activo es compatible con los activos ya seleccionados.
  /// Regla de negocio PL/SQL: Todos los activos de un mismo trámite deben compartir
  /// el mismo [centroInformacion] y [tercero].
  /// Si alguno de los activos no posee CI o Tercero (ej. precargado desde inventario),
  /// no se bloquea la compatibilidad en el cliente para no generar falsos rechazos.
  bool isAssetCompatible(TransferAssetModel asset) {
    if (_selectedAssets.isEmpty) return true;
    final first = _selectedAssets.first;

    final ci1 = asset.centroInformacion?.trim();
    final ci2 = first.centroInformacion?.trim();
    if (ci1 != null && ci1.isNotEmpty && ci2 != null && ci2.isNotEmpty && ci1 != ci2) {
      return false;
    }

    final t1 = asset.tercero?.trim();
    final t2 = first.tercero?.trim();
    if (t1 != null && t1.isNotEmpty && t2 != null && t2.isNotEmpty && t1 != t2) {
      return false;
    }

    return true;
  }

  /// Determina si un activo es seleccionable por el usuario.
  bool isAssetSelectable(TransferAssetModel asset) {
    if (asset.enTramite) return false;
    return isAssetCompatible(asset);
  }

  /// Retorna la razón de inhabilitación de un activo para feedback visual.
  String? getAssetIncompatibilityReason(TransferAssetModel asset) {
    if (asset.enTramite) {
      return 'En trámite pendiente';
    }
    if (!isAssetCompatible(asset)) {
      final first = _selectedAssets.first;
      return 'Incompatible: difiere en CI (${asset.centroInformacion ?? "N/A"} vs ${first.centroInformacion ?? "N/A"}) o Tercero (${asset.tercero ?? "N/A"} vs ${first.tercero ?? "N/A"}) con los ya seleccionados.';
    }
    return null;
  }

  /// Alterna la selección de un activo respetando enTramite y compatibilidad.
  bool toggleAssetSelection(TransferAssetModel asset) {
    if (isAssetSelected(asset)) {
      _selectedAssets.removeWhere((a) => _isSameAsset(a, asset));
      notifyListeners();
      return true;
    }

    // Bloqueo por trámite activo
    if (asset.enTramite) {
      return false;
    }

    // Bloqueo por incompatibilidad PL/SQL
    if (!isAssetCompatible(asset)) {
      return false;
    }

    _selectedAssets.add(asset);
    notifyListeners();
    return true;
  }

  void clearAssetSelection() {
    _selectedAssets.clear();
    notifyListeners();
  }

  /// Agrega un activo pre-seleccionado asegurando que forme parte
  /// de los activos seleccionados para la solicitud de traspaso.
  void addPreselectedAsset(TransferAssetModel asset) {
    if (!_selectedAssets.any((a) => _isSameAsset(a, asset))) {
      _selectedAssets.add(asset);
    }
    if (!_personAssets.any((a) => _isSameAsset(a, asset))) {
      _personAssets.add(asset);
    }
    notifyListeners();
  }

  // ==========================================
  // 3. BODEGA Y COLABORADOR DESTINO
  // ==========================================
  String? _selectedDestinationBodega;
  String? get selectedDestinationBodega => _selectedDestinationBodega;

  bool _isLoadingDestinationPersons = false;
  bool get isLoadingDestinationPersons => _isLoadingDestinationPersons;

  List<TransferPersonModel> _destinationPersons = [];
  List<TransferPersonModel> get destinationPersons => _destinationPersons;

  String? _destinationPersonsError;
  String? get destinationPersonsError => _destinationPersonsError;

  TransferPersonModel? _selectedDestinationPerson;
  TransferPersonModel? get selectedDestinationPerson => _selectedDestinationPerson;

  String? _destinationPersonValidationError;
  String? get destinationPersonValidationError => _destinationPersonValidationError;

  Future<void> selectDestinationBodega(String? bodega, {String? empresa}) async {
    _selectedDestinationBodega = bodega;
    _selectedDestinationPerson = null;
    _destinationPersons = [];
    _destinationPersonsError = null;
    _destinationPersonValidationError = null;
    notifyListeners();

    if (bodega != null && bodega.trim().isNotEmpty) {
      final activeEmpresa = empresa ?? _selectedEmpresa ?? '01';
      await loadDestinationPersons(bodega.trim(), empresa: activeEmpresa);
    }
  }

  Future<void> loadDestinationPersons(String bodega, {String? empresa}) async {
    _isLoadingDestinationPersons = true;
    _destinationPersonsError = null;
    notifyListeners();

    final activeEmpresa = empresa ?? _selectedEmpresa ?? '01';
    try {
      _destinationPersons = await transferRepository.getPersonsByWarehouse(
        bodega: bodega,
        empresa: activeEmpresa,
      );
    } on TransferBusinessException catch (e) {
      _destinationPersonsError = e.message;
    } catch (e) {
      _destinationPersonsError = 'Error al consultar colaboradores de la bodega destino.';
    } finally {
      _isLoadingDestinationPersons = false;
      notifyListeners();
    }
  }

  bool selectDestinationPerson(TransferPersonModel? person) {
    if (person != null &&
        _selectedOriginPerson != null &&
        person.cedula == _selectedOriginPerson!.cedula) {
      _selectedDestinationPerson = null;
      _destinationPersonValidationError =
          'El responsable destino no puede ser igual al responsable origen.';
      notifyListeners();
      return false;
    }

    _selectedDestinationPerson = person;
    _destinationPersonValidationError = null;
    notifyListeners();
    return true;
  }

  // ==========================================
  // 4. OBSERVACIÓN Y VALIDACIÓN GENERAL
  // ==========================================
  String _observacion = '';
  String get observacion => _observacion;

  void setObservacion(String obs) {
    _observacion = obs;
    notifyListeners();
  }

  bool get isFormValid {
    return _selectedOriginPerson != null &&
        _selectedDestinationPerson != null &&
        _selectedAssets.isNotEmpty &&
        _selectedOriginPerson!.cedula != _selectedDestinationPerson!.cedula;
  }

  // ==========================================
  // 5. MÉTODOS DE COMPATIBILIDAD (LEGACY CATALOG)
  // ==========================================
  String _searchCriterion = 'todos';
  String get searchCriterion => _searchCriterion;

  bool _isSearchingEmployee = false;
  String? _employeeName;
  String? _divisionId;
  int? _personaId;
  String? _employeeError;
  String? _employeeTechnicalDetails;
  int? _employeeStatusCode;
  EmployeeResult? _selectedEmployee;
  List<EmployeeResult> _candidateEmployees = [];

  bool _isLoadingWarehouses = false;
  List<WarehouseModel> _warehouses = [];
  String? _selectedWarehouseId;
  String? _warehouseError;
  String? _warehouseTechnicalDetails;
  int? _warehouseStatusCode;

  bool get isSearchingEmployee => _isSearchingEmployee;
  String? get employeeName => _employeeName;
  int? get personaId => _personaId;
  String? get employeeError => _employeeError;
  String? get employeeTechnicalDetails => _employeeTechnicalDetails;
  int? get employeeStatusCode => _employeeStatusCode;
  String? get divisionId => _divisionId;
  EmployeeResult? get selectedEmployee => _selectedEmployee;
  List<EmployeeResult> get candidateEmployees => _candidateEmployees;

  bool get isLoadingWarehouses => _isLoadingWarehouses;
  List<WarehouseModel> get warehouses => _warehouses;
  String? get selectedWarehouseId => _selectedWarehouseId;
  String? get warehouseError => _warehouseError;
  String? get warehouseTechnicalDetails => _warehouseTechnicalDetails;
  int? get warehouseStatusCode => _warehouseStatusCode;

  void setSearchCriterion(String criterion) {
    _searchCriterion = criterion;
    notifyListeners();
  }

  Future<void> searchEmployee(String query, {String? criterion}) async {
    if (catalogRepository == null) return;
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    final activeCriterion = criterion ?? _searchCriterion;
    _isSearchingEmployee = true;
    _employeeError = null;
    _employeeTechnicalDetails = null;
    _employeeStatusCode = null;
    _employeeName = null;
    _divisionId = null;
    _personaId = null;
    _selectedEmployee = null;
    _candidateEmployees = [];
    _warehouses = [];
    _selectedWarehouseId = null;
    _warehouseError = null;
    _warehouseTechnicalDetails = null;
    _warehouseStatusCode = null;
    notifyListeners();

    try {
      List<EmployeeResult> results = [];

      switch (activeCriterion) {
        case 'cedula':
          results = await catalogRepository!.searchEmployees(cedula: cleanQuery);
          break;
        case 'nombre':
          results = await catalogRepository!.searchEmployees(nombre: cleanQuery);
          break;
        case 'apellido':
          results = await catalogRepository!.searchEmployees(apellido: cleanQuery);
          break;
        case 'todos':
        default:
          final isNumeric = RegExp(r'^\d+$').hasMatch(cleanQuery);
          if (isNumeric) {
            results = await catalogRepository!.searchEmployees(cedula: cleanQuery);
          } else {
            final parts = cleanQuery.split(RegExp(r'\s+'));
            if (parts.length >= 2) {
              results = await catalogRepository!.searchEmployees(
                nombre: parts.first,
                apellido: parts.sublist(1).join(' '),
              );
            }
            if (results.isEmpty) {
              results = await catalogRepository!.searchEmployees(nombre: cleanQuery);
            }
            if (results.isEmpty) {
              results = await catalogRepository!.searchEmployees(apellido: cleanQuery);
            }
            if (results.isEmpty) {
              results = await catalogRepository!.searchEmployees(cedula: cleanQuery);
            }
          }
          break;
      }

      if (results.isEmpty) {
        _employeeError = 'Empleado no encontrado para el código: $query';
        _isSearchingEmployee = false;
        notifyListeners();
        return;
      }

      if (results.length == 1) {
        await selectEmployee(results.first);
      } else {
        _candidateEmployees = results;
        _isSearchingEmployee = false;
        notifyListeners();
      }
    } on CatalogBusinessException catch (e) {
      _employeeError = e.userMessage;
      _employeeTechnicalDetails = e.technicalDetails;
      _employeeStatusCode = e.statusCode;
      _isSearchingEmployee = false;
      notifyListeners();
    } catch (e) {
      _employeeError = e.toString().replaceAll('Exception: ', '');
      _employeeTechnicalDetails = e.toString();
      _isSearchingEmployee = false;
      notifyListeners();
    }
  }

  Future<void> selectEmployee(EmployeeResult employee) async {
    if (catalogRepository == null) return;
    _selectedEmployee = employee;
    _employeeName = employee.nombre;
    _divisionId = employee.divisionId;
    _personaId = employee.personaId ?? int.tryParse(employee.cedula ?? '');
    _candidateEmployees = [];
    _employeeError = null;
    _employeeTechnicalDetails = null;
    _employeeStatusCode = null;
    notifyListeners();

    if (_divisionId != null && _divisionId!.isNotEmpty) {
      await _fetchWarehousesForDivision(_divisionId!);
    } else {
      _isSearchingEmployee = false;
      notifyListeners();
    }
  }

  void clearSelectedEmployee() {
    _selectedEmployee = null;
    _employeeName = null;
    _divisionId = null;
    _personaId = null;
    _candidateEmployees = [];
    _warehouses = [];
    _selectedWarehouseId = null;
    _employeeError = null;
    _employeeTechnicalDetails = null;
    _employeeStatusCode = null;
    _warehouseError = null;
    _warehouseTechnicalDetails = null;
    _warehouseStatusCode = null;
    notifyListeners();
  }

  void clearWarehouseError() {
    _warehouseError = null;
    _warehouseTechnicalDetails = null;
    _warehouseStatusCode = null;
    notifyListeners();
  }

  void clearEmployeeError() {
    _employeeError = null;
    _employeeTechnicalDetails = null;
    _employeeStatusCode = null;
    notifyListeners();
  }

  Future<void> retryLoadWarehouses() async {
    if (_divisionId != null && _divisionId!.isNotEmpty) {
      await _fetchWarehousesForDivision(_divisionId!);
    }
  }

  Future<void> _fetchWarehousesForDivision(String divisionId) async {
    if (catalogRepository == null) return;
    _isLoadingWarehouses = true;
    _warehouseError = null;
    _warehouseTechnicalDetails = null;
    _warehouseStatusCode = null;
    notifyListeners();

    try {
      _warehouses = await catalogRepository!.getWarehousesByDivision(divisionId);
    } on CatalogBusinessException catch (e) {
      _warehouseError = e.userMessage;
      _warehouseTechnicalDetails = e.technicalDetails;
      _warehouseStatusCode = e.statusCode;
    } catch (e) {
      _warehouseError = 'Error al consultar las bodegas de la división.';
      _warehouseTechnicalDetails = e.toString();
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

  // ==========================================
  // RESET GENERAL DEL FORMULARIO
  // ==========================================
  void resetForm() {
    _selectedEmpresa = '01';
    _selectedOriginBodega = null;
    _isLoadingOriginPersons = false;
    _originPersons = [];
    _originPersonsError = null;
    _selectedOriginPerson = null;

    _isLoadingAssets = false;
    _personAssets = [];
    _assetsError = null;
    _selectedAssets.clear();

    _selectedDestinationBodega = null;
    _isLoadingDestinationPersons = false;
    _destinationPersons = [];
    _destinationPersonsError = null;
    _selectedDestinationPerson = null;
    _destinationPersonValidationError = null;

    _observacion = '';

    // Legacy fields
    _isSearchingEmployee = false;
    _employeeName = null;
    _divisionId = null;
    _personaId = null;
    _selectedEmployee = null;
    _candidateEmployees = [];
    _employeeError = null;
    _employeeTechnicalDetails = null;
    _employeeStatusCode = null;
    _isLoadingWarehouses = false;
    _warehouses = [];
    _selectedWarehouseId = null;
    _warehouseError = null;
    _warehouseTechnicalDetails = null;
    _warehouseStatusCode = null;

    notifyListeners();
  }
}