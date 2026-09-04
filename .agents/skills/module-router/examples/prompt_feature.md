# Ejemplo de Prompt: Nueva Funcionalidad (Feature)

Este archivo sirve de referencia al agente `module-router` para estructurar prompts de delegación cuando se solicita una nueva característica o pantalla en SigoAPP.

```markdown
<!-- MODULE-ROUTER-CONTEXT -->
## Contexto del Proyecto
SigoAPP es una aplicación Flutter de gestión administrativa empresarial.
- **Arquitectura**: Clean Architecture (Provider + Repository)
- **Backend**: Spring Boot (Java) + Oracle
- **Cliente HTTP**: Dio (instancia centralizada en AppConfig)

## Estado del Backend y Repositorios
- **Modo:** Híbrido. El contrato REST está definido pero el endpoint está en desarrollo en Spring Boot.
- **Endpoints disponibles:** `/api/v1/traspasos/crear` (definido). Usar `MockInventoryRepository` para desarrollo y pruebas locales con `Future.delayed(Duration(milliseconds: 600))`.

## Reglas Obligatorias y de Red
- Usar exclusivamente `AppConfig.createDio()` para peticiones HTTP.
- Toda llamada de red debe envolverse en `try/catch` en el Provider y transicionar a estados controlados (`IDLE`, `LOADING`, `SUCCESS`, `ERROR`).
- Mapear atributos del modelo estrictamente en español `lowerCamelCase` preservando los `@JsonKey` contra el JSON del backend.

## Módulo Afectado y Permisos
- **Módulo:** **Inventario** — Generación y registro de traspaso entre bodegas.
- **Permisos requeridos:** `agst` (Generar traspaso). Comprobar en `TransferFormProvider` o antes de navegar.

## Documentación Funcional Aplicable
- **Documento:** `.context/SigoAPP_Funcional_Inventario.md`
- **Reglas clave:** 
  1. No se permite traspaso entre la misma bodega de origen y destino.
  2. Todo activo debe haber sido verificado o contar con estado disponible antes de añadirlo a la solicitud.

## Archivos Involucrados
| Archivo | Ruta Relativa | Propósito | Líneas clave |
|---------|---------------|-----------|--------------|
| `TransferFormProvider` | `lib/providers/transfer_form_provider.dart` | Manejo del formulario de creación y validación de traspasos | L30-L110 |
| `InventoryRepository` | `lib/repositories/inventory_repository.dart` | Contrato abstracto del repositorio de inventarios | L15-L40 |
| `HttpInventoryRepository` | `lib/repositories/http_inventory_repository.dart` | Implementación con Dio para llamadas al backend | L20-L85 |
| `MockInventoryRepository` | `lib/repositories/mock_inventory_repository.dart` | Simulación con retardo de red para pruebas locales | L10-L60 |
| `InventoryScreen` | `lib/screens/inventory_screen.dart` | Pantalla de inicio del flujo de traspasos | L80-L150 |

## Tarea Solicitada
Implementar la acción `registrarTraspaso()` en `TransferFormProvider`, inyectando `InventoryRepository` y conectando el botón "Confirmar Traspaso" de `InventoryScreen` con el estado de carga y mensaje de éxito/error.

## Restricciones
- No ejecutar llamadas HTTP en el constructor de `TransferFormProvider`.
- No alterar las firmas existentes de `InventoryRepository` sin actualizar sus implementaciones HTTP y Mock.
- Al finalizar, proponer la actualización de `SigoAPP_Mapa_Modulos.md` y `SigoAPP_Funcional_Inventario.md` según AGENTS.md.

## Comandos de Verificación Sugeridos
- Análisis estático: `flutter analyze lib/providers/transfer_form_provider.dart`
- Pruebas unitarias: `flutter test test/providers/transfer_form_provider_test.dart`
```
