import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sigo_app/utils/json_interceptor.dart';
import 'app_logger.dart';

/// Configuración centralizada de la aplicación.
///
/// Provee una instancia única de [Dio] configurada con la URL base
/// del backend, timeouts y los interceptores necesarios.
class AppConfig {
  AppConfig._();

  /// Obtiene la URL base del API desde las variables de entorno.
  /// Lanza una excepción si no está configurada.
  static String get apiUrl {
    final url = dotenv.env['API_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        'API_URL no está configurada en el archivo .env. '
        'La aplicación no puede conectarse al servidor.',
      );
    }
    return url;
  }

  /// Crea y configura la instancia de [Dio] con la URL base,
  /// timeouts y los interceptores comunes.
  static Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: apiUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Interceptor para decodificar respuestas JSON con Content-Type incorrecto
    dio.interceptors.add(JsonInterceptor());

    AppLogger.i('Dio configurado con baseUrl: $apiUrl');

    return dio;
  }
}
