import '../models/person_model.dart';
import 'network_client.dart'; // Importamos la nueva Capa de Red

/// **MOCK ACCOUNT SERVICE (Capa de Negocio / Repositorio)**
///
/// Esta clase ya no contiene la base de datos simulada.
/// Ahora utiliza el NetworkClient para realizar peticiones (simuladas o reales),
/// separando la lógica de negocio (qué hacer con los datos) de la lógica de red (cómo obtener los datos).
class MockAccountService {
  // Instancia del cliente de red (el monolítico)
  final NetworkClient _networkClient = NetworkClient();

  // Simulación del usuario actualmente logueado para registrar la creación
  // En una app real, esto vendría del FirebaseAuth
  final String _currentMockUserId = 'user_flutter_mobile';

  // Obtiene el usuario que está "creando" la cuenta
  String getCurrentUserId() => _currentMockUserId;

  // 1. Búsqueda de persona por cédula (ahora a través de la red)
  Future<PersonModel?> searchPersonByNationalId(String nationalId) async {
    // Llama al cliente de red para obtener el "JSON"
    final jsonResponse = await _networkClient.getPerson(nationalId);

    if (jsonResponse == null) {
      return null;
    }

    // Deserializa el "JSON" (Map) en un objeto Dart
    return PersonModel.fromJson(jsonResponse);
  }

  // 3. Permitir generar cuenta (Simulación de creación a través de la red)
  Future<PersonModel> createAccount(PersonModel person) async {
    // 5. & 6. La Capa de Negocio proporciona los datos que la red necesita
    final jsonResponse = await _networkClient.postCreateAccount(
      nationalId: person.nationalId,
      creatorId: _currentMockUserId,
    );

    // Deserializa la respuesta de la red
    return PersonModel.fromJson(jsonResponse);
  }
}