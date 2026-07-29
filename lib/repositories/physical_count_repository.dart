import '../models/company_model.dart';
import '../models/warehouse_model.dart';
import '../models/article_model.dart';
import '../models/personal_model.dart';
import '../models/physical_count_model.dart';

/// Contrato abstracto para el acceso a datos del módulo de Conteo Físico.
abstract class PhysicalCountRepository {
  /// Obtiene la lista de empresas disponibles.
  Future<List<CompanyModel>> getCompanies();

  /// Obtiene las bodegas asociadas a una empresa.
  Future<List<WarehouseModel>> getWarehouses(String companyId);

  /// Obtiene los artículos asignados a una bodega, con fallback mock si es necesario.
  Future<List<ArticleModel>> getArticles(
    String warehouseId, [
    String? companyId,
  ]);

  /// Busca personal que coincida con los filtros dados.
  Future<List<PersonalModel>> searchPersons({
    String? nombre,
    String? apellido,
    String? cedula,
  });

  /// Crea la apertura de un nuevo conteo físico.
  Future<void> createPhysicalCount(PhysicalCountRequest request);

  /// Realiza la asignación de participantes a un conteo físico.
  Future<void> assignArticles(AsignacionConteoRequest request);

  /// Verifica el estado de conexión con el backend (Health Check).
  Future<bool> checkHealth();

  /// Reporta las cantidades contadas en la iteración actual.
  Future<bool> reportarConteo(String token, ReporteConteoRequest request);

  /// Cierra un conteo físico para una bodega específica.
  Future<ConteoFisicoResponse> closePhysicalCount(String token, CierreConteoRequest request);

  /// Obtiene bodegas con conteo pendiente por empresa
  Future<List<PendingCountWarehouseModel>> getPendingWarehouses(String empresa);
}
