import '../models/company_model.dart';
import '../models/warehouse_model.dart';
import '../models/article_model.dart';

/// Contrato abstracto para el acceso a datos del módulo de Inventario.
abstract class InventoryRepository {
  /// Obtiene la lista de empresas disponibles.
  Future<List<CompanyModel>> getCompanies();

  /// Obtiene las bodegas asociadas a una empresa.
  Future<List<WarehouseModel>> getWarehouses(String companyId);

  /// Obtiene los artículos asignados a una bodega.
  Future<List<ArticleModel>> getArticles(
    String idBodega, [
    String? companyId,
  ]);
}
