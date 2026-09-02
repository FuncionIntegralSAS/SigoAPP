import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/providers/transfer_form_provider.dart';
import 'package:sigo_app/repositories/mock_catalog_repository.dart';

void main() {
  group('TransferFormProvider Tests', () {
    late MockCatalogRepository repository;
    late TransferFormProvider provider;

    setUp(() {
      repository = MockCatalogRepository();
      provider = TransferFormProvider(repository);
    });

    test('Estado inicial debe estar vacío y sin errores', () {
      expect(provider.employeeName, isNull);
      expect(provider.divisionId, isNull);
      expect(provider.employeeError, isNull);
      expect(provider.isSearchingEmployee, isFalse);
      expect(provider.isLoadingWarehouses, isFalse);
      expect(provider.warehouses, isEmpty);
      expect(provider.selectedWarehouseId, isNull);
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

    test('resetForm limpia todo el estado a valores iniciales', () async {
      await provider.searchEmployee('123');
      provider.selectWarehouse('B01');

      expect(provider.employeeName, isNotNull);
      expect(provider.selectedWarehouseId, equals('B01'));

      provider.resetForm();

      expect(provider.employeeName, isNull);
      expect(provider.divisionId, isNull);
      expect(provider.selectedWarehouseId, isNull);
      expect(provider.warehouses, isEmpty);
    });
  });
}
