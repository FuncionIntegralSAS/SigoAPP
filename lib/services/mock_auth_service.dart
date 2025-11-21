import 'package:flutter/material.dart';
import '../models/user_model.dart';

// Este servicio simula un proveedor de autenticación (como Firebase Auth)
class MockAuthService {
  // ValueNotifier expone el usuario actual. Si es null, el usuario no está logueado.
  // Es la mejor manera de notificar a la UI sobre cambios de estado de sesión.
  final ValueNotifier<UserModel?> currentUser = ValueNotifier<UserModel?>(null);

  // Simulación de credenciales válidas
  static const String validUser = 'operador@inventario.com';
  static const String validPass = '123456';

  // Simulación de un usuario para devolver al iniciar sesión
  final UserModel _mockUser = UserModel(
    id: 'user-001-mock',
    name: 'Operador Principal',
    email: validUser,
  );

  // Constructor privado para Singleton
  MockAuthService._();
  static final MockAuthService _instance = MockAuthService._();
  static MockAuthService get instance => _instance;

  // Simula el inicio de sesión
  Future<bool> signIn(String email, String password) async {
    // Retraso para simular una llamada a la red
    await Future.delayed(const Duration(milliseconds: 1500)); 

    if (email == validUser && password == validPass) {
      // Éxito: establece el usuario y notifica a los listeners
      currentUser.value = _mockUser;
      return true;
    } else {
      // Falla: mantiene el usuario como null
      currentUser.value = null;
      return false;
    }
  }

  // Simula el cierre de sesión
  void signOut() {
    // Establece el usuario como null
    currentUser.value = null;
  }
}