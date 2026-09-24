import 'package:sigo_app/modules/inventory/models/employee_result.dart';
import 'package:sigo_app/shared/models/warehouse_model.dart';
import 'package:sigo_app/modules/inventory/repositories/catalog_repository.dart';

/// Implementación mock de [CatalogRepository] para desarrollo y pruebas offline.
///
/// Simula latencia de red mediante [Future.delayed] para validar los estados
/// de carga en la UI ([TransferFormProvider]).
class MockCatalogRepository implements CatalogRepository {
  /// Empleados en memoria: cédula → [EmployeeResult].
  static final _employees = <String, EmployeeResult>{
    '123': const EmployeeResult(nombre: 'Carlos Rodríguez', divisionId: 'D01', cedula: '123', personaId: 123),
    '456': const EmployeeResult(nombre: 'María González', divisionId: 'D02', cedula: '456', personaId: 456),
    '789': const EmployeeResult(nombre: 'Juan Pérez', divisionId: 'D01', cedula: '789', personaId: 789),
    '101': const EmployeeResult(nombre: 'Carlos Gómez', divisionId: 'D01', cedula: '101', personaId: 101),
  };

  /// Bodegas en memoria: divisionId → `List<WarehouseModel>`.
  static final _warehouses = <String, List<WarehouseModel>>{
    'D01': const [
      WarehouseModel(codigoBodega: 'B01', descripcionBodega: 'Bodega Principal', estadoBodega: 'A'),
      WarehouseModel(codigoBodega: 'B02', descripcionBodega: 'Bodega Secundaria', estadoBodega: 'A'),
    ],
    'D02': const [
      WarehouseModel(codigoBodega: 'B03', descripcionBodega: 'Almacén Norte', estadoBodega: 'A'),
    ],
  };

  @override
  Future<List<EmployeeResult>> searchEmployees({
    String? nombre,
    String? apellido,
    String? cedula,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var list = _employees.values.toList();

    if (cedula != null && cedula.trim().isNotEmpty) {
      list = list.where((e) => (e.cedula ?? '').contains(cedula.trim())).toList();
    }
    if (nombre != null && nombre.trim().isNotEmpty) {
      list = list.where((e) => e.nombre.toLowerCase().contains(nombre.trim().toLowerCase())).toList();
    }
    if (apellido != null && apellido.trim().isNotEmpty) {
      list = list.where((e) => e.nombre.toLowerCase().contains(apellido.trim().toLowerCase())).toList();
    }

    return list;
  }

  @override
  Future<EmployeeResult> findEmployee(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final cleanQuery = query.trim().toLowerCase();
    final employee = _employees.values.firstWhere(
      (e) => (e.cedula ?? '').toLowerCase() == cleanQuery ||
             e.nombre.toLowerCase().contains(cleanQuery),
      orElse: () => throw Exception('Empleado no encontrado para el código: $query'),
    );
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
