import 'package:dio/dio.dart';
import '../models/auth_model.dart';
import '../models/physical_count_model.dart';
import 'auth_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HttpAuthRepository implements AuthRepository {
  late final Dio _dio;

  HttpAuthRepository() {
    final baseUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:8080/api/v1';
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
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
      throw Exception('Error de red al intentar iniciar sesión: \${e.message}');
    } catch (e) {
      throw Exception('Error desconocido: \$e');
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
      throw Exception('Error al descargar pendientes: ${e.message}');
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
