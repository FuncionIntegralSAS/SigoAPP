import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/models/auth_model.dart';

void main() {
  group('AuthResponse Tests', () {
    test('fromJson debe parsear documento cuando viene en el payload', () {
      final json = {
        'token': 'eyJhbGciOi...',
        'refreshToken': 'refresh-token-123',
        'type': 'Bearer',
        'username': 'JCAMILO',
        'documento': 'PI26055',
        'expiresIn': 100000,
        'permisos': [
          {'forma': 'TRMO01', 'descripcion': 'Traspasos'},
        ],
      };

      final response = AuthResponse.fromJson(json);

      expect(response.token, 'eyJhbGciOi...');
      expect(response.refreshToken, 'refresh-token-123');
      expect(response.type, 'Bearer');
      expect(response.username, 'JCAMILO');
      expect(response.documento, 'PI26055');
      expect(response.expiresIn, 100000);
      expect(response.permisos?.length, 1);
      expect(response.permisos?.first.forma, 'TRMO01');
    });

    test('fromJson tolera documento nulo cuando no viene en el payload', () {
      final json = {
        'token': 'mock-token',
        'username': 'admin',
      };

      final response = AuthResponse.fromJson(json);

      expect(response.token, 'mock-token');
      expect(response.username, 'admin');
      expect(response.documento, isNull);
    });

    test('Equatable compara por valor incluyendo documento', () {
      const resp1 = AuthResponse(
        token: 'token1',
        username: 'JCAMILO',
        documento: 'PI26055',
      );

      const resp2 = AuthResponse(
        token: 'token1',
        username: 'JCAMILO',
        documento: 'PI26055',
      );

      const resp3 = AuthResponse(
        token: 'token1',
        username: 'JCAMILO',
        documento: 'PI99999',
      );

      expect(resp1, equals(resp2));
      expect(resp1, isNot(equals(resp3)));
    });
  });
}
