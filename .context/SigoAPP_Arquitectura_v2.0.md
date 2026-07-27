# Documentación de Arquitectura de Software
Proyecto: SigoAPP
Versión: 2.2
Fecha de actualización: Julio 2026

## 1. Estructura de Directorios (Mapping)
El proyecto organiza el código fuente bajo el directorio lib/, siguiendo principios de Clean Architecture para facilitar el mantenimiento y la inyección de dependencias hacia el backend (Spring Boot / Oracle).

lib/
 ├── database/      → Persistencia local con SQLite (modo offline)
 ├── exceptions/    → Excepciones de dominio tipadas
 ├── models/        → Modelos de dominio (inmutables)
 ├── providers/     → Manejo de estado (ChangeNotifier)
 ├── repositories/  → Abstracciones y acceso a datos (Contrato + Implementaciones)
 ├── screens/       → Pantallas orquestadoras y contenedores
 │    └── tabs/     → Vistas internas para controladores de pestañas
 ├── services/      → Servicios HTTP, Mocks y clientes de red (infraestructura)
 ├── utils/         → Utilidades transversales y parsers
 └── widgets/       → Componentes UI reutilizables

## 2. Definición Extendida de Modelos (lib/models/)
### 2.1 article_model.dart
Representa un activo físico del inventario. Incluye identidad, responsable asignado, ubicación y metadatos operativos, con integración para lectura QR.

### 2.2 transfer_request.dart
Modelo central para el traslado físico de activos. Mantiene el estado del flujo y garantiza la trazabilidad entre bodegas y responsables. Soporta serialización JSON automática mediante `json_annotation` / `json_serializable` (archivo generado: `transfer_request.g.dart`).

### 2.3 transfer_filter.dart
Filtro inmutable para consultas de traspasos. Permite acotar búsquedas por estado, bodega propuesta, responsable y rango de fechas. Implementa `copyWith` para actualizaciones parciales sin mutación.

### 2.4 requisition_model.dart
Representa una solicitud administrativa de consumo o salida de inventario.
* Responsabilidades: Preservar la trazabilidad jerárquica de cantidades (Solicitada -> Aprobada -> Entregada).
* Llave Primaria: compositeId (generada a partir de empresa, tipo de documento, número, bodega y artículo).
* Estados soportados: 'pe' (Pendiente), 'ap' (Aprobada), 'na' (Rechazada/No aprobada), 'pr' (Procesada).

### 2.5 physical_count_model.dart y company_model.dart (Módulo de Conteo Físico - Apertura)
Modelos encargados de la recolección de datos para la generación de la apertura de un conteo físico de inventario.
* `PhysicalCountRequest`: Capta empresa, bodega, fecha, artículos, bandera de verificación lógica/física y lista de participantes (solo IDs enviados en JSON para optimización).
* `CompanyModel`: Entidad simple para listar empresas base.

### 2.6 active_count_model.dart y count_record_model.dart (Módulo de Conteo Físico - Ejecución Offline)
Modelos diseñados para la operación offline del conteo físico en piso (SQLite).
* `ActiveCountModel`: Representa la cabecera de un conteo activo con metadatos de sincronización. Incluye serialización bidireccional SQLite (`toMap` / `fromMap`).
* `CountRecordModel`: Registro individual de lectura por parte del contador. Soporta serialización dual:
  - SQLite local (`toMap` / `fromMap`) para persistencia offline.
  - API Spring Boot (`toJsonApi`) para sincronización con el backend. El formato de API utiliza nomenclatura en español según convención del procedimiento almacenado.

### 2.7 Modelos de Soporte
* `personal_model.dart`: Modelo de datos del personal de la empresa para el módulo de Conteo Físico. Almacena los datos de identificación del empleado bajo la nomenclatura de base de datos (`perscodi`, `persnomb`, `persapel`, `perscoel`, `persdivi`, `persesta`). Su factory constructor `fromJson` implementa un mapeo tolerante a múltiples formatos de llave (minúsculas, mayúsculas, camelCase y las llaves directas del endpoint de personal: `cedula`, `nombre`, `apellido`, `correo`, `division`, `estado`).
* `user_model.dart`: Modelo básico de usuario autenticado (id, name, email).
* `warehouse_model.dart`: Bodega o centro de costos con deserialización desde API. Extiende `Equatable` con `bodeCodi`, `bodeDesc` y `bodeEsta` como `props`, permitiendo la comparación por valor requerida por `DropdownButton`.

