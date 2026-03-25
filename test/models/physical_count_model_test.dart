import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/models/physical_count_model.dart';

void main() {
  group('PhysicalCountRequest Model', () {
    final DateTime testDate = DateTime(2023, 10, 25, 14, 30);

    test('Soporta comparación por valor (Equatable)', () {
      final request1 = PhysicalCountRequest(
        companyId: 'C1',
        warehouseId: 'W1',
        date: testDate,
        articleId: 'A1',
        verifyExistence: true,
      );

      final request2 = PhysicalCountRequest(
        companyId: 'C1',
        warehouseId: 'W1',
        date: testDate,
        articleId: 'A1',
        verifyExistence: true,
      );

      expect(request1, equals(request2));
    });

    test('toJson convierte correctamente el objeto al formato esperado por el backend', () {
      final request = PhysicalCountRequest(
        companyId: 'C1',
        warehouseId: 'W1',
        logicalWarehouseId: 'L2',
        date: testDate,
        articleId: 'A1',
        verifyExistence: true,
      );

      final result = request.toJson();

      final expectedMap = {
        'empresa': 'C1',
        'bodega': 'W1',
        'bodegaLogica': 'L2',
        'articulo': 'A1',
        'fecha': testDate.toIso8601String().split('.')[0],
        'verificarExistencia': 'S',
      };

      expect(result, expectedMap);
    });
  });
}
