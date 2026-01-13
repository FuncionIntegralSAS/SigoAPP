// Modelo de datos para una Persona y su estado de cuenta asociado
class PersonModel {
  final String nationalId; // Cédula o ID Nacional
  final String fullName;
  final bool accountExists;
  final bool isActive;
  final DateTime? creationDate;
  final String? createdByUserId; // El usuario que registró la cuenta

  PersonModel({
    required this.nationalId,
    required this.fullName,
    this.accountExists = false,
    this.isActive = true,
    this.creationDate,
    this.createdByUserId,
  });

  // Factory constructor para deserializar el mapa JSON de la API (Network Layer)
  factory PersonModel.fromJson(Map<String, dynamic> json) {
    // Manejo de fechas que pueden ser nulas o string ISO
    DateTime? date;
    if (json['creationDate'] is String) {
      date = DateTime.tryParse(json['creationDate'] as String);
    }
    
    return PersonModel(
      nationalId: json['nationalId'] as String,
      fullName: json['fullName'] as String,
      accountExists: (json['accountExists'] ?? false) as bool,
      isActive: (json['isActive'] ?? true) as bool,
      creationDate: date,
      createdByUserId: json['createdByUserId'] as String?,
    );
  }

  // Crea una nueva instancia de PersonModel con la cuenta activada
  PersonModel activateAccount({
    required String createdByUserId,
    required DateTime creationDate,
  }) {
    return PersonModel(
      nationalId: nationalId,
      fullName: fullName,
      accountExists: true,
      isActive: true,
      creationDate: creationDate,
      createdByUserId: createdByUserId,
    );
  }
}