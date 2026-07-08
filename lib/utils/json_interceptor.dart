import 'dart:convert';
import 'package:dio/dio.dart';

/// Un interceptor para Dio que intercepta las respuestas de red.
/// Si el backend retorna un string JSON pero con un Content-Type incorrecto 
/// (ej. text/plain), Dio no lo decodifica automáticamente.
/// Este interceptor intenta parsear los Strings a JSON para evitar el error:
/// "type 'String' is not a subtype of type 'List<dynamic>' o 'Map'".
class JsonInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is String) {
      final String dataString = response.data as String;
      
      // Verificamos si parece un JSON válido antes de decodificar
      final trimmed = dataString.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        try {
          // Intentar decodificar el string a JSON
          response.data = jsonDecode(trimmed);
        } catch (e) {
          // Si falla, dejamos la data original
          print('JsonInterceptor falló al decodificar: $e');
        }
      }
    }
    
    super.onResponse(response, handler);
  }
}
