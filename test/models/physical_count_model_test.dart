import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/models/physical_count_model.dart';
import 'package:sigo_app/models/person_model.dart';

void main() {
  group('PhysicalCountRequest', () {
    final tDate = DateTime(2026, 3, 9);
    final tPerson = PersonModel(
      nationalId: 123456789,
      fullName: 'Juan Perez',
      accountExists: true,
      isActive: true,
    );

    test('should support value equality', () {
      final request1 = PhysicalCountRequest(
        companyId: 'C1',
        warehouseId: 'W1',
        date: tDate,
        articleId: 'All',
        verifyExistence: true,
        participants: [tPerson],
      );
      
      final request2 = PhysicalCountRequest(
        companyId: 'C1',
        warehouseId: 'W1',
        date: tDate,
        articleId: 'All',
        verifyExistence: true,
        participants: [tPerson],
      );

      expect(request1, equals(request2));
    });

    test('toJson should return a JSON map with participants mapped to IDs', () {
      final request = PhysicalCountRequest(
        companyId: 'C1',
        warehouseId: 'All',
        date: tDate,
        articleId: 'A1',
        verifyExistence: false,
        participants: [tPerson],
      );

      final result = request.toJson();

      final expectedMap = {
        'companyId': 'C1',
        'warehouseId': 'All',
        'date': tDate.toIso8601String(),
        'articleId': 'A1',
        'verifyExistence': false,
        'participantsIds': [123456789],
      };

      expect(result, expectedMap);
    });
  });
}