### 2.8 Modelos de Asignación de Conteo Físico (physical_count_model.dart)
Además de `PhysicalCountRequest`, este archivo contiene los modelos para el flujo de asignación de personal:
* `AsignacionConteoRequest`: Encapsula los datos requeridos por el endpoint `POST /api/v1/conteo-fisico/asignar_articulos`: `empresa`, `bodega`, `fechaConteo` (ISO 8601 UTC) y la lista de `UsuarioAsignacion`.
* `UsuarioAsignacion`: Representa a cada contador asignado con `documento` (cédula), `nombre` (nombre + apellido concatenados) y `email`. Ambas clases implementan `Equatable` y exponen `toJson()` con la estructura exacta del schema Swagger.

## 3. Capa de Repositorios (lib/repositories/)
### 3.1 TransferRepository (Contrato Único)
Contrato asíncrono (`Future`) que define la creación, consulta y procesamiento de solicitudes de traspaso de activos. Ambas implementaciones (mock y HTTP) cumplen este mismo contrato, lo que permite intercambiarlas mediante inyección de dependencias en `main.dart`.
* `create(TransferRequest)`: Crea una nueva solicitud.
* `getAllTransfers()`: Obtiene todas las solicitudes.
* `approveTransfer(String)`: Aprueba una solicitud por ID.
* `rejectTransfer({requestId, rejectionReason})`: Rechaza con motivo obligatorio.
* `applyTransfer(TransferRequest)`: Aplica un traspaso aprobado (nota: redundante si el backend aplica automáticamente al aprobar).

#### 3.1.1 MockTransferRepository
Implementación en memoria que utiliza `MockInventoryService` como fuente de datos para desarrollo y pruebas offline. Las operaciones son síncronas internamente pero devuelven `Future` para cumplir el contrato.

#### 3.1.2 HttpTransferRepository
Implementación HTTP real que conecta con los endpoints del backend Spring Boot utilizando `Dio`. Lanza `TransferBusinessException` cuando ocurren errores de red o respuestas no exitosas del servidor.

### 3.2 RequisitionRepository
Contrato que define el acceso a las requisiciones de consumo.
* getRequisitionsByStatus(String status): Consulta filtrada de requerimientos.
* processBatch(Map<String, int> selectedItems, String targetStatus): Envío de múltiples identificadores y cantidades en bloque para optimización de transacciones.

## 4. Lógica de Negocio y Servicios (lib/services/)
### 4.1 mock_inventory_service.dart y mock_requisition_service.dart
Servicios que simulan las respuestas del servidor para habilitar el desarrollo frontend y pruebas offline, implementando latencia artificial.

### 4.2 mock_auth_service.dart y mock_account_service.dart
Servicios mock para autenticación de usuarios y gestión de cuentas respectivamente.
* `MockAuthService`: Singleton con `ValueNotifier<UserModel?>` para notificación reactiva del estado de sesión, consumido por el `AuthWrapper` en `main.dart`.
* `MockAccountService`: Consume `NetworkClient` para consulta y creación de cuentas de personas.

### 4.3 network_client.dart
Cliente de red simulado (patrón Singleton) para operaciones relacionadas con personas y activos de inventario. Simula latencia de red y probabilidad de errores de conexión (5%).
* `getPerson(String nationalId)`: Simula GET /person/{nationalId}.
* `postCreateAccount({nationalId, creatorId})`: Simula POST /create-account.
* `postCreateArticle(Map articleData)`: Simula POST para creación de activos.

### 4.4 notification_service.dart / in_app_notification_service.dart
Sistema de notificaciones in-app basado en contrato abstracto (`NotificationService`) e implementación concreta (`InAppNotificationService`).
* Define tres niveles: `success`, `error`, `info`.
* Implementa las notificaciones mediante `ScaffoldMessenger` con SnackBars coloreados.
* Se inyecta como `Provider<NotificationService>` en el árbol de widgets.

