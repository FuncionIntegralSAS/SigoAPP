# Documentación de Arquitectura de Software
Proyecto: SigoAPP
Versión: 2.4  
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
Todos los modelos de la aplicación siguen una estricta convención de nomenclatura: las propiedades en Dart deben estar escritas en **español `lowerCamelCase`** (ej. `codigoActivo`, `fechaSincronizacion`) para mantener la legibilidad semántica en el dominio y la UI. Sin embargo, para garantizar la compatibilidad con el backend (Spring Boot) y las bases de datos locales (SQLite preexistente), el mapeo en `fromJson`/`toJson` y `fromMap`/`toMap` debe conservar o soportar las llaves originales mediante `@JsonKey` o mecanismos de fallback (ej. `json['idBodega'] ?? json['warehouseId']`).

### 2.1 article_model.dart
Representa un activo físico del inventario. Separa explícitamente la identidad de base de datos / geolocalización (`id: int?`, mapeado a `afgeIdre`) de la identidad de negocio (`codigoActivo: String`, código de barras/QR de la empresa). Incluye responsable asignado, ubicación y metadatos operativos. Todos los flujos operativos (traslados, conteo físico, requisiciones) utilizan `codigoActivo` para prevenir inconsistencias en los payloads hacia el backend.

### 2.2 transfer_request.dart
Modelo central para el traslado físico de activos. Mantiene el estado del flujo y garantiza la trazabilidad entre bodegas y responsables. Soporta serialización JSON automática mediante `json_annotation` / `json_serializable` (archivo generado: `transfer_request.g.dart`).
* Campos de firma asíncrona: `dispatcherSignatureBase64` y `receiverSignatureBase64` (ambos `String?`), permitiendo rastrear si el emisor o el receptor ya plasmaron su firma antes de culminar el traspaso a estado `pr` (procesado/completado).

### 2.3 transfer_filter.dart
Filtro inmutable para consultas de traspasos. Permite acotar búsquedas por estado, bodega propuesta, responsable y rango de fechas. Implementa `copyWith` para actualizaciones parciales sin mutación.

### 2.4 transfer_delivery_request.dart
Modelo de transporte (DTO) para registrar la firma digital en el flujo de entrega y recepción de traspasos.
* Encapsula `transferId` y las firmas opcionales `dispatcherSignatureBase64` y `receiverSignatureBase64`.
* Permite envíos parciales (asíncronos) desde dispositivos y momentos temporales distintos (el despachador firma antes de la salida física y el receptor confirma al recibir).

### 2.5 requisition_model.dart
Representa una solicitud administrativa de consumo o salida de inventario.
* Responsabilidades: Preservar la trazabilidad jerárquica de cantidades (Solicitada -> Aprobada -> Entregada).
* Llave Primaria: compositeId (generada a partir de empresa, tipo de documento, número, bodega y artículo).
* Estados soportados: 'pe' (Pendiente), 'ap' (Aprobada), 'na' (Rechazada/No aprobada), 'pr' (Procesada).

### 2.6 physical_count_model.dart y company_model.dart (Módulo de Conteo Físico - Apertura)
Modelos encargados de la recolección de datos para la generación de la apertura de un conteo físico de inventario.
* `PhysicalCountRequest`: Capta empresa, bodega, fecha, artículos, bandera de verificación lógica/física y lista de participantes (solo IDs enviados en JSON para optimización).
* `CompanyModel`: Entidad simple para listar empresas base.

### 2.7 active_count_model.dart y count_record_model.dart (Módulo de Conteo Físico - Ejecución Offline)
Modelos diseñados para la operación offline del conteo físico en piso (SQLite).
* `ActiveCountModel`: Representa la cabecera de un conteo activo con metadatos de sincronización. Incluye serialización bidireccional SQLite (`toMap` / `fromMap`).
* `CountRecordModel`: Registro individual de lectura por parte del contador. Soporta serialización dual:
  - SQLite local (`toMap` / `fromMap`) para persistencia offline.
  - API Spring Boot (`toJsonApi`) para sincronización con el backend. El formato de API utiliza nomenclatura en español según convención del procedimiento almacenado.

