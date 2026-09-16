import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/models/employee_result.dart';

void main() {
  group('EmployeeResult Model Tests', () {
    test('fromJson mapea correctamente contrato de backend PersonResponse', () {
      final json = {
        "cedula": "1098765432",
        "nombre": "CARLOS ALBERTO",
        "apellido": "PEREZ GOMEZ",
        "correo": "cperez@funcionintegral.com",
        "division": "DIV-01",
        "estado": "ac",
      };

      final employee = EmployeeResult.fromJson(json);

      expect(employee.cedula, equals('1098765432'));
      expect(employee.nombre, equals('CARLOS ALBERTO PEREZ GOMEZ'));
      expect(employee.correo, equals('cperez@funcionintegral.com'));
      expect(employee.divisionId, equals('DIV-01'));
      expect(employee.personaId, equals(1098765432));
    });

    test('fromJson maneja campos legacy/Oracle alternativos con fallback', () {
      final json = {
        "perscodi": "123456",
        "persnomb": "JUAN",
        "persapel": "VALDEZ",
        "perscoel": "jvaldez@cafe.com",
        "persdivi": "D01",
      };

      final employee = EmployeeResult.fromJson(json);

      expect(employee.cedula, equals('123456'));
      expect(employee.nombre, equals('JUAN VALDEZ'));
      expect(employee.correo, equals('jvaldez@cafe.com'));
      expect(employee.divisionId, equals('D01'));
      expect(employee.personaId, equals(123456));
    });
  });
}
