import '../models/auth_model.dart';
import '../models/physical_count_model.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<AuthResponse> loginContador(LoginContadorRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Mock login success logic
    if (request.documento == '123' && request.codigoTemporal == '0000') {
      return const AuthResponse(
        token: 'mock-jwt-token-12345',
        refreshToken: 'mock-refresh-token-12345',
        type: 'Bearer',
        username: 'diego',
        expiresIn: 3600,
      );
    }
    throw Exception('Credenciales mock incorrectas');
  }

  @override
  Future<List<PendienteArticuloResponse>> obtenerPendientes(
    String token,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (token != 'mock-jwt-token-12345') {
      throw Exception('Token inválido');
    }

    return const [
      PendienteArticuloResponse(
        numeroConteo: 1,
        codigoQr: 'ACT-001',
        cantidadContada: 0,
        estado: 'PENDIENTE',
        idBodega: 'BOD-01',
        idArticulo: 101,
        idUsuario: 123,
      ),
      PendienteArticuloResponse(
        numeroConteo: 1,
        codigoQr: 'ACT-002',
        cantidadContada: 0,
        estado: 'PENDIENTE',
        idBodega: 'BOD-01',
        idArticulo: 102,
        idUsuario: 123,
      ),
    ];
  }

  @override
  Future<AuthResponse> refreshToken(String currentToken) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const AuthResponse(token: 'mock-jwt-token-refreshed');
  }
}
