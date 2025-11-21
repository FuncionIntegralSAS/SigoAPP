import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/models/article_model.dart'; 
import 'package:sigo_app/services/mock_inventory_service.dart'; 

void main() {
  late MockInventoryService service;

  // Se ejecuta antes de cada grupo de tests
  setUp(() {
    // Inicializamos el servicio antes de cada test para asegurar la limpieza de datos
    service = MockInventoryService();
  });

  group('MockInventoryService Tests', () {

    // Test 1: Verificar la carga de datos y el filtrado por Bodega ID
    test('getArticlesByWarehouseId debe retornar el número correcto de artículos', () {
      // BOG001 tiene 3 artículos en los datos mock.
      final bogotaArticles = service.getArticlesByCostCenter('BOG001');
      expect(bogotaArticles.length, 3);

      // MED002 tiene 2 artículos en los datos mock.
      final medellinArticles = service.getArticlesByCostCenter('MED002');
      expect(medellinArticles.length, 2);

      // Un ID inexistente debe retornar 0.
      final nonExistentArticles = service.getArticlesByCostCenter('XYZ');
      expect(nonExistentArticles.length, 0);
    });

    // Test 2: Verificar la funcionalidad de actualización de artículos (updateArticle)
    test('updateArticle debe reemplazar un artículo existente con nuevos datos', () {
      const articleCodeToUpdate = 'PC001';
      const warehouseId = 'BOG001';
      
      // 1. Obtener el artículo original
      final originalArticle = service.getArticlesByCostCenter(warehouseId)
          .firstWhere((a) => a.id == articleCodeToUpdate);
      
      // 2. Crear un artículo actualizado (con ubicación)
      final newLat = 4.70;
      final updatedArticle = originalArticle.copyWith(
        latitude: newLat,
        longitude: -74.15,
      );

      // 3. Ejecutar la actualización
      service.updateArticle(updatedArticle);

      // 4. Obtener la lista nuevamente y verificar la actualización
      final updatedList = service.getArticlesByCostCenter(warehouseId);
      final fetchedArticle = updatedList.firstWhere((a) => a.id == articleCodeToUpdate);

      // Aserciones:
      // El total de artículos no debe cambiar
      expect(updatedList.length, 3); 
      // El artículo encontrado debe tener la nueva latitud
      expect(fetchedArticle.latitude, newLat); 
      // El resto de las propiedades deben permanecer iguales
      expect(fetchedArticle.responsible, originalArticle.responsible); 
    });
  });
}