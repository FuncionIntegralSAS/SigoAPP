/// Resultado de búsqueda de empleado usado por [CatalogRepository.findEmployee].
///
/// Encapsula los datos mínimos requeridos por [TransferFormProvider]:
/// - [name]: nombre del empleado para mostrarlo en la UI.
/// - [divisionId]: código de división para la carga en cascada de bodegas.
class EmployeeResult {
  final String name;
  final String? divisionId;

  const EmployeeResult({
    required this.name,
    this.divisionId,
  });

  factory EmployeeResult.fromJson(Map<String, dynamic> json) {
    final rawName =
        json['persnomb'] ??
        json['nombre'] ??
        json['fullName'] ??
        json['name'] ??
        '';
    final rawApel =
        json['persapel'] ?? json['apellido'] ?? json['lastName'] ?? '';
    final fullName =
        rawApel.toString().isNotEmpty
            ? '${rawName.toString()} ${rawApel.toString()}'.trim()
            : rawName.toString();
    final rawDivi =
        json['persdivi'] ??
        json['division'] ??
        json['divisionId'] ??
        json['PERSDIVI'];

    return EmployeeResult(
      name: fullName,
      divisionId: rawDivi?.toString(),
    );
  }
}