### 4.5 Integración Spring Boot (Backend)
Capa de conexión real hacia los endpoints desarrollados en Spring Boot. 
* Cliente HTTP: **Dio** (estandarizado como único cliente HTTP del proyecto).
* Formato de intercambio: JSON en formato camelCase.
* Reglas de catálogos: Carga jerárquica obligatoria (Búsqueda de empleado por identificador -> Obtención de divisionId -> Consulta de bodegas autorizadas por división).
* Lógica pesada: Delegada a procedimientos almacenados en Oracle (ej. PKGTRASPASO).

### 4.6 physical_count_service.dart
Servicio HTTP real para el módulo de Conteo Físico. Conecta con el backend Spring Boot a través de `Dio` para las siguientes operaciones:
* `getCompanies()` → `GET /api/v1/empresas`: Carga el catálogo de empresas.
* `getWarehouses(companyId)` → `GET /api/v1/bodegas/{empresa}`: Carga bodegas por empresa.
* `getArticles(warehouseId, companyId)` → `GET /api/v1/bodegas/asignados/{bodega}/{empresa}`: Carga artículos asignados a una bodega. Implementa fallback a datos mock cuando `companyId` es nulo/vacío o cuando el backend lanza `DioException`. Antepone la opción `"Todos"` (id: `'All'`) al resultado exitoso del backend.
* `searchPersons({nombre, apellido, cedula})` → `GET /api/v1/personal/buscar`: Búsqueda de personal por coincidencia. Envía los query params con las llaves exactas del backend (`nombre`, `apellido`, `cedula`). Lanza `DioException` 400 de forma local si no se provee ningún parámetro, sin consumir recursos de red.
* `createPhysicalCount(request)` → `POST /api/v1/conteo-fisico/registrar`: Crea la apertura del conteo físico.
* `assignArticles(request)` → `POST /api/v1/conteo-fisico/asignar_articulos`: Asigna los contadores seleccionados al conteo abierto.

## 5. Persistencia Local (lib/database/)
### 5.1 database_helper.dart
Singleton que administra la base de datos SQLite para la operación offline del módulo de Conteo Físico.

**Propósito**: Permitir que los contadores en piso registren lecturas de códigos de barras sin depender de conectividad de red. Los registros se almacenan localmente y se sincronizan con el backend cuando hay conexión disponible.

**Esquema de tablas**:
| Tabla | Propósito | Relación |
|-------|-----------|----------|
| `ActiveCountForms` | Cabecera del conteo activo (id, bodega, fecha de sincronización, estado de completitud) | Padre |
| `CountMasterItems` | Artículos maestros que se esperan contar en una bodega | FK → ActiveCountForms.id |
| `CountRecords` | Lecturas individuales realizadas por los contadores (código de barras, cantidad, fecha, estado de sincronización) | FK → ActiveCountForms.id |

**Operaciones CRUD**:
* `saveActiveCount()`: Inserta cabecera + artículos maestros en una transacción con Batch.
* `insertCountRecord()`: Registra una lectura individual.
* `getRecordsForCount()`: Consulta registros filtrados por ID de conteo y número de conteo (1, 2, 3).
* `markRecordsAsSynced()`: Marca registros como sincronizados (`isSynced = 'S'`) tras envío exitoso al backend.
* `clearDatabase()`: Limpia todas las tablas (desarrollo/testing).

**Compatibilidad multiplataforma**: Utiliza `sqflite_common_ffi` para soporte en escritorio (Windows/Linux). La inicialización FFI se ejecuta condicionalmente en `_initDB()` verificando `Platform.isWindows || Platform.isLinux`.

## 6. Excepciones de Dominio (lib/exceptions/)
### 6.1 transfer_business_exception.dart
Excepción tipada para errores de negocio en el módulo de Traspasos.

**Propósito**: Diferenciar errores de negocio (reglas violadas, estados inválidos, respuestas del servidor no exitosas) de errores técnicos genéricos (`DioException`, `Exception`). Esto permite que la capa de presentación (Providers/UI) maneje los errores de forma granular.

