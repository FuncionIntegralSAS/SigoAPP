# Mapa de Módulos de SigoAPP
Propósito: Documentar la relación directa entre cada módulo funcional del sistema y todos los archivos de código involucrados (pantallas, providers, repositorios, modelos, servicios, widgets y utilidades).  
Versión: 1.1  
Fecha de actualización: Agosto 2026

> [!NOTE]
> Este documento es un **archivo pivote** diseñado para ser consumido por agentes de IA y desarrolladores como punto de entrada rápido, mapeando exclusivamente archivos, dependencias, roles y contratos operativos. Las especificaciones de diseño, colores, componentes visuales y lineamientos de interfaz se encuentran centralizadas en [`SigoAPP_Guia_Estilos_UI.md`](./SigoAPP_Guia_Estilos_UI.md).

---

## Índice de Módulos

| # | Módulo de Negocio | Sub-funcionalidades | Permiso(s) Involucrados |
|---|-------------------|---------------------|-------------------------|
| 1 | [Autenticación y Dominio](#1-autenticación-y-dominio) | Configuración de dominio, Login JWT, Expiración de sesión (401) | Ninguno (público) |
| 2 | [Dashboard Principal](#2-dashboard-principal) | Navegación dinámica por permisos | Autenticación válida |
| 3 | [Inventario](#3-inventario) | Verificación de Activos (QR + GPS), Generación de Traspasos, Aprobación de Traspasos, Entrega / Recepción (Firmas) | `avac`, `agqr`, `agst`, `aatr`, `aein` |
| 4 | [Requisiciones](#4-requisiciones) | Aprobación, Entrega de inventario, Firma Digital y Cierre Salida ERP | `areq` |
| 5 | [Conteo Físico](#5-conteo-físico) | Apertura, Asignación de Personal, Cierre, Ejecución Offline | `aacf`, `aacu`, `accf`, `arcf`, `asin` |
| 6 | [Módulo Principal (Solo Debug)](#6-módulo-principal-solo-debug) | Scanner QR, Generador QR, Gestión de cuentas | `kReleaseMode == false` |

---

## 1. Autenticación y Dominio

**Descripción:** Flujo obligatorio de configuración inicial de dominio (QR), autenticación del usuario (login JWT) y gestión centralizada del ciclo de vida de la sesión (expiración automática 401 y logout desacoplado). Punto de arranque de toda la aplicación.

| Capa | Archivo | Ruta |
|------|---------|------|
| **Orquestador** | `main.dart` | `lib/main.dart` |
| **Screen** | `DomainScannerScreen` | `lib/modules/auth/screens/domain_scanner_screen.dart` |
| **Screen** | `AuthScreen` | `lib/modules/auth/screens/auth_screen.dart` |
| **Provider** | `AuthProvider` | `lib/modules/auth/providers/auth_provider.dart` |
| **Repositorio (contrato)** | `AuthRepository` | `lib/modules/auth/repositories/auth_repository.dart` |
| **Repositorio (HTTP)** | `HttpAuthRepository` | `lib/modules/auth/repositories/http_auth_repository.dart` |
| **Repositorio (mock)** | `MockAuthRepository` | `lib/modules/auth/repositories/mock_auth_repository.dart` |
| **Modelo** | `AuthResponse`, `LoginRequest`, `LoginContadorRequest`, `AppPermission`, `Permiso` | `lib/modules/auth/models/auth_model.dart` |
| **Modelo** | `UserModel` | `lib/modules/auth/models/user_model.dart` |
| **Utilidad** | `AppConfig` | `lib/utils/app_config.dart` |
| **Utilidad** | `PermissionUtils`, `PermissionListExtension` | `lib/utils/permission_utils.dart` |
| **Utilidad** | `AppLogger` | `lib/utils/app_logger.dart` |
| **Utilidad** | `JsonInterceptor` (Dio) | `lib/utils/json_interceptor.dart` |
| **Utilidad** | `AuthInterceptor` (Dio) | `lib/utils/auth_interceptor.dart` |
| **Utilidad** | `MockHttpInterceptor` (Dio simulación local) | `lib/utils/mock_http_interceptor.dart` |
| **Utilidad** | `AuthUtils` (Cierre de sesión centralizado) | `lib/utils/auth_utils.dart` |
| **Test Unitario** | `auth_provider_test.dart` | `test/providers/auth_provider_test.dart` |

**Estados del Provider:** `AuthProvider` mantiene: `isAuthenticated`, `isContador` (bandera formal del tipo de sesión), `currentToken`, `currentCedula` (cédula del colaborador), `currentUsername`, `permisos`.

> [!NOTE]
> **Identificación de Sesión y Enrutamiento Raíz:**
> 1. **Cédula del Colaborador (`documento`):** En el login administrativo (`POST /api/v1/auth/login`), el backend devuelve el campo `documento` con la cédula del colaborador en nómina (`PERSONAL.PERSCODI`). `AuthResponse` lo expone como `documento` y `AuthProvider` lo almacena en `_cedula` (`currentCedula`), persistido en `FlutterSecureStorage` (`auth_cedula`). Esto permite que módulos dependientes como Entrega/Recepción de Traspasos y Requisiciones validen la identidad del colaborador directamente por su cédula.
> 2. **Formalización del Tipo de Sesión (`isContador`):** Para evitar proxies ambiguos como `currentCedula == null`, `AuthProvider` gestiona explícitamente el booleano `_isContador` persistido en secure storage (`auth_is_contador`). `AuthWrapper` en `main.dart` evalúa `authProvider.isAuthenticated && !authProvider.isContador` para redirigir al `DashboardScreen` administrativo, permitiendo que las sesiones de contador permanezcan aisladas en el flujo offline de `AccountScreen`.

---

## 2. Dashboard Principal

**Descripción:** Panel de navegación post-login. Muestra dinámicamente las opciones de módulo según los permisos del usuario autenticado. Controla la confirmación de salida (`PopScope`).

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `DashboardScreen` | `lib/modules/dashboard/screens/dashboard_screen.dart` |
| **Provider consumido** | `AuthProvider` (solo lectura de permisos) | `lib/modules/auth/providers/auth_provider.dart` |
| **Modelo consumido** | `AppPermission` | `lib/modules/auth/models/auth_model.dart` |
| **Utilidad** | `PermissionListExtension.hasPermission()` | `lib/utils/permission_utils.dart` |
| **Utilidad** | `AuthUtils` (Cierre de sesión centralizado) | `lib/utils/auth_utils.dart` |

**Navegación desde Dashboard (agrupada por módulo de negocio):**

| Opción en Dashboard | Permiso | Módulo de Negocio | Pantalla Destino |
|---------------------|---------|-------------------|------------------|
| Verificación de Activos | `avac` | Inventario | `AssetVerificationScreen` |
| Generar solicitud de traspaso | `agst` | Inventario | `InventoryScreen` |
| Aprobación de Traspasos | `aatr` | Inventario | `TransferApprovalScreen` |
| Entrega / Recepción | `aein` | Inventario | `TransferDeliveryScreen` |
| Requisiciones | `areq` | Requisiciones | `RequisitionsScreen` |
| Firma de Requisiciones | `areq` | Requisiciones | `RequisitionSignatureScreen` |
| Conteo Físico | `aacf` ∨ `aacu` ∨ `accf` | Conteo Físico | `PhysicalCountScreen` |
| Ejecutar Conteo | `arcf` | Conteo Físico | `ActiveCountScreen` |
| Módulo Principal | Solo `!kReleaseMode` | Debug | `HomeScreen` |

---

## 3. Inventario

**Documentación Funcional:** [`SigoAPP_Funcional_Inventario.md`](./SigoAPP_Funcional_Inventario.md) | [`SigoAPP_Funcional_Traspasos.md`](./SigoAPP_Funcional_Traspasos.md)

**Descripción:** Módulo de negocio que agrupa todas las funcionalidades relacionadas con la gestión del inventario de activos físicos: verificación mediante QR con captura de coordenadas GPS, generación de solicitudes de traspaso entre bodegas y aprobación/rechazo de dichas solicitudes.

### 3.1 Verificación de Activos y Geolocalización

**Permiso:** `avac`  
**Descripción:** Verificación de activos mediante escaneo QR con captura, consulta y sincronización de datos geográficos (coordenadas GPS: latitud y longitud).

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `AssetVerificationScreen` | `lib/modules/inventory/screens/asset_verification_screen.dart` |
| **Provider** | `AssetVerificationProvider` | `lib/modules/inventory/providers/asset_verification_provider.dart` |
| **Provider** | `GeolocationProvider` | `lib/modules/inventory/providers/geolocation_provider.dart` |
| **Repositorio (contrato)** | `GeolocationRepository` | `lib/modules/inventory/repositories/geolocation_repository.dart` |
| **Repositorio (HTTP)** | `HttpGeolocationRepository` | `lib/modules/inventory/repositories/http_geolocation_repository.dart` |
| **Modelo** | `ArticleModel` (identificador negocio `codigoActivo`, ID BD `id`) | `lib/modules/inventory/models/article_model.dart` |
| **Modelo** | `GeolocationModel` | `lib/modules/inventory/models/geolocation_model.dart` |
| **Excepción** | `GeolocationBusinessException` | `lib/exceptions/geolocation_business_exception.dart` |
| **Utilidad** | `ArticleQrParser` | `lib/utils/article_qr_parser.dart` |

### 3.2 Generación de Traspasos

**Permiso:** `agst` (generar traspaso), relacionado con `agqr` (generación QR)  
**Descripción:** Gestión de inventario con filtrado en cascada Empresa → Bodega Origen Personal (`tipo: 'PE'` validado vía `WarehouseModel.isPersonal` y filtrado en selector de `TransferFormWidget`; ante errores de negocio o bodegas no permitidas se vacía la lista de activos y se despliega alerta visual) → Colaborador (`TransferRepository.getPersonsByWarehouse` con filtro `AND B.BODETIBO = 'PE'`, ejecutando `getAssetsByPerson` exclusivamente al seleccionar al colaborador con bodega física obligatoria) y creación de solicitudes de traspaso diferenciadas: **Traspaso Individual** vía botón de acción rápida `⇄` en cada tarjeta de activo (pre-cargando activo único) y **Traspaso Múltiple** interactivo vía Floating Action Button, el cual activa el modo de selección (`_isSelectionMode`) con casillas de verificación, validación de colaborador responsable único y barra de acciones inferior. Orquestación del flujo en `TransferFormProvider` y `TransferFormWidget`:
- Límite máximo de hasta 50 artículos por solicitud (`isAssetSelectable`, `toggleAssetSelection`, alerta SnackBar).
- Validación estricta contra duplicados por `(articulo, placa)` y compatibilidad multi-artículo PL/SQL (`PKG_FI_MOVITRAS` exigiendo mismo `centroInformacion` y mismo `tercero`).
- Bloqueo y descarte de selección para activos con `enTramite == true` (checkbox deshabilitado y badge *"En trámite pendiente"*).
- Propagación transparente y directa de mensajes limpios de negocio `data['msg']` en `HttpTransferRepository` sin recortes de texto. Conexión con endpoints Spring Boot (`POST /api/v1/traspasos/crear`, `GET /api/v1/traspasos/personas`, `GET /api/v1/traspasos/activos?persona={...}&bodega={...}`).

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `InventoryScreen` | `lib/modules/inventory/screens/inventory_screen.dart` |
| **Screen** | `GeneratorScreen` (generación QR) | `lib/modules/inventory/screens/generator_screen.dart` |
| **Provider** | `InventoryProvider` (gestiona inventario y colaboradores vía `TransferRepository`) | `lib/modules/inventory/providers/inventory_provider.dart` |
| **Provider** | `TransferRequestProvider` | `lib/modules/inventory/providers/transfer_request_provider.dart` |
| **Provider** | `TransferFormProvider` | `lib/modules/inventory/providers/transfer_form_provider.dart` |
| **Repositorio (contrato inventario)** | `InventoryRepository` | `lib/modules/inventory/repositories/inventory_repository.dart` |
| **Repositorio (HTTP inventario)** | `HttpInventoryRepository` | `lib/modules/inventory/repositories/http_inventory_repository.dart` |
| **Repositorio (contrato traspasos)** | `TransferRepository` | `lib/modules/inventory/repositories/transfer_repository.dart` |
| **Repositorio (HTTP traspasos)** | `HttpTransferRepository` | `lib/modules/inventory/repositories/http_transfer_repository.dart` |
| **Repositorio (mock traspasos)** | `MockTransferRepository` | `lib/modules/inventory/repositories/mock_transfer_repository.dart` |
| **Repositorio (contrato catálogos)** | `CatalogRepository` | `lib/modules/inventory/repositories/catalog_repository.dart` |
| **Repositorio (HTTP catálogos)** | `HttpCatalogRepository` | `lib/modules/inventory/repositories/http_catalog_repository.dart` |
| **Repositorio (mock catálogos)** | `MockCatalogRepository` | `lib/modules/inventory/repositories/mock_catalog_repository.dart` |
| **Modelo** | `CompanyModel` | `lib/shared/models/company_model.dart` |
| **Modelo** | `WarehouseModel` | `lib/shared/models/warehouse_model.dart` |
| **Modelo** | `ArticleModel` | `lib/modules/inventory/models/article_model.dart` |
| **Modelo** | `TransferPersonModel` | `lib/modules/inventory/models/transfer_person_model.dart` |
| **Modelo** | `TransferAssetModel` | `lib/modules/inventory/models/transfer_asset_model.dart` |
| **Modelo** | `TransferCreateRequest` | `lib/modules/inventory/models/transfer_create_request.dart` |
| **Modelo** | `TransferRequest` | `lib/modules/inventory/models/transfer_request.dart` |
| **Modelo** | `TransferFilter` | `lib/modules/inventory/models/transfer_filter.dart` |
| **Modelo** | `EmployeeResult` | `lib/modules/inventory/models/employee_result.dart` |
| **Widget** | `TransferFormWidget` | `lib/modules/inventory/widgets/transfer_form_widget.dart` |
| **Widget** | `CascadingCatalogsWidget` | `lib/modules/inventory/widgets/cascading_catalogs_widget.dart` |
| **Widget** | `ArticleEditModal` (Edición, GPS y foto desacoplados) | `lib/modules/inventory/widgets/article_edit_modal.dart` |
| **Widget** | `InventoryArticleTile` (Tarjeta de activo con modo normal y selección) | `lib/modules/inventory/widgets/inventory_article_tile.dart` |
| **Widget** | `AppErrorWidget` (Renderizado estandarizado inline/banner) | `lib/shared/widgets/app_error_widget.dart` |
| **Servicio** | `MockInventoryService` | `lib/services/mock_inventory_service.dart` |
| **Servicio** | `NotificationService` / `InAppNotificationService` | `lib/services/notification_service.dart`, `lib/services/in_app_notification_service.dart` |
| **Excepción** | `TransferBusinessException` | `lib/exceptions/transfer_business_exception.dart` |
| **Excepción** | `CatalogBusinessException` | `lib/exceptions/catalog_business_exception.dart` |
| **Utilidad** | `AuthUtils` (Cierre de sesión y reautenticación en banner) | `lib/utils/auth_utils.dart` |

### 3.3 Aprobación de Traspasos

**Permiso:** `aatr`  
**Descripción:** Visualización y gestión (aprobación/rechazo) de solicitudes de traspaso pendientes. Incluye filtros reactivos por estado, búsqueda de responsables, rango de fechas y bodega propuesta. Conectado a consumo HTTP real contra Spring Boot (`HttpTransferRepository`). Integra resolución concurrente (`Future.wait`) entre `CatalogRepository` (para nombres completos de colaboradores formateados como `Nombre Apellido (Cédula)`) y `TransferRepository` (para descripciones oficiales de artículos en `TransferArticleItem.nombre`), optimizado con caché en memoria por lote.

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `TransferApprovalScreen` | `lib/modules/inventory/screens/transfer_approval_screen.dart` |
| **Provider** | `TransferApprovalProvider` | `lib/modules/inventory/providers/transfer_approval_provider.dart` |
| **Repositorio** | `HttpTransferRepository` (vía contrato `TransferRepository`) | `lib/modules/inventory/repositories/http_transfer_repository.dart` |
| **Repositorio (catálogos)** | `CatalogRepository` / `HttpCatalogRepository` | `lib/modules/inventory/repositories/catalog_repository.dart` |
| **Modelo** | `TransferRequest` (con `TransferArticleItem.nombre`) | `lib/modules/inventory/models/transfer_request.dart` |
| **Modelo** | `TransferAssetModel` | `lib/modules/inventory/models/transfer_asset_model.dart` |
| **Modelo** | `EmployeeResult` | `lib/modules/inventory/models/employee_result.dart` |
| **Modelo** | `TransferFilter` | `lib/modules/inventory/models/transfer_filter.dart` |
| **Widget** | `TransferFilterPanel` | `lib/modules/inventory/widgets/transfer_filter_panel.dart` |

> [!IMPORTANT]
> **Consumo HTTP y Ciclo de Vida:** `TransferApprovalProvider` se instancia con `autoLoad: false` en `lib/main.dart` para desacoplar peticiones de red del constructor. `TransferApprovalScreen` es un `StatefulWidget` que dispara la recarga garantizada en `initState` (`WidgetsBinding.instance.addPostFrameCallback`), asegurando datos frescos al ingresar a la pantalla. Además, `loadTransfers({String? empresa, String? bodega})` soporta el paso opcional de filtros contextuales de empresa y bodega hacia los query parameters de `GET /api/v1/traspasos/list`, y coordina el enriquecimiento concurrente por lote con caché local.

> [!TIP]
> **Lineamientos de UI/UX:** Las especificaciones visuales de `TransferApprovalScreen` y `TransferFilterPanel` se detallan en [`SigoAPP_Guia_Estilos_UI.md`](./SigoAPP_Guia_Estilos_UI.md) (§ Módulo 4: Aprobación de Traspasos).

### 3.4 Entrega / Recepción de Traspasos

**Permiso:** Ninguno específico (Filtro por responsable asignado)  
**Descripción:** Paso intermedio tras la aprobación (`ap`). Permite a los responsables del traspaso (despachador `FU` y receptor `DE`) capturar sus firmas de manera desacoplada sin orden estricto mediante canvas interactivo en `SignatureCaptureScreen` (`PUT /api/v1/traspasos/sign/{id}`), y una vez ambas firmas están asentadas, confirmar la recepción en el ERP (`PUT /api/v1/traspasos/recibir/{id}`). `TransferDeliveryProvider` se inyecta con `HttpTransferRepository` y `CatalogRepository`, aplicando enriquecimiento concurrente y preservando los códigos originales de custodios (`personaFuente`, `personaDestino`) para validar la asignación contra la sesión dual (cédula y username).

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `TransferDeliveryScreen` | `lib/modules/inventory/screens/transfer_delivery_screen.dart` |
| **Screen** | `SignatureCaptureScreen` (Canvas interactivo de firma) | `lib/modules/inventory/screens/signature_capture_screen.dart` |
| **Provider** | `TransferDeliveryProvider` (Cotejo dual y firmas desacopladas) | `lib/modules/inventory/providers/transfer_delivery_provider.dart` |
| **Repositorio** | `HttpTransferRepository` (vía contrato `TransferRepository`) | `lib/modules/inventory/repositories/http_transfer_repository.dart` |
| **Repositorio (catálogos)** | `CatalogRepository` / `HttpCatalogRepository` | `lib/modules/inventory/repositories/catalog_repository.dart` |
| **Modelo** | `TransferRequest` (con `personaFuente`/`personaDestino`) | `lib/modules/inventory/models/transfer_request.dart` |
| **Modelo** | `TransferDeliveryRequest` | `lib/modules/inventory/models/transfer_delivery_request.dart` |
| **Excepción** | `TransferBusinessException` (con `friendlyMessage`, `technicalDetails`, `statusCode`) | `lib/exceptions/transfer_business_exception.dart` |
| **Utilidad** | `DialogUtils` (sanitización de errores y modales responsivos) | `lib/utils/dialog_utils.dart` |

---

## 4. Requisiciones

**Documentación Funcional:** [`SigoAPP_Funcional_Requisiciones.md`](./SigoAPP_Funcional_Requisiciones.md)

**Descripción:** Gestión de requisiciones de consumo/salida de inventario. Comprende la aprobación de líneas, la entrega física en bodega con asignación de placas (FIFO), la captura interactiva de firmas digitales manuscritas (Salida SA y Recibo RE) y el asentamiento definitivo en el ERP (`DOCUINVE` y `MOVIINVE`). Conectado a la API Spring Boot (`/api/v1/requisiciones`).

### 4.1 Aprobación y Entrega de Requisiciones (`RequisitionsScreen`)

**Permisos requeridos:** `areq` (Aprobación) y `aein` (Entrega).  
**Punto de entrada:** `DashboardScreen` (Opción "Requisiciones").

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `RequisitionsScreen` | `lib/modules/requisitions/screens/requisitions_screen.dart` |
| **Tab** | `ApprovalTabView` | `lib/modules/requisitions/tabs/approval_tab_view.dart` |
| **Tab** | `DeliveryTabView` | `lib/modules/requisitions/tabs/delivery_tab_view.dart` |
| **Provider** | `RequisitionApprovalProvider` | `lib/modules/requisitions/providers/requisition_approval_provider.dart` |
| **Repositorio (contrato)** | `RequisitionRepository` | `lib/modules/requisitions/repositories/requisition_repository.dart` |
| **Repositorio (HTTP)** | `HttpRequisitionRepository` | `lib/modules/requisitions/repositories/http_requisition_repository.dart` |
| **Modelo** | `RequisitionModel`, `RequisicionDetalle`, `RequisicionResumen`, `RequisicionLineaItem`, `RequisicionFirma` | `lib/modules/requisitions/models/requisition_model.dart` |
| **Modelo** | `CompanyModel` | `lib/shared/models/company_model.dart` |
| **Excepción** | `RequisitionBusinessException` | `lib/exceptions/requisition_business_exception.dart` |
| **Widget** | `RequisitionActionCard` | `lib/modules/requisitions/widgets/requisition_action_card.dart` |
| **Widget** | `RequisitionFilterHeader` | `lib/modules/requisitions/widgets/requisition_filter_header.dart` |

**Permisos por pestaña:**

| Pestaña | Permiso | Status en API |
|---------|---------|---------------|
| Aprobación | `areq` | `'in'` |
| Entrega | `aein` | `'ap'` |

**Filtros y Comportamiento de Tabs:**
- `RequisitionsScreen` utiliza `TabController` con listener. Al iniciar la pantalla (`initState`), se dispara únicamente la carga del catálogo maestro de empresas (`GET /api/v1/empresas/getAll`) mediante `RequisitionApprovalProvider.loadCompanies()`. Se aplica una política de **Lazy Fetch / Fail-Fast UI**, impidiendo la consulta automática de requisiciones sin fecha para proteger la tabla `MOVIRESU`.
- Ambas pestañas (`ApprovalTabView` y `DeliveryTabView`) incorporan en la parte superior el widget institucional `RequisitionFilterHeader` con dos selectores en orden canónico: Empresa (1°) y Fecha `desde` (2°).
- **Estado de Fecha Requerida:** Si no se ha configurado una fecha `desde`, las pestañas muestran un estado instructivo requiriendo seleccionar una fecha inicial.
- **Flujo Master-Detail (Documento ➔ Movimientos):**
  - **Nivel 1 (Master):** La bandeja consume `GET /api/v1/requisiciones` y renderiza tarjetas de documentos de solicitud (`RequisicionResumen`) mediante `RequisitionActionCard`, exponiendo tipo y número de documento, bodega, fecha y estado de líneas. Para especificaciones visuales de la tarjeta, consultar [`SigoAPP_Guia_Estilos_UI.md`](./SigoAPP_Guia_Estilos_UI.md) (§ Módulo 6).
  - **Nivel 2 (Detail bajo demanda):** Al expandir cada documento (`ExpansionTile`), se consulta `GET /api/v1/requisiciones/{empresa}/{tipo}/{num}` con caché en el provider, desplegando los movimientos/artículos (`RequisicionDetalleLinea`) con sus estados, solicitante, observaciones y cantidades.
  - **Procesamiento en Lote (FAB):** Cada línea permite validar y capturar cantidades autorizadas/entregadas ($>0 \land \le \text{máximo permitido}$) y seleccionarse mediante checkbox. El botón flotante `FloatingActionButton` ejecuta la aprobación (`PUT /aprobar`) o entrega (`PUT /entregar`) masiva, notificando vía `SnackBar` y refrescando la bandeja.

---

### 4.2 Firma de Requisiciones y Salida Definitiva ERP (`RequisitionSignatureScreen`)

**Permiso requerido:** Exclusivo **`areq`** (`AppPermission.requisiciones`).  
**Punto de entrada:** `DashboardScreen` (Opción "Firma de Requisiciones").

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `RequisitionSignatureScreen` | `lib/modules/requisitions/screens/requisition_signature_screen.dart` |
| **Screen (Modal/Captura)** | `RequisitionSignatureCaptureScreen` | `lib/modules/requisitions/screens/requisition_signature_capture_screen.dart` |
| **Provider** | `RequisitionSignatureProvider` | `lib/modules/requisitions/providers/requisition_signature_provider.dart` |
| **Repositorio (contrato)** | `RequisitionRepository` | `lib/modules/requisitions/repositories/requisition_repository.dart` |
| **Repositorio (HTTP)** | `HttpRequisitionRepository` | `lib/modules/requisitions/repositories/http_requisition_repository.dart` |
| **Modelo** | `RequisicionResumen`, `RequisicionDetalle`, `RequisicionFirma`, `RequisicionFirmaRequest`, `RequisicionRegistrarRequest` | `lib/modules/requisitions/models/requisition_model.dart` |
| **Widget** | `RequisitionFilterHeader` | `lib/modules/requisitions/widgets/requisition_filter_header.dart` |
| **Test Unitario** | `requisition_signature_provider_test.dart` | `test/providers/requisition_signature_provider_test.dart` |
| **Test Unitario (Modelos)** | `requisition_model_test.dart` | `test/models/requisition_model_test.dart` |

**Características Operativas y Matriz de Estados:**
- **Consulta Protegida:** Requiere obligatoriamente fecha `desde` seleccionada en `RequisitionFilterHeader` (`estado: 'en'`).
- **Inferencia Automática de Roles (Flujo Sin Selección Manual):** El colaborador nunca elige la firma de forma arbitraria; la aplicación valida la identidad a partir de `auth.currentCedula`:
  - **Recepción (RE):** Coincidencia con el solicitante titular (`auth.currentCedula == detail.tercero`) o con el responsable oficial de la bodega destino (`auth.currentCedula == detail.responsableBodegaDestino`) en movimientos entre bodegas. Si coincide y falta firma RE, se habilita de forma exclusiva el botón *"Firmar Recibo (RE)"*.
  - **Salida (SA):** Coincidencia estricta con el responsable de la bodega origen (`auth.currentCedula == detail.responsableBodega`). Sin fallbacks permisivos. Si califica y falta firma SA, se habilita el botón único *"Firmar Salida (SA)"*.
  - **Metadatos Enriquecidos de Firma (`RequisicionFirma`):** Se mapean `tipo`, `persona`, `nombre` y `fecha` (ISO 8601). La condición `firmada` se deriva formalmente como `(fecha != null && fecha.isNotEmpty) || firmada == true`. Los badges visuales exponen el nombre del firmante y la fecha/hora formateada.
  - **Espera de Co-Firmante:** Si el colaborador ya firmó su rol respectivo, la tarjeta muestra un aviso informativo indicando que su firma está asentada y se espera la contraparte.
  - **Usuario Sin Rol:** Si el colaborador no es receptor ni despachador, la tarjeta muestra un aviso indicando que carece de rol en el documento, bloqueando acciones de firma.
  - **Captura Anti-Suplantación (`RequisitionSignatureCaptureScreen`):** Campo de cédula en modo solo lectura (`readOnly: true`), garantizando que la firma manuscrita quede vinculada estrictamente a la sesión autenticada.
  - **Estado "Lista para ERP" (`bothSigned`):** Se ocultan los botones de firma y se habilita la acción *"Registrar Salida"*, reservada de forma exclusiva para el responsable de la bodega fuente (`isDispatcher`). Si el usuario autenticado no es el responsable, se despliega un contenedor informativo indicando que las firmas están completas y la salida está pendiente de registro.
  - **Detalle de Componentes Visuales:** Para la paleta cromática, franjas laterales de estado, badges y modales de este flujo, consultar [`SigoAPP_Guia_Estilos_UI.md`](./SigoAPP_Guia_Estilos_UI.md) (§ Módulo 6).
- **Punto de No Retorno e Idempotencia:** Al pulsar *"Registrar Salida"*, se despliega diálogo modal confirmatorio advirtiendo el impacto inmediato en el inventario. Ejecuta `PUT /api/v1/requisiciones/{empresa}/{tipoDocumento}/{numero}/registrar` enviando `{}` como body (o `RequisicionRegistrarRequest` opcional para recepciones parciales). Si el documento ya fue registrado (`estado == 'rg'`), `RequisitionSignatureProvider` maneja la operación de manera idempotente actualizando el estado local y refrescando la bandeja sin disparar excepción de error al usuario, transicionando el documento y generando los registros oficiales en `DOCUINVE` y `MOVIINVE`.

---

## 5. Conteo Físico

**Descripción:** Módulo de negocio completo para la administración del conteo físico de inventario, desde su apertura y asignación de personal hasta su cierre administrativo y la ejecución en piso en modo offline.

### 5.1 Administración del Conteo (Apertura, Asignación, Cierre)

**Punto de entrada:** `PhysicalCountScreen` → `DashboardScreen` (opción "Conteo Físico")  
**Condición de visibilidad:** Al menos uno de `aacf`, `aacu` o `accf`.  
**Regla de Bodegas:** La apertura de conteo consulta exclusivamente bodegas de tipo físico (`'FI'`) mediante `HttpPhysicalCountRepository.getWarehouses()` (`GET /api/v1/bodegas/empresa/{empresa}/FI`).

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `PhysicalCountScreen` | `lib/modules/physical_count/screens/physical_count_screen.dart` |
| **Tab** | `PhysicalCountAssignmentTab` | `lib/modules/physical_count/tabs/physical_count_assignment_tab.dart` |
| **Tab** | `PhysicalCountOpeningTab` | `lib/modules/physical_count/tabs/physical_count_opening_tab.dart` |
| **Tab** | `PhysicalCountClosingTab` | `lib/modules/physical_count/tabs/physical_count_closing_tab.dart` |
| **Provider** | `PhysicalCountProvider` | `lib/modules/physical_count/providers/physical_count_provider.dart` |
| **Repositorio (contrato)** | `PhysicalCountRepository` | `lib/modules/physical_count/repositories/physical_count_repository.dart` |
| **Repositorio (HTTP)** | `HttpPhysicalCountRepository` | `lib/modules/physical_count/repositories/http_physical_count_repository.dart` |
| **Repositorio (mock)** | `MockPhysicalCountRepository` | `lib/modules/physical_count/repositories/mock_physical_count_repository.dart` |
| **Modelo** | `PhysicalCountRequest`, `AsignacionConteoRequest`, `UsuarioAsignacion`, `CierreConteoRequest`, `ConteoFisicoResponse`, `PendingCountWarehouseModel` | `lib/modules/physical_count/models/physical_count_model.dart` |
| **Modelo** | `CompanyModel` | `lib/shared/models/company_model.dart` |
| **Modelo** | `WarehouseModel` | `lib/shared/models/warehouse_model.dart` |
| **Modelo** | `ArticleModel` | `lib/modules/inventory/models/article_model.dart` |
| **Modelo** | `PersonalModel` | `lib/modules/physical_count/models/personal_model.dart` |
| **Utilidad** | `DropdownTemplates` | `lib/utils/dropdown_template.dart` |
| **Utilidad** | `DialogUtils` | `lib/utils/dialog_utils.dart` |

**Visibilidad de Tabs por Permiso:**

| Pestaña | Permiso (código) | Nombre del Permiso | Widget |
|---------|------------------|--------------------|--------|
| Asignar Personal | `aacu` | `asignacionConteo` | `PhysicalCountAssignmentTab` |
| Apertura | `aacf` | `aperturaConteo` | `PhysicalCountOpeningTab` |
| Cierre | `accf` | `cerrarConteo` | `PhysicalCountClosingTab` |

**Estados del `PhysicalCountProvider` (independientes por pestaña):**

| Grupo de Estado | Variables | Consumido por |
|-----------------|-----------|---------------|
| Global (Apertura + Asignación) | `_state`, `_errorMessage` | `PhysicalCountOpeningTab`, `PhysicalCountAssignmentTab` |
| Cierre | `_closeState`, `_closeErrorMessage`, `_closeSuccessMessage` | `PhysicalCountClosingTab` |
| Bodegas Pendientes (Cierre) | `isLoadingPendingWarehouses`, `_pendingWarehousesErrorMessage`, `pendingWarehouses` | `PhysicalCountClosingTab` |

> [!IMPORTANT]
> **Recuperación de Estado:** `PhysicalCountScreen` es `StatefulWidget` con recarga automática en `initState` cuando `companies.isEmpty` o `state == PhysicalCountState.error`. Método público: `provider.loadInitialData()`.

> [!NOTE]
> **Documentación funcional detallada:** `.context/SigoAPP_Funcional_ConteoFisico.md`

### 5.2 Ejecución del Conteo en Piso (Offline)

**Punto de entrada:** `ActiveCountScreen` → `DashboardScreen` (opción "Ejecutar Conteo")  
**Permiso:** `arcf` (`realizarConteo`)  
**Descripción:** Ejecución del conteo físico en piso en modo offline. Lectura de códigos de barras con persistencia local SQLite y sincronización diferida al backend.

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `ActiveCountScreen` | `lib/modules/physical_count/screens/active_count_screen.dart` |
| **Provider** | `ActiveCountProvider` | `lib/modules/physical_count/providers/active_count_provider.dart` |
| **Repositorio (contrato)** | `PhysicalCountRepository` (compartido con §5.1) | `lib/modules/physical_count/repositories/physical_count_repository.dart` |
| **Repositorio (HTTP)** | `HttpPhysicalCountRepository` (compartido con §5.1) | `lib/modules/physical_count/repositories/http_physical_count_repository.dart` |
| **Database** | `DatabaseHelper` (SQLite) | `lib/database/database_helper.dart` |
| **Modelo** | `ActiveCountModel` | `lib/modules/physical_count/models/active_count_model.dart` |
| **Modelo** | `CountRecordModel` | `lib/modules/physical_count/models/count_record_model.dart` |
| **Widget** | `ContinuousScanView` | `lib/modules/physical_count/widgets/continuous_scan_view.dart` |
| **Widget** | `ListCountView` | `lib/modules/physical_count/widgets/list_count_view.dart` |

**Tablas SQLite involucradas:** `ActiveCountForms`, `CountMasterItems`, `CountRecords`.

---

## 6. Módulo Principal (Solo Debug)

**Descripción:** Pantalla exclusiva para desarrollo y testing. **No se muestra en builds de producción** (`kReleaseMode == true`). Proporciona acceso directo a inventario, escaneo QR, generación QR y gestión de cuentas.

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `HomeScreen` | `lib/modules/debug/screens/home_screen.dart` |
| **Screen** | `ScannerScreen` | `lib/modules/debug/screens/scanner_screen.dart` |
| **Screen** | `GeneratorScreen` | `lib/modules/inventory/screens/generator_screen.dart` |
| **Screen** | `AccountScreen` | `lib/modules/debug/screens/account_screen.dart` |
| **Screen** | `InventoryScreen` (reutilizada del módulo Inventario §3.2) | `lib/modules/inventory/screens/inventory_screen.dart` |
| **Screen** | `TransferApprovalScreen` (reutilizada del módulo Inventario §3.3) | `lib/modules/inventory/screens/transfer_approval_screen.dart` |
| **Widget** | `PrinterConnectionDialog` | `lib/modules/debug/widgets/printer_connection_dialog.dart` |
| **Provider** | `PrinterProvider` | `lib/modules/debug/providers/printer_provider.dart` |
| **Servicio** | `BluetoothPrinterService` | `lib/services/bluetooth_printer_service.dart` |
| **Servicio** | `MockAuthService` | `lib/services/mock_auth_service.dart` |
| **Servicio** | `MockAccountService` | `lib/services/mock_account_service.dart` |
| **Servicio** | `NetworkClient` (singleton mock) | `lib/services/network_client.dart` |
| **Modelo** | `PersonModel` | `lib/modules/debug/models/person_model.dart` |

---

## Servicios Transversales

Los siguientes servicios y utilidades son compartidos entre múltiples módulos:

| Archivo | Ruta | Consumido por |
|---------|------|---------------|
| `AppConfig` | `lib/utils/app_config.dart` | Todos (configuración de Dio, dominio) |
| `AppLogger` | `lib/utils/app_logger.dart` | Todos (logging centralizado) |
| `JsonInterceptor` | `lib/utils/json_interceptor.dart` | Todos los repositorios HTTP |
| `AuthInterceptor` | `lib/utils/auth_interceptor.dart` | Todos los repositorios HTTP (token JWT automático) |
| `NotificationService` | `lib/services/notification_service.dart` | Inventario (Traspasos) |
| `InAppNotificationService` | `lib/services/in_app_notification_service.dart` | Inventario (Traspasos) |
| `PermissionUtils` | `lib/utils/permission_utils.dart` | Dashboard, PhysicalCountScreen |
| `AuthProvider` | `lib/modules/auth/providers/auth_provider.dart` | Todos (token JWT, permisos) |
| `CompanyDropdownField` | `lib/shared/widgets/company_dropdown_field.dart` | Requisiciones, Conteo Físico, Inventario (Selector estándar de Empresas) |
| `WarehouseDropdownField` | `lib/shared/widgets/warehouse_dropdown_field.dart` | Conteo Físico, Inventario, Traspasos (Selector estándar de Bodegas) |
| `AppErrorWidget` | `lib/shared/widgets/app_error_widget.dart` | Todos los módulos (Renderizado estandarizado de errores: inline, banner y view) |
| `WarehouseModel` | `lib/shared/models/warehouse_model.dart` | Inventario, Traspasos, Conteo Físico (Bodega con `tipo` y getter `isPersonal`) |
| `CompanyModel` | `lib/shared/models/company_model.dart` | Requisiciones, Conteo Físico, Inventario (Empresas) |
| `DropdownTemplates` | `lib/utils/dropdown_template.dart` | Todos los selectores desplegables con búsqueda interna |

---

## Grafo de Dependencias de Inyección (main.dart)

```
main.dart
 ├── AppConfig.init() → Dio (backendDio)
 │
 ├── Provider<NotificationService>        ← InAppNotificationService
 │
 ├── [MÓDULO INVENTARIO]
 │   ├── InventoryProvider                ← HttpInventoryRepository(backendDio) + HttpTransferRepository
 │   ├── TransferRequestProvider          ← HttpTransferRepository(backendDio) + NotificationService
 │   ├── TransferApprovalProvider         ← HttpTransferRepository(backendDio) + CatalogRepository
 │   ├── TransferDeliveryProvider         ← HttpTransferRepository(backendDio) + CatalogRepository
 │   ├── TransferFormProvider             ← HttpTransferRepository(backendDio) + CatalogRepository
 │   ├── AssetVerificationProvider        ← (sin repositorio externo)
 │   └── GeolocationProvider              ← HttpGeolocationRepository(backendDio)
 │
 ├── [MÓDULO REQUISICIONES]
 │   ├── RequisitionApprovalProvider      ← HttpRequisitionRepository(backendDio)
 │   └── RequisitionSignatureProvider     ← HttpRequisitionRepository(backendDio)
 │
 ├── [MÓDULO CONTEO FÍSICO]
 │   ├── PhysicalCountProvider            ← HttpPhysicalCountRepository(backendDio)
 │   └── ActiveCountProvider              ← HttpPhysicalCountRepository(backendDio)
 │
 ├── AuthProvider                         ← HttpAuthRepository(backendDio)
 └── PrinterProvider                      ← BluetoothPrinterService
```

> [!WARNING]
> **Todos los Providers listados arriba son globales** (instanciados una sola vez en el arranque de la app). Las pantallas que los consumen deben cumplir la regla de **Recuperación de Estado** documentada en `SigoAPP_Arquitectura.md` §11.
