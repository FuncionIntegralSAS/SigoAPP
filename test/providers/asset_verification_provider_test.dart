import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/modules/inventory/models/article_model.dart';
import 'package:sigo_app/modules/inventory/providers/asset_verification_provider.dart';

void main() {
  group('AssetVerificationProvider Unit Tests', () {
    late AssetVerificationProvider provider;

    final expectedArticle1 = ArticleModel(
      id: 1,
      codigoActivo: 'ACT-001',
      nombre: 'Laptop Dell Latitude',
      placa: 'PLA-100',
      bodega: 'B01',
      responsable: 'Carlos Ruiz',
    );

    final expectedArticle2 = ArticleModel(
      id: 2,
      codigoActivo: 'ACT-002',
      nombre: 'Monitor LG 27"',
      placa: 'PLA-200',
      bodega: 'B01',
      responsable: 'Carlos Ruiz',
    );

    final List<ArticleModel> expectedList = [
      expectedArticle1,
      expectedArticle2,
    ];

    setUp(() {
      provider = AssetVerificationProvider();
    });

    test('Estado inicial es vacío y sin conflictos', () {
      expect(provider.verifiedAssetCodes, isEmpty);
      expect(provider.conflictAssets, isEmpty);
      expect(provider.selectedWarehouse, isNull);
      expect(provider.selectedOwner, isNull);
    });

    test('verifyAsset valida coincidencia por código de activo', () {
      final scanned = ArticleModel(
        codigoActivo: 'ACT-001',
        nombre: 'Laptop Dell Latitude',
        placa: '',
        bodega: 'B01',
      );

      bool notified = false;
      provider.addListener(() => notified = true);

      final result = provider.verifyAsset(scanned, expectedList);

      expect(result, isTrue);
      expect(notified, isTrue);
      expect(provider.isVerified(expectedArticle1), isTrue);
      expect(provider.isVerified(expectedArticle2), isFalse);
      expect(provider.conflictAssets, isEmpty);
    });

    test('verifyAsset valida coincidencia por placa del activo', () {
      final scanned = ArticleModel(
        codigoActivo: 'OTHER-CODE',
        nombre: 'Monitor LG',
        placa: 'PLA-200',
        bodega: 'B01',
      );

      final result = provider.verifyAsset(scanned, expectedList);

      expect(result, isTrue);
      expect(provider.isVerified(expectedArticle2), isTrue);
      expect(provider.conflictAssets, isEmpty);
    });

    test('verifyAsset registra conflicto cuando el activo no está en la lista esperada', () {
      final conflictArticle = ArticleModel(
        codigoActivo: 'ACT-999',
        nombre: 'Impresora HP LaserJet',
        placa: 'PLA-999',
        bodega: 'B02',
        responsable: 'Maria López',
      );

      final result = provider.verifyAsset(conflictArticle, expectedList);

      expect(result, isFalse);
      expect(provider.isVerified(conflictArticle), isFalse);
      expect(provider.conflictAssets.length, equals(1));
      expect(provider.conflictAssets.first.codigoActivo, equals('ACT-999'));
    });

    test('verifyAsset no duplica activos en conflicto al escanear múltiples veces', () {
      final conflictArticle = ArticleModel(
        codigoActivo: 'ACT-999',
        nombre: 'Impresora HP LaserJet',
        placa: 'PLA-999',
        bodega: 'B02',
      );

      provider.verifyAsset(conflictArticle, expectedList);
      provider.verifyAsset(conflictArticle, expectedList);

      expect(provider.conflictAssets.length, equals(1));
    });

    test('verifyAsset remueve activo de conflictAssets si posteriormente coincide', () {
      final conflictArticle = ArticleModel(
        codigoActivo: 'ACT-001',
        nombre: 'Laptop Dell Latitude',
        placa: 'PLA-100',
        bodega: 'B01',
      );

      // Primero se escanea contra una lista vacía (simulando conflicto)
      provider.verifyAsset(conflictArticle, []);
      expect(provider.conflictAssets.length, equals(1));

      // Luego se escanea contra la lista correcta
      final result = provider.verifyAsset(conflictArticle, expectedList);

      expect(result, isTrue);
      expect(provider.conflictAssets, isEmpty);
      expect(provider.isVerified(conflictArticle), isTrue);
    });

    test('resetVerification limpia conjuntos de verificados y conflictos', () {
      provider.verifyAsset(expectedArticle1, expectedList);
      provider.verifyAsset(
        ArticleModel(codigoActivo: 'CONFLICT', nombre: 'X', placa: '', bodega: ''),
        expectedList,
      );

      expect(provider.verifiedAssetCodes, isNotEmpty);
      expect(provider.conflictAssets, isNotEmpty);

      bool notified = false;
      provider.addListener(() => notified = true);

      provider.resetVerification();

      expect(provider.verifiedAssetCodes, isEmpty);
      expect(provider.conflictAssets, isEmpty);
      expect(notified, isTrue);
    });

    test('reset restablece selecciones y verificación', () {
      provider.selectWarehouse('B01');
      provider.selectOwner('Carlos Ruiz');
      provider.verifyAsset(expectedArticle1, expectedList);

      provider.reset();

      expect(provider.selectedWarehouse, isNull);
      expect(provider.selectedOwner, isNull);
      expect(provider.verifiedAssetCodes, isEmpty);
      expect(provider.conflictAssets, isEmpty);
    });

    test('hasResponsibleConflict evalúa discrepancia de responsable', () {
      provider.selectOwner('Carlos Ruiz');

      expect(provider.hasResponsibleConflict(articleResponsible: 'Carlos Ruiz'), isFalse);
      expect(provider.hasResponsibleConflict(articleResponsible: 'Maria López'), isTrue);
    });
  });
}
