import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/models/company_model.dart';
import 'package:sigo_app/models/warehouse_model.dart';
import 'package:sigo_app/models/article_model.dart';
import 'package:sigo_app/providers/inventory_provider.dart';
import 'package:sigo_app/repositories/inventory_repository.dart';

void main() {
  group('InventoryProvider', () {
    late _MockInventoryRepo mockRepository;
    late InventoryProvider provider;

    setUp(() {
      mockRepository = _MockInventoryRepo();
      provider = InventoryProvider(mockRepository);
    });

    test('Constructor NO debe disparar loadCompanies automáticamente', () {
      expect(provider.state, InventoryState.initial);
      expect(provider.companies, isEmpty);
      expect(mockRepository.getCompaniesCallCount, 0);
    });

    test('loadCompanies() debe actualizar estado a loading y luego success con datos', () async {
      mockRepository.companiesToReturn = [
        const CompanyModel(
          codigo: 'EMP1',
          descripcion: 'Empresa Test 1',
          nit: '900123456',
          estado: 'A',
        ),
      ];

      final future = provider.loadCompanies();
      expect(provider.state, InventoryState.loading);

      await future;
      expect(provider.state, InventoryState.success);
      expect(provider.companies.length, 1);
      expect(provider.companies.first.codigo, 'EMP1');
      expect(mockRepository.getCompaniesCallCount, 1);
    });

    test('loadCompanies() maneja error 401 con mensaje de sesión expirada', () async {
      mockRepository.errorToThrow = DioException(
        requestOptions: RequestOptions(path: '/api/v1/empresas/getAll'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/empresas/getAll'),
          statusCode: 401,
        ),
      );

      await provider.loadCompanies();
      expect(provider.state, InventoryState.error);
      expect(
        provider.errorMessage,
        'Su sesión ha expirado o no tiene permisos. Por favor, vuelva a iniciar sesión.',
      );
    });

    test('loadCompanies() maneja error 403 con mensaje de permisos', () async {
      mockRepository.errorToThrow = DioException(
        requestOptions: RequestOptions(path: '/api/v1/empresas/getAll'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/empresas/getAll'),
          statusCode: 403,
        ),
      );

      await provider.loadCompanies();
      expect(provider.state, InventoryState.error);
      expect(
        provider.errorMessage,
        'Su sesión ha expirado o no tiene permisos. Por favor, vuelva a iniciar sesión.',
      );
    });

    test('resetForm() limpia la selección y resetea el estado a initial', () async {
      mockRepository.companiesToReturn = [
        const CompanyModel(
          codigo: 'EMP1',
          descripcion: 'Empresa Test 1',
          nit: '900123456',
          estado: 'A',
        ),
      ];
      await provider.loadCompanies();
      provider.selectCompany(provider.companies.first);

      expect(provider.selectedCompany, isNotNull);

      provider.resetForm();

      expect(provider.selectedCompany, isNull);
      expect(provider.selectedWarehouse, isNull);
      expect(provider.warehouses, isEmpty);
      expect(provider.articles, isEmpty);
      expect(provider.state, InventoryState.initial);
    });
  });
}

class _MockInventoryRepo implements InventoryRepository {
  List<CompanyModel> companiesToReturn = [];
  List<WarehouseModel> warehousesToReturn = [];
  List<ArticleModel> articlesToReturn = [];
  Exception? errorToThrow;
  int getCompaniesCallCount = 0;

  @override
  Future<List<CompanyModel>> getCompanies() async {
    getCompaniesCallCount++;
    if (errorToThrow != null) throw errorToThrow!;
    return companiesToReturn;
  }

  @override
  Future<List<WarehouseModel>> getWarehouses(String companyId) async {
    if (errorToThrow != null) throw errorToThrow!;
    return warehousesToReturn;
  }

  @override
  Future<List<ArticleModel>> getArticles(
    String idBodega, [
    String? companyId,
  ]) async {
    if (errorToThrow != null) throw errorToThrow!;
    return articlesToReturn;
  }
}