**Uso actual**: Lanzada exclusivamente desde `HttpTransferRepository` en los bloques `catch (DioException)`, transformando errores de red en mensajes de negocio legibles para el usuario.

**Patrón recomendado para extensión**: Si se requieren excepciones para otros módulos, seguir la convención `<módulo>_business_exception.dart` (ej. `requisition_business_exception.dart`, `count_business_exception.dart`).

## 7. Utilidades (lib/utils/)
### 7.1 article_qr_parser.dart
Utilidad para el parseo de cadenas QR leídas por el scanner.

**Propósito**: Encapsular la lógica de separación de la cadena QR en sus componentes (placa del activo e identificador del artículo). Esta lógica fue delegada al frontend antes del envío al backend, según decisión de arquitectura documentada en v1.8.

**Justificación de ubicación**: Se mantiene en `utils/` y no en `services/` porque es una operación pura (sin estado, sin I/O, sin dependencias externas) que se limita a transformar una cadena de entrada en datos estructurados.

## 8. Providers (lib/providers/)
### 8.1 TransferRequestProvider
Orquestador de estado para la creación de traslados físicos de activos.
* Consume `TransferRepository` (contrato asíncrono) y `NotificationService`.
* Implementa `try/catch` para notificar tanto éxitos como errores de negocio al usuario.

### 8.2 TransferApprovalProvider
Orquestador de estado para la aprobación, rechazo y aplicación de traslados.
* Mantiene estado local de la lista de traspasos (`_transfers`), indicador de carga (`_loading`) y error (`_error`).
* Ejecuta `loadTransfers()` automáticamente al ser instanciado.
* Recarga la lista completa tras cada operación exitosa (aprobar/rechazar/aplicar).

### 8.3 TransferFormProvider
Provider para el formulario de creación de traspasos. Implementa la carga en cascada de catálogos: Búsqueda de empleado → Obtención de división → Carga de bodegas autorizadas.

### 8.4 AssetVerificationProvider
Maneja la lógica de interpretación de códigos QR (separación de placa y artículo) y validación contra el servicio.

### 8.5 RequisitionApprovalProvider
Gestor de estado centralizado para el flujo de requisiciones administrativas.
* Mantiene la lista de requisiciones visibles según la pestaña activa.
* Administra un mapa temporal de ítems seleccionados para procesamiento en lote.
* Dispara el método processBatchSelection() hacia el repositorio.

### 8.6 PhysicalCountProvider
Orquestador de estado para el submódulo de Conteo Físico (Apertura y Asignación).
* Administra las listas maestras de selectores (dropdowns) con carga en cascada: Empresa → Bodega → Artículos.
* Maneja los estados del submódulo de forma reaccionaria a eventos del usuario (`INITIAL`, `EN_PROCESO`, `CREADA`, `ERROR`).
* Implementa las validaciones estrictas de campos de la UI antes de derivar responsabilidades al service.
* `searchPersons({nombre, apellido, cedula})`: Valida en cliente que al menos un campo tenga valor, delega al servicio y actualiza `foundPersons`. Maneja errores 400 y de red con mensajes diferenciados.
* `togglePersonSelection(person)` / `removePerson(person)`: Gestionan la lista `selectedPersons` comparando personas por `perscodi` (sin dependencia de referencia de objeto).
* `assignPhysicalCount()`: Valida que haya empresa, bodega y al menos un participante seleccionados; construye el objeto `AsignacionConteoRequest` mapeando `selectedPersons` a `UsuarioAsignacion` y delega al servicio. Tras éxito, transita al estado `CREADA`.

### 8.7 ActiveCountProvider
Orquestador de estado para la ejecución offline del conteo físico en piso.
* Consume `DatabaseHelper` directamente para operaciones CRUD sobre SQLite.
* Administra registros de lecturas de códigos de barras y artículos pendientes de conteo.

## 9. Componentes de UI y Navegación
### 9.1 RequisitionsScreen y Tabs
Pantalla principal de requisiciones construida sobre un TabController explícito. 
* ApprovalTabView: Consume la lista de requisiciones en estado pendiente ('pe').
* DeliveryTabView: Consume la lista de requisiciones en estado aprobado ('ap').

