# Historial de Cambios de Arquitectura
Proyecto: SigoAPP

Este documento contiene el registro histórico de las evoluciones arquitectónicas de la aplicación. Para ver la composición actual, consulta [SigoAPP_Arquitectura.md](./SigoAPP_Arquitectura.md).

---

## Control de Cambios e Histórico (v2.4 a v3.0 - Arquitectura Modular Feature-First)

1. **Reestructuración a Feature-First / Modular**: Se transformó la estructura plana del código fuente (`lib/models/`, `lib/repositories/`, `lib/providers/`, `lib/screens/`, `lib/widgets/`) en una jerarquía modular orientada a dominios de negocio bajo `lib/modules/` y `lib/shared/`:
   - `lib/modules/auth/`: Dominio, autenticación y configuración de acceso.
   - `lib/modules/dashboard/`: Panel y navegación dinámica.
   - `lib/modules/inventory/`: Inventario de activos, geolocalización satelital y traspasos físicos.
   - `lib/modules/requisitions/`: Solicitudes administrativas de consumo, aprobación masiva y firmas manuscritas.
   - `lib/modules/physical_count/`: Apertura, asignación de personal, cierre y conteo offline con SQLite.
   - `lib/modules/debug/`: Utilidades exclusivas de desarrollo, testing y diagnóstico.
   - `lib/shared/`: Modelos y selectores reutilizables entre múltiples módulos (`CompanyModel`, `WarehouseModel`, dropdowns estándar).
2. **Estandarización de Sentencias Import**: Se migraron 400 sentencias de importación hacia rutas canónicas `package:sigo_app/modules/...` y `package:sigo_app/shared/...`, eliminando ambigüedades de rutas relativas.
3. **Mantenimiento y Aislamiento de Tests**: Se actualizaron las suites de pruebas unitarias garantizando el 100% de éxito (160/160 tests aprobados) y cero advertencias en `flutter analyze`.

## Control de Cambios e Histórico (v1.7 a v1.8)

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

## Control de Cambios e Histórico (v1.8 a v1.9)
1. Integración del Módulo de Conteo Físico: Se crearon los modelos `PhysicalCountRequest` y `CompanyModel` para envío de datos estructurados hacia el backend, logrando optimizar el ancho de banda enviando únicamente el `nationalId` en forma de arreglo numérico.
2. Gestión Reactiva de Estados con `PhysicalCountProvider`: Orquestación robusta de operaciones del UI y el servicio, integrando transiciones `INITIAL` -> `EN_PROCESO` -> `CREADA` / `ERROR`.
3. Pantalla de Conteo Físico Avanzada (`PhysicalCountScreen`): Formulario dinámico con capacidades de búsqueda en tiempo real (por nombre y cédula para contadores), así como soporte para asignaciones holísticas (valores `"All"`).
4. Manejo Expandido de Códigos HTTP Estrictos: Ampliación de las simulaciones y captación de arquitecturas de red con respuestas intencionales HTTP 400 (Bad Request), 409 (Conflict/Bodegas bloqueadas) y 500 (Internal Error).

## Control de Cambios e Histórico (v1.9 a v2.0)
1. **Documentación de capas no registradas**: Se incorporaron a la arquitectura las carpetas `database/`, `exceptions/` y `utils/` con sus respectivos archivos y propósitos.
2. **Unificación del contrato de Repositorios**: Se eliminó la duplicación de la clase abstracta `TransferRepository` que existía tanto en `transfer_repository.dart` (firmas síncronas) como en `http_transfer_repository.dart` (firmas asíncronas). Ahora existe un único contrato asíncrono (`Future`) en `transfer_repository.dart` que ambas implementaciones (`MockTransferRepository` y `HttpTransferRepository`) cumplen.
3. **Estandarización del cliente HTTP**: Se consolidó un único cliente HTTP (`Dio`) en todo el proyecto referenciado en **[Rules_Networking.md](./Rules_Networking.md)**.
4. **Integración de TransferBusinessException**: La excepción tipada se integró transformando errores de red en mensajes de negocio (ver reglas de red).
5. **Asincronización de Providers de Traspasos**: `TransferApprovalProvider` y `TransferRequestProvider` se adaptaron al contrato asíncrono. El primero ahora mantiene estado local de la lista, expone `loadTransfers()` y ejecuta carga automática al instanciarse. El segundo implementó el `try/catch` pendiente con notificación de errores vía `NotificationService`.
6. **Limpieza de dependencias**: Se eliminaron `cupertino_icons` (sin uso detectado) y `win32` (dependencia transitiva, no requiere declaración explícita). Se conservaron `pdf`, `path_provider` y `open_filex` para uso en desarrollo posterior.

