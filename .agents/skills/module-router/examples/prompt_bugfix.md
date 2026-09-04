# Ejemplo de Prompt: Corrección de Error (Bugfix)

Este archivo sirve de referencia para estructurar prompts cuando se deba corregir una falla, excepción no controlada o regresión en SigoAPP.

```markdown
<!-- MODULE-ROUTER-CONTEXT -->
## Contexto del Proyecto
SigoAPP es una aplicación Flutter de gestión administrativa empresarial.
- **Arquitectura**: Clean Architecture (Provider + Repository)
- **Backend**: Spring Boot (Java) + Oracle
- **Cliente HTTP**: Dio (instancia centralizada en AppConfig)

## Estado del Backend y Repositorios
- **Modo:** HTTP Real.
- **Endpoints disponibles:** `/api/v1/activos/geolocalizacion` (retorna `204 No Content` si el activo aún no tiene coordenadas registradas).

## Reglas Obligatorias y de Red
- Validar explícitamente `response.statusCode == 204` o `response.data == null` retornando `null` o valor por defecto sin intentar deserializar con `fromJson` para evitar `TypeError: null is not a subtype of Map<String, dynamic>`.
- Manejar la excepción en el Provider emitiendo mensaje humano amigable.

## Módulo Afectado y Permisos
- **Módulo:** **Inventario / Geolocalización** — Verificación de coordenadas GPS de activos.
- **Permisos requeridos:** `avac` (Verificación de activos).

## Documentación Funcional Aplicable
- **Documento:** `.context/SigoAPP_Funcional_Inventario.md`
- **Reglas clave:** Si el activo no posee geolocalización previa, la app debe solicitar la captura de coordenadas actuales del dispositivo en lugar de fallar.

## Archivos Involucrados
| Archivo | Ruta Relativa | Propósito | Líneas clave |
|---------|---------------|-----------|--------------|
| `HttpGeolocationRepository` | `lib/repositories/http_geolocation_repository.dart` | Cliente Dio para consulta y guardado de coordenadas | L40-L75 |
| `GeolocationProvider` | `lib/providers/geolocation_provider.dart` | Estado de captura y validación geográfica | L60-L105 |
| `GeolocationModel` | `lib/models/geolocation_model.dart` | Modelo con campos latitud y longitud | L10-L35 |

## Tarea Solicitada
Corregir la excepción `TypeError` producida al consultar un activo nuevo que responde con HTTP 204 en `HttpGeolocationRepository.obtenerGeolocalizacion()`. Asegurar que devuelva `null` de forma segura y que `GeolocationProvider` maneje este estado permitiendo una nueva captura de coordenadas sin marcar error en pantalla.

## Restricciones
- No relajar el tipado estricto a tipos dinámicos en los modelos.
- No alterar la firma del repositorio si se puede resolver con tipo retornable nullable `Future<GeolocationModel?>`.

## Comandos de Verificación Sugeridos
- Pruebas unitarias: `flutter test test/repositories/http_geolocation_repository_test.dart test/providers/geolocation_provider_test.dart`
- Análisis: `flutter analyze lib/repositories/http_geolocation_repository.dart`
```
