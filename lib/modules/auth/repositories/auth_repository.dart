import 'package:sigo_app/modules/auth/models/auth_model.dart';
import 'package:sigo_app/modules/physical_count/models/physical_count_model.dart';

abstract class AuthRepository {
  /// Realiza el login principal con usuario y contraseña.
  Future<AuthResponse> login(LoginRequest request);

  /// Realiza el login del contador con cédula y código temporal.
  Future<AuthResponse> loginContador(LoginContadorRequest request);

  /// Obtiene la lista de artículos pendientes de contar para el usuario autenticado.
  Future<List<PendienteArticuloResponse>> obtenerPendientes(String token);

  /// Refresca el token.
  Future<AuthResponse> refreshToken(String currentToken);
}
