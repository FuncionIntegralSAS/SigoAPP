import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../repositories/auth_repository.dart';
import '../models/auth_model.dart';
import '../models/physical_count_model.dart';
import '../utils/permission_utils.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  String? _cedula; // Para saber qué contador inició sesión
  String? _username;
  List<Permiso> _permisos = [];

  AuthProvider(this._repository) {
    _checkSavedSession();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;
  String? get currentCedula => _cedula;
  String? get currentToken => _token;
  String? get currentUsername => _username;
  List<Permiso> get permisos => _permisos;

  Future<void> _checkSavedSession() async {
    _token = await _storage.read(key: 'auth_token');
    _cedula = await _storage.read(key: 'auth_cedula');
    _username = await _storage.read(key: 'auth_username');
    
    final permisosStr = await _storage.read(key: 'auth_permissions');
    _permisos = PermissionUtils.parsePermissions(permisosStr);

    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = LoginRequest(username: username, password: password);
      final response = await _repository.login(request);

      _token = "Bearer ${response.token}";
      _username = response.username ?? username; // Si no viene en la respuesta, usamos el enviado
      _cedula = null; // No es un contador
      _permisos = response.permisos ?? [];

      // TODO: Remover esta salvedad antes del paso a producción
      if (_username == 'FPLPNACUA') {
        _permisos = AppPermission.values.map((e) => Permiso(forma: e.code)).toList();
      }

      await _storage.write(key: 'auth_token', value: _token);
      if (_username != null) {
        await _storage.write(key: 'auth_username', value: _username);
      }
      if (response.refreshToken != null) {
        await _storage.write(key: 'auth_refresh_token', value: response.refreshToken);
      }
      
      final permisosJson = PermissionUtils.encodePermissions(_permisos);
      await _storage.write(key: 'auth_permissions', value: permisosJson);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> mockLogin(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    if (username == 'operador@inventario.com' && password == '123456') {
      _token = "Bearer mock-token-operator";
      _username = "operador";
      _cedula = null;
      // TODO: Remover o revisar esta salvedad antes del paso a producción
      _permisos = AppPermission.values.map((e) => Permiso(forma: e.code)).toList();

      await _storage.write(key: 'auth_token', value: _token);
      await _storage.write(key: 'auth_username', value: _username);
      final permisosJson = PermissionUtils.encodePermissions(_permisos);
      await _storage.write(key: 'auth_permissions', value: permisosJson);

      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      _errorMessage = 'Credenciales inválidas. (Usa operador@inventario.com / 123456)';
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginContador(String cedula, String codigoTemporal) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = LoginContadorRequest(documento: cedula, codigoTemporal: codigoTemporal);
      final response = await _repository.loginContador(request);

      _token = "Bearer ${response.token}";
      _cedula = cedula;
      _username = response.username;
      _permisos = response.permisos ?? [];

      // TODO: Remover esta salvedad antes del paso a producción
      if (_username == 'FPLPNACUA') {
        _permisos = AppPermission.values.map((e) => Permiso(forma: e.code)).toList();
      }

      await _storage.write(key: 'auth_token', value: _token);
      await _storage.write(key: 'auth_cedula', value: _cedula);
      if (_username != null) {
        await _storage.write(key: 'auth_username', value: _username);
      }
      if (response.refreshToken != null) {
        await _storage.write(key: 'auth_refresh_token', value: response.refreshToken);
      }
      
      final permisosJson = PermissionUtils.encodePermissions(_permisos);
      await _storage.write(key: 'auth_permissions', value: permisosJson);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<List<PendienteArticuloResponse>> descargarPendientes() async {
    if (_token == null) throw Exception('No hay sesión iniciada');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pendientes = await _repository.obtenerPendientes(_token!);
      _isLoading = false;
      notifyListeners();
      return pendientes;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return [];
    }
  }

  Future<void> logout() async {
    _token = null;
    _cedula = null;
    _username = null;
    _permisos = [];
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'auth_cedula');
    await _storage.delete(key: 'auth_username');
    await _storage.delete(key: 'auth_refresh_token');
    await _storage.delete(key: 'auth_permissions');
    notifyListeners();
  }
}
