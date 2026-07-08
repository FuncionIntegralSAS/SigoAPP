// Modelo de datos para una Persona y su estado de cuenta asociado
class PersonalModel {
  final String perscodi; // Cédula o ID Nacional
  final String persnomb;
  final String persapel;
  final String perscoel;
  final String persdivi;
  final String persesta;

  PersonalModel({
    required this.perscodi,
    required this.persnomb,
    required this.persapel,
    required this.perscoel,
    required this.persdivi,
    required this.persesta,
  });

  // Factory constructor para deserializar el mapa JSON de la API (Network Layer)
  factory PersonalModel.fromJson(Map<String, dynamic> json) {
    final rawCodi = json['cedula'] ?? json['perscodi'] ?? json['PERSCODI'] ?? json['persCodi'] ?? json['nationalId'] ?? json['id'];
    final rawNomb = json['nombre'] ?? json['persnomb'] ?? json['PERSNOMB'] ?? json['persNomb'] ?? json['fullName'] ?? json['name'] ?? '';
    final rawApel = json['apellido'] ?? json['persapel'] ?? json['PERSAPEL'] ?? json['persApel'] ?? json['lastName'] ?? '';
    final rawCoel = json['correo'] ?? json['perscoel'] ?? json['PERSCOEL'] ?? json['persCoel'] ?? json['email'] ?? '';
    final rawDivi = json['division'] ?? json['persdivi'] ?? json['PERSDIVI'] ?? json['persDivi'] ?? '';
    final rawEsta = json['estado'] ?? json['persesta'] ?? json['PERSESTA'] ?? json['persEsta'] ?? '';

    return PersonalModel(
      perscodi: rawCodi?.toString() ?? '0',
      persnomb: rawNomb.toString(),
      persapel: rawApel.toString(),
      perscoel: rawCoel.toString(),
      persdivi: rawDivi.toString(),
      persesta: rawEsta.toString(),
    );
  }

  // Crea una nueva instancia de PersonModel con la cuenta activada
  PersonalModel activateAccount({
    required String createdByUserId,
    required DateTime creationDate,
  }) {
    return PersonalModel(
      perscodi: perscodi,
      persnomb: persnomb,
      persapel: persapel,
      perscoel: perscoel,
      persdivi: persdivi,
      persesta: persesta,
    );
  }
}
