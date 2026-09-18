# Utilidades del Proyecto (lib/utils)

Este documento describe las clases y métodos utilitarios de la carpeta `lib/utils`. Sirve para contextualizar a los asistentes de inteligencia artificial sobre el propósito de cada utilidad y los lugares donde actualmente se usan en el proyecto.

## `dialog_utils.dart`
- **Propósito**: Provee métodos estáticos para mostrar cuadros de diálogo reutilizables (*Alerts* / Modales) y sanitización inteligente de errores de servidor y base de datos.
  - `showPendingWarehousesErrorDialog`: Error estandarizado cuando falla la carga de bodegas pendientes en conteo físico.
  - `showErrorDialog`: Modal de error para el usuario final con redacción concisa y amigable. Si el mensaje recibido contiene volcados de base de datos o stack traces, invoca automáticamente `extractFriendlyMessage` para presentar únicamente la causa funcional en el cuerpo principal, y resguarda la traza técnica completa (`technicalDetails`, código HTTP, endpoint y botón de copiado al portapapeles) dentro del acordeón expandible para desarrollador, garantizando adaptabilidad responsiva sin desbordamientos visuales.
  - `extractFriendlyMessage`: Método utilitario que procesa cadenas crudas de error provenientes de Oracle PL/SQL (`ORA-20xxx`), extrayendo el mensaje de negocio tras pipes (`121|...`), limpiando prefijos de JDBC/Spring Boot (`CallableStatement`, `HikariProxy`, etc.) y retornando una descripción clara para el usuario final.
- **Lugares de uso**: 
  - `lib/screens/tabs/physical_count_closing_tab.dart`
  - `lib/widgets/transfer_form_widget.dart`
  - `lib/screens/transfer_delivery_screen.dart`
  - `lib/screens/transfer_approval_screen.dart`
  - `lib/repositories/http_transfer_repository.dart`
  - `lib/providers/transfer_delivery_provider.dart`

## `app_config.dart`
- **Propósito**: Maneja la configuración centralizada de la aplicación (clase `AppConfig`). Se encarga de proveer una instancia única de `Dio` pre-configurada (URL base, *timeouts*, interceptores como `AuthInterceptor`, `MockHttpInterceptor` y `JsonInterceptor`), gestionar la persistencia dinámica del dominio mediante `flutter_secure_storage`, y proveer las llaves globales desacopladas `AppConfig.navigatorKey` y `AppConfig.scaffoldMessengerKey` para navegación y notificaciones sin requerir `BuildContext`.
- **Lugares de uso**:
  - `lib/main.dart`
  - `lib/screens/domain_scanner_screen.dart`
  - `lib/utils/auth_utils.dart`

## `app_logger.dart`
- **Propósito**: Provee un mecanismo de *logging* centralizado (`AppLogger`) garantizando que los logs de consola (debug, info, warn, error) solo se emitan cuando la app corre en modo *debug*, protegiendo la información sensible en producción.
- **Lugares de uso**:
  - `lib/utils/app_config.dart`
  - `lib/utils/json_interceptor.dart`
  - `lib/utils/auth_interceptor.dart`
  - `lib/utils/mock_http_interceptor.dart`
  - `lib/utils/auth_utils.dart`
  - `lib/repositories/http_physical_count_repository.dart`

## `article_qr_parser.dart`
- **Propósito**: Contiene el método estático `fromQr` que recibe una cadena leída desde un código QR (con el formato clave:valor separado por `|`) y la decodifica estructurándola en un objeto de tipo `ArticleModel`.
- **Lugares de uso**:
  - `lib/screens/scanner_screen.dart`

## `dropdown_template.dart`
- **Propósito**: Proporciona plantillas de configuración (como el método `DropdownTemplates.searchData`) para la construcción estandarizada de menús desplegables con barra de búsqueda interna, utilizando el paquete `dropdown_button2`. Es la base para los widgets canónicos transversales `CompanyDropdownField` y `WarehouseDropdownField`.
- **Lugares de uso**: 
  - `lib/widgets/company_dropdown_field.dart`
  - `lib/widgets/warehouse_dropdown_field.dart`
  - `lib/screens/tabs/physical_count_opening_tab.dart`
  - `lib/screens/tabs/physical_count_closing_tab.dart`