## Control de Cambios e Histórico (v2.0 a v2.1)
1. **Integración real del servicio de Personal**: Se implementó `searchPersons` en `physical_count_service.dart` como llamada HTTP real a `GET /api/v1/personal/buscar`. Los parámetros de búsqueda se envían con las llaves exactas del backend (`nombre`, `apellido`, `cedula`). Se eliminaron todos los `print` de diagnóstico del código de producción.
2. **Modelo `PersonalModel` con mapeo tolerante**: Se rediseñó `personal_model.dart` bajo la nomenclatura de base de datos. Su `fromJson` prioriza las llaves reales del endpoint de personal (`cedula`, `nombre`, `apellido`, `correo`, `division`, `estado`) manteniendo compatibilidad con variantes en mayúsculas y camelCase. Esto resolvió el problema de visualización donde la cédula aparecía como `0` y nombre/apellido vacíos.
3. **Nuevo flujo de Asignación de Personal**: Se incorporaron dos nuevas clases en `physical_count_model.dart` (`AsignacionConteoRequest` y `UsuarioAsignacion`) con serialización `toJson` alineada al schema Swagger del endpoint `POST /api/v1/conteo-fisico/asignar_articulos`. Se corrigió la ruta del endpoint que en una versión intermedia apuntaba a `/asignar_articulos` sin el prefijo de la API.
4. **`assignPhysicalCount()` en el Provider**: El `PhysicalCountProvider` incorpora la lógica de negocio para validar y construir la petición de asignación a partir del estado compartido (empresa, bodega, fecha y personas seleccionadas), permitiendo que la pestaña de Asignación consuma datos capturados en la pestaña de Apertura sin acoplamiento directo entre vistas.
5. **Mejoras de UI en dropdowns**: Los ítems de los selectores Empresa, Bodega y Artículo ahora muestran formato `"código - descripción"` para facilitar la identificación visual. `WarehouseModel` extendido con `Equatable` para resolver el error de aserción de `DropdownButton` al comparar elementos por valor.
6. **Integración `dropdown_button2` con barras de búsqueda**: Migración completa de los tres selectores de apertura a `dropdown_button2` v3.x con `ValueNotifier` y `valueListenable` por selector. Se configuraron `onMenuStateChange` para limpiar el filtro de búsqueda al cerrar cada dropdown.
7. **Rediseño de AuthScreen (Dual Login Responsivo)**: Se implementó un `LayoutBuilder` en la pantalla inicial de autenticación que expone simultáneamente el inicio de sesión contra el Servidor Real (`HttpAuthRepository`) y el Entorno de Pruebas Mock. Se apilan verticalmente en pantallas pequeñas y se ubican uno al lado del otro en escritorio.
8. **Eliminación Total de `MockAuthService`**: Se eliminó el uso de servicios mock independientes para sesión. El `AuthWrapper` en `main.dart` ahora observa unificadamente el `AuthProvider`. Se introdujo el método `mockLogin` directamente en el Provider para inyectar credenciales simuladas localmente cuando el usuario usa el panel Mock, centralizando el estado de autenticación.
9. **Refactorización del Botón Logout**: Todas las vistas de la app (`HomeScreen`, `InventoryScreen`) fueron migradas para ejecutar `context.read<AuthProvider>().logout()` finalizando exitosamente la transición global al estado manejado por Provider.

## Control de Cambios e Histórico (v2.1 a v2.2)

1. **Infraestructura de Configuración Centralizada**: Se unificó la inyección y configuración de red mediante `AppConfig.createDio()` y se eliminaron fallbacks silenciosos, alineándose con las reglas de red.

2. **Logger centralizado (`AppLogger`)**: Se creó `lib/utils/app_logger.dart` con métodos estáticos (`d`, `i`, `w`, `e`) que verifican `kDebugMode` antes de imprimir. La regla `avoid_print: true` fue habilitada en `analysis_options.yaml` para que el linter detecte cualquier `print()` residual.

