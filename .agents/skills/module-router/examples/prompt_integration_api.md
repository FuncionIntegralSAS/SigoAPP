# Ejemplo de Prompt: Integración de API (Backend Spring Boot)

Este archivo sirve de referencia para estructurar prompts de delegación cuando se conecta un nuevo endpoint procedente del backend Spring Boot.

```markdown
<!-- MODULE-ROUTER-CONTEXT -->
## Contexto del Proyecto
SigoAPP es una aplicación Flutter de gestión administrativa empresarial.
- **Arquitectura**: Clean Architecture (Provider + Repository)
- **Backend**: Spring Boot (Java) + Oracle
- **Cliente HTTP**: Dio (instancia centralizada en AppConfig)

## Estado del Backend y Repositorios
- **Modo:** HTTP Real.
- **Endpoints disponibles:** `POST /api/v1/inventario/traspasos/entregar` y `POST /api/v1/inventario/traspasos/recibir`. Ambos reciben `TraspasoEntregaRequest` en JSON y requieren cabecera `Authorization: Bearer <token>`.

## Reglas Obligatorias y de Red
- El `AuthInterceptor` inyecta automáticamente el token Bearer para rutas no públicas (`Rules_Networking.md §5`).
- Todo modelo de payload debe crearse en `lib/models/` fuertemente tipado con factorías `fromJson` y `toJson`.
- Nombres de atributos en Dart en español `lowerCamelCase` mapeados a las claves exactas de Spring Boot con `@JsonKey` o mapeo manual.

## Módulo Afectado y Permisos
- **Módulo:** **Inventario / Traspasos** — Confirmación de entrega y recepción con firma digital.
- **Permisos requeridos:** `aein` (Entrega/Recepción de inventario) o usuario autenticado según la etapa.

## Documentación Funcional Aplicable
- **Documento:** `.context/SigoAPP_Funcional_Inventario.md`
- **Reglas clave:** 
  1. La entrega requiere captura obligatoria de firma digital y cédula del transportador/receptor.
  2. La recepción valida que la cantidad de ítems recibidos coincida con los despachados antes de cerrar el traspaso.

## Archivos Involucrados
| Archivo | Ruta Relativa | Propósito | Líneas clave |
|---------|---------------|-----------|--------------|
| `InventoryRepository` | `lib/repositories/inventory_repository.dart` | Métodos `entregarTraspaso()` y `recibirTraspaso()` | L25-L60 |
| `HttpInventoryRepository` | `lib/repositories/http_inventory_repository.dart` | Implementación HTTP con Dio y manejo de errores 400/500 | L45-L120 |
| `InventoryProvider` | `lib/providers/inventory_provider.dart` | Orquestación de estado, loading y confirmaciones UI | L70-L160 |
| `TransferDeliveryScreen` | `lib/screens/transfer_delivery_screen.dart` | Pantalla donde el usuario final firma y confirma | L90-L210 |

## Tarea Solicitada
Integrar el contrato de entrega y recepción en `HttpInventoryRepository`, conectar los métodos en `InventoryProvider` y asegurar que la pantalla `TransferDeliveryScreen` envíe el payload adecuado al servidor mostrando indicador de progreso y captura de errores HTTP 400 (Bad Request).

## Restricciones
- No enviar objetos anidados masivos; enviar únicamente identificadores requeridos según Rules_Networking.md §2.
- Al terminar, actualizar `.context/SigoAPP_Mapa_Modulos.md` y `.context/Rules_Networking.md` si se agregaron nuevas rutas.

## Comandos de Verificación Sugeridos
- Pruebas unitarias: `flutter test test/repositories/http_inventory_repository_test.dart test/providers/inventory_provider_test.dart`
- Linter: `flutter analyze lib/repositories/http_inventory_repository.dart`
```
