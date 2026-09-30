import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/exceptions/auth_business_exception.dart';
import 'package:sigo_app/modules/auth/models/auth_model.dart';
import 'package:sigo_app/modules/physical_count/models/physical_count_model.dart';
import 'package:sigo_app/modules/auth/providers/auth_provider.dart';
import 'package:sigo_app/modules/auth/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  AuthResponse? loginResponse;
  AuthResponse? loginContadorResponse;
  bool shouldThrowLogin = false;
  Exception? exceptionToThrow;

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (shouldThrowLogin) throw Exception('Error en login');
    return loginResponse ??
        const AuthResponse(
          token: 'mock-admin-jwt-token',
          username: 'admin_user',
          documento: '1098765432',
          expiresIn: 3600,
        );
  }

  @override
  Future<AuthResponse> loginContador(LoginContadorRequest request) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return loginContadorResponse ??
        const AuthResponse(
          token: 'mock-contador-jwt-token',
          username: 'contador_user',
          expiresIn: 3600,
        );
  }

  @override
  Future<List<PendienteArticuloResponse>> obtenerPendientes(String token) async {
    return [];
  }

  @override
  Future<AuthResponse> refreshToken(String currentToken) async {
    return const AuthResponse(token: 'refreshed-token');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository fakeRepository;
  const storage = FlutterSecureStorage();

  setUp(() {
    fakeRepository = FakeAuthRepository();
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AuthProvider - Formalización del Tipo de Sesión', () {
    test('login() administrativo debe asignar isContador == false y conservar currentCedula', () async {
      final provider = AuthProvider(fakeRepository);
      await Future.delayed(const Duration(milliseconds: 10));

      final success = await provider.login('admin_user', 'password123');

      expect(success, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.isContador, isFalse);
      expect(provider.currentCedula, '1098765432');
      expect(provider.currentUsername, 'admin_user');

      // Verificar persistencia en SecureStorage
      expect(await storage.read(key: 'auth_is_contador'), 'false');
      expect(await storage.read(key: 'auth_cedula'), '1098765432');
      expect(await storage.read(key: 'auth_token'), 'Bearer mock-admin-jwt-token');
    });

    test('loginContador() debe asignar isContador == true y guardar cédula', () async {
      final provider = AuthProvider(fakeRepository);
      await Future.delayed(const Duration(milliseconds: 10));

      final success = await provider.loginContador('54321678', '4321');

      expect(success, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.isContador, isTrue);
      expect(provider.currentCedula, '54321678');
      expect(provider.currentUsername, 'contador_user');

      // Verificar persistencia en SecureStorage
      expect(await storage.read(key: 'auth_is_contador'), 'true');
      expect(await storage.read(key: 'auth_cedula'), '54321678');
      expect(await storage.read(key: 'auth_token'), 'Bearer mock-contador-jwt-token');
    });

    test('mockLogin() debe asignar isContador == false', () async {
      final provider = AuthProvider(fakeRepository);
      await Future.delayed(const Duration(milliseconds: 10));

      final success = await provider.mockLogin('operador@inventario.com', '123456');

      expect(success, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.isContador, isFalse);
      expect(await storage.read(key: 'auth_is_contador'), 'false');
    });

    test('_checkSavedSession() debe restaurar adecuadamente flag isContador == false en sesión administrativa', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'Bearer saved-admin-token',
        'auth_cedula': '1098765432',
        'auth_username': 'admin_user',
        'auth_is_contador': 'false',
      });

      final provider = AuthProvider(fakeRepository);
      await provider.checkSavedSession();

      expect(provider.isAuthenticated, isTrue);
      expect(provider.isContador, isFalse);
      expect(provider.currentCedula, '1098765432');
      expect(provider.currentUsername, 'admin_user');
    });

    test('_checkSavedSession() debe restaurar adecuadamente flag isContador == true en sesión de contador', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'Bearer saved-contador-token',
        'auth_cedula': '987654321',
        'auth_username': 'contador_user',
        'auth_is_contador': 'true',
      });

      final provider = AuthProvider(fakeRepository);
      await provider.checkSavedSession();

      expect(provider.isAuthenticated, isTrue);
      expect(provider.isContador, isTrue);
      expect(provider.currentCedula, '987654321');
      expect(provider.currentUsername, 'contador_user');
    });

    test('logout() debe reiniciar isContador a false y borrar la clave auth_is_contador', () async {
      final provider = AuthProvider(fakeRepository);
      await Future.delayed(const Duration(milliseconds: 10));

      // Iniciar sesión como contador
      await provider.loginContador('54321678', '4321');
      expect(provider.isContador, isTrue);
      expect(await storage.read(key: 'auth_is_contador'), 'true');

      // Cerrar sesión
      await provider.logout();

      expect(provider.isAuthenticated, isFalse);
      expect(provider.isContador, isFalse);
      expect(provider.currentCedula, isNull);
      expect(provider.currentToken, isNull);
      expect(provider.currentUsername, isNull);

      // Verificar que auth_is_contador y credenciales fueron eliminadas
      expect(await storage.read(key: 'auth_is_contador'), isNull);
      expect(await storage.read(key: 'auth_token'), isNull);
      expect(await storage.read(key: 'auth_cedula'), isNull);
    });
  });

  group('AuthProvider - Manejo de Errores y AuthBusinessException', () {
    test('login() ante AuthBusinessException almacena errorMessage limpio y lastAuthException', () async {
      const expectedException = AuthBusinessException(
        'Usuario o contraseña incorrectos',
        code: 'SIGAPP_401',
        statusCode: 400,
        endpoint: 'POST /api/v1/auth/login',
        technicalDetails: 'Endpoint: POST /api/v1/auth/login\nCódigo HTTP: 400\nCódigo de Negocio: SIGAPP_401',
      );
      fakeRepository.exceptionToThrow = expectedException;

      final provider = AuthProvider(fakeRepository);
      await Future.delayed(const Duration(milliseconds: 10));

      final success = await provider.login('usuario_invalido', 'clave_erronea');

      expect(success, isFalse);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.errorMessage, 'Usuario o contraseña incorrectos');
      expect(provider.lastAuthException, isNotNull);
      expect(provider.lastAuthException!.code, 'SIGAPP_401');
      expect(provider.lastAuthException!.statusCode, 400);
      expect(provider.lastAuthException!.endpoint, 'POST /api/v1/auth/login');
      expect(provider.lastAuthException!.technicalDetails, contains('SIGAPP_401'));
    });

    test('loginContador() ante AuthBusinessException con código SIGAPP_407 almacena mensaje de bloqueo', () async {
      const expectedException = AuthBusinessException(
        'Usuario bloqueado',
        code: 'SIGAPP_407',
        statusCode: 400,
        endpoint: 'POST /api/v1/auth/login/contador',
      );
      fakeRepository.exceptionToThrow = expectedException;

      final provider = AuthProvider(fakeRepository);
      await Future.delayed(const Duration(milliseconds: 10));

      final success = await provider.loginContador('12345678', '9999');

      expect(success, isFalse);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.errorMessage, 'Usuario bloqueado');
      expect(provider.lastAuthException, isNotNull);
      expect(provider.lastAuthException!.code, 'SIGAPP_407');
    });

    test('login() ante excepción técnica no tipada limpia errorMessage y deja lastAuthException nulo', () async {
      fakeRepository.exceptionToThrow = Exception('Fallo inesperado del sistema');

      final provider = AuthProvider(fakeRepository);
      await Future.delayed(const Duration(milliseconds: 10));

      final success = await provider.login('user', 'pass');

      expect(success, isFalse);
      expect(provider.errorMessage, 'Fallo inesperado del sistema');
      expect(provider.lastAuthException, isNull);
    });
  });
}
