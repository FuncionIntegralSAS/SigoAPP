import 'package:flutter_test/flutter_test.dart';
import 'package:'

void main() {
  // Configuración de un artículo base para usar en todos los tests
  final baseArticle = ArticleModel(
    code: 'PC001',
    licensePlate: 'ABC-123',
    name: 'Portátil Prueba',
    responsible: 'Responsable Test',
    costCenter: 'BOG001',
  );

  group('ArticleModel Tests', () {

    // Test 1: Verificar que el getter qrData funciona correctamente sin ubicación.
    test('qrData debe codificar los datos básicos sin ubicación', () {
      final expectedQrData = 'Código:PC001|Placa:ABC-123|Nombre:Portátil Prueba';
      expect(baseArticle.qrData, expectedQrData);
    });

    // Test 2: Verificar que el getter qrData incluye la ubicación cuando está presente.
    test('qrData debe incluir la ubicación (Lat/Lon) si está presente', () {
      final locatedArticle = baseArticle.copyWith(
        latitude: 4.600000,
        longitude: -74.080000,
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
        latitude: newLat,
        longitude: newLon,
      );

      expect(updatedArticle.latitude, newLat);
      expect(updatedArticle.longitude, newLon);
      expect(updatedArticle.code, baseArticle.code);
      expect(updatedArticle.licensePlate, baseArticle.licensePlate);
    });

    // Test 4: Verificar los operadores de igualdad (== y hashCode)
    test('Dos instancias con el mismo Code y CostCenter deben ser iguales', () {
      final articleA = baseArticle;
      // Una nueva instancia (diferente referencia de memoria) con los mismos datos clave
      final articleB = ArticleModel(
        code: 'PC001',
        licensePlate: 'OTRA PLACA', // Diferente
        name: 'OTRO NOMBRE', // Diferente
        responsible: 'OTRO RESPONSABLE', // Diferente
        costCenter: 'BOG001',
      );
      
      // Test de igualdad: deben ser iguales porque 'code' y 'costCenter' coinciden.
      expect(articleA, articleB); 
      // Test de desigualdad: si el código es diferente, no deben ser iguales.
      final articleC = articleA.copyWith(code: 'PC002');
      expect(articleA, isNot(articleC));

      // Test de hashCode: si son iguales, sus hashCodes también deben ser iguales.
      expect(articleA.hashCode, articleB.hashCode);
    });
  });
}