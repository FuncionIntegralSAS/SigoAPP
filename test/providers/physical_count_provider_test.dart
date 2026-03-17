import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/providers/physical_count_provider.dart';
import 'package:sigo_app/services/physical_count_service.dart';
import 'package:sigo_app/models/company_model.dart';
import 'package:sigo_app/models/warehouse_model.dart';
import 'package:sigo_app/models/article_model.dart';
import 'package:sigo_app/models/person_model.dart';

// Mock service para poder probar el provider de forma aislada
class MockPhysicalCountService extends PhysicalCountService {
  bool simulateError = false;

  @override
  Future<List<CompanyModel>> getCompanies() async {
    if (simulateError) throw Exception('Error');
    return [const CompanyModel(id: 'C1', name: 'Empresa Test')];
  }

  @override
  Future<List<WarehouseModel>> getWarehouses(String companyId) async {
    return [const WarehouseModel(id: 'W1', name: 'Bodega Test')];
  }

  @override
  Future<List<ArticleModel>> getArticles(String warehouseId) async {
    return [const ArticleModel(id: 'A1', name: 'Artículo Test', licensePlate: '', warehouse: 'W1')];
  }

  @override
  Future<List<PersonModel>> searchPersons({
    String? nombre,
    String? apellido,
    String? cedula,
  }) async {
    return [PersonModel(nationalId: 1, fullName: 'Test user')];
  }

  @override
  Future<void> createPhysicalCount(request) async {
    if (simulateError) throw Exception('Error creating count');
  }
}

void main() {
  group('PhysicalCountProvider', () {
    late PhysicalCountProvider provider;
    late MockPhysicalCountService mockService;

    setUp(() {
      mockService = MockPhysicalCountService();
      provider = PhysicalCountProvider(mockService);
    });

    test('Initial state should be EN_PROCESO or INITIAL after load', () async {
      // Al ser async, inicializa y luego pasa a INITIAL cuando termina el constructor
      await Future.delayed(const Duration(milliseconds: 100)); // Esperar carga
      expect(provider.state, PhysicalCountState.INITIAL);
      expect(provider.companies.isNotEmpty, true);
    });

    test('Validating empty form should set error state', () async {
      await provider.submitPhysicalCount();
      expect(provider.state, PhysicalCountState.ERROR);
      expect(provider.errorMessage, 'Debe seleccionar una Empresa.');
    });

    test('Completing form and submitting should succeed', () async {
      await Future.delayed(const Duration(milliseconds: 10)); // Espera inicial

      provider.selectCompany(provider.companies.first);
      await Future.delayed(const Duration(milliseconds: 10));

      provider.selectWarehouse(provider.warehouses.first);
      await Future.delayed(const Duration(milliseconds: 10));

      provider.selectArticle(provider.articles.first);
      
      provider.togglePersonSelection(PersonModel(nationalId: 1, fullName: 'Test user'));
      
      await provider.submitPhysicalCount();

      expect(provider.state, PhysicalCountState.CREADA);
      expect(provider.errorMessage, isNull);
    });
  });
}
