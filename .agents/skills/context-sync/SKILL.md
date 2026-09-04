---
name: context-sync
description: Automatiza la verificación y propuesta de actualización de los documentos de contexto en .context/ según las reglas de AGENTS.md. Úsalo cuando se agreguen, eliminen o modifiquen archivos, módulos, providers, utilidades o permisos en SigoAPP, o cuando el usuario indique que una tarea de desarrollo ha finalizado.
---

# Skill: Sincronización de Contexto y Documentación (Context Sync)

## Propósito
Este skill garantiza la consistencia entre el código fuente de SigoAPP (`lib/`, `test/`) y la documentación de arquitectura en `.context/`, automatizando el cumplimiento estricto de la sección **§Sincronización de Documentación del Proyecto** de `.agents/AGENTS.md`.

## Cuándo se activa
- El usuario indica explícitamente que los ajustes de código son satisfactorios (ej.: "listo", "perfecto", "funciona bien", "terminamos").
- El agente determina que las iteraciones respecto a la solicitud principal del usuario han concluido.
- Se agregaron, eliminaron o renombraron pantallas, providers, repositorios, modelos, utilidades o permisos.
- El usuario solicita verificar o sincronizar la documentación del proyecto.

## Herramientas Auxiliares
- **Script de Verificación:** [check_sync.dart](./scripts/check_sync.dart) — Inspecciona `git status` y cruza los archivos modificados con la tabla de impacto de `AGENTS.md`.
  ```bash
  dart run .agents/skills/context-sync/scripts/check_sync.dart
  ```

## Flujo de ejecución

### Paso 1: Detección de Cambios
Ejecuta el script de verificación o inspecciona el estado del repositorio:
```bash
git status --porcelain
git diff --name-only HEAD~1
```
Identifica qué archivos en `lib/` fueron creados, modificados o eliminados.

### Paso 2: Evaluación de Impacto
Cruza los archivos detectados con la **Tabla de Impacto** de `AGENTS.md`:

| Tipo de Cambio | Documentos Afectados en `.context/` |
|----------------|-------------------------------------|
| Nuevo módulo / pantalla | `SigoAPP_Mapa_Modulos.md`, `SigoAPP_Arquitectura.md` |
| Nuevo provider / repositorio | `SigoAPP_Mapa_Modulos.md`, `SigoAPP_Arquitectura.md` |
| Nueva utilidad | `utils_documentation.md`, `SigoAPP_Mapa_Modulos.md` |
| Nuevo permiso | `visualizacion_dinamica_dashboard.md`, `SigoAPP_Mapa_Modulos.md` |
| Cambio de endpoints / red | `Rules_Networking.md` |
| Eliminación de archivo | Todos los documentos que lo referencien |
| Módulo funcional nuevo | Crear `SigoAPP_Funcional_<Modulo>.md`, actualizar `SigoAPP_Mapa_Modulos.md` |
| Cambio arquitectónico mayor | `SigoAPP_Historial_Cambios.md` |

### Paso 3: Elaborar la Propuesta de Actualización
Redacta los cambios específicos requeridos en cada documento afectado:
- Nuevas filas en las tablas de `SigoAPP_Mapa_Modulos.md`.
- Actualización de árboles de arquitectura en `SigoAPP_Arquitectura.md`.
- Documentación de métodos públicos en `utils_documentation.md`.

### Paso 4: Solicitar Aprobación Explícita
**IMPORTANTE:** De acuerdo con `AGENTS.md`, el agente **nunca debe modificar `.context/` sin aprobación previa**. Presenta al usuario la lista de documentos afectados y los cambios exactos propuestos, solicitando confirmación para aplicarlos.

### Paso 5: Aplicar Cambios Aprobados
Una vez recibida la aprobación del usuario, utiliza `replace_file_content` o `write_to_file` para actualizar los documentos correspondientes en `.context/`.

## Reglas del Skill

1. **No aplicar cambios sin aprobación:** Todo ajuste a `.context/` requiere consentimiento explícito del usuario.
2. **Preservar formato:** Mantener las tablas markdown, notas `> [!NOTE]` y convenciones estilísticas preexistentes en cada documento.
3. **No registrar cambios menores en el historial:** Solo los cambios arquitectónicos significativos se añaden a `SigoAPP_Historial_Cambios.md`. Actualizaciones de tablas o renombramientos menores no se registran allí.
