# Reglas y Mejores Prácticas: Capa de Red (Networking)

Este documento centraliza las convenciones y mejores prácticas implementadas en el proyecto **SigoAPP** (versión 1.9 y superior) referentes a la comunicación entre la aplicación Flutter y el backend (principalmente construido en Spring Boot con base de datos Oracle). 

Su propósito es ser una guía de consulta rápida para desarrolladores presentes y futuros.

## 1. Convenciones Generales de API
- **Formato:** Todas las peticiones (Payloads) y respuestas deben estructurarse en formato JSON utilizando notación `camelCase` de manera estricta.
- **RESTful Estricto:** Se deben preferir diseños de endpoint orientados a recursos (ej. `/api/v1/personal/buscar`), empleando adecuadamente los verbos de HTTP (`GET`, `POST`, `PUT`, `DELETE`).

## 2. Tipado y Modelos (`lib/models`)
- Jamás usar estructuras dinámicas (ej. `Map<String, dynamic>`) directamente en la UI o en los Providers. Todo mapeo debe realizarse mediante clases de Modelo fuertemente tipadas (usando `fromJson` y `toJson`).
- **Nomenclatura (Español lowerCamelCase):** Las propiedades de los modelos en Dart deben estar estrictamente en español y en formato `lowerCamelCase` (ej. `codigoActivo`, `idBodega`). Sin embargo, los contratos JSON con el backend **jamás** deben romperse. Para lograr esto, se debe usar obligatoriamente la anotación `@JsonKey(name: 'original_key')` (si se usa `json_serializable`) o mapear manualmente en las factorías `fromJson` y `toJson` con la llave exacta esperada por Spring Boot.
- **Optimización de Payloads:** Si un proceso complejo (como un Conteo Físico o un Traspaso) requiere enviar participantes o dependencias, enviar *únicamente* los IDs necesarios (ej. `nationalId`, `articleId`) en lugar de los objetos anidados completos para reducir el peso de las peticiones.

## 3. Implementación de Servicios (`lib/services`)
- **Inyección de Dependencias:** Todo servicio debe inyectar la dependencia encargada de red (`Dio` u `http`). Esto facilita mockear (simular) dicho cliente al momento de hacer pruebas automáticas.
- **Mapeo de Endpoints:** Centralizar las URLs o rutas en constantes para que la refactorización a futuro no obligue a modificar múltiples archivos.
- **Consultas tipo Búsqueda / Query Params:** Para solicitudes HTTP GET que impliquen la búsqueda de datos o la aplicación de múltiples filtros, usar parámetros preasignados con soporte de _null safety_ en Dart. No se debe generar un string masivo con los query.

_Mala práctica:_
```dart
Future<void> search(String queryConcatenado) { ... }
```
_Buena práctica:_
```dart
Future<void> searchPerson({String? nombre, String? apellido, String? cedula}) { ... }
```

## 4. Validaciones de Peticiones y Manejo de Errores
- **Validación Temprana (Fail Fast):** Validar la forma del request antes de realizar la llamada HTTP. Si hacen falta parámetros obligatorios *lógicos* (como la necesidad de enviar al menos uno de tres parámetros para búsqueda), lanzar excepción desde el Servicio y/o rechazar el proceso en el Provider antes de golpear el servidor, para así ahorrar uso de red.
- **Identificación de Errores HTTP:**
  - `400 Bad Request`: Representan errores de malformación, datos faltantes, o validaciones en donde intervino el usuario. Siempre extraer el string `message` de la API para mostrarlo al usuario.
  - `409 Conflict`: Casos puntuales en los que reglas lógicas colisionan (ej. bodega ya bloqueada, lote consumido). Siempre informar sobre el conflicto puntual.
  - `500 Internal Server Error`: Errores imprevisibles; la aplicación no debe crashear, sino proveer una advertencia general invirtiendo en logs internos, invitando a intentar más tarde.
- **Manejo Resiliente:** Toda llamada de red debe ir protegida mediante un bloque `try/catch`. Nunca derivar la excepción cruda a la UI. Capturarla en el Provider y transformarla a un estado `(state == PhysicalCountState.ERROR)` proveyendo un mensaje `errorMessage` humano y amigable.

## 5. Pruebas y Simulaciones (Mocks)
- **Mocks con Latencia:** Al construir un servicio falso (`MockService`), utilizar `Future.delayed` para simular asincronía y asegurar que los *Loading States* (`CircularProgressIndicator`) actúan correctamente en la UI.
- **Inyección de Errores Intencionales:** Para garantizar la solidez de los Providers, los Mocks deben incluir la bandera intencional de simulación de errores (`throw DioException()`), con el fin de correr pruebas unitarias validando la transición a estado ERROR de sus respectivos flujos.