### 2.8 Modelos de Soporte
* `personal_model.dart`: Modelo de datos del personal de la empresa para el módulo de Conteo Físico. Almacena los datos de identificación del empleado bajo la nomenclatura de base de datos (`perscodi`, `persnomb`, `persapel`, `perscoel`, `persdivi`, `persesta`). Su factory constructor `fromJson` implementa un mapeo tolerante a múltiples formatos de llave (minúsculas, mayúsculas, camelCase y las llaves directas del endpoint de personal: `cedula`, `nombre`, `apellido`, `correo`, `division`, `estado`).
* `user_model.dart`: Modelo básico de usuario autenticado (id, name, email).
* `warehouse_model.dart`: Bodega o centro de costos con deserialización desde API. Extiende `Equatable` con `bodeCodi`, `bodeDesc` y `bodeEsta` como `props`, permitiendo la comparación por valor requerida por `DropdownButton`.

### 2.9 Modelos de Asignación y Cierre de Conteo Físico (physical_count_model.dart)
Además de `PhysicalCountRequest`, este archivo contiene los modelos para el flujo de asignación y cierre:
* `AsignacionConteoRequest`: Encapsula los datos requeridos por el endpoint `POST /api/v1/conteo-fisico/asignar_articulos`: `empresa`, `bodega`, `fechaConteo` (ISO 8601 UTC) y la lista de `UsuarioAsignacion`.
* `UsuarioAsignacion`: Representa a cada contador asignado con `documento` (cédula), `nombre` (nombre + apellido concatenados) y `email`. Ambas clases implementan `Equatable` y exponen `toJson()` con la estructura exacta del schema Swagger.
* `CierreConteoRequest`: Modelo de petición para el cierre de un conteo activo. Encapsula únicamente el campo `bodega` (String), mapeado directamente al campo `@NotBlank` del backend Spring Boot.
* `ConteoFisicoResponse`: Modelo de respuesta de los endpoints de conteo (particularmente `/cerrar`). Contiene `success` (bool) y `message` (String). Implementa `Equatable` y `fromJson` con valores por defecto defensivos.

### 2.10 geolocation_model.dart (Módulo de Geolocalización)
Representa las coordenadas geográficas asociadas a un activo físico en la base de datos Oracle / Spring Boot.
* Campos principales: `afgeIdre` (int, ID del registro del activo), `afgeLati` (double, latitud), `afgeLong` (double, longitud).
* Campos de auditoría opcionales: `afgeFcre`, `afgeUcre`, `afgeFedi`, `afgeUedi`.
* Serialización bidireccional JSON tipada (`fromJson`, `toJson`).

## 3. Capa de Repositorios (lib/repositories/)
### 3.1 TransferRepository (Contrato Único)
Contrato asíncrono (`Future`) que define la creación, consulta y procesamiento de solicitudes de traspaso de activos. Ambas implementaciones (mock y HTTP) cumplen este mismo contrato, lo que permite intercambiarlas mediante inyección de dependencias en `main.dart`.
* `create(TransferRequest)`: Crea una nueva solicitud.
* `getAllTransfers()`: Obtiene todas las solicitudes.
* `approveTransfer(String)`: Aprueba una solicitud por ID.
* `rejectTransfer({requestId, rejectionReason})`: Rechaza con motivo obligatorio.
* `applyTransfer(TransferRequest)`: Aplica un traspaso aprobado (nota: redundante si el backend aplica automáticamente al aprobar).
* `applyTransferDelivery(TransferDeliveryRequest)`: Registra la firma digital parcial o total del traspaso en el backend (`POST /api/v1/traspasos/{id}/entregar`).

#### 3.1.1 MockTransferRepository
Implementación en memoria que utiliza `MockInventoryService` como fuente de datos para desarrollo y pruebas offline. Las operaciones son síncronas internamente pero devuelven `Future` para cumplir el contrato.

#### 3.1.2 HttpTransferRepository
Implementación HTTP real que conecta con los endpoints del backend Spring Boot utilizando `Dio`. Lanza `TransferBusinessException` cuando ocurren errores de red o respuestas no exitosas del servidor.

### 3.2 RequisitionRepository
Contrato que define el acceso a las requisiciones de consumo.
* getRequisitionsByStatus(String status): Consulta filtrada de requerimientos.
* processBatch(Map<String, int> selectedItems, String targetStatus): Envío de múltiples identificadores y cantidades en bloque para optimización de transacciones.

