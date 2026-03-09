import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/models/company_model.dart';

void main() {
  group('CompanyModel', () {
    test('should support value equality', () {
      const company1 = CompanyModel(id: '1', name: 'Empresa A');
      const company2 = CompanyModel(id: '1', name: 'Empresa A');
      expect(company1, equals(company2));
    });

    test('fromJson should return a valid model', () {
      final Map<String, dynamic> jsonMap = {
        'id': '10',
        'name': 'Company Test',
      };
      
      final result = CompanyModel.fromJson(jsonMap);

      expect(result, const CompanyModel(id: '10', name: 'Company Test'));
    });

    test('toJson should return a JSON map containing proper data', () {
      const company = CompanyModel(id: '10', name: 'Company Test');
      
      final result = company.toJson();

      final expectedMap = {
        'id': '10',
        'name': 'Company Test',
      };
      
      expect(result, expectedMap);
    });
  });
}