3. **Inyección de Dio unificada**: Los repositorios HTTP fueron refactorizados para recibir la instancia única de `Dio` por constructor garantizando la aplicación de interceptores globales (ver **[Rules_Networking.md](./Rules_Networking.md)**).

4. **Corrección de Application ID**: El `namespace` y `applicationId` en `android/app/build.gradle.kts` fueron cambiados de `com.example.flutter_application_1` a `com.funcionintegralsas.sigoapp`. Google Play rechaza cualquier app con `com.example.*`.

5. **Permiso INTERNET en release**: Se agregó `<uses-permission android:name="android.permission.INTERNET"/>` al `AndroidManifest.xml` principal (antes solo estaba en los manifests de `debug/` y `profile/`).

6. **Nombre de la app unificado a `"SIGAPP"`**: El nombre genérico `flutter_application_1` fue reemplazado por `"SIGAPP"` en todos los archivos nativos de cada plataforma soportada (Windows, Android, iOS, Web, Linux, macOS).

7. **UX Nativa**: Se agregó `SafeArea` en `AuthScreen` (protección contra notch/punch-hole) y `PopScope` con diálogo de confirmación en `DashboardScreen` (previene cierre accidental con botón atrás de Android).

8. **Protección de datos sensibles en logs**: Los bloques `debugPrint` que exponían el token JWT y el refresh token en `auth_provider.dart` fueron envueltos con `if (kDebugMode)`. Las llamadas `print()` en `http_physical_count_repository.dart` y `json_interceptor.dart` fueron migradas a `AppLogger`. El `debugPrint` de migración de SQLite en `database_helper.dart` también fue protegido con `kDebugMode`.

9. **Credenciales mock eliminadas de UI**: `AuthScreen` ya no precarga los controladores con las credenciales de prueba ni muestra el texto `'Credenciales de prueba: operador@inventario.com / 123456'` en la interfaz de producción. El panel Mock (con credenciales visibles) solo se renderiza con `!kReleaseMode`.

10. **Documentación de producción**: Se creó el archivo `.context/SigoAPP_Produccion.md` como documento dedicado con checklist de release, guía de keystore, estado de cada módulo mock vs. real, y registro de todos los cambios de esta fase.

11. **Configuración de Ícono Adaptativo y Ejecutable**: Se incorporó la dependencia `flutter_launcher_icons` (^0.14.3) en `pubspec.yaml` apuntando a `assets/images/LOGO_SIN_FONDO.png`. Se generaron exitosamente los íconos nativos para Android, iOS y ejecutable de Windows.

## Control de Cambios e Histórico (v2.2 a v2.3)

1. **Inversión del orden de pestañas en `PhysicalCountScreen`**: La pestaña de Asignación de Personal pasa a ser la primera, y la de Apertura pasa a ser la segunda, reflejando el flujo natural del usuario (primero selecciona el equipo, luego configura el conteo).

2. **Método unificado `createAndAssignPhysicalCount()`**: Se eliminaron los botones de acción individuales de cada pestaña. Se creó un único método en `PhysicalCountProvider` que valida todos los campos de ambas pestañas, ejecuta el POST de creación (`/registrar`) y, solo si es exitoso, ejecuta el POST de asignación (`/asignar_articulos`). Si la creación falla, el flujo se detiene y se muestra el error sin ejecutar la asignación.

3. **Nueva pestaña `PhysicalCountClosingTab` (Cierre de Conteo)**: Se creó el archivo `lib/screens/tabs/physical_count_closing_tab.dart` como la tercera pestaña de `PhysicalCountScreen`. Permite ingresar el código de una bodega y ejecutar el cierre del conteo físico activo.

4. **Nuevos modelos en `physical_count_model.dart`**:
   - `CierreConteoRequest`: Encapsula el campo `bodega` requerido por `POST /api/v1/conteo-fisico/cerrar`.
   - `ConteoFisicoResponse`: Parsea la respuesta del backend con campos `success` (bool) y `message` (String).

5. **Nuevo contrato y implementación de `closePhysicalCount`**: Método agregado a `PhysicalCountRepository` (contrato abstracto) e implementado en `HttpPhysicalCountRepository`. Retorna `ConteoFisicoResponse` para exponer el mensaje del backend a la UI. El header `Authorization` se inyecta vía `Options.headers` (igual que `reportarConteo`).