### 9.2 RequisitionActionCard
Componente visual tipo tarjeta expandible para iterar sobre listas de requisiciones.
* Utiliza las propiedades jerárquicas del modelo para limitar dinámicamente las cantidades que el usuario puede ingresar.
* Maneja checkboxes condicionales e indicadores visuales de requerimientos.

### 9.3 PhysicalCountScreen y Tabs
Pantalla que implementa el formulario principal para generar y asignar un conteo físico, organizada en pestañas.
* `PhysicalCountOpeningTab`: Formulario de apertura con selectores en cascada (Empresa, Bodega, Artículo) implementados con `dropdown_button2` v3.x. Incluye barras de búsqueda dinámicas en cada dropdown usando `DropdownTemplates.searchData` y `ValueNotifier` por selector para sincronizar estado con el Provider. Los ítems se muestran en formato `"código - descripción"`.
* `PhysicalCountAssignmentTab`: Asignación de contadores al conteo. Incluye:
  - Panel `ExpansionTile` de búsqueda avanzada con campos Nombre, Apellido y Cédula.
  - `ListView` de resultados con `CircleAvatar`, nombre completo y cédula por entrada; selección múltiple mediante `Checkbox`.
  - Sección de participantes seleccionados como `Chip` eliminables.
  - Botón **"Asignar Participantes al Conteo"** (ancho completo) que dispara `provider.assignPhysicalCount()`, muestra `SnackBar` verde en éxito y resetea el formulario para prevenir duplicados.
  - Overlay de `CircularProgressIndicator` durante operaciones asíncronas.
  - Manejo de errores vía `SnackBar` rojo usando `addPostFrameCallback` para evitar llamadas a `setState` durante el build.

### 9.4 ActiveCountScreen
Pantalla para la ejecución del conteo físico en piso (modo offline).
* `ContinuousScanView`: Vista de escaneo continuo de códigos de barras.
* `ListCountView`: Vista de lista para registros contados y pendientes.

### 9.5 Pantallas Complementarias
* `AuthScreen`: Pantalla de autenticación/login.
* `DashboardScreen`: Dashboard principal post-login con navegación a módulos.
* `HomeScreen`: Pantalla principal de navegación (denominada "Módulo Principal" en la UI), utilizada de forma exclusiva por los desarrolladores para testear accesos directos al inventario, scanner, generador QR y aprobación de traspasos. No está destinada para el paso a Producción.
* `AccountScreen`: Gestión de cuentas de personas.
* `ScannerScreen`: Escaneo de códigos QR con `MobileScanner`.
* `GeneratorScreen`: Generación de códigos QR con `QrImageView`.
* `InventoryScreen`: Pantalla principal de gestión de inventario con geolocalización.
* `TransferApprovalScreen`: Pantalla de aprobación/rechazo de traspasos con filtros y diálogos.

## 10. Flujo Funcional Integrado (Traspasos y Requisiciones)
El sistema opera bajo una premisa de desacoplamiento de interfaz y negocio. La UI solo despacha intenciones al Provider, quien delega al Repositorio. El inventario real o los estados de requisición solo se alteran tras la respuesta exitosa del servidor.

## 11. Principios de Diseño Consolidados
* Inmutabilidad en Modelos.
* Separación de responsabilidades (Clean Architecture).
* Optimización de red mediante Batch Processing (envío masivo).
* UI Reactiva mediante Provider.
* Contrato único de repositorio con implementaciones intercambiables (Mock/HTTP).
* Excepciones de dominio tipadas para diferenciación de errores.
* Persistencia local offline con sincronización diferida (SQLite + Backend).
* Cliente HTTP estandarizado (`Dio`) como única librería de red.

---

## 12. Control de Cambios e Histórico (v1.7 a v1.8)

A continuación, se evidencian las modificaciones arquitectónicas introducidas en la versión 1.8 respecto a su predecesora:

