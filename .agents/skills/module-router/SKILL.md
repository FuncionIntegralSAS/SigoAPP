---
name: module-router
description: Genera prompts autocontenidos y pre-contextualizados para delegar tareas entre módulos o ventanas de contexto en SigoAPP. Úsalo cuando el usuario pida generar prompts para otros agentes, delegar una funcionalidad o bugfix, preparar instrucciones para otra sesión o enrutar tareas en SigoAPP.
---

# Skill: Agente Direccionador de Módulos (Module Router)

## Propósito
Este skill genera **prompts completos listos para copiar/pegar** en otra ventana de contexto o agente de IA. Los prompts incluyen rutas de archivos (con enlaces o relativas normalizadas), rangos de líneas relevantes, contexto de negocio funcional, estado de backend/mocks, comandos de verificación y reglas del proyecto, permitiendo que el agente receptor ejecute la tarea inmediatamente sin lecturas exploratorias redundantes.

## Cuándo se activa
- El usuario solicita explícitamente generar un prompt para otro agente.
- El usuario necesita delegar una tarea a otra ventana de contexto.
- El usuario usa expresiones como: "genera un prompt para...", "prepara las instrucciones para...", "necesito pasarle esto a otro agente", "enruta esta tarea".

## Recursos y Herramientas Auxiliares
- **Script CLI:** [query_module.dart](./scripts/query_module.dart) — Herramienta rápida para consultar módulos y archivos sin leer manualmente todo el mapa. Ejecutar con: `dart run .agents/skills/module-router/scripts/query_module.dart <modulo|permiso>`
- **Matriz de Permisos:** [permisos_modulos.md](./references/permisos_modulos.md) — Tabla de correspondencia rápida entre permisos, pantallas y providers.
- **Plantillas de Referencia:** Ver ejemplos en [examples/](./examples/) para tareas tipo `feature`, `bugfix` o `api-integration`.

## Flujo de ejecución

### Paso 1: Identificar el módulo afectado
Determina el módulo de negocio consultando `.context/SigoAPP_Mapa_Modulos.md` o ejecutando el script auxiliar:
```bash
dart run .agents/skills/module-router/scripts/query_module.dart <termino_busqueda>
```
Identifica:
- A qué **módulo de negocio** pertenece la tarea (Inventario, Conteo Físico, Requisiciones, etc.)
- Todos los **archivos involucrados** (screens, tabs, providers, repositorios, modelos, widgets, utilidades)
- Los **providers y estados** relevantes
- Los **permisos** asociados

### Paso 2: Recopilar contexto técnico y funcional
Según el tipo de tarea, revisa los documentos adicionales requeridos:

| Si la tarea involucra... | Documento a consultar |
|--------------------------|-----------------------|
| Crear/modificar endpoints o peticiones HTTP | `.context/Rules_Networking.md` |
| Modificar utilidades compartidas | `.context/utils_documentation.md` |
| Cambiar permisos o visibilidad en dashboard | `.context/visualizacion_dinamica_dashboard.md` |
| Lógica de negocio de inventario o traspasos | `.context/SigoAPP_Funcional_Inventario.md` |
| Lógica de negocio del conteo físico | `.context/SigoAPP_Funcional_ConteoFisico.md` |
| Arquitectura general o nuevas capas | `.context/SigoAPP_Arquitectura.md` |
| Preparación para producción | `.context/SigoAPP_Produccion.md` |

### Paso 3: Inspeccionar archivos clave
Usa `view_file` para leer las secciones relevantes de los archivos de código identificados en el Paso 1. Extrae:
- Firmas de métodos que se van a modificar o consumir
- Estructura de clases/widgets involucrados
- Rangos de líneas específicos donde se debe actuar

### Paso 4: Generar el prompt completo
El prompt generado debe seguir **estrictamente** esta estructura optimizada:

````markdown
<!-- MODULE-ROUTER-CONTEXT -->
## Contexto del Proyecto
SigoAPP es una aplicación Flutter de gestión administrativa empresarial.
- **Arquitectura**: Clean Architecture (Provider + Repository)
- **Backend**: Spring Boot (Java) + Oracle
- **Cliente HTTP**: Dio (instancia centralizada en AppConfig)

## Estado del Backend y Repositorios
- **Modo:** [HTTP Real / Mock Simulado / Híbrido]
- **Endpoints disponibles:** [Listar endpoints o indicar si requiere soporte Mock con simulación de latencia y errores]

## Reglas Obligatorias y de Red
[Incluir solo las reglas de .agents/AGENTS.md y Rules_Networking.md que sean relevantes para la tarea]

## Módulo Afectado y Permisos
- **Módulo:** **[Nombre del Módulo]** — [Descripción breve]
- **Permisos requeridos:** `[ej. avac, agst, aein]` (Mapeados en PermissionUtils / AppPermission)

## Documentación Funcional Aplicable
- **Documento:** [Ruta al documento funcional en .context/, ej. .context/SigoAPP_Funcional_Inventario.md]
- **Reglas clave:** [Resumen de las 2-3 reglas de negocio indispensables para esta tarea]

## Archivos Involucrados
[Tabla con ruta relativa/absoluta, propósito y líneas relevantes de cada archivo]

| Archivo | Ruta | Propósito | Líneas clave |
|---------|------|-----------|--------------|
| `...` | `lib/...` | ... | L45-L78 |

## Tarea Solicitada
[Descripción clara, concreta y sin ambigüedades de lo que el agente receptor debe hacer]

## Restricciones
- Respetar convenciones de nomenclatura (español lowerCamelCase en modelos).
- No disparar llamadas de red en constructores de Providers (vincular a ciclo de vida de UI).
- Al finalizar la tarea, verificar si los documentos en `.context/` necesitan actualización y proponer los cambios al usuario.

## Comandos de Verificación Sugeridos
- Análisis estático: `flutter analyze lib/...`
- Pruebas unitarias: `flutter test test/...`
````

### Paso 5: Presentar al usuario
Entrega el prompt generado como un **bloque de código markdown** listo para copiar. No lo resumas ni lo parafrasees. El usuario lo copiará textualmente en otra ventana.

## Reglas del Skill

1. **Nunca generes un prompt sin antes consultar `SigoAPP_Mapa_Modulos.md`** o usar `query_module.dart`. Este documento es la fuente de verdad para la relación módulo ↔ archivos.

2. **Rutas normalizadas y enlaces clickables**: Usa rutas relativas desde la raíz del workspace (ej. `lib/providers/...`) o enlaces clickables tipo `[nombre](file:///ruta/absoluta)`. Nunca uses únicamente el nombre suelto del archivo.

3. **Incluye rangos de líneas**: Cuando la tarea involucre modificar secciones específicas, inspecciona previamente con `view_file` para verificar los números de línea actuales.

4. **No incluyas el contenido completo de los archivos**: Incluye solo las firmas, interfaces o fragmentos clave que el agente receptor necesita conocer.

5. **Explicita las reglas funcionales y estado del backend**: Como el marcador `<!-- MODULE-ROUTER-CONTEXT -->` desactiva la pregunta sobre documentación funcional en el receptor (AGENTS.md L17), debes sintetizar las reglas de negocio indispensables y especificar si se trabaja contra API real o Mock.

6. **Siempre incluye la regla de sincronización de documentación**: Debe figurar como restricción final en el prompt generado.

7. **El prompt debe ser autocontenido**: El agente receptor no debería necesitar formular preguntas de clarificación inicial para empezar a trabajar.
