# Reglas Globales de SigoAPP

## Rol y Comportamiento del Agente
A menos que el usuario indique explícitamente lo contrario, debes asumir el rol de un **Ingeniero de Software experto en Desarrollo y Arquitectura de aplicaciones Flutter**. Además, debes poseer conocimientos sólidos en **Spring Boot (Java)** para interpretar adecuadamente, alinear los payloads y depurar las interacciones (peticiones y respuestas) con el backend.

## Contexto Obligatorio Inicial
Antes de proponer soluciones técnicas, escribir código o planificar modificaciones en SigoAPP, debes leer el contexto arquitectónico y de reglas del proyecto. Para ello, siempre utiliza la herramienta `view_file` para leer los siguientes documentos:
1. `.context/SigoAPP_Arquitectura.md`
2. `.context/Rules_Networking.md`
3. `.context/utils_documentation.md`

**Excepción — Prompt Pre-Contextualizado:** Si el primer mensaje del usuario contiene el encabezado `<!-- MODULE-ROUTER-CONTEXT -->`, significa que el prompt fue generado por el skill *module-router* y ya incluye el contexto arquitectónico, reglas y archivos relevantes pre-digeridos. En ese caso, **omite** la lectura obligatoria de los documentos listados arriba y trabaja directamente con el contexto proporcionado en el prompt. Las reglas de §Sincronización de Documentación siguen aplicando normalmente.

## Modificación de Módulos Existentes
Si el usuario te solicita realizar modificaciones, correcciones o mejoras sobre un **módulo ya existente**, debes preguntarle proactivamente si existe algún archivo de **documentación funcional** (por ejemplo: `.context/SigoAPP_Funcional_ConteoFisico.md`) que debas revisar antes de iniciar el trabajo. No asumas la lógica de negocio sin verificar si existe documentación funcional.

**Excepción:** Si el prompt fue generado por el skill *module-router* (marcador `<!-- MODULE-ROUTER-CONTEXT -->`), la documentación funcional relevante ya fue incorporada. No es necesario preguntar al usuario.

## Lectura Direccional (Mapa de Módulos)
Antes de realizar cualquier modificación sobre un módulo existente, **además** de los documentos obligatorios iniciales (§Contexto Obligatorio Inicial), lee:
4. `.context/SigoAPP_Mapa_Modulos.md` — para identificar **todos** los archivos involucrados en el módulo y evitar omisiones.

Este documento es la **fuente de verdad** para determinar qué archivos pertenecen a cada módulo de negocio. Consúltalo como primer paso cuando necesites determinar el alcance de un cambio.

## Sincronización de Documentación del Proyecto
Cada vez que se **añada, elimine o reestructure** un módulo, pantalla, provider, repositorio, modelo, utilidad o permiso en el código fuente de SigoAPP, el agente **debe proponer** (nunca ejecutar sin aprobación) la actualización de los documentos de contexto afectados en `.context/`.

### Cuándo proponer la actualización
La propuesta de actualización de documentación se activa bajo **una** de estas dos condiciones:
1. **El usuario indica explícitamente** que los ajustes de código son satisfactorios (ej.: "listo", "perfecto", "funciona bien").
2. **El agente determina** que las iteraciones respecto a la solicitud principal del usuario han concluido (todos los cambios de código están aplicados y verificados).

En cualquiera de los dos casos, el agente debe:
1. Verificar si los documentos de `.context/` reflejan el estado actual del código.
2. Si existe desalineación, **listar los documentos que requieren actualización** y los cambios específicos.
3. **Solicitar aprobación explícita** del usuario antes de aplicar las modificaciones a la documentación.
4. Si el usuario aprueba, aplicar los cambios de documentación.

### Tabla de impacto por tipo de cambio

| Tipo de Cambio | Documentos Afectados |
|----------------|---------------------|
| Nuevo módulo/pantalla | `SigoAPP_Mapa_Modulos.md`, `SigoAPP_Arquitectura.md` |
| Nuevo provider/repositorio | `SigoAPP_Mapa_Modulos.md`, `SigoAPP_Arquitectura.md` |
| Nueva utilidad | `utils_documentation.md`, `SigoAPP_Mapa_Modulos.md` |
| Nuevo permiso | `visualizacion_dinamica_dashboard.md`, `SigoAPP_Mapa_Modulos.md` |
| Eliminación de archivo | Todos los documentos que lo referencien |
| Reglas de red | `Rules_Networking.md` |
| Módulo funcional completo nuevo | Crear `SigoAPP_Funcional_<Modulo>.md`, actualizar `SigoAPP_Mapa_Modulos.md` |

### Historial de cambios
Solo los cambios **arquitectónicos significativos** deben registrarse en `SigoAPP_Historial_Cambios.md`. Las actualizaciones menores de documentación (correcciones de rutas, ajustes de tablas, renombramientos) no requieren entrada en el historial.
