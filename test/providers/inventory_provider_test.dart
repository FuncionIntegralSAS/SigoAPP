import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/shared/models/company_model.dart';
import 'package:sigo_app/shared/models/warehouse_model.dart';
import 'package:sigo_app/modules/inventory/models/article_model.dart';
import 'package:sigo_app/modules/inventory/models/transfer_person_model.dart';
import 'package:sigo_app/modules/inventory/models/transfer_asset_model.dart';
import 'package:sigo_app/modules/inventory/models/transfer_request.dart';
import 'package:sigo_app/modules/inventory/models/transfer_delivery_request.dart';
import 'package:sigo_app/modules/inventory/providers/inventory_provider.dart';
import 'package:sigo_app/modules/inventory/repositories/inventory_repository.dart';
import 'package:sigo_app/modules/inventory/repositories/transfer_repository.dart';

void main() {
  group('InventoryProvider', () {
    late _MockInventoryRepo mockRepository;
    late _MockTransferRepo mockTransferRepo;
    late InventoryProvider provider;

    setUp(() {
      mockRepository = _MockInventoryRepo();
      mockTransferRepo = _MockTransferRepo();
      provider = InventoryProvider(
        mockRepository,
        transferRepository: mockTransferRepo,
      );
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
      expect(provider.selectedCollaborator, isNull);
      expect(provider.warehouses, isEmpty);
      expect(provider.collaborators, isEmpty);
      expect(provider.articles, isEmpty);
      expect(provider.state, InventoryState.initial);
    });

    test('selectWarehouse carga colaboradores de la bodega pero no artículos', () async {
      const company = CompanyModel(codigo: 'EMP1', descripcion: 'Empresa 1', nit: '123', estado: 'A');
      const warehouse = WarehouseModel(codigoBodega: 'BOD01', descripcionBodega: 'Bodega Central', estadoBodega: 'A');
      mockTransferRepo.personsToReturn = [
        const TransferPersonModel(cedula: '12345', nombre: 'Juan', apellido: 'Diaz'),
      ];

      provider.selectedCompany = company;
      provider.selectWarehouse(warehouse);

      // Esperamos que se completen las operaciones asíncronas
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.selectedWarehouse, warehouse);
      expect(provider.articles, isEmpty);
      expect(provider.collaborators.length, 1);
      expect(provider.collaborators.first.cedula, '12345');
      expect(mockTransferRepo.getPersonsCallCount, 1);
    });

    test('selectCollaborator consulta getAssetsByPerson en la bodega activa tras seleccionar colaborador', () async {
      mockTransferRepo.assetsToReturn = [
        const TransferAssetModel(
          articulo: 'ASSET99',
          nombre: 'Impresora Fiscal',
          placa: 'IMP-99',
        ),
      ];

      provider.selectedCompany = const CompanyModel(codigo: 'EMP1', descripcion: 'Empresa 1', nit: '123', estado: 'A');
      provider.selectWarehouse(const WarehouseModel(codigoBodega: 'BOD01', descripcionBodega: 'Bodega Central', estadoBodega: 'A'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.articles, isEmpty);

      const collaborator = TransferPersonModel(cedula: '99999', nombre: 'Andres', apellido: 'Gomez');
      await provider.selectCollaborator(collaborator);

      expect(mockTransferRepo.getAssetsCallCount, 1);
      expect(mockTransferRepo.lastBodegaPassedToGetAssets, 'BOD01');
      expect(provider.articles.length, 1);
      expect(provider.articles.first.codigoActivo, 'ASSET99');
      expect(provider.articles.first.responsable, 'Andres Gomez');
    });

    test('selectCollaborator con null o ALL limpia la lista de artículos', () async {
      mockTransferRepo.assetsToReturn = [
        const TransferAssetModel(
          articulo: 'ASSET99',
          nombre: 'Impresora Fiscal',
          placa: 'IMP-99',
        ),
      ];
      provider.selectedCompany = const CompanyModel(codigo: 'EMP1', descripcion: 'Empresa 1', nit: '123', estado: 'A');
      provider.selectWarehouse(const WarehouseModel(codigoBodega: 'BOD01', descripcionBodega: 'Bodega Central', estadoBodega: 'A'));
      await Future.delayed(const Duration(milliseconds: 50));

      const collaborator = TransferPersonModel(cedula: '12345', nombre: 'Juan', apellido: 'Diaz');
      await provider.selectCollaborator(collaborator);
      expect(provider.articles.length, 1);
      expect(provider.selectedCollaborator, isNotNull);

      // Pasar opción 'ALL'
      const allCollaborator = TransferPersonModel(cedula: 'ALL', nombre: 'Todos los colaboradores', apellido: '');
      await provider.selectCollaborator(allCollaborator);
      expect(provider.selectedCollaborator, isNull);
      expect(provider.articles, isEmpty);

      // Re-seleccionar y deseleccionar con null
      await provider.selectCollaborator(collaborator);
      expect(provider.articles.length, 1);

      await provider.selectCollaborator(null);
      expect(provider.selectedCollaborator, isNull);
      expect(provider.articles, isEmpty);
    });

    test('refreshArticles() con colaborador seleccionado refresca los activos remotos', () async {
      mockTransferRepo.assetsToReturn = [
        const TransferAssetModel(
          articulo: 'ASSET99',
          nombre: 'Impresora Fiscal',
          placa: 'IMP-99',
        ),
      ];

      provider.selectedCompany = const CompanyModel(codigo: 'EMP1', descripcion: 'Empresa 1', nit: '123', estado: 'A');
      provider.selectWarehouse(const WarehouseModel(codigoBodega: 'BOD01', descripcionBodega: 'Bodega Central', estadoBodega: 'A'));
      await Future.delayed(const Duration(milliseconds: 50));

      const collaborator = TransferPersonModel(cedula: '99999', nombre: 'Andres', apellido: 'Gomez');
      await provider.selectCollaborator(collaborator);

      expect(mockTransferRepo.getAssetsCallCount, 1);
      expect(mockTransferRepo.lastBodegaPassedToGetAssets, 'BOD01');
      expect(provider.articles.length, 1);
      expect(provider.articles.first.codigoActivo, 'ASSET99');

      // Backend actualiza los activos asignados al colaborador
      mockTransferRepo.assetsToReturn = [
        const TransferAssetModel(
          articulo: 'ASSET99',
          nombre: 'Impresora Fiscal',
          placa: 'IMP-99',
        ),
        const TransferAssetModel(
          articulo: 'ASSET100',
          nombre: 'Escáner Código Barras',
          placa: 'SCN-100',
        ),
      ];

      await provider.refreshArticles();

      expect(mockTransferRepo.getAssetsCallCount, 2);
      expect(provider.articles.length, 2);
      expect(provider.articles.map((a) => a.codigoActivo), containsAll(['ASSET99', 'ASSET100']));
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
  Future<List<WarehouseModel>> getWarehouses(String companyId, {String tipo = 'PE'}) async {
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

class _MockTransferRepo implements TransferRepository {
  List<TransferPersonModel> personsToReturn = [];
  List<TransferAssetModel> assetsToReturn = [];
  int getPersonsCallCount = 0;
  int getAssetsCallCount = 0;

  @override
  Future<List<TransferPersonModel>> getPersonsByWarehouse({
    required String bodega,
    required String empresa,
  }) async {
    getPersonsCallCount++;
    return personsToReturn;
  }

  String? lastBodegaPassedToGetAssets;

  @override
  Future<List<TransferAssetModel>> getAssetsByPerson({
    required String persona,
    required String bodega,
    String? empresa,
  }) async {
    getAssetsCallCount++;
    lastBodegaPassedToGetAssets = bodega;
    return assetsToReturn;
  }

  @override
  Future<void> create(dynamic request) async {}

  @override
  Future<List<TransferRequest>> getAllTransfers({
    String? estado,
    String? empresa,
    String? bodega,
    bool fetchDetails = true,
  }) async => [];

  @override
  Future<TransferRequest?> getTransferById(String id) async => null;

  @override
  Future<void> approveTransfer(String requestId, {String? observacion}) async {}

  @override
  Future<void> rejectTransfer({
    required String requestId,
    required String motivoRechazo,
  }) async {}

  @override
  Future<void> signTransfer({
    required String transferId,
    required String tipoFirma,
    required String firmaBase64,
  }) async {}

  @override
  Future<void> receiveTransfer(String transferId) async {}

  @override
  Future<void> applyTransfer(TransferRequest request) async {}

  @override
  Future<void> applyTransferDelivery(TransferDeliveryRequest request) async {}
}

