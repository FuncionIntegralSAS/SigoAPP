/// Resultado de búsqueda de empleado usado por [CatalogRepository.findEmployee].
///
/// Encapsula los datos mínimos requeridos por [TransferFormProvider]:
/// - [name]: nombre del empleado para mostrarlo en la UI.
/// - [divisionId]: código de división para la carga en cascada de bodegas.
class EmployeeResult {
  final String nombre;
  final String? divisionId;
  final int? personaId;
  final String? cedula;
  final String? correo;

  const EmployeeResult({
    required this.nombre,
    this.divisionId,
    this.personaId,
    this.cedula,
    this.correo,
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

    final rawCedula = json['cedula'] ?? json['perscodi'] ?? json['persCodi'] ?? json['nationalId'];
    final rawId = json['id'] ?? json['persidre'] ?? rawCedula;
    final personaId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    return EmployeeResult(
      nombre: fullName,
      divisionId: rawDivi?.toString(),
      personaId: personaId,
      cedula: rawCedula?.toString(),
      correo: (json['correo'] ?? json['perscoel'] ?? json['email'])?.toString(),
    );
  }
}
