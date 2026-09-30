/// Excepción tipada para errores de negocio en el módulo de Autenticación.
///
/// Diferencia errores de negocio (credenciales incorrectas, sesión expirada,
/// permisos insuficientes) de errores técnicos genéricos ([Exception]).
///
/// Separa el mensaje amigable de usuario ([message]) de los detalles
/// técnicos requeridos para depuración ([code], [technicalDetails], [statusCode], [endpoint]).
class AuthBusinessException implements Exception {
  final String message;
  final String? code;
  final String? technicalDetails;
  final int? statusCode;
  final String? endpoint;

  const AuthBusinessException(
    this.message, {
    this.code,
    this.technicalDetails,
    this.statusCode,
    this.endpoint,
  });

  @override
  String toString() => message;
}
