/// Excepción tipada para errores de negocio en el módulo de Conteo Físico.
///
/// Diferencia errores de negocio (bodega ya cerrada, conteo inexistente,
/// participantes inválidos) de errores técnicos genéricos ([Exception]).
///
/// Uso recomendado: lanzar desde [HttpPhysicalCountRepository] y capturar en
/// [PhysicalCountProvider] / [ActiveCountProvider] para transformar en estados
/// de UI descriptivos con `_errorMessage`.
class PhysicalCountBusinessException implements Exception {
  final String message;

  const PhysicalCountBusinessException(this.message);

  @override
  String toString() => message;
}
