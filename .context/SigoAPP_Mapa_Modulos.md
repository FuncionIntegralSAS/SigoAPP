# Mapa de Módulos de SigoAPP
Propósito: Documentar la relación directa entre cada módulo funcional del sistema y todos los archivos de código involucrados (pantallas, providers, repositorios, modelos, servicios, widgets y utilidades).  
Versión: 1.1  
Fecha de actualización: Agosto 2026

> [!NOTE]
> Este documento está diseñado para ser consumido por agentes de IA y desarrolladores como punto de entrada rápido, evitando búsquedas extensivas entre archivos de código para identificar co-dependencias de operaciones y estados.

---

## Índice de Módulos

| # | Módulo de Negocio | Sub-funcionalidades | Permiso(s) Involucrados |
|---|-------------------|---------------------|-------------------------|
| 1 | [Autenticación y Dominio](#1-autenticación-y-dominio) | Configuración de dominio, Login JWT | Ninguno (público) |
| 2 | [Dashboard Principal](#2-dashboard-principal) | Navegación dinámica por permisos | Autenticación válida |
| 3 | [Inventario](#3-inventario) | Verificación de Activos (QR + GPS), Generación de Traspasos, Aprobación de Traspasos | `avac`, `agqr`, `agst`, `aatr` |
| 4 | [Requisiciones](#4-requisiciones) | Aprobación y Entrega de inventario | `areq`, `aein` |
| 5 | [Conteo Físico](#5-conteo-físico) | Apertura, Asignación de Personal, Cierre, Ejecución Offline | `aacf`, `aacu`, `accf`, `arcf`, `asin` |
| 6 | [Módulo Principal (Solo Debug)](#6-módulo-principal-solo-debug) | Scanner QR, Generador QR, Gestión de cuentas | `kReleaseMode == false` |

---

## 1. Autenticación y Dominio

**Descripción:** Flujo obligatorio de configuración inicial de dominio (QR) y autenticación del usuario (login JWT). Punto de arranque de toda la aplicación.

| Capa | Archivo | Ruta |
|------|---------|------|
| **Orquestador** | `main.dart` | `lib/main.dart` |
| **Screen** | `DomainScannerScreen` | `lib/screens/domain_scanner_screen.dart` |
| **Screen** | `AuthScreen` | `lib/screens/auth_screen.dart` |
| **Provider** | `AuthProvider` | `lib/providers/auth_provider.dart` |
| **Repositorio (contrato)** | `AuthRepository` | `lib/repositories/auth_repository.dart` |
| **Repositorio (HTTP)** | `HttpAuthRepository` | `lib/repositories/http_auth_repository.dart` |
| **Repositorio (mock)** | `MockAuthRepository` | `lib/repositories/mock_auth_repository.dart` |
| **Modelo** | `AuthModel`, `AppPermission`, `Permiso` | `lib/models/auth_model.dart` |
| **Modelo** | `UserModel` | `lib/models/user_model.dart` |
| **Utilidad** | `AppConfig` | `lib/utils/app_config.dart` |
| **Utilidad** | `PermissionUtils`, `PermissionListExtension` | `lib/utils/permission_utils.dart` |
| **Utilidad** | `AppLogger` | `lib/utils/app_logger.dart` |
| **Utilidad** | `JsonInterceptor` (Dio) | `lib/utils/json_interceptor.dart` |

**Estados del Provider:** `AuthProvider` mantiene: `isAuthenticated`, `currentToken`, `currentCedula`, `permisos`.

---

## 2. Dashboard Principal

**Descripción:** Panel de navegación post-login. Muestra dinámicamente las opciones de módulo según los permisos del usuario autenticado. Controla la confirmación de salida (`PopScope`).

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `DashboardScreen` | `lib/screens/dashboard_screen.dart` |
| **Provider consumido** | `AuthProvider` (solo lectura de permisos) | `lib/providers/auth_provider.dart` |
| **Modelo consumido** | `AppPermission` | `lib/models/auth_model.dart` |
| **Utilidad** | `PermissionListExtension.hasPermission()` | `lib/utils/permission_utils.dart` |

**Navegación desde Dashboard (agrupada por módulo de negocio):**

| Opción en Dashboard | Permiso | Módulo de Negocio | Pantalla Destino |
|---------------------|---------|-------------------|------------------|
| Verificación de Activos | `avac` | Inventario | `AssetVerificationScreen` |
| Generar solicitud de traspaso | `agst` | Inventario | `InventoryScreen` |
| Aprobación de Traspasos | `aatr` | Inventario | `TransferApprovalScreen` |
| Requisiciones | `areq` | Requisiciones | `RequisitionsScreen` |
| Conteo Físico | `aacf` ∨ `aacu` ∨ `accf` | Conteo Físico | `PhysicalCountScreen` |
| Ejecutar Conteo | `arcf` | Conteo Físico | `ActiveCountScreen` |
| Módulo Principal | Solo `!kReleaseMode` | Debug | `HomeScreen` |

---

## 3. Inventario

**Descripción:** Módulo de negocio que agrupa todas las funcionalidades relacionadas con la gestión del inventario de activos físicos: verificación mediante QR con captura de coordenadas GPS, generación de solicitudes de traspaso entre bodegas y aprobación/rechazo de dichas solicitudes.

### 3.1 Verificación de Activos

**Permiso:** `avac`  
**Descripción:** Verificación de activos mediante escaneo QR con captura de datos geográficos (latitud y longitud).

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `AssetVerificationScreen` | `lib/screens/asset_verification_screen.dart` |
| **Provider** | `AssetVerificationProvider` | `lib/providers/asset_verification_provider.dart` |
| **Modelo** | `ArticleModel` | `lib/models/article_model.dart` |
| **Utilidad** | `ArticleQrParser` | `lib/utils/article_qr_parser.dart` |

### 3.2 Generación de Traspasos

**Permiso:** `agst` (generar traspaso), relacionado con `agqr` (generación QR)  
**Descripción:** Formulario de creación de solicitudes de traspaso de activos entre bodegas. Incluye carga en cascada de catálogos (búsqueda de empleado → división → bodegas autorizadas) e integración con geolocalización e inventario.

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `InventoryScreen` | `lib/screens/inventory_screen.dart` |
| **Provider** | `TransferRequestProvider` | `lib/providers/transfer_request_provider.dart` |
| **Provider** | `TransferFormProvider` | `lib/providers/transfer_form_provider.dart` |
| **Repositorio (contrato)** | `TransferRepository` | `lib/repositories/transfer_repository.dart` |
| **Repositorio (HTTP)** | `HttpTransferRepository` | `lib/repositories/http_transfer_repository.dart` |
| **Repositorio (mock)** | `MockTransferRepository` | `lib/repositories/mock_transfer_repository.dart` |
| **Repositorio (contrato catálogos)** | `CatalogRepository` | `lib/repositories/catalog_repository.dart` |
| **Repositorio (HTTP catálogos)** | `HttpCatalogRepository` | `lib/repositories/http_catalog_repository.dart` |
| **Repositorio (mock catálogos)** | `MockCatalogRepository` | `lib/repositories/mock_catalog_repository.dart` |
| **Modelo** | `TransferRequest` | `lib/models/transfer_request.dart` |
| **Modelo** | `TransferFilter` | `lib/models/transfer_filter.dart` |
| **Modelo** | `ArticleModel` | `lib/models/article_model.dart` |
| **Modelo** | `EmployeeResult` | `lib/models/employee_result.dart` |
| **Widget** | `TransferFormWidget` | `lib/widgets/transfer_form_widget.dart` |
| **Widget** | `CascadingCatalogsWidget` | `lib/widgets/cascading_catalogs_widget.dart` |
| **Servicio** | `MockInventoryService` | `lib/services/mock_inventory_service.dart` |
| **Servicio** | `NotificationService` / `InAppNotificationService` | `lib/services/notification_service.dart`, `lib/services/in_app_notification_service.dart` |
| **Excepción** | `TransferBusinessException` | `lib/exceptions/transfer_business_exception.dart` |

### 3.3 Aprobación de Traspasos

**Permiso:** `aatr`  
**Descripción:** Visualización y gestión (aprobación/rechazo) de solicitudes de traspaso pendientes. Incluye filtros por estado y bodega propuesta. Comparte `TransferRepository` con §3.2.

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `TransferApprovalScreen` | `lib/screens/transfer_approval_screen.dart` |
| **Provider** | `TransferApprovalProvider` | `lib/providers/transfer_approval_provider.dart` |
| **Repositorio** | `TransferRepository` (compartido con §3.2) | `lib/repositories/transfer_repository.dart` |
| **Modelo** | `TransferRequest` | `lib/models/transfer_request.dart` |
| **Modelo** | `TransferFilter` | `lib/models/transfer_filter.dart` |
| **Widget** | `TransferFilterPanel` | `lib/widgets/transfer_filter_panel.dart` |

> [!IMPORTANT]
> **Recuperación de Estado:** `TransferApprovalScreen` es `StatefulWidget` con recarga automática en `initState` si la lista de traspasos está vacía o hay un error previo (regla de Recuperación de Estado en Providers Globales — ver `SigoAPP_Arquitectura.md` §11).

---

## 4. Requisiciones

**Descripción:** Gestión de requisiciones de consumo/salida de inventario. Organizada en dos pestañas: Aprobación y Entrega.

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `RequisitionsScreen` | `lib/screens/requisitions_screen.dart` |
| **Tab** | `ApprovalTabView` | `lib/screens/tabs/approval_tab_view.dart` |
| **Tab** | `DeliveryTabView` | `lib/screens/tabs/delivery_tab_view.dart` |
| **Provider** | `RequisitionApprovalProvider` | `lib/providers/requisition_approval_provider.dart` |
| **Repositorio (contrato)** | `RequisitionRepository` | `lib/repositories/requisition_repository.dart` |
| **Servicio (mock)** | `MockRequisitionService` | `lib/services/mock_requisition_service.dart` |
| **Modelo** | `RequisitionModel` | `lib/models/requisition_model.dart` |
| **Widget** | `RequisitionActionCard` | `lib/widgets/requisition_action_card.dart` |

**Permisos por pestaña:**

| Pestaña | Permiso | Status en API |
|---------|---------|---------------|
| Aprobación | `areq` | `'in'` |
| Entrega | `aein` | `'ap'` |

**Comportamiento de Tabs:** `RequisitionsScreen` usa `TabController` con listener. Al cambiar de pestaña, recarga automáticamente las requisiciones con el `status` correspondiente.

---

## 5. Conteo Físico

**Descripción:** Módulo de negocio completo para la administración del conteo físico de inventario, desde su apertura y asignación de personal hasta su cierre administrativo y la ejecución en piso en modo offline.

### 5.1 Administración del Conteo (Apertura, Asignación, Cierre)

**Punto de entrada:** `PhysicalCountScreen` → `DashboardScreen` (opción "Conteo Físico")  
**Condición de visibilidad:** Al menos uno de `aacf`, `aacu` o `accf`.

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `PhysicalCountScreen` | `lib/screens/physical_count_screen.dart` |
| **Tab** | `PhysicalCountAssignmentTab` | `lib/screens/tabs/physical_count_assignment_tab.dart` |
| **Tab** | `PhysicalCountOpeningTab` | `lib/screens/tabs/physical_count_opening_tab.dart` |
| **Tab** | `PhysicalCountClosingTab` | `lib/screens/tabs/physical_count_closing_tab.dart` |
| **Provider** | `PhysicalCountProvider` | `lib/providers/physical_count_provider.dart` |
| **Repositorio (contrato)** | `PhysicalCountRepository` | `lib/repositories/physical_count_repository.dart` |
| **Repositorio (HTTP)** | `HttpPhysicalCountRepository` | `lib/repositories/http_physical_count_repository.dart` |
| **Repositorio (mock)** | `MockPhysicalCountRepository` | `lib/repositories/mock_physical_count_repository.dart` |
| **Modelo** | `PhysicalCountRequest`, `AsignacionConteoRequest`, `UsuarioAsignacion`, `CierreConteoRequest`, `ConteoFisicoResponse`, `PendingCountWarehouseModel` | `lib/models/physical_count_model.dart` |
| **Modelo** | `CompanyModel` | `lib/models/company_model.dart` |
| **Modelo** | `WarehouseModel` | `lib/models/warehouse_model.dart` |
| **Modelo** | `ArticleModel` | `lib/models/article_model.dart` |
| **Modelo** | `PersonalModel` | `lib/models/personal_model.dart` |
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
| **Screen** | `ActiveCountScreen` | `lib/screens/active_count_screen.dart` |
| **Provider** | `ActiveCountProvider` | `lib/providers/active_count_provider.dart` |
| **Repositorio (contrato)** | `PhysicalCountRepository` (compartido con §5.1) | `lib/repositories/physical_count_repository.dart` |
| **Repositorio (HTTP)** | `HttpPhysicalCountRepository` (compartido con §5.1) | `lib/repositories/http_physical_count_repository.dart` |
| **Database** | `DatabaseHelper` (SQLite) | `lib/database/database_helper.dart` |
| **Modelo** | `ActiveCountModel` | `lib/models/active_count_model.dart` |
| **Modelo** | `CountRecordModel` | `lib/models/count_record_model.dart` |
| **Widget** | `ContinuousScanView` | `lib/widgets/continuous_scan_view.dart` |
| **Widget** | `ListCountView` | `lib/widgets/list_count_view.dart` |

**Tablas SQLite involucradas:** `ActiveCountForms`, `CountMasterItems`, `CountRecords`.

---

## 6. Módulo Principal (Solo Debug)

**Descripción:** Pantalla exclusiva para desarrollo y testing. **No se muestra en builds de producción** (`kReleaseMode == true`). Proporciona acceso directo a inventario, escaneo QR, generación QR y gestión de cuentas.

| Capa | Archivo | Ruta |
|------|---------|------|
| **Screen** | `HomeScreen` | `lib/screens/home_screen.dart` |
| **Screen** | `ScannerScreen` | `lib/screens/scanner_screen.dart` |
| **Screen** | `GeneratorScreen` | `lib/screens/generator_screen.dart` |
| **Screen** | `AccountScreen` | `lib/screens/account_screen.dart` |
| **Screen** | `InventoryScreen` (reutilizada del módulo Inventario §3.2) | `lib/screens/inventory_screen.dart` |
| **Screen** | `TransferApprovalScreen` (reutilizada del módulo Inventario §3.3) | `lib/screens/transfer_approval_screen.dart` |
| **Widget** | `PrinterConnectionDialog` | `lib/widgets/printer_connection_dialog.dart` |
| **Provider** | `PrinterProvider` | `lib/providers/printer_provider.dart` |
| **Servicio** | `BluetoothPrinterService` | `lib/services/bluetooth_printer_service.dart` |
| **Servicio** | `MockAuthService` | `lib/services/mock_auth_service.dart` |
| **Servicio** | `MockAccountService` | `lib/services/mock_account_service.dart` |
| **Servicio** | `NetworkClient` (singleton mock) | `lib/services/network_client.dart` |
| **Modelo** | `PersonModel` | `lib/models/person_model.dart` |

---

## Servicios Transversales

Los siguientes servicios y utilidades son compartidos entre múltiples módulos:

| Archivo | Ruta | Consumido por |
|---------|------|---------------|
| `AppConfig` | `lib/utils/app_config.dart` | Todos (configuración de Dio, dominio) |
| `AppLogger` | `lib/utils/app_logger.dart` | Todos (logging centralizado) |
| `JsonInterceptor` | `lib/utils/json_interceptor.dart` | Todos los repositorios HTTP |
| `NotificationService` | `lib/services/notification_service.dart` | Inventario (Traspasos) |
| `InAppNotificationService` | `lib/services/in_app_notification_service.dart` | Inventario (Traspasos) |
| `PermissionUtils` | `lib/utils/permission_utils.dart` | Dashboard, PhysicalCountScreen |
| `AuthProvider` | `lib/providers/auth_provider.dart` | Todos (token JWT, permisos) |

---

## Grafo de Dependencias de Inyección (main.dart)

```
main.dart
 ├── AppConfig.init() → Dio (backendDio)
 │
 ├── Provider<NotificationService>        ← InAppNotificationService
 │
 ├── [MÓDULO INVENTARIO]
 │   ├── TransferRequestProvider          ← MockTransferRepository + NotificationService
 │   ├── TransferApprovalProvider         ← MockTransferRepository
 │   ├── TransferFormProvider             ← HttpCatalogRepository(backendDio)
 │   └── AssetVerificationProvider        ← (sin repositorio externo)
 │
 ├── [MÓDULO REQUISICIONES]
 │   └── RequisitionApprovalProvider      ← MockRequisitionService
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