1. Desacoplamiento de Modelos: Se introdujo requisition_model.dart para separar conceptualmente las solicitudes de consumo/salida de los traspasos físicos (transfer_request.dart).
2. Procesamiento en Lote (Batch Processing): Se reemplazó el flujo de aprobación unitario por un mapa de recolección en el Provider (RequisitionApprovalProvider) que permite enviar múltiples IDs y cantidades en una sola transacción HTTP hacia el backend.
3. Navegación por Pestañas: Se refactorizó la interfaz lineal de RequisitionsScreen. (Nota: Originalmente se planificaron multiples tabs pero se utiliza actualmente un único tab para la aprobación de requisiciones).
4. Componentes Genéricos: Creación de RequisitionActionCard con validaciones internas dinámicas basadas en el estado del registro, eliminando la necesidad de crear interfaces duplicadas para cada etapa del flujo.
5. Definición de Contrato Backend: Establecimiento de formato camelCase estricto para el intercambio JSON con Spring Boot. Adicionalmente, se clarifica la separación de estados por módulo:
   * Módulo de Traspasos: Utiliza la nomenclatura oficial de la API en Spring Boot ('pe' [Pendiente], 'ap' [Aprobada], 'na' [No Aprobada/Rechazada], 'pr' [Procesada]).
   * Módulo de Requisiciones: Utiliza los estados ('in' [Ingresada/Solicitada], 'ap' [Aprobada], 'en' [Entregada], 'an' [Anulada]).
6. Lógica de Catálogos: Inclusión de la regla de negocio de carga en cascada para la búsqueda de personal y filtrado de bodegas por divisionId.
7. Adaptación de Scanner: Delegación de la lógica de partición de cadenas QR (placa y artículo) a la capa frontend antes del envío al backend.

## 13. Control de Cambios e Histórico (v1.8 a v1.9)
1. Integración del Módulo de Conteo Físico: Se crearon los modelos `PhysicalCountRequest` y `CompanyModel` para envío de datos estructurados hacia el backend, logrando optimizar el ancho de banda enviando únicamente el `nationalId` en forma de arreglo numérico.
2. Gestión Reactiva de Estados con `PhysicalCountProvider`: Orquestación robusta de operaciones del UI y el servicio, integrando transiciones `INITIAL` -> `EN_PROCESO` -> `CREADA` / `ERROR`.
3. Pantalla de Conteo Físico Avanzada (`PhysicalCountScreen`): Formulario dinámico con capacidades de búsqueda en tiempo real (por nombre y cédula para contadores), así como soporte para asignaciones holísticas (valores `"All"`).
4. Manejo Expandido de Códigos HTTP Estrictos: Ampliación de las simulaciones y captación de arquitecturas de red con respuestas intencionales HTTP 400 (Bad Request), 409 (Conflict/Bodegas bloqueadas) y 500 (Internal Error).

## 14. Control de Cambios e Histórico (v1.9 a v2.0)
1. **Documentación de capas no registradas**: Se incorporaron a la arquitectura las carpetas `database/`, `exceptions/` y `utils/` con sus respectivos archivos y propósitos.
2. **Unificación del contrato de Repositorios**: Se eliminó la duplicación de la clase abstracta `TransferRepository` que existía tanto en `transfer_repository.dart` (firmas síncronas) como en `http_transfer_repository.dart` (firmas asíncronas). Ahora existe un único contrato asíncrono (`Future`) en `transfer_repository.dart` que ambas implementaciones (`MockTransferRepository` y `HttpTransferRepository`) cumplen.
3. **Estandarización del cliente HTTP**: Se migró `HttpTransferRepository` de la librería `http` a `Dio`, consolidando un único cliente HTTP en todo el proyecto. Se eliminó la dependencia `http` del `pubspec.yaml`.
4. **Integración de TransferBusinessException**: La excepción tipada se integró en `HttpTransferRepository`, transformando errores de red (`DioException`) en mensajes de negocio legibles para el usuario. Esto permite a los Providers distinguir errores de dominio de errores técnicos.
5. **Asincronización de Providers de Traspasos**: `TransferApprovalProvider` y `TransferRequestProvider` se adaptaron al contrato asíncrono. El primero ahora mantiene estado local de la lista, expone `loadTransfers()` y ejecuta carga automática al instanciarse. El segundo implementó el `try/catch` pendiente con notificación de errores vía `NotificationService`.
6. **Limpieza de dependencias**: Se eliminaron `cupertino_icons` (sin uso detectado) y `win32` (dependencia transitiva, no requiere declaración explícita). Se conservaron `pdf`, `path_provider` y `open_filex` para uso en desarrollo posterior.