6. **Estado independiente para Cierre en `PhysicalCountProvider`**: Se añadieron los campos `_closeState`, `_closeErrorMessage` y `_closeSuccessMessage` con sus respectivos getters y métodos helper (`_setCloseState`, `_setCloseError`, `clearCloseError`, `resetCloseForm`). Esto garantiza que el estado de la operación de cierre no interfiera con el de apertura/asignación.

7. **Diálogo de confirmación con diseño Material profesional**: Antes de ejecutar el cierre, se muestra un `AlertDialog` con título en mayúsculas (`"CONFIRMAR CIERRE"`), padding explícito, botones en fila horizontal forzada con `Row` + `Expanded` + `StadiumBorder`, acción secundaria como `OutlinedButton` (color deepPurple) y acción primaria como `ElevatedButton` (color rojo). Si el usuario cancela, la petición no se ejecuta (`confirmed == true && mounted` como guardia).

8. **Diálogo de resultado con diseño consistente**: El diálogo de éxito del cierre usa título en mayúsculas (`"CONTEO CERRADO"`), muestra el `message` del backend (`closeSuccessMessage`) con fallback local, botón verde "Aceptar" alineado a la derecha, y padding explícito. Al aceptar, limpia el `TextField` y resetea el estado de cierre.

## Control de Cambios e Histórico (v2.3 a v2.4)

1. **Control de Acceso Basado en Permisos (RBAC Dinámico)**:
   - **Backend Integration**: Procesamiento del atributo `permisos` retornado en `/login` (`usuario`, `forma`, `tipoRol`, `tipoForma`, `producto`).
   - **Enum de Permisos (`AppPermission`)**: Se creó el enum en `lib/models/auth_model.dart` para asegurar los tipos (*type-safety*) mapeando cada código `forma` (`avac`, `aacf`, `areq`, etc.).
   - **Utilitario de Permisos (`PermissionUtils` y `PermissionListExtension`)**: Se centralizó la lógica en `lib/utils/permission_utils.dart` separando la persistencia y consulta del `AuthProvider`. Incluye `parsePermissions` / `encodePermissions` y la extensión `PermissionListExtension` sobre `List<Permiso>` (`hasPermission`, `hasAnyPermission`).
   - **Evaluación Tolerante a Caso (`toLowerCase()`)**: Las comparaciones normalizan las cadenas con `.toLowerCase()` para admitir tanto respuestas en mayúsculas del backend (`"AVAC"`, `"AEIN"`) como minúsculas.
   - **Renderizado Dinámico en UI**:
     - `DashboardScreen`: Filtra dinámicamente cada tarjeta del `GridView` plano según los permisos del usuario logueado.
     - `PhysicalCountScreen`: Construye dinámicamente sus pestañas (*Asignar Personal*, *Apertura*, *Cierre*) filtrando aquellas no autorizadas.
   - Documentación técnica dedicada disponible en `/.context/visualizacion_dinamica_dashboard.md`.

## Control de Cambios e Histórico (v2.4 a v2.5)

1. **Flujo de Entrega / Recepción de Traspasos con Firmas Digitales**:
   - **Modelo de Firmas Asíncronas**: Se actualizaron `TransferRequest` y `TransferDeliveryRequest` con los campos opcionales `dispatcherSignatureBase64` y `receiverSignatureBase64` para admitir firmas en tiempos y dispositivos independientes. El estado transiciona a `pr` (completado) únicamente cuando ambas firmas son registradas.
   - **Canvas de Firma Digital**: Se incorporó el paquete `signature` para capturar firmas vectoriales fluidas y convertirlas a PNG/Base64.
   - **Validación de Roles y Precedencia**: La pantalla `SignatureCaptureScreen` identifica si el usuario actual es despachador o receptor según su cédula de sesión (`AuthProvider.currentCedula`), bloqueando la firma del receptor hasta que el despachador haya firmado el envío.
   - **Provider y Repositorios**: Se creó `TransferDeliveryProvider` inyectado globalmente en `main.dart`, extendiendo `TransferRepository`, `MockTransferRepository` y `HttpTransferRepository` con el método `applyTransferDelivery`.
   - **Navegación en Dashboard**: Se incorporó la tarjeta `Entrega / Recepción` en `DashboardScreen` accesible a usuarios autenticados con traspasos asignados.

