import '../models/person_model.dart';

/// **CLIENTE DE RED (Simulado)**
/// Maneja la comunicación con la "API" para Personas y Activos.
class NetworkClient {
  // Singleton instance
  static final NetworkClient _instance = NetworkClient._internal();
  factory NetworkClient() => _instance;
  NetworkClient._internal();

  // Simulación de la base de datos de Personas
  static final List<PersonModel> _mockPeople = [
    PersonModel(
      nationalId: '1018420001',
      fullName: 'Andrés Felipe Restrepo',
      accountExists: true,
      isActive: true,
      creationDate: DateTime.now().subtract(const Duration(days: 30)),
      createdByUserId: 'admin_user_001',
    ),
    PersonModel(
      nationalId: '1018420002',
      fullName: 'Carolina Díaz Martínez',
      accountExists: false,
      isActive: true,
    ),
  ];

  /// Simula una llamada GET para buscar una persona por ID.
  Future<Map<String, dynamic>?> getPerson(String nationalId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final person = _mockPeople.firstWhere(
        (p) => p.nationalId == nationalId,
      );
      return {
        'nationalId': person.nationalId,
        'fullName': person.fullName,
        'accountExists': person.accountExists,
        'isActive': person.isActive,
        'creationDate': person.creationDate?.toIso8601String(),
        'createdByUserId': person.createdByUserId,
      };
    } catch (e) {
      return null;
    }
  }

  /// Simula una llamada POST para crear o actualizar la cuenta de una persona.
  Future<Map<String, dynamic>> postCreateAccount({
    required String nationalId,
    required String creatorId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    int index = _mockPeople.indexWhere((p) => p.nationalId == nationalId);
    if (index == -1) {
      throw Exception('Error 404: La persona no existe.');
    }

    final person = _mockPeople[index];
    final newAccount = person.activateAccount(
      createdByUserId: creatorId,
      creationDate: DateTime.now(),
    );

    _mockPeople[index] = newAccount;

    return {
      'nationalId': newAccount.nationalId,
      'fullName': newAccount.fullName,
      'accountExists': newAccount.accountExists,
      'isActive': newAccount.isActive,
      'creationDate': newAccount.creationDate!.toIso8601String(),
      'createdByUserId': newAccount.createdByUserId,
    };
  }

  /// **NUEVO MÉTODO: Simulación de POST para crear un Activo en Inventario**
  /// Recibe un mapa de datos y devuelve el objeto creado con un ID generado por el "servidor".
  Future<Map<String, dynamic>> postCreateArticle(Map<String, dynamic> articleData) async {
    // Simula latencia de red al procesar el guardado
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // Simulación de generación de ID único en el servidor
    final String newId = 'A${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    
    // El servidor retorna el objeto completo con su nuevo ID
    final Map<String, dynamic> response = {
      ...articleData,
      'id': newId,
    };

    return response;
  }
}