### 3.3 GeolocationRepository
Contrato abstracto para la persistencia y consulta de geolocalización de activos físicos (`lib/repositories/geolocation_repository.dart`).
* `getGeolocationByAssetId(int assetId)`: Consulta coordenadas existentes para un activo (`GET /api/v1/geolocalizacion-activos/{assetId}`).
* `createGeolocation(GeolocationModel model)`: Registra nuevas coordenadas (`POST /api/v1/geolocalizacion-activos`).
* `updateGeolocation(GeolocationModel model)`: Actualiza coordenadas de un activo (`PUT /api/v1/geolocalizacion-activos/{afgeIdre}`).
* `deleteGeolocation(int assetId)`: Elimina el registro geográfico (`DELETE /api/v1/geolocalizacion-activos/{assetId}`).

#### 3.3.1 HttpGeolocationRepository
Implementación concreta que utiliza la instancia unificada de `Dio`. Lanza `GeolocationBusinessException` ante fallos de respuesta del servidor o problemas de red.

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
Toda la comunicación de red, gestión de interceptores (Dio), manejo de excepciones y convenciones de payload está delegada y estandarizada en nuestro archivo de reglas. Para más detalles, consultar imperativamente **[Rules_Networking.md](./Rules_Networking.md)**.

### 4.6 physical_count_service.dart
Servicio HTTP real para el módulo de Conteo Físico. Conecta con el backend Spring Boot a través de `Dio` para las siguientes operaciones:
* `getCompanies()` → `GET /api/v1/empresas`: Carga el catálogo de empresas.
* `getWarehouses(companyId)` → `GET /api/v1/bodegas/{empresa}`: Carga bodegas por empresa.
* `getArticles(warehouseId, companyId)` → `GET /api/v1/bodegas/asignados/{bodega}/{empresa}`: Carga artículos asignados a una bodega. Implementa fallback a datos mock cuando `companyId` es nulo/vacío o cuando el backend lanza `DioException`. Antepone la opción `"Todos"` (id: `'All'`) al resultado exitoso del backend.
* `searchPersons({nombre, apellido, cedula})` → `GET /api/v1/personal/buscar`: Búsqueda de personal por coincidencia. Envía los query params con las llaves exactas del backend (`nombre`, `apellido`, `cedula`). Lanza `DioException` 400 de forma local si no se provee ningún parámetro, sin consumir recursos de red.
* `createPhysicalCount(request)` → `POST /api/v1/conteo-fisico/registrar`: Crea la apertura del conteo físico.
* `assignArticles(request)` → `POST /api/v1/conteo-fisico/asignar_articulos`: Asigna los contadores seleccionados al conteo abierto.
* `closePhysicalCount(token, request)` → `POST /api/v1/conteo-fisico/cerrar`: Cierra un conteo físico activo para una bodega. Requiere envío explícito del header `Authorization` (mismo patrón que `reportarConteo`). Retorna `ConteoFisicoResponse` con los campos `success` y `message` del backend.

### 4.7 bluetooth_printer_service.dart
Servicio de comunicación directa con hardware de impresoras Bluetooth (SPP / clásicas). Utiliza `flutter_pos_printer_platform_image_3` para descubrimiento y conexión de dispositivos. Implementado para enviar tramas de bytes sin necesidad de drivers en el SO.

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

### 6.2 geolocation_business_exception.dart
Excepción tipada para errores de negocio y conectividad en las operaciones de geolocalización (`HttpGeolocationRepository`).
* Extrae el campo `message` y `code` enviados en la respuesta JSON estructurada del backend (`{success: false, message: ...}`).
* Proporciona mensajes claros para la capa de presentación cuando las peticiones REST de ubicación fallan.

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
Orquestador de estado para el submódulo de Conteo Físico (Apertura, Asignación y Cierre).
* Administra las listas maestras de selectores (dropdowns) con carga en cascada: Empresa → Bodega → Artículos.
* Mantiene **dos grupos de estado independientes** para evitar interferencias entre las pestañas:
  - Estado global (`_state`, `_errorMessage`): para los flujos de Apertura y Asignación.
  - Estado de cierre (`_closeState`, `_closeErrorMessage`, `_closeSuccessMessage`): exclusivo de la pestaña de Cierre, completamente desacoplado.