## Control de Cambios e Histórico (v2.5 a v2.6)

1. **Módulo de Geolocalización de Activos**:
   - **Modelo `GeolocationModel`**: Implementación de modelo fuertemente tipado para las coordenadas (`afgeIdre`, `afgeLati`, `afgeLong`) y auditoría con mapeo bidireccional JSON.
   - **Capa de Repositorio (`GeolocationRepository` y `HttpGeolocationRepository`)**: Contrato abstracto e implementación HTTP con `Dio` para interactuar con los endpoints REST `/api/v1/geolocalizacion-activos` (GET, POST, PUT, DELETE).
   - **Excepción Tipada `GeolocationBusinessException`**: Manejo desacoplado de errores técnicos y mensajes de negocio provenientes de la API REST.
   - **Gestión de Estado (`GeolocationProvider`)**: Inyección global en `main.dart` con soporte para sincronización automática (`syncGeolocation` que consulta existencia y conmuta entre POST y PUT según corresponda).

2. **Refactorización y Blindaje de Identidad en `ArticleModel`**:
   - **Separación de Llaves de Identidad**: Se estableció `codigoActivo` (`String`) como el identificador único de negocio (referencia visible, etiquetas QR y códigos de barras), mientras que `id` (`int?`) quedó estrictamente restringido como identificador interno de base de datos/geolocalización (`afgeIdre`).
   - **Blindaje de Módulos Operativos**: Se adaptaron y validaron todos los flujos de traslados, conteo físico, apertura, asignación, servicios mock y parsers de QR para garantizar que el atributo `id` no se filtre ni contamine las peticiones REST de negocio, eliminando riesgos de fallas por incompatibilidad de tipos o de esquema en Spring Boot.

## Control de Cambios e Histórico (v2.6 a v2.7)

1. **Búsqueda Dinámica de Personal y Selección Interactiva de Destino**:
   - **Consumo Real de API**: `HttpCatalogRepository.searchPersons()` migrado para consultar directamente `GET /api/v1/personal/buscar` enviando parámetros opcionales (`nombre`, `apellido`, `cedula`).
   - **Selección de Candidatos en UI (`TransferFormWidget`)**: Búsqueda por cédula, nombre o apellido con despliegue de diálogo interactivo de selección cuando existen múltiples coincidencias, y auto-completado inequívoco ante coincidencias únicas.
   - **Carga en Cascada**: Resolución automática de la división del empleado destino y carga de bodegas autorizadas asociadas.

2. **Estandarización de Diálogos de Diagnóstico para Desarrollador (`DialogUtils.showErrorDialog`)**:
   - **Modal de Diagnóstico**: Se diseñó un diálogo modal con estilo Material estándar que presenta al usuario un mensaje funcional conciso junto a un código de error o estado HTTP, incorporando un acordeón expandible (*"Detalles técnicos para soporte"*) con la ruta (`endpoint`) y la traza técnica retornada por el servidor sin exponer secretos.

3. **Tipado Estructurado de Excepciones y Mapeo en Repositorios**:
   - **`TransferBusinessException` Enriquecida**: Se añadieron los campos opcionales `statusCode`, `endpoint` y `technicalDetails`.
   - **Nueva `CatalogBusinessException`**: Excepción de negocio especializada para fallos de consulta en catálogos y personal.
   - **Blindaje de Repositorios HTTP**: `HttpTransferRepository` y `HttpCatalogRepository` implementaron el helper centralizado `_mapDioException` para capturar respuestas del backend (`response.data['message']`), enriquecer excepciones de negocio y registrar trazas con `AppLogger.e`.

