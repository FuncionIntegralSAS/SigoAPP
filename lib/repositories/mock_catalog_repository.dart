import '../models/employee_result.dart';
import '../models/warehouse_model.dart';
import 'catalog_repository.dart';

/// Implementación mock de [CatalogRepository] para desarrollo y pruebas offline.
///
/// Simula latencia de red mediante [Future.delayed] para validar los estados
/// de carga en la UI ([TransferFormProvider]).
class MockCatalogRepository implements CatalogRepository {
  /// Empleados en memoria: cédula → [EmployeeResult].
  static final _employees = <String, EmployeeResult>{
    '123': const EmployeeResult(name: 'Carlos Rodríguez', divisionId: 'D01'),
    '456': const EmployeeResult(name: 'María González', divisionId: 'D02'),
    '789': const EmployeeResult(name: 'Juan Pérez', divisionId: 'D01'),
  };

  /// Bodegas en memoria: divisionId → List<WarehouseModel>.
  static final _warehouses = <String, List<WarehouseModel>>{
    'D01': const [
      WarehouseModel(bodeCodi: 'B01', bodeDesc: 'Bodega Principal', bodeEsta: 'A'),
      WarehouseModel(bodeCodi: 'B02', bodeDesc: 'Bodega Secundaria', bodeEsta: 'A'),
    ],
    'D02': const [
      WarehouseModel(bodeCodi: 'B03', bodeDesc: 'Almacén Norte', bodeEsta: 'A'),
    ],
  };

  @override
  Future<EmployeeResult> findEmployee(String query) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final employee = _employees[query.trim()];
    if (employee == null) {
      throw Exception('Empleado no encontrado para el código: $query');
    }
    return employee;
  }

  @override
  Future<List<WarehouseModel>> getWarehousesByDivision(
    String divisionId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return _warehouses[divisionId] ?? [];
  }
}