* `createAndAssignPhysicalCount()`: Método unificado que realiza las dos peticiones HTTP en secuencia (creación → asignación). Valida en cliente todos los campos de ambas pestañas (empresa, bodega, artículo y al menos un participante seleccionado). Si la creación falla, detiene el flujo y notifica el error; si pasa, ejecuta la asignación. Permite que el usuario complete el flujo completo desde un único botón en la segunda pestaña.
* `searchPersons({nombre, apellido, cedula})`: Valida en cliente que al menos un campo tenga valor, delega al servicio y actualiza `foundPersons`. Maneja errores 400 y de red con mensajes diferenciados.
* `togglePersonSelection(person)` / `removePerson(person)`: Gestionan la lista `selectedPersons` comparando personas por `perscodi` (sin dependencia de referencia de objeto).
* `closePhysicalCount(token, warehouseCode)`: Valida en cliente que `warehouseCode` no esté vacío, construye `CierreConteoRequest` y delega al repositorio. Almacena el `message` de `ConteoFisicoResponse` en `closeSuccessMessage` para mostrarlo en el diálogo de éxito. Maneja errores HTTP 400 y 403 con mensajes diferenciados. Expone `clearCloseError()` y `resetCloseForm()` para que la UI limpie el estado tras interacciones.

### 8.7 ActiveCountProvider
Orquestador de estado para la ejecución offline del conteo físico en piso.
* Consume `DatabaseHelper` directamente para operaciones CRUD sobre SQLite.
* Administra registros de lecturas de códigos de barras y artículos pendientes de conteo.

### 8.8 PrinterProvider
Gestor de conexión e impresión Bluetooth global.
* Mantiene la lista de dispositivos emparejados y el estado de la conexión.
* Delega en `BluetoothPrinterService` para los comandos de red.
* Contiene la lógica de transformación usando `esc_pos_utils_plus` para generar los tickets QR de manera nativa (comando directo) en paralelo a la generación de archivos PDF.

### 8.9 TransferDeliveryProvider
Orquestador de estado para el submódulo de Entrega / Recepción de traspasos.
* Consume `TransferRepository` para consultar solicitudes aprobadas (`ap`) y remitir firmas digitales (`applyTransferDelivery`).
* Implementa filtrado local en base al identificador/cédula del usuario en sesión (`getAssignedTransfers(userIdentifier)`).
* Gestiona el envío asíncrono y parcial de firmas (emisor o receptor) convirtiendo las capturas en Base64.

### 8.10 GeolocationProvider
Gestor de estado para la sincronización y consulta de geolocalización de activos.
* Consume `GeolocationRepository`.
* `syncGeolocation(int assetId, double lat, double lon)`: Orquesta la sincronización automática (intenta obtener coordenadas existentes; si no existen invoca POST `createGeolocation`, y si existen invoca PUT `updateGeolocation`).
* `getGeolocation(int assetId)`: Consulta la ubicación registrada para un activo.
* Expone la bandera `isLoading` para estados visuales de progreso.

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
* `PhysicalCountAssignmentTab`: Asignación de contadores al conteo (primera pestaña). Incluye:
  - Panel `ExpansionTile` de búsqueda avanzada con campos Nombre, Apellido y Cédula.
  - `ListView` de resultados con `CircleAvatar`, nombre completo y cédula por entrada; selección múltiple mediante `Checkbox`.
  - Sección de participantes seleccionados como `Chip` eliminables.
  - **No contiene botón de acción propio**; la acción final se delega al botón de la pestaña de Apertura.
  - Overlay de `CircularProgressIndicator` durante operaciones asíncronas.
  - Manejo de errores vía `SnackBar` rojo usando `addPostFrameCallback` para evitar llamadas a `setState` durante el build.
