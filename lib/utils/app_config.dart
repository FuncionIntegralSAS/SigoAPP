import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sigo_app/utils/json_interceptor.dart';
import 'package:sigo_app/utils/auth_interceptor.dart';
import 'app_logger.dart';

/// Configuración centralizada de la aplicación.
///
/// Provee una instancia única de [Dio] configurada con la URL base
/// del backend, timeouts y los interceptores necesarios. Maneja la
/// persistencia dinámica del dominio.
class AppConfig {
  AppConfig._();

  static const _storage = FlutterSecureStorage();
  static const String _baseUrlKey = 'domain_base_url';
  
  static Dio? _dioInstance;
  static String? _storedUrl;

  /// Notificador para que la UI reaccione a los cambios de configuración del dominio
  static final ValueNotifier<bool> domainConfiguredNotifier = ValueNotifier(false);

  /// Inicializa la configuración cargando la URL base almacenada, si existe.
  static Future<void> init() async {
    try {
      _storedUrl = await _storage.read(key: _baseUrlKey);
      domainConfiguredNotifier.value = _storedUrl != null && _storedUrl!.isNotEmpty;
      AppLogger.i('AppConfig init: Dominio configurado = ${domainConfiguredNotifier.value}');
    } catch (e) {
      AppLogger.e('Error al leer de secure storage', e);
      _storedUrl = null;
      domainConfiguredNotifier.value = false;
    }
  }

  /// Obtiene la URL base actual (de storage o fallback a .env).
  static String get apiUrl {
    final url = _storedUrl ?? dotenv.env['API_URL'];
    if (url == null || url.isEmpty) {
      // No lanzamos error directamente, porque si no está, 
      // la UI debería manejarlo mostrando el Scanner.
      return '';
    }
    return url;
  }

  /// Crea y configura la instancia de [Dio] con la URL base actual.
  static Dio createDio() {
    _dioInstance = Dio(
      BaseOptions(
        baseUrl: apiUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Interceptor centralizado de autenticación para adjuntar token JWT
    _dioInstance!.interceptors.add(AuthInterceptor());

    // Interceptor para decodificar respuestas JSON con Content-Type incorrecto
    _dioInstance!.interceptors.add(JsonInterceptor());

    AppLogger.i('Dio configurado con baseUrl: $apiUrl');

    return _dioInstance!;
  }

  /// Actualiza la URL base de forma dinámica y la persiste
  static Future<void> updateBaseUrl(String newUrl) async {
    await _storage.write(key: _baseUrlKey, value: newUrl);
    _storedUrl = newUrl;
    if (_dioInstance != null) {
      _dioInstance!.options.baseUrl = newUrl;
      AppLogger.i('Dio baseUrl actualizado a: $newUrl');
    }
    domainConfiguredNotifier.value = true;
  }

  /// Borra la configuración del dominio actual
  static Future<void> clearBaseUrl() async {
    await _storage.delete(key: _baseUrlKey);
    _storedUrl = null;
    if (_dioInstance != null) {
      _dioInstance!.options.baseUrl = dotenv.env['API_URL'] ?? '';
    }
    domainConfiguredNotifier.value = false;
    AppLogger.i('Dominio limpiado de la configuración.');
  }
}