4. **Optimización y Blindaje Asíncrono en Aprobación de Traspasos**:
   - **Filtrado en Servidor (`GET /api/v1/traspasos/list?estado=pe`)**: `TransferApprovalProvider` ahora envía el parámetro de estado directamente a la API, optimizando el consumo de red y rendimiento al consultar únicamente los pendientes por defecto o el criterio del filtro activo.
   - **Corrección de Aserciones Asíncronas en UI (`TransferApprovalScreen`)**: Se aseguró el `await` de operaciones `approveTransfer` y `rejectTransfer`, erradicando falsos positivos en notificaciones SnackBar y mostrando retroalimentación real mediante `DialogUtils.showErrorDialog`.
   - **Prevención de Doble Pulsación (`isProcessing`)**: Registro reactivo de solicitudes en vuelo que bloquea botones de acción y muestra indicadores de carga contextuales por tarjeta.
   - **Resiliencia de UI**: Incorporación de estado vacío informativo con botón de reintento, indicador lineal de recarga y botón de refresco manual en el `AppBar`.

5. **Documentación Funcional Exhaustiva de Traspasos**:
   - Se redactó el documento `.context/SigoAPP_Funcional_Traspasos.md` con la máquina de estados completa (`pe` -> `ap`/`na` -> `af` -> `tr`/`ad` -> `co`), detalles de precedencia en firmas manuscritas (`FU` / `DE`), contratos REST y matriz de errores.

## Control de Cambios e Histórico (v2.7 a v2.8)

1. **Adaptación a Arquitectura Multi-Artículo en Traspasos**:
   - `TransferCreateRequest` refactorizado para enviar el array obligatorio `articulos: [ { "articulo": "...", "placa": "..." } ]` y campos de identificación `personaFuente`, `personaDestino` y `empresa` en formato String.
   - Creación de `TransferArticleItem` y `TransferFirmItem` como submodelos estructurados en `transfer_request.dart`.
   - El atributo `id` de las rutas y modelos pasa a representar el `numeroTramite` (`MOTRNUTR`), agrupando todos los activos de una misma solicitud.

2. **Nuevo Ciclo de Vida Simplificado (4 Estados Canónicos)**:
   - Eliminación de los estados intermedios `af` y `ad` de la tabla `FI_MOVITRAS`.
   - Estandarización en 4 estados oficiales: `pe` (Pendiente), `ap` (Aprobado), `na` (Rechazado) y `re` (Recibido).
   - Soporte para consultas de bandeja agrupada con `estado=pr` (agrupa trámites en `ap`, `na` y `re`).

3. **Firmas Digitales Desacopladas (Sin Orden Requerido)**:
   - Eliminación de la restricción secuencial en `SignatureCaptureScreen` y `TransferDeliveryProvider`.
   - Despachador Fuente (`FU`) y Receptor Destino (`DE`) pueden firmar en cualquier orden de forma independiente mediante `PUT /api/v1/traspasos/sign/{id}`.
   - Las firmas se gestionan en la entidad `FI_MOTRFIRM` y no modifican el estado `ap` del trámite.

4. **Afectación Diferida en ERP y Confirmación de Recepción**:
   - Incorporación del método `confirmReceipt` en `TransferDeliveryProvider` y del botón destacado *"Confirmar Recepción ERP"* en `TransferDeliveryScreen`.
   - Invocación de `PUT /api/v1/traspasos/recibir/{id}` cuando ambas firmas están registradas (`bothSigned`), asentando las existencias en `DOCUINVE`/`MOVIINVE` y concluyendo el traspaso en estado `re`.

5. **Enriquecimiento Concurrente de Bandeja**:
   - `HttpTransferRepository.getAllTransfers` enriquece las cabeceras ligeras retornadas por `GET /api/v1/traspasos/list` consultando concurrentemente `GET /api/v1/traspasos/get/{id}` para mostrar artículos, placa y custodios en las tarjetas de interfaz.

## Control de Cambios e Histórico (v2.8 a v2.9)

1. **Flujo Dinámico en Cascada para Creación de Traspasos**:
   - Rediseño de `TransferFormWidget` y `TransferFormProvider` para guiar al usuario en secuencia interactiva: Empresa -> Bodega Origen -> Colaboradores Fuente -> Activos Asignados -> Bodega Destino -> Colaboradores Destino -> Observación -> Envío.
2. **Endpoints Auxiliares de Consulta de Colaboradores y Activos**:
   - Incorporación de `TransferPersonModel` y consumo de `GET /api/v1/traspasos/personas?bodega={bodega}&empresa={empresa}` en `TransferRepository`.
   - Incorporación de `TransferAssetModel` y consumo de `GET /api/v1/traspasos/activos?persona={persona}&empresa={empresa}` en `TransferRepository`.