## 15. Control de Cambios e Histórico (v2.0 a v2.1)
1. **Integración real del servicio de Personal**: Se implementó `searchPersons` en `physical_count_service.dart` como llamada HTTP real a `GET /api/v1/personal/buscar`. Los parámetros de búsqueda se envían con las llaves exactas del backend (`nombre`, `apellido`, `cedula`). Se eliminaron todos los `print` de diagnóstico del código de producción.
2. **Modelo `PersonalModel` con mapeo tolerante**: Se rediseñó `personal_model.dart` bajo la nomenclatura de base de datos. Su `fromJson` prioriza las llaves reales del endpoint de personal (`cedula`, `nombre`, `apellido`, `correo`, `division`, `estado`) manteniendo compatibilidad con variantes en mayúsculas y camelCase. Esto resolvió el problema de visualización donde la cédula aparecía como `0` y nombre/apellido vacíos.
3. **Nuevo flujo de Asignación de Personal**: Se incorporaron dos nuevas clases en `physical_count_model.dart` (`AsignacionConteoRequest` y `UsuarioAsignacion`) con serialización `toJson` alineada al schema Swagger del endpoint `POST /api/v1/conteo-fisico/asignar_articulos`. Se corrigió la ruta del endpoint que en una versión intermedia apuntaba a `/asignar_articulos` sin el prefijo de la API.
4. **`assignPhysicalCount()` en el Provider**: El `PhysicalCountProvider` incorpora la lógica de negocio para validar y construir la petición de asignación a partir del estado compartido (empresa, bodega, fecha y personas seleccionadas), permitiendo que la pestaña de Asignación consuma datos capturados en la pestaña de Apertura sin acoplamiento directo entre vistas.
5. **Mejoras de UI en dropdowns**: Los ítems de los selectores Empresa, Bodega y Artículo ahora muestran formato `"código - descripción"` para facilitar la identificación visual. `WarehouseModel` extendido con `Equatable` para resolver el error de aserción de `DropdownButton` al comparar elementos por valor.
6. **Integración `dropdown_button2` con barras de búsqueda**: Migración completa de los tres selectores de apertura a `dropdown_button2` v3.x con `ValueNotifier` y `valueListenable` por selector. Se configuraron `onMenuStateChange` para limpiar el filtro de búsqueda al cerrar cada dropdown.
7. **Rediseño de AuthScreen (Dual Login Responsivo)**: Se implementó un `LayoutBuilder` en la pantalla inicial de autenticación que expone simultáneamente el inicio de sesión contra el Servidor Real (`HttpAuthRepository`) y el Entorno de Pruebas Mock. Se apilan verticalmente en pantallas pequeñas y se ubican uno al lado del otro en escritorio.
8. **Eliminación Total de `MockAuthService`**: Se eliminó el uso de servicios mock independientes para sesión. El `AuthWrapper` en `main.dart` ahora observa unificadamente el `AuthProvider`. Se introdujo el método `mockLogin` directamente en el Provider para inyectar credenciales simuladas localmente cuando el usuario usa el panel Mock, centralizando el estado de autenticación.
9. **Refactorización del Botón Logout**: Todas las vistas de la app (`HomeScreen`, `InventoryScreen`) fueron migradas para ejecutar `context.read<AuthProvider>().logout()` finalizando exitosamente la transición global al estado manejado por Provider.

## 16. Preparación para Producción

Todo lo relacionado con el despliegue en Google Play Store y entornos de producción está documentado en el archivo dedicado:

📄 **[SigoAPP_Produccion.md](./SigoAPP_Produccion.md)**

Resumen de los aspectos cubiertos:

