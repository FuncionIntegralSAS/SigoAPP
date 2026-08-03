import 'package:dio/dio.dart';
import '../models/auth_model.dart';
import '../models/physical_count_model.dart';
import 'auth_repository.dart';

class HttpAuthRepository implements AuthRepository {
  final Dio _dio;

  HttpAuthRepository(this._dio);

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final payload = request.toJson();

      final response = await _dio.post('/login', data: payload);
      if (response.statusCode == 200 && response.data != null) {
        return AuthResponse.fromJson(response.data);
      }
      throw Exception('Respuesta inesperada al iniciar sesión');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Credenciales incorrectas');
      }
      throw Exception(
        'Error de red al intentar iniciar sesión: ${e.message ?? 'sin detalle'}',
      );
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  @override
  Future<AuthResponse> loginContador(LoginContadorRequest request) async {
    try {
      final response = await _dio.post(
        '/login/contador',
        data: request.toJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
        return AuthResponse.fromJson(response.data);
      }
      throw Exception('Respuesta inesperada al iniciar sesión');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Credenciales incorrectas');
      }
      throw Exception(
        'Error de red al intentar iniciar sesión: ${e.message ?? 'sin detalle'}',
      );
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  @override
  Future<List<PendienteArticuloResponse>> obtenerPendientes(
    String token,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/conteo-fisico/pendientes',
        options: Options(headers: {'Authorization': token}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => PendienteArticuloResponse.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        'Error al descargar pendientes: ${e.message ?? 'sin detalle'}',
      );
    } catch (e) {
      throw Exception('Error procesando respuesta: $e');
    }
  }

  @override
  Future<AuthResponse> refreshToken(String currentToken) async {
    try {
      final response = await _dio.post(
        '/api/v1/refresh',
        options: Options(headers: {'Authorization': currentToken}),
      );
      if (response.statusCode == 200 && response.data != null) {
        return AuthResponse.fromJson(response.data);
      }
      throw Exception('Fallo al refrescar sesión');
    } catch (_) {
      throw Exception('Error al refrescar token');
    }
  }
}
