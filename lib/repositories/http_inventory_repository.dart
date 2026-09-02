import 'package:dio/dio.dart';
import '../models/company_model.dart';
import '../models/warehouse_model.dart';
import '../models/article_model.dart';
import 'inventory_repository.dart';

/// Implementación HTTP real del [InventoryRepository] usando [Dio].
class HttpInventoryRepository implements InventoryRepository {
  final Dio _dio;

  HttpInventoryRepository(this._dio);

  @override
  Future<List<CompanyModel>> getCompanies() async {
    final response = await _dio.get('/api/v1/empresas/getAll');
    if (response.statusCode == 204 || response.data == null || response.data is! List) {
      return [];
    }
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => CompanyModel.fromJson(json)).toList();
  }

  @override
  Future<List<WarehouseModel>> getWarehouses(String companyId) async {
    final response = await _dio.get('/api/v1/bodegas/empresa/$companyId');
    if (response.statusCode == 204 || response.data == null || response.data is! List) {
      return [];
    }
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => WarehouseModel.fromJson(json)).toList();
  }

  @override
  Future<List<ArticleModel>> getArticles(
    String idBodega, [
    String? companyId,
  ]) async {
    if (companyId == null || companyId.isEmpty) {
      // Si no se envía companyId, retornamos lista vacía o manejamos según negocio
      // Manteniendo el fallback por ahora
      return [];
    }

    try {
      final response = await _dio.get(
        '/api/v1/articulos/asignados/$idBodega/$companyId',
      );
      if (response.statusCode == 204 || response.data == null || response.data is! List) {
        return [];
      }
      final List<dynamic> data = response.data as List<dynamic>;

      // No inyectar 'Todos' aquí, eso es lógica de UI para filtros.
      // Se obtienen los artículos limpios.
      final List<ArticleModel> articles =
          data.map((json) => ArticleModel.fromJson(json)).toList();
      return articles;
    } catch (e) {
      rethrow;
    }
  }
}
