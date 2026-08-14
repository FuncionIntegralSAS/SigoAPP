---
name: module-router
description: Genera prompts completos y precisos para delegar tareas de desarrollo a otros agentes o ventanas de contexto en SigoAPP. Identifica automáticamente los archivos, módulos y dependencias involucradas usando la documentación del proyecto.
---

# Skill: Agente Direccionador de Módulos (Module Router)

## Propósito
Este skill genera **prompts completos listos para copiar/pegar** en otra ventana de contexto o agente de IA. Los prompts incluyen rutas absolutas de archivos, rangos de líneas relevantes, contexto de negocio y reglas del proyecto, para que el agente receptor pueda ejecutar la tarea sin necesidad de hacer búsquedas exploratorias.

## Cuándo se activa
- El usuario solicita explícitamente generar un prompt para otro agente.
- El usuario necesita delegar una tarea a otra ventana de contexto.
- El usuario usa expresiones como: "genera un prompt para...", "prepara las instrucciones para...", "necesito pasarle esto a otro agente".

## Flujo de ejecución

### Paso 1: Identificar el módulo afectado
Lee `.context/SigoAPP_Mapa_Modulos.md` para determinar:
- A qué **módulo de negocio** pertenece la tarea (Inventario, Conteo Físico, Requisiciones, etc.)
- Todos los **archivos involucrados** (screens, tabs, providers, repositorios, modelos, widgets, utilidades)
- Los **providers y estados** relevantes
- Los **permisos** asociados

### Paso 2: Recopilar contexto técnico
Según el tipo de tarea, lee los documentos adicionales necesarios:

| Si la tarea involucra... | Lee además... |
|--------------------------|---------------|
| Crear/modificar endpoints o peticiones HTTP | `.context/Rules_Networking.md` |
| Modificar utilidades compartidas | `.context/utils_documentation.md` |
| Cambiar permisos o visibilidad en dashboard | `.context/visualizacion_dinamica_dashboard.md` |
| Lógica de negocio del conteo físico | `.context/SigoAPP_Funcional_ConteoFisico.md` |
| Arquitectura general o nuevas capas | `.context/SigoAPP_Arquitectura.md` |
| Preparación para producción | `.context/SigoAPP_Produccion.md` |

### Paso 3: Inspeccionar archivos clave
Usa `view_file` para leer las secciones relevantes de los archivos de código identificados en el Paso 1. Extrae:
- Firmas de métodos que se van a modificar o consumir
- Estructura de clases/widgets involucrados
- Rangos de líneas específicos donde se debe actuar

### Paso 4: Generar el prompt completo
El prompt generado debe seguir **estrictamente** esta estructura:

```
<!-- MODULE-ROUTER-CONTEXT -->
## Contexto del Proyecto
SigoAPP es una aplicación Flutter de gestión administrativa empresarial.
- **Arquitectura**: Clean Architecture (Provider + Repository)
- **Backend**: Spring Boot (Java) + Oracle
- **Cliente HTTP**: Dio (instancia centralizada en AppConfig)

## Reglas Obligatorias
[Incluir solo las reglas de .agents/AGENTS.md y Rules_Networking.md que sean relevantes para la tarea]

## Módulo Afectado
**[Nombre del módulo]** — [Descripción breve del módulo]

## Archivos Involucrados
[Tabla con ruta absoluta, propósito y líneas relevantes de cada archivo]

| Archivo | Ruta | Propósito | Líneas clave |
|---------|------|-----------|--------------|
| ... | `lib/...` | ... | L45-L78 |

## Tarea Solicitada
[Descripción clara y concreta de lo que el agente receptor debe hacer]

## Restricciones
- [Restricciones de arquitectura, convenciones de nombrado, etc.]
- Al finalizar la tarea, verificar si los documentos en `.context/` necesitan actualización y proponer los cambios al usuario.

## Resultado Esperado
[Qué archivos deben quedar modificados/creados y cómo verificar que funciona]
```

### Paso 5: Presentar al usuario
Entrega el prompt generado como un **bloque de código markdown** listo para copiar. No lo resumas ni lo parafrasees. El usuario lo copiará textualmente en otra ventana.

## Reglas del Skill

1. **Nunca generes un prompt sin antes consultar `SigoAPP_Mapa_Modulos.md`**. Este documento es la fuente de verdad para la relación módulo ↔ archivos.

2. **Incluye rutas absolutas** desde `lib/` en todas las referencias a archivos. Nunca uses solo el nombre del archivo.

3. **Incluye rangos de líneas** cuando la tarea involucre modificar secciones específicas de un archivo. Usa `view_file` para verificar los números de línea actuales.

4. **No incluyas el contenido completo de los archivos** en el prompt. Incluye solo las firmas, interfaces o fragmentos que el agente receptor necesita conocer para ejecutar la tarea.

5. **Siempre incluye la regla de sincronización de documentación** como restricción al final del prompt, para que el agente receptor también la cumpla.

6. **Si la tarea abarca múltiples módulos**, genera un prompt por módulo o indica claramente las dependencias cruzadas en una sección "Dependencias entre módulos".

7. **El prompt debe ser autocontenido**. El agente receptor no debería necesitar preguntar nada adicional para ejecutar la tarea. Si hay ambigüedades, resuélvelas con el usuario antes de generar el prompt.
