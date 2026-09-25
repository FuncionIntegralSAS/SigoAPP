import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/exceptions/catalog_business_exception.dart';
import 'package:sigo_app/shared/models/warehouse_model.dart';
import 'package:sigo_app/modules/inventory/models/transfer_asset_model.dart';
import 'package:sigo_app/modules/inventory/providers/transfer_form_provider.dart';
import 'package:sigo_app/modules/inventory/repositories/mock_catalog_repository.dart';
import 'package:sigo_app/modules/inventory/repositories/mock_transfer_repository.dart';
import 'package:sigo_app/services/mock_inventory_service.dart';

void main() {
  group('TransferFormProvider Tests - Nuevo Flujo Dinámico', () {
    late MockInventoryService inventoryService;
    late MockTransferRepository transferRepository;
    late MockCatalogRepository catalogRepository;
    late TransferFormProvider provider;

    setUp(() {
      inventoryService = MockInventoryService();
      transferRepository = MockTransferRepository(inventoryService);
      catalogRepository = MockCatalogRepository();
      provider = TransferFormProvider(
        transferRepository,
        catalogRepository: catalogRepository,
      );
    });

    test('Estado inicial del flujo dinámico debe estar limpio', () {
      expect(provider.selectedEmpresa, equals('01'));
      expect(provider.selectedOriginBodega, isNull);
      expect(provider.isLoadingOriginPersons, isFalse);
      expect(provider.originPersons, isEmpty);
      expect(provider.selectedOriginPerson, isNull);

      expect(provider.isLoadingAssets, isFalse);
      expect(provider.personAssets, isEmpty);
      expect(provider.selectedAssets, isEmpty);

      expect(provider.selectedDestinationBodega, isNull);
      expect(provider.isLoadingDestinationPersons, isFalse);
      expect(provider.destinationPersons, isEmpty);
      expect(provider.selectedDestinationPerson, isNull);

      expect(provider.isFormValid, isFalse);
    });

    test('selectOriginBodega carga colaboradores de la bodega origen', () async {
      final future = provider.selectOriginBodega('B01');
      expect(provider.selectedOriginBodega, equals('B01'));
      expect(provider.isLoadingOriginPersons, isTrue);

      await future;

      expect(provider.isLoadingOriginPersons, isFalse);
      expect(provider.originPersons.length, greaterThanOrEqualTo(2));
      expect(provider.originPersons.first.cedula, equals('PI26055'));
      expect(provider.originPersons.first.nombreCompleto, equals('JUAN CAMILO DIAZ GOMEZ'));
    });

    test('selectOriginPerson carga activos del colaborador fuente', () async {
      await provider.selectOriginBodega('B01');
      final person = provider.originPersons.first;

      final future = provider.selectOriginPerson(person);
      expect(provider.selectedOriginPerson, equals(person));
      expect(provider.isLoadingAssets, isTrue);

      await future;

      expect(provider.isLoadingAssets, isFalse);
      expect(provider.personAssets, isNotEmpty);
      expect(provider.selectedAssets, isEmpty);
    });

    test('toggleAssetSelection bloquea activo cuando enTramite == true', () async {
      await provider.selectOriginBodega('B01');
      await provider.selectOriginPerson(provider.originPersons.first);

      final inTransitAsset = provider.personAssets.firstWhere((a) => a.enTramite);
      expect(inTransitAsset.enTramite, isTrue);
      expect(provider.isAssetSelectable(inTransitAsset), isFalse);
      expect(provider.getAssetIncompatibilityReason(inTransitAsset), contains('En trámite'));

      final toggled = provider.toggleAssetSelection(inTransitAsset);
      expect(toggled, isFalse);
      expect(provider.selectedAssets, isEmpty);
    });

    test('toggleAssetSelection aplica regla de compatibilidad PL/SQL (mismo CI y Tercero)', () async {
      await provider.selectOriginBodega('B01');
      await provider.selectOriginPerson(provider.originPersons.first);

      // Primer activo con CI-01 y Tercero 900123456
      final asset1 = provider.personAssets.firstWhere((a) => !a.enTramite && a.centroInformacion == 'CI-01');
      expect(provider.toggleAssetSelection(asset1), isTrue);
      expect(provider.selectedAssets.length, 1);

      // Segundo activo con mismo CI-01 y Tercero 900123456 (compatible)
      final compatibleAsset = provider.personAssets.firstWhere(
        (a) => !a.enTramite && a.centroInformacion == 'CI-01' && a.articulo != asset1.articulo,
      );
      expect(provider.isAssetCompatible(compatibleAsset), isTrue);
      expect(provider.isAssetSelectable(compatibleAsset), isTrue);
      expect(provider.toggleAssetSelection(compatibleAsset), isTrue);
      expect(provider.selectedAssets.length, 2);

      // Tercer activo con CI-02 (incompatible)
      final incompatibleAsset = provider.personAssets.firstWhere((a) => a.centroInformacion == 'CI-02');
      expect(provider.isAssetCompatible(incompatibleAsset), isFalse);
      expect(provider.isAssetSelectable(incompatibleAsset), isFalse);
      expect(provider.getAssetIncompatibilityReason(incompatibleAsset), contains('Incompatible'));

      final toggledIncompatible = provider.toggleAssetSelection(incompatibleAsset);
      expect(toggledIncompatible, isFalse);
      expect(provider.selectedAssets.length, 2); // No se añade
    });

    test('addPreselectedAsset añade activo a selectedAssets y personAssets (incluso con CI/Tercero nulos)', () {
      const asset = TransferAssetModel(
        articulo: 'TEST-001',
        placa: 'PLA-TEST',
        nombre: 'ACTIVO DE PRUEBA',
        centroInformacion: null,
        tercero: null,
        enTramite: false,
      );

      provider.addPreselectedAsset(asset);

      expect(provider.selectedAssets, contains(asset));
      expect(provider.personAssets, contains(asset));
      expect(provider.isAssetSelected(asset), isTrue);
      expect(provider.isAssetCompatible(asset), isTrue);
    });

    test('Activos con mismo articulo pero distinta placa se diferencian y seleccionan independientemente', () {
      const assetA = TransferAssetModel(
        articulo: 'PORTATIL-01',
        placa: 'PLA-001',
        nombre: 'Portátil Dell',
        centroInformacion: 'CI-01',
        tercero: '900123456',
      );
      const assetB = TransferAssetModel(
        articulo: 'PORTATIL-01',
        placa: 'PLA-002',
        nombre: 'Portátil Dell',
        centroInformacion: 'CI-01',
        tercero: '900123456',
      );

      provider.addPreselectedAsset(assetA);
      expect(provider.isAssetSelected(assetA), isTrue);
      expect(provider.isAssetSelected(assetB), isFalse);
      expect(provider.selectedAssets.length, 1);

      provider.toggleAssetSelection(assetB);
      expect(provider.isAssetSelected(assetA), isTrue);
      expect(provider.isAssetSelected(assetB), isTrue);
      expect(provider.selectedAssets.length, 2);

      provider.toggleAssetSelection(assetA);
      expect(provider.isAssetSelected(assetA), isFalse);
      expect(provider.isAssetSelected(assetB), isTrue);
      expect(provider.selectedAssets.length, 1);
    });

    test('isAssetCompatible permite activos con CI o Tercero nulo (precargados de inventario)', () {
      const assetWithInfo = TransferAssetModel(
        articulo: 'A-01',
        nombre: 'Activo con CI y Tercero',
        centroInformacion: 'CI-01',
        tercero: '900123456',
      );
      const assetWithoutInfo = TransferAssetModel(
        articulo: 'A-02',
        nombre: 'Activo sin CI ni Tercero de inventario',
        centroInformacion: null,
        tercero: null,
      );

      provider.addPreselectedAsset(assetWithInfo);
      expect(provider.isAssetCompatible(assetWithoutInfo), isTrue);

      provider.clearAssetSelection();
      provider.addPreselectedAsset(assetWithoutInfo);
      expect(provider.isAssetCompatible(assetWithInfo), isTrue);
    });

    test('selectDestinationPerson valida que no sea la misma persona fuente', () async {
      await provider.selectOriginBodega('B01');
      final personFuente = provider.originPersons.first; // PI26055
      await provider.selectOriginPerson(personFuente);

      await provider.selectDestinationBodega('B02');
      expect(provider.destinationPersons, isNotEmpty);

      // Intentar seleccionar la misma persona fuente como destino
      final samePerson = provider.destinationPersons.firstWhere((p) => p.cedula == personFuente.cedula);
      final success = provider.selectDestinationPerson(samePerson);

      expect(success, isFalse);
      expect(provider.selectedDestinationPerson, isNull);
      expect(provider.destinationPersonValidationError, contains('no puede ser igual'));

      // Seleccionar una persona diferente
      final differentPerson = provider.destinationPersons.firstWhere((p) => p.cedula != personFuente.cedula);
      final validSuccess = provider.selectDestinationPerson(differentPerson);

      expect(validSuccess, isTrue);
      expect(provider.selectedDestinationPerson, equals(differentPerson));
      expect(provider.destinationPersonValidationError, isNull);
    });

    test('isFormValid retorna true únicamente cuando todos los pasos son válidos', () async {
      expect(provider.isFormValid, isFalse);

      await provider.selectOriginBodega('B01');
      await provider.selectOriginPerson(provider.originPersons.first);
      expect(provider.isFormValid, isFalse);

      final validAsset = provider.personAssets.firstWhere((a) => !a.enTramite);
      provider.toggleAssetSelection(validAsset);
      expect(provider.isFormValid, isFalse);

      await provider.selectDestinationBodega('B02');
      final differentPerson = provider.destinationPersons.firstWhere(
        (p) => p.cedula != provider.selectedOriginPerson!.cedula,
      );
      provider.selectDestinationPerson(differentPerson);

      expect(provider.isFormValid, isTrue);
    });

    test('selectOriginBodega rechaza bodegas que no sean de tipo personal PE', () async {
      await provider.selectOriginBodega('B01', tipo: 'FI');

      expect(provider.selectedOriginBodega, equals('B01'));
      expect(provider.selectedOriginBodegaTipo, equals('FI'));
      expect(provider.originPersonsError, contains('bodegas personales [PE]'));
      expect(provider.originPersons, isEmpty);
      expect(provider.isFormValid, isFalse);
    });

    test('toggleAssetSelection impide seleccionar más de 50 artículos', () {
      for (int i = 1; i <= 50; i++) {
        provider.addPreselectedAsset(TransferAssetModel(
          articulo: 'ART-$i',
          placa: 'PLA-$i',
          nombre: 'Artículo $i',
          centroInformacion: 'CI-01',
          tercero: '900123456',
        ));
      }
      expect(provider.selectedAssets.length, equals(50));

      const extraAsset = TransferAssetModel(
        articulo: 'ART-51',
        placa: 'PLA-51',
        nombre: 'Artículo 51',
        centroInformacion: 'CI-01',
        tercero: '900123456',
      );

      expect(provider.isAssetSelectable(extraAsset), isFalse);
      expect(provider.getAssetIncompatibilityReason(extraAsset), contains('50 artículos'));

      final added = provider.toggleAssetSelection(extraAsset);
      expect(added, isFalse);
      expect(provider.selectedAssets.length, equals(50));
      expect(provider.selectionLimitError, contains('50 artículos'));
    });

    test('setEmpresa reinicia el flujo secuencial ante cambio de empresa', () async {
      await provider.selectOriginBodega('B01');
      await provider.selectOriginPerson(provider.originPersons.first);
      expect(provider.originPersons, isNotEmpty);

      provider.setEmpresa('02');

      expect(provider.selectedEmpresa, equals('02'));
      expect(provider.selectedOriginBodega, isNull);
      expect(provider.originPersons, isEmpty);
      expect(provider.selectedOriginPerson, isNull);
      expect(provider.personAssets, isEmpty);
      expect(provider.selectedAssets, isEmpty);
    });

    test('resetForm restablece todos los valores a su estado inicial', () async {
      await provider.selectOriginBodega('B01');
      await provider.selectOriginPerson(provider.originPersons.first);
      final asset = provider.personAssets.firstWhere((a) => !a.enTramite);
      provider.toggleAssetSelection(asset);
      provider.setObservacion('Observación de prueba');

      provider.resetForm();

      expect(provider.selectedEmpresa, equals('01'));
      expect(provider.selectedOriginBodega, isNull);
      expect(provider.selectedOriginPerson, isNull);
      expect(provider.selectedAssets, isEmpty);
      expect(provider.observacion, isEmpty);
      expect(provider.isFormValid, isFalse);
    });
  });

  group('TransferFormProvider Tests - Retrocompatibilidad Catálogo', () {
    late MockInventoryService inventoryService;
    late MockTransferRepository transferRepository;
    late MockCatalogRepository catalogRepository;
    late TransferFormProvider provider;

    setUp(() {
      inventoryService = MockInventoryService();
      transferRepository = MockTransferRepository(inventoryService);
      catalogRepository = MockCatalogRepository();
      provider = TransferFormProvider(
        transferRepository,
        catalogRepository: catalogRepository,
      );
    });

    test('searchEmployee con cédula válida carga empleado y bodegas en cascada por división', () async {
      final future = provider.searchEmployee('123');
      expect(provider.isSearchingEmployee, isTrue);

      await future;

      expect(provider.isSearchingEmployee, isFalse);
      expect(provider.isLoadingWarehouses, isFalse);
      expect(provider.employeeName, equals('Carlos Rodríguez'));
      expect(provider.divisionId, equals('D01'));
      expect(provider.employeeError, isNull);
      expect(provider.warehouses.length, equals(2));
      expect(provider.warehouses.first.codigoBodega, equals('B01'));
    });

    test('searchEmployee con cédula inválida captura error amigablemente', () async {
      await provider.searchEmployee('99999');

      expect(provider.isSearchingEmployee, isFalse);
      expect(provider.employeeName, isNull);
      expect(provider.divisionId, isNull);
      expect(provider.employeeError, contains('Empleado no encontrado'));
      expect(provider.warehouses, isEmpty);
    });

    test('selectWarehouse asigna selectedWarehouseId correctamente', () {
      provider.selectWarehouse('B01');
      expect(provider.selectedWarehouseId, equals('B01'));

      provider.selectWarehouse(null);
      expect(provider.selectedWarehouseId, isNull);
    });

    test('searchEmployee por nombre con múltiples coincidencias puebla candidateEmployees', () async {
      await provider.searchEmployee('Carlos');

      expect(provider.isSearchingEmployee, isFalse);
      expect(provider.employeeName, isNull);
      expect(provider.candidateEmployees.length, equals(2));
      expect(provider.candidateEmployees.map((e) => e.nombre), containsAll(['Carlos Rodríguez', 'Carlos Gómez']));
    });

    test('selectEmployee selecciona candidato y carga bodegas en cascada', () async {
      await provider.searchEmployee('Carlos');
      expect(provider.candidateEmployees.length, equals(2));

      final selected = provider.candidateEmployees.firstWhere((e) => e.cedula == '101');
      await provider.selectEmployee(selected);

      expect(provider.selectedEmployee?.cedula, equals('101'));
      expect(provider.employeeName, equals('Carlos Gómez'));
      expect(provider.divisionId, equals('D01'));
      expect(provider.candidateEmployees, isEmpty);
      expect(provider.warehouses.length, equals(2));
    });

    test('clearSelectedEmployee limpia el empleado seleccionado y las bodegas', () async {
      await provider.searchEmployee('123');
      expect(provider.employeeName, equals('Carlos Rodríguez'));
      expect(provider.warehouses, isNotEmpty);

      provider.clearSelectedEmployee();

      expect(provider.employeeName, isNull);
      expect(provider.divisionId, isNull);
      expect(provider.selectedEmployee, isNull);
      expect(provider.warehouses, isEmpty);
    });

    test('captura CatalogBusinessException al cargar bodegas y permite reintentar', () async {
      final failingRepo = FailingCatalogRepository();
      failingRepo.shouldFailWarehouses = true;
      final errorProvider = TransferFormProvider(
        transferRepository,
        catalogRepository: failingRepo,
      );

      await errorProvider.searchEmployee('123');

      expect(errorProvider.employeeName, equals('Carlos Rodríguez'));
      expect(errorProvider.warehouseError, contains('Error interno en el servidor'));
      expect(errorProvider.warehouseStatusCode, equals(500));
      expect(errorProvider.warehouses, isEmpty);

      failingRepo.shouldFailWarehouses = false;
      await errorProvider.retryLoadWarehouses();

      expect(errorProvider.warehouseError, isNull);
      expect(errorProvider.warehouses.length, equals(2));
    });
  });
}

class FailingCatalogRepository extends MockCatalogRepository {
  bool shouldFailWarehouses = false;

  @override
  Future<List<WarehouseModel>> getWarehousesByDivision(String divisionId) async {
    if (shouldFailWarehouses) {
      throw const CatalogBusinessException(
        'Error interno en el servidor al consultar las bodegas de la división.',
        technicalDetails:
            'GET /api/v1/bodegas/division/D01 [HTTP 500]\nORA-00904: invalid identifier',
        statusCode: 500,
        endpoint: '/api/v1/bodegas/division/D01',
      );
    }
    return super.getWarehousesByDivision(divisionId);
  }
}
