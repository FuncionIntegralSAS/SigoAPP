import 'package:dio/dio.dart';
import 'package:sigo_app/exceptions/auth_business_exception.dart';
import 'package:sigo_app/modules/auth/models/auth_model.dart';
import 'package:sigo_app/modules/physical_count/models/physical_count_model.dart';
import 'package:sigo_app/modules/auth/repositories/auth_repository.dart';
import 'package:sigo_app/utils/app_logger.dart';

class HttpAuthRepository implements AuthRepository {
  final Dio _dio;

  HttpAuthRepository(this._dio);

  AuthBusinessException _mapDioException(
    DioException e,
    String endpoint,
    String defaultUserMsg,
  ) {
    AppLogger.e('Error en $endpoint', e);
    final statusCode = e.response?.statusCode;

    String? serverMsg;
    String? serverCode;

    if (e.response?.data is Map) {
      final map = e.response!.data as Map;
      serverMsg = (map['message'] ?? map['msg'] ?? map['error'])?.toString();
      serverCode = map['code']?.toString();
    } else if (e.response?.data is String) {
      final str = e.response!.data as String;
      if (str.trim().isNotEmpty && !str.trim().startsWith('<')) {
        serverMsg = str.trim();
      }
    }

    final String userMsg;
    if (serverMsg != null && serverMsg.trim().isNotEmpty) {
      userMsg = serverMsg.trim();
    } else if (statusCode == 401 || statusCode == 403) {
      userMsg = 'Credenciales incorrectas o acceso no autorizado.';
    } else if (statusCode == 500) {
      userMsg = 'Error interno en el servidor al intentar autenticar.';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      userMsg =
          'Error de conexión con el servidor. Verifique su red o la configuración del dominio.';
    } else {
      userMsg = defaultUserMsg;
    }

    final techDetails = [
      'Endpoint: $endpoint',
      if (statusCode != null) 'Código HTTP: $statusCode',
      if (serverCode != null && serverCode.trim().isNotEmpty)
        'Código de Negocio: $serverCode',
      if (serverMsg != null && serverMsg.trim().isNotEmpty)
        'Respuesta del servidor:\n$serverMsg',
      if (e.message != null && e.message!.isNotEmpty)
        'Detalle Dio: ${e.message}',
    ].join('\n');

    return AuthBusinessException(
      userMsg,
      code: serverCode,
      technicalDetails: techDetails,
      statusCode: statusCode,
      endpoint: endpoint,
    );
  }

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    const endpoint = 'POST /api/v1/auth/login';
    try {
      final payload = request.toJson();

      final response = await _dio.post('/api/v1/auth/login', data: payload);
      if (response.statusCode == 200 && response.data != null) {
        return AuthResponse.fromJson(response.data);
      }
      throw const AuthBusinessException('Respuesta inesperada al iniciar sesión');
    } on DioException catch (e) {
      throw _mapDioException(e, endpoint, 'Error al iniciar sesión.');
    } catch (e) {
      if (e is AuthBusinessException) rethrow;
      throw Exception('Error desconocido: $e');
    }
  }

  @override
  Future<AuthResponse> loginContador(LoginContadorRequest request) async {
    const endpoint = 'POST /api/v1/auth/login/contador';
    try {
      final response = await _dio.post(
        '/api/v1/auth/login/contador',
        data: request.toJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
        return AuthResponse.fromJson(response.data);
      }
      throw const AuthBusinessException('Respuesta inesperada al iniciar sesión');
    } on DioException catch (e) {
      throw _mapDioException(e, endpoint, 'Error al iniciar sesión como contador.');
    } catch (e) {
      if (e is AuthBusinessException) rethrow;
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
      final statusCode = e.response?.statusCode;

      if (statusCode == 401 || statusCode == 402 || statusCode == 403) {
        throw const AuthBusinessException(
          'Tu sesión ha expirado o el token es inválido. Por favor, vuelve a iniciar sesión.',
        );
      }
      throw Exception(
        'Error al descargar pendientes: ${e.message ?? 'sin detalle'}',
      );
    } catch (e) {
      if (e is AuthBusinessException) rethrow;
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
