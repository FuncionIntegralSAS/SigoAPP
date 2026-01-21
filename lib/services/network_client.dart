import '../models/person_model.dart';
import 'dart:async';
import 'dart:math';

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

  final List<Map<String, dynamic>> _mockDatabase = [
    {
      'id': '1',
      'fullName': 'Juan Perez',
      'nationalId': '1018420001',
      'accountExists': false,
      'isActive': true,
      'creationDate': null,
      'createdByUserId': null,
    },
    {
      'id': '2',
      'fullName': 'Maria Lopez',
      'nationalId': '20203030',
      'accountExists': true,
      'isActive': true,
      'creationDate': '2023-10-01T10:30:00',
      'createdByUserId': 'admin_01',
    },
    {
      'id': '3',
      'fullName': 'Carlos Bloqueado',
      'nationalId': '99999',
      'accountExists': false,
      'isActive': false,
      'creationDate': null,
      'createdByUserId': null,
    },
  ];

  /// Simula GET /person/{nationalId}
  Future<Map<String, dynamic>?> getPerson(String nationalId) async {
    await _simulateNetworkDelay();
    _simulateRandomError();

    try {
      return _mockDatabase.firstWhere(
        (p) => p['nationalId'] == nationalId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Simula POST /create-account
  Future<Map<String, dynamic>> postCreateAccount({
    required String nationalId,
    required String creatorId,
  }) async {
    await _simulateNetworkDelay();
    
    // Buscar en la "DB" y actualizar
    int index = _mockDatabase.indexWhere((p) => p['nationalId'] == nationalId);
    
    if (index != -1) {
      _mockDatabase[index]['accountExists'] = true;
      _mockDatabase[index]['creationDate'] = DateTime.now().toIso8601String();
      _mockDatabase[index]['createdByUserId'] = creatorId;
      
      return _mockDatabase[index];
    } else {
      throw Exception("No se pudo encontrar la persona para crear la cuenta.");
    }
  }

  // --- Helpers de Simulación ---

  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(const Duration(milliseconds: 1500));
  }

  void _simulateRandomError() {
    // 5% de probabilidad de fallo de conexión
    if (Random().nextInt(100) < 5) {
      throw Exception("Error de conexión al servidor (Timeout)");
    }
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