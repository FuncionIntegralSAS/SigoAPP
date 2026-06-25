import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/models/company_model.dart';

void main() {
  group('CompanyModel', () {
    test('should support value equality', () {
      const company1 = CompanyModel(
        codigo: '1',
        nit: '1',
        estado: '1',
        descripcion: 'Empresa A',
      );
      const company2 = CompanyModel(
        codigo: '1',
        nit: '1',
        estado: '1',
        descripcion: 'Empresa A',
      );
      expect(company1, equals(company2));
    });

    test('fromJson should return a valid model', () {
      final Map<String, dynamic> jsonMap = {'id': '10', 'name': 'Company Test'};

      final result = CompanyModel.fromJson(jsonMap);

      expect(
        result,
        const CompanyModel(
          codigo: '10',
          nit: '10',
          estado: '10',
          descripcion: 'Company Test',
        ),
      );
    });

    test('toJson should return a JSON map containing proper data', () {
      const company = CompanyModel(
        codigo: '10',
        nit: '10',
        estado: '10',
        descripcion: 'Company Test',
      );

      final result = company.toJson();

      final expectedMap = {
        'codigo': '10',
        'nit': '10',
        'estado': '10',
        'descripcion': 'Company Test',
      };

      expect(result, expectedMap);
    });
  });
}
