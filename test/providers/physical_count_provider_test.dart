import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/providers/physical_count_provider.dart';
import 'package:sigo_app/repositories/mock_physical_count_repository.dart';
import 'package:sigo_app/models/personal_model.dart';

void main() {
  group('PhysicalCountProvider', () {
    late PhysicalCountProvider provider;
    late MockPhysicalCountRepository mockRepository;

    setUp(() {
      mockRepository = MockPhysicalCountRepository();
      provider = PhysicalCountProvider(mockRepository);
    });

    test('Initial state should be EN_PROCESO or INITIAL after load', () async {
      // Al ser async, inicializa y luego pasa a INITIAL cuando termina el constructor
      await Future.delayed(const Duration(milliseconds: 100)); // Esperar carga
      expect(provider.state, PhysicalCountState.initial);
      expect(provider.companies.isNotEmpty, true);
    });

    test('Validating empty form should set error state', () async {
      await provider.submitPhysicalCount();
      expect(provider.state, PhysicalCountState.error);
      expect(provider.errorMessage, 'Debe seleccionar una Empresa.');
    });

    test('Completing form and submitting should succeed', () async {
      await Future.delayed(const Duration(milliseconds: 100)); // Espera inicial

      provider.selectCompany(provider.companies.first);
      await Future.delayed(const Duration(milliseconds: 100));

      provider.selectWarehouse(provider.warehouses.first);
      await Future.delayed(const Duration(milliseconds: 100));

      provider.selectArticle(provider.articles.first);

      provider.togglePersonSelection(
        PersonalModel(
          perscodi: '1',
          persnomb: 'Test',
          persapel: 'user',
          perscoel: 'test@sigo.com',
          persdivi: '1',
          persesta: 'A',
        ),
      );

      await provider.submitPhysicalCount();

      expect(provider.state, PhysicalCountState.creada);
      expect(provider.errorMessage, isNull);
    });
  });
}
