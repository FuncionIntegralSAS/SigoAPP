import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/models/article_model.dart';

void main() {
  // Configuración de un artículo base para usar en todos los tests
  final baseArticle = ArticleModel(
    id: 1,
    codigoActivo: 'PC001',
    placa: 'ABC-123',
    nombre: 'Portátil Prueba',
    responsable: 'Responsable Test',
    bodega: 'BOG001',
  );

  group('ArticleModel Tests', () {
    // Test 1: Verificar que el getter qrData funciona correctamente sin ubicación.
    test('qrData debe codificar los datos básicos sin ubicación', () {
      final expectedQrData =
          'Código:PC001|Placa:ABC-123|Nombre:Portátil Prueba';
      expect(baseArticle.qrData, expectedQrData);
    });

    // Test 2: Verificar que el getter qrData incluye la ubicación cuando está presente.
    test('qrData debe incluir la ubicación (Lat/Lon) si está presente', () {
      final locatedArticle = baseArticle.copyWith(
        latitud: 4.600000,
        longitud: -74.080000,
      );
      final expectedQrData =
          'Código:PC001|Placa:ABC-123|Nombre:Portátil Prueba|Lat:4.600000|Lon:-74.080000';
      expect(locatedArticle.qrData, expectedQrData);
    });

    // Test 3: Verificar que copyWith actualiza la ubicación y mantiene el resto.
    test('copyWith debe actualizar la Lat/Lon manteniendo los datos Core', () {
      final newLat = 10.0;
      final newLon = 20.0;
      final updatedArticle = baseArticle.copyWith(
        latitud: newLat,
        longitud: newLon,
      );

      expect(updatedArticle.latitud, newLat);
      expect(updatedArticle.longitud, newLon);
      expect(updatedArticle.id, baseArticle.id);
      expect(updatedArticle.codigoActivo, baseArticle.codigoActivo);
      expect(updatedArticle.placa, baseArticle.placa);
    });

    // Test 4: Verificar los operadores de igualdad (== y hashCode)
    test('Dos instancias con el mismo Code y CostCenter deben ser iguales', () {
      final articleA = baseArticle;
      // Una nueva instancia (diferente referencia de memoria) con los mismos datos clave
      final articleB = ArticleModel(
        id: 1,
        codigoActivo: 'PC001',
        placa: 'OTRA PLACA',
        nombre: 'OTRO NOMBRE',
        responsable: 'OTRO RESPONSABLE',
        bodega: 'BOG001',
      );

      // Test de igualdad: deben ser iguales porque 'id', 'codigoActivo' y 'bodega' coinciden.
      expect(articleA, articleB);
      // Test de desigualdad: si el código es diferente, no deben ser iguales.
      final articleC = articleA.copyWith(codigoActivo: 'PC002');
      expect(articleA, isNot(articleC));

      // Test de hashCode: si son iguales, sus hashCodes también deben ser iguales.
      expect(articleA.hashCode, articleB.hashCode);
    });
  });
}
