/// Excepción tipada para errores de negocio y de red en el módulo de Requisiciones.
///
/// Separa el mensaje amigable de usuario ([message]) de los detalles
/// técnicos requeridos para depuración ([technicalDetails], [statusCode], [endpoint]).
class RequisitionBusinessException implements Exception {
  final String message;
  final String? technicalDetails;
  final int? statusCode;
  final String? endpoint;

  const RequisitionBusinessException(
    this.message, {
    this.technicalDetails,
    this.statusCode,
    this.endpoint,
  });

  @override
  String toString() => message;
}
