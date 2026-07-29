# Utilidades del Proyecto (lib/utils)

Este documento describe las clases y métodos utilitarios de la carpeta `lib/utils`. Sirve para contextualizar a los asistentes de inteligencia artificial sobre el propósito de cada utilidad y los lugares donde actualmente se usan en el proyecto.

## `dialog_utils.dart`
- **Propósito**: Provee métodos estáticos para mostrar cuadros de diálogo reutilizables (*Alerts* / Modales). Por ejemplo, cuenta con `showPendingWarehousesErrorDialog` para mostrar un error estandarizado cuando falla la carga de bodegas pendientes.
- **Lugares de uso**: 
  - `lib/screens/tabs/physical_count_closing_tab.dart`

## `app_config.dart`
- **Propósito**: Maneja la configuración centralizada de la aplicación (clase `AppConfig`). Se encarga de proveer una instancia única de `Dio` pre-configurada (URL base, *timeouts*, interceptores) y de gestionar la persistencia dinámica del dominio mediante `flutter_secure_storage`.
- **Lugares de uso**:
  - `lib/main.dart`
  - `lib/screens/domain_scanner_screen.dart`

## `app_logger.dart`
- **Propósito**: Provee un mecanismo de *logging* centralizado (`AppLogger`) garantizando que los logs de consola (debug, info, warn, error) solo se emitan cuando la app corre en modo *debug*, protegiendo la información sensible en producción.
- **Lugares de uso**:
  - `lib/utils/app_config.dart`
  - `lib/utils/json_interceptor.dart`
  - `lib/repositories/http_physical_count_repository.dart`

## `article_qr_parser.dart`
- **Propósito**: Contiene el método estático `fromQr` que recibe una cadena leída desde un código QR (con el formato clave:valor separado por `|`) y la decodifica estructurándola en un objeto de tipo `ArticleModel`.
- **Lugares de uso**:
  - `lib/screens/scanner_screen.dart`

## `dropdown_template.dart`
- **Propósito**: Proporciona plantillas de configuración (como el método `DropdownTemplates.searchData`) para la construcción estandarizada de menús desplegables con barra de búsqueda interna, utilizando el paquete `dropdown_button2`.
- **Lugares de uso**:
  - `lib/screens/tabs/physical_count_opening_tab.dart`
  - `lib/screens/tabs/physical_count_closing_tab.dart`

## `json_interceptor.dart`
- **Propósito**: Interceptor de `Dio` diseñado para capturar respuestas del backend que vienen en formato de texto o con un `Content-Type` incorrecto (por ejemplo `text/plain`), pero que en realidad son un JSON válido. Este interceptor hace el _parsing_ forzado para evitar errores tipo `String is not a subtype of Map/List`.
- **Lugares de uso**:
  - `lib/utils/app_config.dart` (se añade a la instancia global de Dio)