* `PhysicalCountOpeningTab`: Formulario de apertura con selectores en cascada (Empresa, Bodega, Artículo) implementados con `dropdown_button2` v3.x (segunda pestaña). Incluye barras de búsqueda dinámicas en cada dropdown usando `DropdownTemplates.searchData` y `ValueNotifier` por selector para sincronizar estado con el Provider. Los ítems se muestran en formato `"código - descripción"`. Contiene el **único botón de acción** del flujo: "Generar Apertura y Asignar Personal", que dispara `provider.createAndAssignPhysicalCount()` ejecutando las dos peticiones HTTP en secuencia. El diálogo de éxito indica que tanto la apertura como la asignación se completaron.
* `PhysicalCountClosingTab`: Pestaña independiente de Cierre de Conteo (tercera pestaña). Incluye:
  - `TextField` para ingresar el código de la bodega a cerrar (campo de texto libre; se reemplazará por lista de valores en iteración futura).
  - Botón rojo "Cerrar Conteo" que primero muestra un **diálogo de confirmación** antes de ejecutar la petición.
  - **Diálogo de confirmación** con título `"CONFIRMAR CIERRE"` en mayúsculas, texto explicativo con el código de bodega interpolado, y fila de botones horizontales forzada mediante `Row` + `Expanded`: `OutlinedButton` (Cancelar, color deepPurple, forma `StadiumBorder`) y `ElevatedButton` (Confirmar, color rojo, forma `StadiumBorder`).
  - **Diálogo de resultado** con título `"CONTEO CERRADO"` en mayúsculas, mensaje proveniente del backend (`provider.closeSuccessMessage`) con fallback, y botón verde "Aceptar" alineado a la derecha.
  - Consume exclusivamente `closeState` / `closeErrorMessage` / `closeSuccessMessage` del provider, sin afectar el estado de las otras pestañas.
  - Obtiene el token JWT de `AuthProvider` en el momento del envío y lo pasa como parámetro al provider.

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
* `TransferDeliveryScreen`: Listado de traspasos aprobados asignados al usuario para iniciar el proceso de firmas.
* `SignatureCaptureScreen`: Pantalla interactiva con canvas de dibujo (paquete `signature`) para registrar la firma digital según el rol del usuario (despachador o receptor con validación de precedencia).

## 10. Flujo Funcional Integrado (Traspasos y Requisiciones)
El sistema opera bajo una premisa de desacoplamiento de interfaz y negocio. La UI solo despacha intenciones al Provider, quien delega al Repositorio. El inventario real o los estados de requisición solo se alteran tras la respuesta exitosa del servidor.
* **Flujo Asíncrono de Traspasos:**
  1. *Generación (`pe`)*: Solicitud creada desde `InventoryScreen`.
  2. *Aprobación (`ap`)*: Aprobada desde `TransferApprovalScreen`.
  3. *Firma Despachador*: El emisor firma en `SignatureCaptureScreen` autorizando la salida física.
  4. *Firma Receptor*: El receptor valida la recepción firmando en su dispositivo (solo permitido tras la firma del despachador).
  5. *Completado (`pr`)*: Con ambas firmas registradas, el estado transiciona a completado.

## 11. Principios de Diseño Consolidados
* Inmutabilidad en Modelos.
* Separación de responsabilidades (Clean Architecture).
* Optimización de red mediante Batch Processing (envío masivo).
* UI Reactiva mediante Provider.
* Contrato único de repositorio con implementaciones intercambiables (Mock/HTTP).
* Excepciones de dominio tipadas para diferenciación de errores.
* Persistencia local offline con sincronización diferida (SQLite + Backend).
* Cliente HTTP estandarizado (`Dio`) como única librería de red.
* **Recuperación de Estado en Providers Globales:** Las pantallas principales que consumen Providers instanciados de manera global (ej. en `main.dart`) deben estar implementadas preferentemente como `StatefulWidget`. En su ciclo de vida (`initState`), deben verificar si el proveedor mantiene un estado de error previo (ej. por expiración de token 401 o falla de red) o si sus listas maestras están vacías, para invocar automáticamente la recarga de datos iniciales. Esto garantiza la resiliencia en la navegación del usuario sin requerir reinicios de la aplicación.

---

## 12. Preparación para Producción

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

## 13. Historial de Cambios (Changelog)

El registro de las evoluciones arquitectónicas y controles de cambio pasados ha sido movido a su propio documento para mantener este archivo estrictamente enfocado en la composición actual y vigente del proyecto.

Para consultar el historial de versiones, dirígete a:
📄 **[SigoAPP_Historial_Cambios.md](./SigoAPP_Historial_Cambios.md)**
