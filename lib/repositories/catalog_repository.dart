import '../models/employee_result.dart';
import '../models/warehouse_model.dart';

/// Contrato de acceso a datos para catálogos auxiliares del módulo de Traspasos.
///
/// Define las dos operaciones de carga en cascada orquestadas por
/// [TransferFormProvider]:
/// 1. [findEmployee]: Busca un empleado por cédula/código y retorna sus datos
///    básicos (nombre + división).
/// 2. [getWarehousesByDivision]: Obtiene las bodegas autorizadas para la
///    división del empleado encontrado.
///
/// Tanto [HttpCatalogRepository] como [MockCatalogRepository] cumplen este
/// contrato, lo que permite intercambiarlos mediante inyección de dependencias.
abstract class CatalogRepository {
  /// Busca un empleado por su cédula o código interno.
  ///
  /// Lanza [Exception] si no se encuentra el empleado o hay error de red.
  Future<EmployeeResult> findEmployee(String query);

  /// Retorna las bodegas asociadas a la división [divisionId].
  ///
  /// Lanza [Exception] si ocurre un error de red.
  Future<List<WarehouseModel>> getWarehousesByDivision(String divisionId);
}