3. **Reglas de Negocio y Compatibilidad Multi-Artículo PL/SQL**:
   - Bloqueo en tiempo real de activos en trámite (`enTramite: true`) con badge visual informativo.
   - Aplicación de compatibilidad multi-artículo de `PKG_FI_MOVITRAS`: todos los activos de una misma solicitud deben coincidir en `centroInformacion` y `tercero`. La UI inhabilita dinámicamente aquellos que no coincidan con el primer activo seleccionado.
   - Validación estricta de diferenciación de colaboradores: `personaDestino.cedula != personaFuente.cedula`.
4. **Exclusión de Bodegas en el Payload de Creación**:
   - El payload enviado a `POST /api/v1/traspasos/crear` omite intencionalmente las bodegas (las bodegas se usan exclusivamente en el cliente como filtro para consultar a las personas asociadas).

## Control de Cambios e Histórico (v2.9 a v3.0)

1. **Inyección de Dependencias y Consumo HTTP en Entrega/Recepción**:
   - Corrección en `main.dart` para inyectar la instancia compartida `httpTransferRepository` en `TransferDeliveryProvider`, eliminando el uso inadvertido de `MockTransferRepository`.
2. **Preservación de Códigos Originales de Custodios (`TransferRequest`)**:
   - Incorporación de `personaFuente` y `personaDestino` en `TransferRequest` para retener las cédulas enviadas por el backend y evitar su destrucción durante el enriquecimiento con `CatalogRepository`.
   - Implementación de getters inteligentes `codigoFuente` y `codigoDestino` con fallback seguro a `responsableActual` y `responsablePropuesto`.
3. **Identificación Dual de Sesión y Firmas Desacopladas**:
   - Soporte para cotejo simultáneo de cédula (`currentCedula`) y usuario de sesión (`currentUsername`) en `TransferDeliveryProvider.getAssignedTransfers`.
   - Habilitación interactiva del canvas de firmas en `SignatureCaptureScreen` (`canSign = true`) permitiendo el registro desacoplado de firmas de entrega (`FU`) y recepción (`DE`) mediante `PUT /api/v1/traspasos/sign/{id}`.
4. **Composición de Identificador de Trámite y Limpieza de Trazas**:
   - `HttpTransferRepository.getTransferById` compuesto para enviar como path parameter el ID real del trámite (`MOTRNUTR`), tolerando respuestas envueltas en `data`.
   - Depuración y limpieza de logs redundantes en consola durante eventos de redimensión de ventana, preservando exclusivamente la traza de consulta de firmas.
5. **Sanitización Inteligente de Errores y Diagnóstico Técnico en Modales (`DialogUtils`)**:
   - Creación del método `DialogUtils.extractFriendlyMessage(String raw)` para procesar excepciones crudas de Oracle PL/SQL (`ORA-20xxx`), aislando el mensaje de negocio tras pipes (`121|...`) y filtrando prefijos de infraestructura Spring/JDBC (`CallableStatement`, `HikariProxy`, etc.).
   - Refactorización de `DialogUtils.showErrorDialog` para presentar en el cuerpo principal un mensaje comprensible para el usuario final, resguardando la traza técnica completa (`technicalDetails`), código HTTP y endpoint dentro de una sección expandible para desarrollador con botón de copiado.
   - Ajuste de responsividad y eliminación de desbordamientos visuales (overflow de 7.3px corregido al remover el badge HTTP de la fila del toggle y envolver el texto con `Flexible` y `MainAxisSize.min`).
   - Propagación desacoplada en `TransferBusinessException` (`friendlyMessage`, `technicalDetails`, `statusCode`) consumida por `TransferDeliveryProvider` y visualizada en `TransferDeliveryScreen`.

## Control de Cambios e Histórico (v3.0 a v3.1)

