import 'package:sigo_app/shared/models/company_model.dart';
import 'package:sigo_app/shared/models/warehouse_model.dart';
import 'package:sigo_app/modules/inventory/models/article_model.dart';

/// Contrato abstracto para el acceso a datos del módulo de Inventario.
abstract class InventoryRepository {
  /// Obtiene la lista de empresas disponibles.
  Future<List<CompanyModel>> getCompanies();

  /// Obtiene las bodegas asociadas a una empresa por [tipo] ('PE' para personal / traspasos, 'FI' para almacén físico).
  Future<List<WarehouseModel>> getWarehouses(String companyId, {String tipo = 'PE'});

  /// Obtiene los artículos asignados a una bodega.
  Future<List<ArticleModel>> getArticles(
    String idBodega, [
    String? companyId,
  ]);
}
