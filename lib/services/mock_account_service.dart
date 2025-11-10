import '../models/person_model.dart';

class MockAccountService {
  // Simulación de la base de datos de Personas
  // Cédulas que ya existen y su estado.
  static final List<PersonModel> _mockPeople = [
    // 1. Persona con cuenta activa existente
    PersonModel(
      nationalId: '1018420001',
      fullName: 'Andrés Felipe Restrepo',
      accountExists: true,
      isActive: true,
      creationDate: DateTime.now().subtract(const Duration(days: 30)),
      createdByUserId: 'admin_user_001',
    ),
    // 2. Persona sin cuenta, pero activa en el sistema
    PersonModel(
      nationalId: '1018420002',
      fullName: 'Carolina Díaz Martínez',
      accountExists: false,
      isActive: true,
    ),
    // 3. Persona con cuenta inactiva (Validación de estado activo)
    PersonModel(
      nationalId: '1018420003',
      fullName: 'Ricardo Gaviria Loaiza',
      accountExists: true,
      isActive: false, // Inactivo
      creationDate: DateTime.now().subtract(const Duration(days: 100)),
      createdByUserId: 'system_user_999',
    ),
  ];

  // Simulación del usuario actualmente logueado para registrar la creación
  // En una app real, esto vendría del FirebaseAuth
  final String _currentMockUserId = 'user_flutter_mobile';

  // Obtiene el usuario que está "creando" la cuenta
  String getCurrentUserId() => _currentMockUserId;

  // 1. Búsqueda de persona por cédula
  PersonModel? searchPersonByNationalId(String nationalId) {
    // Buscar si el ID existe en la lista mock
    try {
      return _mockPeople.firstWhere(
        (p) => p.nationalId == nationalId,
      );
    } catch (e) {
      // Si no se encuentra, retornamos null
      return null;
    }
  }

  // 3. Permitir generar cuenta (Simulación de creación)
  PersonModel createAccount(PersonModel person) {
    // 5. & 6. Registrar usuario, fecha y hora de creación
    final newAccount = person.activateAccount(
      createdByUserId: _currentMockUserId,
      creationDate: DateTime.now(),
    );

    // En un entorno real, aquí se llamaría a la API/Base de Datos
    // Actualizamos el mock para simular la persistencia (esto es temporal)
    int index = _mockPeople.indexWhere((p) => p.nationalId == person.nationalId);
    if (index != -1) {
      _mockPeople[index] = newAccount;
    } else {
      _mockPeople.add(newAccount);
    }

    return newAccount;
  }
}