1. **Migración a HTTP Real del Módulo de Requisiciones**:
   - Reemplazo definitivo de `MockRequisitionService` (eliminado) por `HttpRequisitionRepository` en `main.dart` inyectado en `RequisitionApprovalProvider`.
   - Conexión con los endpoints oficiales de Spring Boot (`/api/v1/requisiciones/**`) para consulta por terna (`empresa`, `tipoDocumento`, `numero`), aprobación de cantidades, entrega física de activos y consulta de firmas.
   - Creación de la excepción de negocio tipada `RequisitionBusinessException` (`lib/exceptions/requisition_business_exception.dart`) para encapsular códigos de retorno PL/SQL (`code != 0`), mensajes funcionales y detalles técnicos.
   - Formalización del documento funcional [`SigoAPP_Funcional_Requisiciones.md`](./SigoAPP_Funcional_Requisiciones.md) detallando la máquina de estados derivada (`in`, `ap`, `en`, `ae`, `rg`) y contratos REST.

2. **Simulación Local Inteligente (`MockHttpInterceptor`)**:
   - Creación de `MockHttpInterceptor` (`lib/utils/mock_http_interceptor.dart`) agregado a la instancia centralizada de `Dio` en `AppConfig`.
   - Permite el desarrollo y pruebas de interfaz bajo el perfil "Entorno de Pruebas (MOCK)" resolviendo peticiones salientes con `Authorization: mock-token` directamente en memoria con código 200 OK y payloads simulados coherentes (empresas, bodegas, artículos, personal, requisiciones), evitando envíos de tráfico fallido a red o caídas por servidor inalcanzable.

3. **Estandarización de Identificación de Sesión y Enrutamiento Raíz**:
   - `AuthResponse` incorpora el atributo `documento` (cédula del colaborador en nómina) propagado a `_cedula` (`currentCedula`) y persistido en `FlutterSecureStorage` (`auth_cedula`).
   - `AuthProvider` formaliza la bandera `isContador` persistida en `'auth_is_contador'`, permitiendo que `AuthWrapper` en `main.dart` direccione limpiamente al `DashboardScreen` (`isAuthenticated && !isContador`) o mantenga el aislamiento de contadores físicos en `AuthScreen`.

## Control de Cambios e Histórico (v3.1 a v3.2)

1. **Protección de Red Fail-Fast UI / Lazy Fetch en Requisiciones**:
   - Eliminación de la consulta automática sin fecha al arrancar `RequisitionsScreen` (`initState`) y en el listener de cambio de pestaña, protegiendo la tabla histórica `MOVIRESU` (>100.000 registros).
   - En `RequisitionApprovalProvider.loadRequisitions`, si el parámetro `desde` es nulo o vacío, se omiten inmediatamente las peticiones de red y se mantiene la bandeja en estado limpio sin emitir errores.
   - En `ApprovalTabView` y `DeliveryTabView`, se implementó un estado de espera informativo con ícono institucional de calendario (`Icons.calendar_month_outlined`) que invita al operador a seleccionar una fecha inicial en el filtro superior.
   - En `HttpRequisitionRepository.getRequisitionsByStatus`, se incorporó una guarda de seguridad preventiva que retorna lista vacía si `desde` es nulo o vacío.

2. **Rediseño Conceptual y Jerárquico Master-Detail (Documento ➔ Movimientos)**:
   - **Nivel 1 (Master):** La bandeja consume `GET /api/v1/requisiciones` y expone directamente la colección de documentos de solicitud (`RequisicionResumen`), visualizados mediante `RequisitionActionCard` con franja lateral de estado canónica de 5px, terna identificadora, bodega, fecha de radicación y badge de conteo de artículos solicitados.
   - **Nivel 2 (Detail bajo demanda):** Al expandir la tarjeta mediante `ExpansionTile`, se consulta bajo demanda el detalle específico (`GET /api/v1/requisiciones/{empresa}/{tipo}/{num}`) con sistema de caché en el provider, desplegando metadatos extendidos (solicitante, observaciones) y los movimientos individuales (`RequisicionDetalleLinea`).
   - **Captura y Validación de Cantidades:** Cada movimiento valida en tiempo real las cantidades ingresadas ($>0 \land \le \text{máximo permitido}$ de acuerdo con la pestaña activa), inhabilitando el checkbox ante valores incorrectos. Se agregaron accesos rápidos para seleccionar o limpiar todas las líneas de un documento.
   - **Procesamiento Masivo Preservado:** El botón flotante `FloatingActionButton` centraliza el procesamiento en bloque (`PUT /aprobar` o `PUT /entregar`), agrupando las líneas seleccionadas por terna e invocando los endpoints transaccionales con recarga automática tras el éxito.

