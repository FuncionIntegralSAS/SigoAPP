import '../models/company_model.dart';
import '../models/warehouse_model.dart';
import '../models/article_model.dart';
import '../models/personal_model.dart';
import '../models/physical_count_model.dart';
import 'physical_count_repository.dart';

/// Implementación Mock del [PhysicalCountRepository] para desarrollo
/// offline y pruebas unitarias.
class MockPhysicalCountRepository implements PhysicalCountRepository {
  bool simulateError = false;

  @override
  Future<List<CompanyModel>> getCompanies() async {
    if (simulateError) throw Exception('Error al obtener empresas (Mock)');
    await Future.delayed(const Duration(milliseconds: 50));
    return [
      const CompanyModel(
        codigo: 'C1',
        nit: 'C1',
        estado: 'C1',
        descripcion: 'Empresa Test (Mock)',
      ),
    ];
  }

  @override
  Future<List<WarehouseModel>> getWarehouses(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return [
      const WarehouseModel(
        bodeCodi: 'W1',
        bodeDesc: 'Bodega Test (Mock)',
        bodeEsta: 'W1',
      ),
    ];
  }

  @override
  Future<List<ArticleModel>> getArticles(
    String warehouseId, [
    String? companyId,
  ]) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return [
      const ArticleModel(
        id: 'All',
        name: 'Todos',
        licensePlate: '',
        warehouse: 'All',
      ),
      const ArticleModel(
        id: 'A1',
        name: 'Computador Portátil (Mock)',
        licensePlate: 'P-001',
        warehouse: 'W1',
      ),
      const ArticleModel(
        id: 'A2',
        name: 'Silla Ergonómica (Mock)',
        licensePlate: 'S-005',
        warehouse: 'W1',
      ),
    ];
  }

  @override
  Future<List<PersonalModel>> searchPersons({
    String? nombre,
    String? apellido,
    String? cedula,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return [
      PersonalModel(
        perscodi: '1',
        persnomb: 'Test (Mock)',
        persapel: 'User',
        perscoel: 'test@sigo.com',
        persdivi: '1',
        persesta: 'A',
      ),
    ];
  }

  @override
  Future<void> createPhysicalCount(PhysicalCountRequest request) async {
    if (simulateError) {
      throw Exception('Error al crear conteo físico (Mock)');
    }
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<void> assignArticles(AsignacionConteoRequest request) async {
    if (simulateError) {
      throw Exception('Error al asignar participantes (Mock)');
    }
    await Future.delayed(const Duration(milliseconds: 50));
  }
}
