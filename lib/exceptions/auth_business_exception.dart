/// Excepción tipada para errores de negocio en el módulo de Autenticación.
///
/// Diferencia errores de negocio (credenciales incorrectas, sesión expirada,
/// permisos insuficientes) de errores técnicos genéricos ([Exception]).
///
/// Uso recomendado: lanzar desde [HttpAuthRepository] y capturar en
/// [AuthProvider] para transformar en estados de UI descriptivos.
class AuthBusinessException implements Exception {
  final String message;

  const AuthBusinessException(this.message);

  @override
  String toString() => message;
}