| Área | Estado | Referencia |
|------|--------|------------|
| Variables de entorno (`AppConfig`, `flutter_dotenv`) | ✅ | Sección 2 |
| Application ID (`com.funcionintegralsas.sigoapp`) | ✅ | Sección 3.1 |
| Permiso INTERNET en release | ✅ | Sección 3.2 |
| Nombre de la app (`SIGAPP`) en todas las plataformas | ✅ | Sección 5 |
| Logger centralizado (`AppLogger` + `avoid_print`) | ✅ | Sección 4 |
| Protección de tokens JWT en logs | ✅ | Sección 4.2 |
| Credenciales mock eliminadas de UI de producción | ✅ | Sección 4.4 |
| SafeArea en pantalla de login | ✅ | Sección 6.1 |
| Confirmación de salida (`PopScope`) en Dashboard | ✅ | Sección 6.2 |
| Signing config (keystore de producción) | ⏳ | Sección 3.4 |
| Ícono adaptativo (`flutter_launcher_icons`) | ✅ | Sección 6.3 |
| URL de producción | ⏳ | Sección 2 |

---

## 17. Control de Cambios e Histórico (v2.1 a v2.2)

1. **Infraestructura de Configuración Centralizada**: Se creó `lib/utils/app_config.dart` (`AppConfig`) como única fuente de configuración del cliente HTTP. Valida la presencia de `API_URL` en dotenv y provee `AppConfig.createDio()` con timeouts, cabeceras y `JsonInterceptor` precargados. Se eliminaron los fallbacks silenciosos (`'https://api.tu-servidor.com'`, `'http://10.0.2.2:8080'`).

2. **Logger centralizado (`AppLogger`)**: Se creó `lib/utils/app_logger.dart` con métodos estáticos (`d`, `i`, `w`, `e`) que verifican `kDebugMode` antes de imprimir. La regla `avoid_print: true` fue habilitada en `analysis_options.yaml` para que el linter detecte cualquier `print()` residual.

3. **Inyección de Dio unificada**: `HttpAuthRepository` fue refactorizado para recibir `Dio` por constructor (igual que `HttpPhysicalCountRepository`). `main.dart` crea una única instancia de `Dio` vía `AppConfig.createDio()` e inyecta la misma a ambos repositorios.

4. **Corrección de Application ID**: El `namespace` y `applicationId` en `android/app/build.gradle.kts` fueron cambiados de `com.example.flutter_application_1` a `com.funcionintegralsas.sigoapp`. Google Play rechaza cualquier app con `com.example.*`.

5. **Permiso INTERNET en release**: Se agregó `<uses-permission android:name="android.permission.INTERNET"/>` al `AndroidManifest.xml` principal (antes solo estaba en los manifests de `debug/` y `profile/`).

6. **Nombre de la app unificado a `"SIGAPP"`**: El nombre genérico `flutter_application_1` fue reemplazado por `"SIGAPP"` en todos los archivos nativos de cada plataforma soportada (Windows, Android, iOS, Web, Linux, macOS).

7. **UX Nativa**: Se agregó `SafeArea` en `AuthScreen` (protección contra notch/punch-hole) y `PopScope` con diálogo de confirmación en `DashboardScreen` (previene cierre accidental con botón atrás de Android).

8. **Protección de datos sensibles en logs**: Los bloques `debugPrint` que exponían el token JWT y el refresh token en `auth_provider.dart` fueron envueltos con `if (kDebugMode)`. Las llamadas `print()` en `http_physical_count_repository.dart` y `json_interceptor.dart` fueron migradas a `AppLogger`. El `debugPrint` de migración de SQLite en `database_helper.dart` también fue protegido con `kDebugMode`.

9. **Credenciales mock eliminadas de UI**: `AuthScreen` ya no precarga los controladores con las credenciales de prueba ni muestra el texto `'Credenciales de prueba: operador@inventario.com / 123456'` en la interfaz de producción. El panel Mock (con credenciales visibles) solo se renderiza con `!kReleaseMode`.

10. **Documentación de producción**: Se creó el archivo `.context/SigoAPP_Produccion.md` como documento dedicado con checklist de release, guía de keystore, estado de cada módulo mock vs. real, y registro de todos los cambios de esta fase.

11. **Configuración de Ícono Adaptativo y Ejecutable**: Se incorporó la dependencia `flutter_launcher_icons` (^0.14.3) en `pubspec.yaml` apuntando a `assets/images/LOGO_SIN_FONDO.png`. Se generaron exitosamente los íconos nativos para Android, iOS y ejecutable de Windows.