## `json_interceptor.dart`
- **Propósito**: Interceptor de `Dio` diseñado para capturar respuestas del backend que vienen en formato de texto o con un `Content-Type` incorrecto (por ejemplo `text/plain`), pero que en realidad son un JSON válido. Este interceptor hace el _parsing_ forzado para evitar errores tipo `String is not a subtype of Map/List`.
- **Lugares de uso**:
  - `lib/utils/app_config.dart` (se añade a la instancia global de Dio)

## `mock_http_interceptor.dart`
- **Propósito**: Interceptor de `Dio` para simulación local cuando la sesión activa pertenece al "Entorno de Pruebas (MOCK)". Detecta si la cabecera `Authorization` contiene `mock-token` y resuelve las peticiones en `onRequest` directamente con código 200 OK y payloads simulados coherentes (empresas, bodegas, artículos, traspasos, personas, requisiciones y transacciones `code: 0`), sin enviar tráfico a la red y previniendo caídas o bloqueos de UI.
- **Lugares de uso**:
  - `lib/utils/app_config.dart` (se añade a la instancia global de Dio)

## `auth_interceptor.dart`
- **Propósito**: Interceptor de `Dio` encargado de inyectar automáticamente la cabecera `Authorization: Bearer <token>` en todas las peticiones salientes hacia endpoints protegidos leyendo el token JWT de `FlutterSecureStorage` (clave `'auth_token'`). Excluye automáticamente los endpoints públicos de autenticación (`/api/v1/auth/`). Ante respuestas HTTP 401 en endpoints protegidos, valida que no sea una sesión mock y dispara de inmediato la expulsión controlada invocando `AuthUtils.handleSessionExpired()`.
- **Lugares de uso**:
  - `lib/utils/app_config.dart` (se añade a la instancia global de Dio)

## `auth_utils.dart`
- **Propósito**: Provee métodos estáticos transversales para la gestión, navegación reactiva y expulsión de sesión.
  - `logout(context)`: Cierra la sesión activa en `AuthProvider` (limpiando credenciales y token JWT en almacenamiento seguro y memoria con concurrencia y timeout), resetea todos los Providers globales (`InventoryProvider`, `TransferFormProvider`, `TransferApprovalProvider`, `TransferDeliveryProvider`, `PhysicalCountProvider`, `ActiveCountProvider`, `RequisitionApprovalProvider`, `AssetVerificationProvider`) y vacía la pila de navegación mediante `pushAndRemoveUntil` (despachado de forma no bloqueante para evitar el congelamiento de `newRoute.popped`) redirigiendo a la pantalla raíz (`AuthWrapper`).
  - `handleSessionExpired()`: Dispara el cierre de sesión automático desacoplado de `BuildContext` ante errores 401. Muestra un SnackBar flotante formal con `AppConfig.scaffoldMessengerKey` (*"Tu sesión ha expirado. Por favor, inicia sesión de nuevo"*), limpia el storage y los Providers, y redirige a `AuthWrapper` vía `AppConfig.navigatorKey` de forma no bloqueante.
  - `isLoggingOutNotifier` / `isLoggingOut`: Semáforo reactivo basado en `ValueNotifier<bool>` para debouncing y control de concurrencia, evitando tormentas de expulsión repetidas ante múltiples peticiones 401 simultáneas. Permite a widgets como `DashboardScreen` (`PopScope`) escuchar el estado de salida en tiempo real para neutralizar diálogos modales de confirmación de salida durante la expulsión.
  - `resetSemaphore()`: Método `@visibleForTesting` para restablecer explícitamente el semáforo a `false` en pruebas unitarias o recuperaciones controladas.
- **Lugares de uso**:
  - `lib/utils/auth_interceptor.dart`
  - `lib/screens/inventory_screen.dart`
  - `lib/screens/dashboard_screen.dart`
  - `lib/screens/account_screen.dart`
  - `lib/screens/home_screen.dart`


