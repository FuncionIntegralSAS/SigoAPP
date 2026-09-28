# Evaluación y Puntos Pendientes de SigoAPP

Este documento consolida el estado actual derivado del análisis exhaustivo de arquitectura, diseño y prácticas implementadas en el proyecto **SigoAPP** (especialmente en el módulo de Inventario y su alineación con el backend Spring Boot / Oracle), detallando exclusivamente **aquellos elementos pendientes por resolver**, clasificados por prioridad, tipo de acción y estado de definición.

---

## 1. Resumen Ejecutivo de Estado Pendiente

| Bloque | Pendientes Técnicos | Pendientes de Definición Funcional | Total Pendientes |
| :--- | :---: | :---: | :---: |
| **Fase 2: Alto / Robustez y Ciclo de Vida** | 3 | 0 | 3 |
| **Fase 3: Medio / Calidad de Código & UX** | 6 | 0 | 6 |
| **Fase 4: Menor / Estandarización** | 1 | 0 | 1 |
| **Definición de Negocio y Permisos** | 0 | 3 | 3 |
| **Sincronización de Documentación (`.context/`)** | 3 | 0 | 3 |
| **Total General** | **13** | **3** | **16** |

---

## 2. Puntos Pendientes Técnicos por Resolver

### 2.1 Prioridad Alta (Fase 2: Robustez y Ciclo de Vida)

