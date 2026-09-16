/// Excepción tipada para errores de negocio y comunicación en el catálogo de SigoAPP.
///
/// Separa el mensaje amigable para el usuario final ([userMessage])
/// de los detalles técnicos requeridos para depuración por el desarrollador
/// ([technicalDetails], [statusCode], [endpoint]).
class CatalogBusinessException implements Exception {
  final String userMessage;
  final String? technicalDetails;
  final int? statusCode;
  final String? endpoint;

  const CatalogBusinessException(
    this.userMessage, {
    this.technicalDetails,
    this.statusCode,
    this.endpoint,
  });

  @override
  String toString() => userMessage;
}