#### [PENDIENTE] 2.1 Desacoplar `loadTransfers()` del Constructor de `TransferApprovalProvider`
- **Archivo afectado:** [transfer_approval_provider.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/providers/transfer_approval_provider.dart#L10-L12) y [main.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/main.dart#L90)
- **Problema:** El constructor de `TransferApprovalProvider` ejecuta automáticamente `loadTransfers()` al inicializarse en el árbol global de `MultiProvider`. Esto dispara una petición asíncrona antes de que el usuario inicie sesión o sin token JWT válido en implementaciones HTTP.
- **Solución requerida:**
  1. Remover la invocación directa `loadTransfers();` del constructor de [TransferApprovalProvider](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/providers/transfer_approval_provider.dart).
  2. Confirmar que la carga explícita se mantenga delegada al `initState` mediante `addPostFrameCallback` en [transfer_approval_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/transfer_approval_screen.dart).

#### [PENDIENTE] 2.2 Feedback Visual de Carga y Error en `TransferApprovalScreen`
- **Archivo afectado:** [transfer_approval_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/transfer_approval_screen.dart#L43-L60)
- **Problema:** Si `provider.loading` está activo o si `provider.error` contiene un mensaje de fallo de red, la UI solo muestra el texto `"No hay solicitudes que coincidan con los filtros"`. No existe retroalimentación de progreso ni opción para reintentar la operación.
- **Solución requerida:**
  1. Mostrar un `CircularProgressIndicator` centrado cuando `provider.loading == true` y la lista esté vacía.
  2. Mostrar un banner o widget descriptivo de error con botón **"Reintentar"** (`provider.loadTransfers()`) cuando `provider.error != null`.

#### [PENDIENTE] 2.3 Inyección Configurable de `TransferRepository` en `main.dart`
- **Archivo afectado:** [main.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/main.dart#L50-L52)
- **Problema:** `main.dart` instancia de forma rígida `MockTransferRepository(inventoryService)`. Los demás repositorios (`inventoryRepository`, `catalogRepository`, `authRepository`, `geolocationRepository`, `physicalCountRepository`) ya consumen `Http*Repository` conectado a `backendDio`.
- **Solución requerida:**
  1. Permitir alternar entre [MockTransferRepository](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/repositories/mock_transfer_repository.dart) y [HttpTransferRepository](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/repositories/http_transfer_repository.dart) mediante una variable de entorno en `.env` (ej. `USE_MOCK_TRANSFERS=true|false`).
  2. Conectar [HttpTransferRepository](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/repositories/http_transfer_repository.dart) con `backendDio` cuando el backend esté en ejecución.

---

### 2.2 Prioridad Media (Fase 3: Calidad de Código, UX y Mantenibilidad)

#### [PENDIENTE] 3.1 Centralización de Utilidades de Geolocalización y Permisos GPS
- **Archivos afectados:**
  - [generator_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/generator_screen.dart)
  - [inventory_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/inventory_screen.dart)
  - [asset_verification_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/asset_verification_screen.dart)
- **Problema:** En las tres pantallas existe código duplicado para verificar `Geolocator.isLocationServiceEnabled()`, validar `LocationPermission` (`denied`, `deniedForever`) y capturar la posición actual con timeout.
- **Solución requerida:**
  1. Crear la utilidad `location_utils.dart` en `lib/utils/` con métodos estáticos seguros (`checkAndRequestPermission()`, `determinePosition()`).
  2. Reemplazar la lógica dispersa en las tres pantallas por el llamado a esta utilidad centralizada.

#### [PENDIENTE] 3.2 Limpieza de Textos Técnicos y Leyendas Mock en UI
- **Archivos afectados:** [generator_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/generator_screen.dart) e [inventory_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/inventory_screen.dart)
- **Problema:** Se presentan cadenas en la interfaz de usuario como `"(Simulación)"` o `"En Mock se omitió el guardado"`, las cuales son artefactos de desarrollo que degradan la percepción de producción.
- **Solución requerida:**
  1. Condicionar o eliminar mensajes de simulación en diálogos visibles para el usuario final, utilizándolos únicamente bajo banderas de depuración (`kDebugMode`) o sustituyéndolos por mensajes amigables.

#### [PENDIENTE] 3.3 Consistencia de Modelo en `ArticleModel` y Deserialización
- **Archivo afectado:** [article_model.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/models/article_model.dart#L36-L45)
- **Problema / Alineación Backend:** La tabla principal de activos (`ACTIFIJO`) no maneja coordenadas geográficas; estas se gestionan de forma segregada en la tabla `ACFIGEOL` mediante el ID numérico (`afgeIdre` / `article.id`).
- **Solución requerida:**
  1. Preservar la separación estricta: las coordenadas GPS no deben forzarse en el payload de artículos de `ACTIFIJO`.
  2. Mapear en `ArticleModel.fromJson` los atributos reales disponibles en el endpoint (ej. `estado`, `comentarios`), garantizando que la georreferenciación continúe operando a través de [HttpGeolocationRepository](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/repositories/http_geolocation_repository.dart).

#### [PENDIENTE] 3.4 Deprecación Formal del Método Redundante `applyTransfer`
- **Archivos afectados:**
  - [transfer_repository.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/repositories/transfer_repository.dart#L28-L29)
  - [http_transfer_repository.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/repositories/http_transfer_repository.dart#L99-L106)
- **Problema:** En el backend, al aprobar un traspaso (`PUT /api/v1/traspasos/{id}/procesar` con decisión `'ap'`), el cambio de custodia del activo se aplica automáticamente en base de datos. Por ende, el método `applyTransfer` en el contrato es redundante (actualmente solo retorna un `Future.value()`).
- **Solución requerida:**
  1. Agregar la anotación `@deprecated` formal en el contrato [TransferRepository](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/repositories/transfer_repository.dart) explicando su obsolescencia y preparar su futura extracción sin romper referencias existentes.

#### [PENDIENTE] 3.5 Evaluación de Reemplazo Global de Contenedores de Error por `SessionErrorBanner`
- **Archivos afectados:**
  - Pantallas del módulo de inventario ([inventory_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/inventory_screen.dart), [generator_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/generator_screen.dart), etc.)
  - Pantallas con listas y pestañas ([approval_tab_view.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/tabs/approval_tab_view.dart), etc.)
- **Problema / Implicación a Evaluar:**
  Actualmente coexisten contenedores simples de error (`Container` con fondo rojo), diálogos modales (`DialogUtils.showErrorDialog`) y `SnackBar`. Se debe evaluar la conveniencia técnica y de experiencia de usuario antes de reemplazar masivamente estos contenedores por un widget global `SessionErrorBanner`, ponderando:
  1. Si para sesión expirada (401/403) es más conveniente un banner no bloqueante en la vista o una interrupción modal/diálogo que impida continuar operando con credenciales caducadas.
  2. Si el interceptor de red ([auth_interceptor.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/utils/auth_interceptor.dart)) o un listener centralizado en `main.dart` debería capturar el 401/403 y redirigir directamente a Login mediante `AuthUtils.logout(context)` en vez de delegar la presentación a cada pantalla individual.
  3. Consistencia visual entre pantallas con formulario desplazable (`SingleChildScrollView`) vs pantallas basadas en listas (`ListView`).
- **Estado:** Postergado para evaluación posterior a la implementación de `AuthUtils.logout`.

#### [PENDIENTE] 3.6 Auditoría y Refactorización Arquitectónica de `InventoryScreen` (Desacoplamiento, Normalización de Botones y Modularización UI)
- **Archivo afectado:** [inventory_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/modules/inventory/screens/inventory_screen.dart)
- **Diagnóstico General y Métricas:**
  `InventoryScreen` acumula actualmente ~690 líneas de código y concentra múltiples responsabilidades que contravienen el Principio de Responsabilidad Única (SRP) y las directrices canónicas de desarrollo en Flutter. La pantalla mezcla la instanciación de UI con lógica de selección masiva, reglas de negocio de compatibilidad de traspasos, instanciación manual heterogénea de botones, orquestación de modales de navegación, sincronización imperativa de notifiers dentro del ciclo `build()`, y métodos constructores privados (`_build*`) que impiden la optimización de rebuilds.
- **Hallazgos de la Auditoría según Mejores Prácticas de Flutter:**
  1. **Falta de Normalización y Estandarización de Botones y Barras de Acción:**
     - En el `bottomNavigationBar` ([L388-L454](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/modules/inventory/screens/inventory_screen.dart#L388-L454)), se instancian tres botones de forma heterogénea con estilos inline manuales (`OutlinedButton.icon` con bordes rojos manuales para Cancelar, `OutlinedButton.icon` sin estilo para Marcar todos, y `ElevatedButton.icon` con `primaryColor` para Realizar traspaso).
     - El `FloatingActionButton.extended` ([L368-L386](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/modules/inventory/screens/inventory_screen.dart#L368-L386)) define colores y tipografías ad-hoc en lugar de consumir un tema centralizado.
     - En el `AppBar` ([L330-L365](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/modules/inventory/screens/inventory_screen.dart#L330-L365)) y en `_buildErrorBanner` ([L556-L568](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/modules/inventory/screens/inventory_screen.dart#L556-L568)), se crean `IconButton` inline con configuraciones de iconos y tooltips repetitivas.
     - *Recomendación:* Crear o emplear componentes reusables de acción (ej. `SelectionActionBar`, `AppPrimaryButton`, `AppOutlinedButton`) y normalizar la invocación de botones mediante una interfaz declarativa unificada.
  2. **Acoplamiento de Reglas de Negocio en la Vista (`_toggleArticleSelection` y `_toggleSelectAll`):**
     - Métodos que acumulan más de 135 líneas de reglas de negocio ([L99-L174](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/modules/inventory/screens/inventory_screen.dart#L99-L174) y [L183-L245](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/modules/inventory/screens/inventory_screen.dart#L183-L245)): validación de `enTramite`, límite de 50 activos, verificación de coincidencia de responsable actual (`firstResp == artResp`), validación de coincidencia de bodega origen (`firstBodega == artBodega`), y validación de bodega de custodia personal `PE`.
     - *Recomendación:* Trasladar toda la lógica de validación, filtrado y selección de activos al `InventoryProvider` o a un controlador de selección dedicado (`InventorySelectionController`), dejando a la vista únicamente la invocación declarativa del evento (`controller.toggleSelection(article)`).
  3. **Inconsistencia Arquitectónica en Selectores (`_buildCollaboratorSelector` vs `CompanyDropdownField` / `WarehouseDropdownField`):**
     - Mientras que las empresas y las bodegas están modularizadas en widgets dedicados reutilizables ([`CompanyDropdownField`](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/shared/widgets/company_dropdown_field.dart) y [`WarehouseDropdownField`](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/shared/widgets/warehouse_dropdown_field.dart)), el selector de colaborador ([L602-L688](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/modules/inventory/screens/inventory_screen.dart#L602-L688)) se encuentra acoplado dentro de `InventoryScreen` con más de 85 líneas inline.
     - *Recomendación:* Extraer un nuevo widget reutilizable `CollaboratorDropdownField` en `lib/shared/widgets/` que encapsule el `DropdownButtonFormField2`, su buscador y sus estados (cargando, inhabilitado, selección).
  4. **Generación de Claves Compuestas en la Vista (`_getArticleKey`):**
     - La lógica para discernir la identidad única de un activo (placa, ID de registro o hash) reside en la vista ([L53-L62](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/modules/inventory/screens/inventory_screen.dart#L53-L62)).
     - *Recomendación:* Mover esta lógica al modelo [`ArticleModel`](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/modules/inventory/models/article_model.dart) como getter inmutable (`article.uniqueSelectionKey`).
  5. **Anti-patrón de Métodos Auxiliares `_build*` en lugar de Widgets Especializados:**
     - Uso de `_buildErrorBanner`, `_buildCompanySelector`, `_buildWarehouseSelector` y `_buildCollaboratorSelector`. En Flutter, los métodos auxiliares de construcción impiden que el framework omita rebuilds mediante widgets `const` y fragmentan la legibilidad del árbol.
     - *Recomendación:* Convertir estos bloques en widgets `StatelessWidget` / `StatefulWidget` independientes.
  6. **Rebuilds Ineficientes por `context.watch` Global:**
     - En [L321-L322](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/modules/inventory/screens/inventory_screen.dart#L321-L322), `context.watch<AuthProvider>()` y `context.watch<InventoryProvider>()` rebuildean todo el `Scaffold` ante cualquier cambio en los providers.
     - *Recomendación:* Usar `Consumer` o `Selector` localizados en los nodos que verdaderamente dependen del estado reactivo (contador de lista, body de artículos, etc.).
  7. **Efectos Colaterales en el Ciclo `build()` (`_syncNotifiers`):**
     - En [L323](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/modules/inventory/screens/inventory_screen.dart#L323), se invoca `_syncNotifiers(provider)` durante la fase de construcción de widgets para mutar un `ValueNotifier`, lo cual puede provocar avisos y reentradas en el pipeline de renderizado de Flutter.
     - *Recomendación:* Manejar la sincronización reactiva en listeners del provider o eliminar el `ValueNotifier` acoplado sustituyéndolo por el estado del propio provider.
  8. **Orquestación Imperativa de Diálogos y Modales de Traspaso:**
     - `_showTransferForm` ([L248-L275](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/modules/inventory/screens/inventory_screen.dart#L248-L275)) y `_startMultipleTransfer` ([L278-L317](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/modules/inventory/screens/inventory_screen.dart#L278-L317)) combinan validaciones condicionales, resolución de bodegas coincidentes, apertura de `showModalBottomSheet` y refresco subsiguiente.
     - *Recomendación:* Extraer un delegado o coordinador de navegación de traspasos (`TransferNavigationCoordinator`).
- **Estado:** **PENDIENTE / TAREA FUTURA** (Evaluación completada sin modificaciones de código aplicadas por el momento).

---

### 2.3 Prioridad Baja (Fase 4: Estandarización Menor)

#### [PENDIENTE] 4.1 Estandarización de Notificaciones con `NotificationService`
- **Archivos afectados:** Pantallas del módulo de inventario ([inventory_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/inventory_screen.dart), [generator_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/generator_screen.dart), etc.)
- **Problema:** Algunas pantallas invocan directamente `ScaffoldMessenger.of(context).showSnackBar(...)` en lugar de utilizar el servicio centralizado [NotificationService](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/services/notification_service.dart) inyectado en `main.dart`.
- **Solución requerida:**
  1. Reemplazar invocaciones directas de `ScaffoldMessenger` por métodos unificados (`showSuccess()`, `showError()`, `showWarning()`) de `NotificationService`.

---

## 3. Puntos Pendientes de Definición Funcional (En Pausa / Reglas de Negocio)

Estos puntos dependen de decisiones de negocio y especificaciones que aún no han sido definidas por el equipo:

### 3.1 Lógica de Verificación de Activos (`AssetVerificationScreen`)
- **Archivos involucrados:**
  - [asset_verification_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/asset_verification_screen.dart)
  - [asset_verification_provider.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/providers/asset_verification_provider.dart)
- **Estado:** **PAUSADO** a solicitud del usuario (*"no, esto lo he de definir más adelante, aún no cuento con la lógica precisa"*).
- **Aspectos pendientes por definir:**
  1. ¿Contra qué fuente de datos se debe validar el activo escaneado: directamente contra el endpoint `/api/v1/articulos/asignados/{cedula}` o contra un endpoint específico de verificación física?
  2. Definir si la validación compara el responsable escaneado en el QR físico vs. la base de datos, o si valida que el activo pertenezca a la bodega/división del usuario autenticado.
  3. Reconectar o refactorizar [AssetVerificationProvider](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/providers/asset_verification_provider.dart), el cual actualmente se encuentra desconectado de la pantalla principal.

### 3.2 Posible Separación de Permiso RBAC para Receptores de Traspasos
- **Archivos involucrados:**
  - [auth_provider.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/providers/auth_provider.dart)
  - [dashboard_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/dashboard_screen.dart)
  - [transfer_delivery_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/transfer_delivery_screen.dart)
- **Estado:** **EN ANÁLISIS**.
- **Aspectos pendientes por definir:**
  1. Actualmente se utiliza `aein` (`AppPermission.entregaInventario`) para restringir el acceso general a la pantalla "Entrega / Recepción".
  2. El usuario indicó: *"bloqueemos el permiso a la opción del menú con aein, posiblemente añadamos otro permiso para los receptores"*.
  3. Se debe confirmar con el backend si existirá un código específico (ej. `arin` o similar) para separar a quien entrega de quien recibe, o si ambos continuarán bajo el rol de `aein` diferenciándose internamente por la cédula de origen/destino.

### 3.3 Identificación del Responsable de Bodega y Validación de Renderizado de Firmas en Requisiciones
- **Archivos involucrados:**
  - [requisition_signature_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/requisition_signature_screen.dart)
  - [requisition_signature_capture_screen.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/screens/requisition_signature_capture_screen.dart)
  - [requisition_signature_provider.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/providers/requisition_signature_provider.dart)
  - [requisition_model.dart](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/lib/models/requisition_model.dart)
- **Estado:** **EN ANÁLISIS / DEFINICIÓN**.
- **Aspectos pendientes por definir:**
  1. **Identificación del Responsable Oficial de Bodega (Firma Salida `SA` y Recibo `RE`):** **RESUELTO**. El backend expuso en `GET /api/v1/requisiciones/{empresa}/{tipoDocumento}/{numero}` los campos `responsableBodega` (`BODEGA.BODERESP` de bodega origen) y `responsableBodegaDestino` (`RESUBODS` de bodega destino, si aplica) con `NULLIF(BODERESP, '.')`. El frontend (`RequisicionDetalle` y `RequisitionSignatureScreen`) consume ambos campos para la inferencia estricta de roles (`isDispatcher` y `isReceiver`), manteniendo fallback por permiso `aein` para bodegas sin encargado asignado.
  2. **Validación del Renderizado y Visualización de la Firma:** Verificar y validar el renderizado de la firma digital estampada (formato base64 PNG exportado por el lienzo `signature`), evaluando tanto su visualización en la aplicación móvil (preview/auditoría) como su renderizado e impresión en los reportes oficiales o comprobantes generados por el backend ERP Oracle.

---

## 4. Puntos Pendientes de Sincronización de Documentación (`.context/`)

De acuerdo con las reglas de [AGENTS.md](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/.agents/AGENTS.md), tras la aprobación de los cambios de código, se debe actualizar la documentación del proyecto:

| Documento | Estado | Modificación Pendiente Requerida |
| :--- | :---: | :--- |
| [.context/visualizacion_dinamica_dashboard.md](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/.context/visualizacion_dinamica_dashboard.md#L78) | **Desalineado** | Actualizar la sección de "Entrega / Recepción": cambiar de *"Opción disponible para todo usuario autenticado"* a opción protegida por el permiso **`aein`**. |
| [.context/SigoAPP_Mapa_Modulos.md](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/.context/SigoAPP_Mapa_Modulos.md#L17) | **Desalineado** | En la tabla de módulos (sección 3) y la tabla de rutas (sección 2.1), actualizar el permiso de `TransferDeliveryScreen` sustituyendo `Autenticado` por **`aein`**. |
| [.context/SigoAPP_Historial_Cambios.md](file:///f:/Juan_Camilo_Diaz/Projects/APP_Gestion_Administrativa/SigoAPP/.context/SigoAPP_Historial_Cambios.md) | **Pendiente** | Agregar entrada registrando el endurecimiento de seguridad con `aein` y la restricción de bodegas destino por división del receptor. |

---

## 5. Plan de Acción y Orden de Ejecución Sugerido

Una vez revisado este reporte, el orden recomendado para continuar es:

```mermaid
flowchart TD
    A["Revisión de EVALUATION.md"] --> B{"Aprobación del Usuario"}
    B -->|Aprobar Fase 2| C["Ejecutar Fase 2: Robustez y Ciclo de Vida (2.1, 2.2, 2.3)"]
    B -->|Sincronizar Contexto| D["Actualizar Documentos en .context/ (Tablas y Permisos)"]
    B -->|Definir Negocio| E["Definir Lógica de Verificación (3.1) o Permiso de Recepción (3.2)"]
    C --> F["Pruebas Unitarias y Verificación"]
    F --> G["Ejecutar Fase 3: Calidad de Código & UX"]
```
