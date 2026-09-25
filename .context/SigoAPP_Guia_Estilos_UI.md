# Guía de Estilos, Apariencia Estética y UI/UX de SigoAPP

**Versión:** 2.0  
**Fecha:** Septiembre 2026  
**Ámbito:** Transversal a toda la aplicación SigoAPP (Directrices Generales de Proyecto y Especificaciones Particulares por Pantalla y Módulo).

---

## 📌 Estructura y Navegación del Documento

Este documento se estructura formalmente en dos grandes secciones para garantizar que todo desarrollador o agente de IA mantenga la coherencia visual institucional y a la vez aplique los requerimientos específicos de cada pantalla operativa:

1. **[PARTE I — DIRECTRICES GENERALES (A NIVEL DE PROYECTO / TRANSVERSAL)](#parte-i--directrices-generales-a-nivel-de-proyecto--transversal):**
   * Fundamentos y filosofía visual de la aplicación.
   * Jerarquía de superficies, contenedores y paleta cromática transversal.
   * Código de colores de estado canónico del sistema.
   * Sistema de radios (`BorderRadius`), bordes y sombras.
   * Componentes transversales estándar (AppBars, franjas métricas, paneles de filtros, botones formales, modales y diálogos).
   * Manejo de estados asíncronos transversales (carga, vacío, error).
   * Anti-patrones de diseño explícitamente prohibidos.

2. **[PARTE II — ESPECIFICACIONES PARTICULARES (POR PANTALLA Y MÓDULO)](#parte-ii--especificaciones-particulares-por-pantalla-y-módulo):**
   * **Módulo 1:** Autenticación y Configuración de Dominio (`DomainScannerScreen`, `AuthScreen`).
   * **Módulo 2:** Dashboard Principal y Navegación Dinámica (`DashboardScreen`).
   * **Módulo 3:** Inventario, Verificación y Catálogo (`InventoryScreen`, `AssetVerificationScreen`, `GeneratorScreen`).
   * **Módulo 4:** Aprobación de Traspasos (`TransferApprovalScreen`, `TransferFilterPanel`).
   * **Módulo 5:** Entrega, Recepción y Captura de Firmas (`TransferDeliveryScreen`, `SignatureCaptureScreen`).
   * **Módulo 6:** Requisiciones de Inventario (`RequisitionsScreen`, `ApprovalTabView`, `DeliveryTabView`).
   * **Módulo 7:** Conteo Físico Administrativo y en Piso (`PhysicalCountScreen`, `ActiveCountScreen`).
   * **Módulo 8:** Gestión de Cuenta y Utilidades de Diagnóstico (`AccountScreen`, `ScannerScreen`, `HomeScreen`).

---

# PARTE I — DIRECTRICES GENERALES (A NIVEL DE PROYECTO / TRANSVERSAL)

Esta sección define las reglas maestras que **todas** las pantallas, widgets y diálogos de SigoAPP deben cumplir obligatoriamente. Ninguna pantalla o componente particular puede contradecir estas pautas base.

---

## 1. Filosofía de Diseño y Propósito Visual

SigoAPP es una aplicación empresarial e industrial orientada a operaciones de logística, activos fijos y gestión administrativa en campo y bodega. Su diseño estético responde a cuatro pilares inquebrantables:

1. **Sobriedad Corporativa Institucional:**
   * Interfaces limpias, serias y formales, libres de gradientes llamativos, adornos tipo videojuego o paletas pastel deslavadas sin contraste.
   * El color se usa como vehículo funcional de información (estados, acciones críticas, alertas), no como mero adorno.
2. **Alta Densidad de Información:**
   * La aplicación se opera en entornos de alta rotación donde el operador necesita visualizar el contexto completo de un registro (ID, procedencia, destino, responsable, cantidad) sin verse obligado a desplazarse verticalmente por pantallas kilométricas.
   * Aprovechamiento milimétrico del espacio mediante espaciados verticales compactos (`4px` a `8px`) y filas estructuradas de un solo renglón.
3. **Escaneo Visual Rápido (Scanning en Milisegundos):**
   * Empleo sistemático de **franjas verticales laterales de 5px** en tarjetas para identificar el estado del trámite al instante.
   * Badges con tipografía en negrita monoespacio para placas, seriales y números de trámite.
4. **Consistencia Transversal:**
   * Cada módulo nuevo desarrollado debe parecer diseñado por el mismo equipo y bajo las mismas reglas que los módulos existentes.

---

## 2. Paleta Cromática, Tokens y Jerarquía de Superficies

### 2.1 Jerarquía de Superficies y Fondos
| Elemento | Token / Valor Flutter | Comportamiento y Propósito |
|---|---|---|
| **Fondo Global de Pantalla** | `Colors.grey.shade50` | Fondo base del `Scaffold`. Genera un suave contraste con las tarjetas blancas y reduce la fatiga visual. |
| **Superficie de Tarjetas (`Card`)** | `Colors.white` | Superficie elevada limpia para registros y trámites. Siempre combinada con borde sutil. |
| **Borde Sutil de Tarjetas** | `BorderSide(color: Colors.grey.shade200, width: 1)` | Delimitación nítida sin recurrir a sombras invasivas. |
| **Fondo de Paneles de Filtros** | `Colors.white` | Barra superior plana delimitada por `Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1))`. |
| **Superficies Secundarias Internas** | `Colors.grey.shade50` | Bloques interiores dentro de tarjetas (origen/destino, observaciones, metadatos). |
| **Borde de Controles e Inputs** | `Border.all(color: Colors.grey.shade300, width: 1)` | Contornos de campos de texto, botones secundarios y chips inactivos. |

### 2.2 Colores Corporativos y de Acción
| Rol | Token / Valor | Uso Estándar |
|---|---|---|
| **Primario Institucional** | `Theme.of(context).colorScheme.primary` | AppBars sólidos, botones principales estándar, tabs activas, destinos de flujo. |
| **Aprobación / Éxito** | Verde Esmeralda (`Color(0xFF1B5E20)` o `Colors.green.shade700`) | Botones de aprobación (`ElevatedButton`), badges de aprobado/verificado, confirmaciones. |
| **Rechazo / Peligro** | Rojo Corporativo (`Colors.red.shade700`, bordes `Colors.red.shade300`) | Botones de rechazo (`OutlinedButton`), badges de error/anulado, motivo de rechazo. |
| **Informativo / Proceso** | Índigo / Azul (`Colors.indigo.shade700` / `Colors.blue.shade700`) | Trámites procesados, consultas históricas, sincronización en piso. |
| **Advertencia / Pendiente** | Ámbar (`Colors.amber.shade800`) | Trámites pendientes de revisión, alertas de tiempo, estado de cálculo GPS. |

### 2.3 Código de Colores de Estado Canónico (Identidad SigoAPP)
Cualquier entidad que implemente estados de ciclo de vida (traspasos, requisiciones, inventarios) debe utilizar la siguiente correspondencia cromática obligatoria:

```dart
Color getStatusColor(TransferStatus status) {
  switch (status) {
    case TransferStatus.pending:
      return Colors.amber.shade800;
    case TransferStatus.approved:
      return Colors.green.shade700;
    case TransferStatus.rejected:
      return Colors.red.shade700;
    case TransferStatus.received:
      return Colors.blue.shade700;
    case TransferStatus.completed:
      return Colors.indigo.shade700;
    case TransferStatus.sourceSigned:
      return Colors.purple.shade700;
    case TransferStatus.targetSigned:
      return Colors.teal.shade700;
  }
}
```

---

## 3. Sistema de Radios de Esquinas (`BorderRadius`), Bordes y Sombras

Para evitar la estética inflada e informal del Material 3 desconfigurado, SigoAPP utiliza una escala de curvaturas estricta:

* **`BorderRadius.circular(6)` — Badges y Chips Compactos:**
  Utilizado para placas de activos, identificadores de trámite (`#1234`), chips de conteo (`3 artículos`) y selectores secundarios de filtro activo.
* **`BorderRadius.circular(8)` — Controles Operativos e Inputs:**
  Utilizado para todos los botones de acción (`ElevatedButton`, `OutlinedButton`), botones de estado de filtro, campos de texto (`TextFormField`) y menús desplegables (`DropdownButtonFormField`).
* **`BorderRadius.circular(12)` — Tarjetas y Diálogos:**
  Utilizado para tarjetas principales de registro (`Card`), paneles flotantes y ventanas modales de confirmación (`AlertDialog`).
* **Regla de Elevaciones:**
  * Tarjetas operativas: `elevation: 1.0` o `elevation: 1.5` como máximo.
  * AppBars: `elevation: 0` estrictamente.
  * Diálogos modales: `elevation: 3.0`.

---

## 4. Componentes Transversales Estándar

### 4.1 AppBar Corporativo Sólido
Toda pantalla principal o secundaria debe utilizar el AppBar con fondo primario sólido y contenido en blanco puro de alto contraste:
```dart
appBar: AppBar(
  title: Text(
    tituloPantalla,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
  ),
  backgroundColor: Theme.of(context).colorScheme.primary,
  foregroundColor: Colors.white,
  elevation: 0,
  actions: [ ... ],
)
```

### 4.2 Franja Superior de Resumen (Métricas de Conteo)
Inmediatamente debajo del AppBar o del panel de filtros se debe situar una franja continua informativa:
```dart
Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  color: Colors.white,
  child: Text(
    'Registros en lista: ${elementos.length}',
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 13,
      color: Colors.black87,
    ),
  ),
),
const Divider(height: 1, thickness: 1),
```

### 4.3 Tarjeta de Registro con Franja Vertical de Estado (5px)
Patrón transversal obligatorio para representar registros con estado (`lib/modules/inventory/widgets/inventory_article_tile.dart`, `lib/modules/inventory/screens/transfer_approval_screen.dart`):
```dart
Card(
  elevation: 1.5,
  margin: const EdgeInsets.symmetric(vertical: 4),
  color: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: Colors.grey.shade200, width: 1),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra vertical de estado
          Container(width: 5, color: statusColor),
          // Contenido estructurado
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ...
            ),
          ),
        ],
      ),
    ),
  ),
)
```

### 4.4 Botones de Acción Formales
* **Botón de Aprobación / Confirmación:**
  `ElevatedButton` con fondo verde esmeralda `Color(0xFF1B5E20)`, texto e icono en blanco, esquinas `r: 8`, elevación `1.0`.
* **Botón de Rechazo / Cancelación:**
  `OutlinedButton` con borde `Colors.red.shade300`, texto e icono en `Colors.red.shade700`, fondo transparente, esquinas `r: 8`.
* **Botón Secundario Neutro:**
  `OutlinedButton` con borde `Colors.grey.shade300`, texto e icono en `Colors.grey.shade800`, esquinas `r: 8`.

### 4.5 Diálogos Modales Estándar y Modales de Error
Todo diálogo modal (`showDialog` / `AlertDialog`) debe respetar:
* `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))`.
* Campos de entrada con `OutlineInputBorder(borderRadius: BorderRadius.circular(8))`.
* Botones de acción alineados al pie con esquinas `r: 8`.

#### Directrices para Diálogos de Error (`DialogUtils.showErrorDialog` y `DialogUtils.showInferredErrorDialog`)
1. **Desacoplamiento Funcional vs Técnico:**
   * **Cuerpo Principal:** Debe mostrar exclusivamente un mensaje amigable y conciso para el operador final (procesado con `DialogUtils.extractFriendlyMessage`), libre de volcados de JDBC, ORA de base de datos o stack traces crudos.
   * **Sección de Diagnóstico Expandible:** El acordeón "Ver detalles técnicos (Desarrollador)" aloja la información completa de depuración (código HTTP, endpoint consultado, traza del servidor y botón de copiado al portapapeles) en un contenedor monoespaciado (`11px`) con fondo `Colors.grey.shade100` y borde sutil.
2. **Inferencia Automática Universal (`DialogUtils.showInferredErrorDialog`):**
   * Permite a cualquier módulo invocar el diálogo modal pasando directamente la excepción tipada (`TransferBusinessException`, `RequisitionBusinessException`, `CatalogBusinessException`, etc.), `DioException`, o cadena de error. El método extrae de forma tipada y segura el mensaje funcional, código HTTP, endpoint y `technicalDetails`.
3. **Prevención Estricta de Desbordamientos Visuales (`Overflow`):**
   * La fila del encabezado del acordeón desplegable debe utilizar `MainAxisSize.min` y envolver el texto explicativo con `Flexible` para evitar errores de renderizado (`RenderFlex overflowed`) en ventanas compactas de Windows o dispositivos móviles.
   * Queda prohibido ubicar badges adicionales (ej. chips de método o código HTTP) en la misma fila horizontal del toggle desplegable; dichos metadatos deben residir estructurados dentro del área expandida.

#### Directrices para Diálogos de Confirmación y Éxito (`DialogUtils.showConfirmationDialog` y `DialogUtils.showSuccessDialog`)
1. **Diálogos de Confirmación (`showConfirmationDialog`):**
   * Estructura modal (`r: 12`, botones `r: 8`) con `barrierDismissible: false` para evitar toques involuntarios fuera del diálogo en entornos operativos.
   * Retorna `Future<bool?>` (`true` al confirmar, `false` al cancelar).
   * Admite icono opcional en el encabezado (`IconData? icon`), personalización de botones (`confirmText`, `cancelText`), color de confirmación configurable (`confirmButtonColor`) y bandera destructiva (`isDestructive: true` con fondo `Colors.red.shade700`).
2. **Diálogos de Éxito (`showSuccessDialog`):**
   * Modal formal de finalización exitosa (`r: 12`) con icono circular verde esmeralda (`Icons.check_circle_outline`, fondo `Colors.green.shade50`) y `barrierDismissible: false`.
   * Admite callback opcional `onAccept` que se ejecuta inmediatamente tras el cierre (`pop()`), ideal para disparar navegaciones o limpiezas de formulario sin condiciones de carrera.

### 4.6 Selectores Desplegables de Catálogo (Empresas y Bodegas)

Para garantizar consistencia visual y operativa en toda la aplicación, queda prohibido maquetar selectores de empresas o bodegas con implementaciones ad-hoc dispersas. Se deben utilizar obligatoriamente los widgets estandarizados del proyecto:

* **Empresas:** [`CompanyDropdownField`](../lib/widgets/company_dropdown_field.dart)
* **Bodegas:** [`WarehouseDropdownField`](../lib/widgets/warehouse_dropdown_field.dart)

#### Anatomía y Convenciones Obligatorias:
1. **Tipado de Dominio Estricto:** Operan exclusivamente con los modelos de datos inmutables del dominio (`CompanyModel` y `WarehouseModel`), previniendo desalineaciones por strings crudos o nulos imprevistos.
2. **Iconografía Institucional:**
   - Selector de Empresas: `prefixIcon: const Icon(Icons.business_outlined, size: 20)`.
   - Selector de Bodegas: `prefixIcon: const Icon(Icons.storefront_outlined, size: 20)`.
3. **Control de Esquinas y Espaciado:**
   - Borde rectangular estandarizado: `OutlineInputBorder(borderRadius: BorderRadius.circular(8))`.
   - Padding interno compacto: `contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)`.
4. **Búsqueda Interna Bimodal:**
   - Integran `DropdownTemplates.searchData` permitiendo al operador buscar en tiempo real tanto por **código** como por **descripción** (ambos normalizados a minúsculas).
5. **Manejo Reactivo de Estados Asíncronos:**
   - Inhabilitación automática (`onChanged: null`) cuando `isLoading == true` o la lista de catálogos esté vacía.
   - Textos guía (`hintText`) contextuales y dinámicos:
     - En carga: `"Cargando empresas..."` / `"Cargando bodegas..."`.
     - Lista vacía: `"No hay empresas disponibles"` / `"No hay bodegas disponibles"`.
     - Inactivo opcional: `"Todas las empresas"` / `"Todas las bodegas"` (cuando `allowClear: true`).
     - Formulario obligatorio: `"Seleccione una empresa"` / `"Seleccione una bodega"`.
6. **Formato de Renderizado del Ítem:**
   - Etiqueta de una sola línea con elipsis: `'${item.codigo} - ${item.descripcion}'` (`maxLines: 1`, `overflow: TextOverflow.ellipsis`).
7. **Deselección / Limpieza Rápida (`allowClear: true`):**
   - En paneles de filtros o consultas opcionales, al activar `allowClear: true`, el selector despliega automáticamente un botón `IconButton(Icons.clear)` como `suffixIcon` cuando hay un valor seleccionado, permitiendo regresar a estado nulo en un toque.

#### Ejemplo de Instanciación Canónica:

```dart
// Selector de Empresa (en formulario obligatorio)
CompanyDropdownField(
  value: provider.selectedCompany,
  companies: provider.companies,
  isLoading: provider.isLoadingCompanies,
  isRequired: true,
  onChanged: (CompanyModel? company) => provider.selectCompany(company),
)

// Selector de Bodega (en panel de filtros con deselección permitida)
WarehouseDropdownField(
  value: provider.selectedWarehouse,
  warehouses: provider.warehouses,
  isLoading: provider.isLoadingWarehouses,
  allowClear: true,
  onChanged: (WarehouseModel? bodega) => provider.selectWarehouse(bodega),
)
```

### 4.7 Notificaciones y Retroalimentación Rápida (SnackBars Institucionales)

Toda notificación flotante debe gestionarse a través de la API estandarizada de [`DialogUtils`](../lib/utils/dialog_utils.dart). Queda estrictamente prohibido instanciar `SnackBar` ad-hoc o utilizar fondos oscuros genéricos.

#### Tríada Semántica Institucional:
* **Éxito (`DialogUtils.showSuccessSnackBar`):**
  - **Fondo:** Verde Esmeralda Institucional `Colors.green.shade700` (`Color(0xFF1B5E20)`).
  - **Icono:** `Icons.check_circle_outline` (blanco, 24px).
  - **Uso:** Confirmación de trámites, creaciones, recepciones o aprobaciones exitosas.
* **Información (`DialogUtils.showInfoSnackBar`):**
  - **Fondo:** Azul Institucional `Colors.blue.shade800`.
  - **Icono:** `Icons.info_outline` (blanco, 24px).
  - **Uso:** Avisos contextuales, instrucciones operativas o estados informativos neutros.
* **Advertencia / Validación de Negocio (`DialogUtils.showWarningSnackBar`):**
  - **Fondo:** Ámbar Institucional `Colors.amber.shade800`.
  - **Icono:** `Icons.warning_amber_rounded` (blanco, 24px).
  - **Uso:** Restricciones de validación operativa (ej. *"Límite alcanzado: Máximo 50 artículos"*, *"Todos los activos deben pertenecer al mismo responsable"* o *"No se encontraron bodegas pendientes"*).

#### Reglas de Renderizado y Despacho:
1. **Comportamiento Flotante:** `behavior: SnackBarBehavior.floating` con esquinas redondeadas compactas `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))`.
2. **Tipografía de Alto Contraste:** Texto blanco puro (`Colors.white`) con `FontWeight.w600`.
3. **Limpieza Automática de Cola:** Toda invocación a `DialogUtils` ejecuta `ScaffoldMessenger.of(context).hideCurrentSnackBar()` antes de mostrar el nuevo mensaje, garantizando respuesta táctil inmediata y previniendo encolamientos acumulativos.
4. **Duración Ajustable:**
   - Estándar: `Duration(seconds: 4)` (por defecto).
   - Escaneo Rápido / Continuo (`ContinuousScanView`): `Duration(milliseconds: 800)` para ritmo ágil de operario.

#### Ejemplo de Implementación Canónica:
```dart
// Éxito
DialogUtils.showSuccessSnackBar(context, 'Traspaso creado exitosamente.');

// Advertencia de validación de negocio
DialogUtils.showWarningSnackBar(context, 'Límite alcanzado: Máximo 50 artículos por solicitud.');

// Información
DialogUtils.showInfoSnackBar(context, 'Se seleccionaron 5 activos compatibles.');

// Escaneo continuo ágil
DialogUtils.showSuccessSnackBar(
  context,
  'Artículo $barcode registrado exitosamente.',
  duration: const Duration(milliseconds: 800),
);
```

---

## 5. Manejo de Estados Asíncronos Transversales

1. **Estado de Carga (`loading: true`):**
   * Vista inicial: `Center(child: CircularProgressIndicator())` sobre fondo neutro.
   * Recarga en segundo plano: Botones de refresco o acciones secundarias inhabilitadas temporalmente (`onPressed: loading ? null : () => ...`).
2. **Estado Vacío (`items.isEmpty`):**
   * Contenedor centrado con icono gris temático de tamaño medio (`48px` a `56px`), título en negrita (`16px`, `Colors.grey.shade700`) y subtítulo explicativo conciso en gris.
3. **Estado de Error (`errorMessage != null`):**
   * **Widget Canónico Transversal:** Se debe utilizar obligatoriamente [`AppErrorWidget`](../lib/shared/widgets/app_error_widget.dart) para cualquier renderizado en pantalla:
     - `AppErrorWidget.inline(message: ...)`: Contenedor horizontal compacto (`r: 6`, fondo `Colors.red.shade50` o `Colors.amber.shade50`, borde sutil `0.8px`, icono 16px y tipografía 12px) ubicado inmediatamente debajo de inputs, selectores o límites de conteo.
     - `AppErrorWidget.banner(title: ..., message: ..., onRetry: ..., onShowDetails: ...)`: Banner de bloque en tarjetas o secciones (`r: 8`, fondo `Colors.red.shade50`, borde `1.0px`, icono 20px, título en negrita `13px` y descripción amigable `12px`), con soporte opcional para reintento y visualización de detalles técnicos.
     - `AppErrorWidget.view(title: ..., message: ..., onRetry: ...)`: Vista completa centrada para errores de pantalla completa con icono circular de 48px y botón formal de reintento (`FilledButton.tonalIcon`). Obligatorio en bandejas maestras cuando la lista de documentos esté vacía debido a un fallo de red o backend (`ApprovalTabView`, `DeliveryTabView`, `RequisitionSignatureScreen`, `TransferApprovalScreen`, `TransferDeliveryScreen`).

---

## 6. Anti-Patrones Transversales Prohibidos

> [!CAUTION]
> Queda estrictamente prohibido introducir en SigoAPP:
> 1. **Chips estilo píldora desbordados (`BorderRadius.circular(20)` o `30`)** que inflen innecesariamente la altura de paneles y reduzcan la densidad de datos.
> 2. **AppBars transparentes o en colores pasteles claros** sin contraste sobre el contenido.
> 3. **Tarjetas sin indicador visual de estado** cuando la entidad posee ciclo de vida (pendientes, aprobados, rechazados, completados).
> 4. **Sombras difusas desmedidas (`elevation > 3`)** que generen efecto borroso en la interfaz.
> 5. **Colores pastel sin contraste** para texto o badges operativos que dificulten la lectura en pantallas de dispositivos industriales bajo luz natural.

---

# PARTE II — ESPECIFICACIONES PARTICULARES (POR PANTALLA Y MÓDULO)

Esta sección define las particularidades funcionales, de layout, flujos de interacción y componentes exclusivos para cada módulo y pantalla del proyecto.

---

## Módulo 1: Autenticación y Configuración de Dominio

### Pantallas Involucradas
* `DomainScannerScreen` (`lib/modules/auth/screens/domain_scanner_screen.dart`)
* `AuthScreen` (`lib/modules/auth/screens/auth_screen.dart`)

### Especificaciones de Layout y UI/UX
1. **Pantalla de Autenticación (`AuthScreen`):**
   * **Layout:** Vista centrada vertical y horizontalmente sobre fondo `Colors.grey.shade50`.
   * **Tarjeta de Login:** Contenedor central blanco con radio `BorderRadius.circular(16)`, elevación `2.0` y borde sutil `Colors.grey.shade200`. Ancho máximo acotado (máx. 420px en tablets/web).
   * **Branding:** Logotipo o isotipo institucional en la cabecera del formulario con subtítulo sobrio: `"Sistema de Gestión Operativa"`.
   * **Campos de Entrada:** `TextFormField` para cédula/usuario y contraseña con `prefixIcon` institucional, borde rectangular `OutlineInputBorder(borderRadius: BorderRadius.circular(8))` y validación en tiempo real.
   * **Botón Principal:** Botón de acceso con ancho total (`double.infinity`), altura de 48px, fondo primario institucional y esquinas `r: 8`. Al procesar, sustituye el texto por `SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))`.
   * **Cambio de Servidor / Dominio:** Botón de texto discreto en el pie (`TextButton`) con icono `Icons.qr_code_scanner` para abrir el escáner de dominio.
2. **Pantalla de Escáner de Dominio (`DomainScannerScreen`):**
   * **Layout:** Visor de cámara a pantalla completa con máscara oscura y marco de lectura cuadrado centrado con bordes en el color primario corporativo.
   * **Panel Inferior:** Tarjeta flotante blanca con opción de ingreso manual de URL/dominio mediante campo de texto `r: 8` y botón "Guardar y Conectar".

---

## Módulo 2: Dashboard Principal y Navegación Dinámica

### Pantalla Involucrada
* `DashboardScreen` (`lib/modules/dashboard/screens/dashboard_screen.dart`)

### Especificaciones de Layout y UI/UX
1. **AppBar del Dashboard:**
   * Título: `"SIGAPP"` con texto institucional en blanco.
   * Acciones: Botón de refresco manual de permisos y botón de logout institucional (`Icons.logout_rounded`) que invoca `AuthUtils.confirmLogout(context)`.
2. **Encabezado de Bienvenida:**
   * Franja superior de fondo blanco con saludo al usuario, cédula y rol actual con tipografía limpia (`fontSize: 14`, negrita en nombre).
3. **Grid Modular Dinámico:**
   * `GridView.builder` responsivo (2 columnas en móviles, 3-4 en tablets).
   * Tarjeta de Módulo: Fondo blanco, esquinas `BorderRadius.circular(12)`, borde fino `Colors.grey.shade200` y elevación suave `1.0`.
   * Icono del Módulo: Contenedor cuadrado redondeado (`48x48`, `r: 10`) con fondo translúcido del color primario `primary.withValues(alpha: 0.1)` e icono temático en color primario pleno.
   * Texto del Módulo: Título en negrita centrado o alineado a la izquierda (`13px`), máximo 2 líneas.
4. **Badges de Notificación sobre Módulos:**
   * Si un módulo cuenta con tareas pendientes (ej. aprobación de traspasos pendientes `aatr`), se debe posicionar un badge circular rojo o ámbar en la esquina superior derecha de la tarjeta con el conteo numérico de solicitudes pendientes.
5. **Control de Salida de la App:**
   * Manejo obligatorio con `PopScope` para interceptar el botón atrás de Android y desplegar diálogo modal institucional de confirmación de salida.

---

## Módulo 3: Inventario, Verificación y Catálogo

### Pantallas y Widgets Involucrados
* `InventoryScreen` (`lib/modules/inventory/screens/inventory_screen.dart`)
* `AssetVerificationScreen` (`lib/modules/inventory/screens/asset_verification_screen.dart`)
* `GeneratorScreen` (`lib/modules/inventory/screens/generator_screen.dart`)
* `InventoryArticleTile` (`lib/modules/inventory/widgets/inventory_article_tile.dart`)
* `CascadingCatalogsWidget` (`lib/modules/inventory/widgets/cascading_catalogs_widget.dart`)
* `ArticleEditModal` (`lib/modules/inventory/widgets/article_edit_modal.dart`)

### Especificaciones de Layout y UI/UX
1. **Pantalla Principal de Inventario (`InventoryScreen`):**
   * **AppBar:** Título `"Inventario de Activos"`, botón de búsqueda y acceso directo al escáner de código de barras / QR.
   * **Filtros en Cascada (`CascadingCatalogsWidget`):** Selectores empresa → bodega → colaborador en contenedor blanco superior delimitado.
   * **Franja Métrica:** `"Activos en lista: ${articulos.length}"` con separador continuo.
   * **Tarjeta de Activo (`InventoryArticleTile`):**
     * Franja vertical de 5px: Verde si el activo ya fue auditado/verificado, gris si está pendiente de conteo, ámbar si tiene solicitud de traspaso en curso.
     * Placa y Serial: Placa destacada en badge gris claro con fuente monoespacio en negrita (`Placa: ACT-9847`).
     * Botón de Acción Rápida: Botón de transferencia individual `⇄` en el lateral derecho para abrir directamente la creación de traspaso pre-cargado.
   * **Modo Selección Múltiple (`_isSelectionMode`):**
     * Activado desde el Floating Action Button institucional.
     * Checkboxes integrados en cada tarjeta de activo con animación suave.
     * Barra inferior fija de acciones: Conteo de seleccionados (`"N seleccionados"`), botón cancelar selección y botón `"Crear Traspaso Múltiple"` en color primario.
2. **Modal de Edición Rápida de Artículo (`ArticleEditModal`):**
   * Diálogo modal o modal bottom sheet con esquinas `BorderRadius.circular(12)`.
   * Secciones bien demarcadas con encabezados en gris oscuro: Datos del activo, Ubicación física, Coordenadas GPS y Evidencia fotográfica.
3. **Verificación de Activos (`AssetVerificationScreen`):**
   * Visor de cámara en mitad superior y tarjeta de resultados en mitad inferior.
   * Badge de GPS satelital: Verde fijo cuando la precisión es `< 10m` con coordenadas visibles, ámbar titilante mientras calcula fijación geográfica.

---

## Módulo 4: Aprobación de Traspasos

### Pantallas y Widgets Involucrados
* `TransferApprovalScreen` (`lib/modules/inventory/screens/transfer_approval_screen.dart`)
* `TransferFilterPanel` (`lib/modules/inventory/widgets/transfer_filter_panel.dart`)

### Especificaciones de Layout y UI/UX
1. **Panel de Filtros Fijo (`TransferFilterPanel`):**
   * Ubicación fija bajo el AppBar, fondo blanco plano con borde inferior `Colors.grey.shade200`.
   * **Botón de Filtros Secundarios:** Selector rectangular `r: 8` a la izquierda con icono `Icons.filter_list_rounded` y badge circular primario con la cantidad de filtros avanzados activos (empresa, bodega, fechas).
   * **Separador vertical:** `Container(height: 22, width: 1, color: Colors.grey.shade300)`.
   * **Carrusel de Estados:** Botones rectangulares `r: 8` en scroll horizontal (`Pendientes`, `Procesados`, `Aprobados`, `Rechazados`, `Recibidos`). Estado activo con fondo translúcido `alpha: 0.1` y borde `1.4px` en el color del estado; estado inactivo en fondo neutro con borde `Colors.grey.shade300`.
2. **Franja Superior de Resumen:**
   * `"Solicitudes en lista: ${transfers.length}"` en fondo blanco con `Divider(height: 1, thickness: 1)`.
3. **Tarjeta de Traspaso (`_TransferCard`):**
   * Franja lateral de 5px con color dinámico según `getStatusColor(transfer.estado)`.
   * **Fila Superior:** Badge gris con identificador (`Trámite #1234`), identificador de requisición si existe y badge de estado de alto contraste a la derecha.
   * **Bloque de Trayectoria Origen ➔ Destino (Fila Única):**
     * Contenedor compacto en fondo `Colors.grey.shade50`, borde `Colors.grey.shade200`, `r: 8`.
     * Origen: Icono `Icons.storefront_outlined`, nombre de bodega origen en negrita (`12px`), responsable abajo en gris (`11px`).
     * Centro: Flecha sutil `Icons.arrow_forward_rounded` (`15px`, `Colors.grey.shade400`).
     * Destino: Icono `Icons.warehouse_outlined` en color primario, bodega destino en negrita (`12px`), responsable abajo en gris (`11px`).
   * **Desglose de Activos:**
     * Registro único: Fila con icono de inventario, nombre de activo y badge con número de placa.
     * Multi-artículo: Acordeón colapsable con badge `"N artículos"`, previsualización del primer activo y lista expandible.
   * **Observaciones y Motivo de Rechazo:**
     * Observaciones normales: Bloque gris tenue con icono de comillas `Icons.format_quote_rounded`.
     * Motivo de rechazo: Bloque de alerta en rojo tenue (`Colors.red.shade50`, borde `Colors.red.shade200`) con icono explicativo.
4. **Footer de Acciones Operativas:**
   * Visible únicamente en trámites pendientes (`pe`).
   * Botón Rechazar: `OutlinedButton` en rojo corporativo (`foregroundColor: Colors.red.shade700`, borde `Colors.red.shade300`, `r: 8`).
   * Botón Aprobar: `ElevatedButton` en verde esmeralda institucional (`Color(0xFF1B5E20)`, `foregroundColor: Colors.white`, `r: 8`).
   * **Modal de Rechazo:** Diálogo modal `r: 12` con campo multilínea obligatorio (`TextFormField`) para ingresar el motivo de rechazo; botón de confirmación en rojo corporativo inhabilitado si el motivo está vacío.

---

## Módulo 5: Entrega, Recepción y Captura de Firmas

### Pantallas Involucradas
* `TransferDeliveryScreen` (`lib/modules/inventory/screens/transfer_delivery_screen.dart`)
* `SignatureCaptureScreen` (`lib/modules/inventory/screens/signature_capture_screen.dart`)

### Especificaciones de Layout y UI/UX
1. **Pantalla de Entrega / Despacho (`TransferDeliveryScreen`):**
   * Listado de solicitudes en estado aprobado (`ap`) listas para despacho o entrega física.
   * **Título de la Tarjeta (`_DeliveryCard`):** Cuando el trámite contenga más de 1 artículo (`request.articulos.length > 1`), el título principal de la tarjeta muestra exclusivamente `-cantidad- artículos` (ej. `'2 artículos'`). Si es un solo artículo, muestra el nombre individual del activo.
   * **Subtítulo Multi-Artículo:** Debajo del título, cuando hay múltiples artículos, se detalla la lista de activos incluidos (*"Artículos incluidos: [Nombre] ([Código]), ..."*).
   * Tarjeta de trámite con sección de validación de entrega:
     * Checkbox o verificación de cada activo físico entregado contra lista.
     * Indicador de Firma de Origen / Despacho: Badge ámbar `"Pendiente firma entrega"` o verde `"Firma entrega registrada"`.
     * Indicador de Firma de Receptor: Badge ámbar `"Pendiente firma receptor"` o verde `"Firma receptor registrada"`.
   * Botón de acción con icono de stylus `Icons.draw_rounded` para abrir la captura de firmas.
2. **Pantalla de Captura de Firma Digital (`SignatureCaptureScreen`):**
   * **AppBar Sólido:** Título `"Captura de Firma - [Rol]"` (ej. Entrega / Recepción).
   * **Área de Firma (Canvas):** Fondo blanco puro delimitado por borde `Colors.grey.shade300` con línea horizontal punteada de guía para el trazo.
   * **Barra Inferior de Acciones Fija:**
     * Botón `"Limpiar Trazo"` (`OutlinedButton` neutro con icono `Icons.clear_rounded`, esquinas `r: 8`).
     * Botón `"Confirmar y Guardar Firma"` (`ElevatedButton` en verde esmeralda institucional `Color(0xFF1B5E20)`, esquinas `r: 8`).

---

## Módulo 6: Requisiciones de Inventario

### Pantallas y Tabs Involucrados
* `RequisitionsScreen` (`lib/modules/requisitions/screens/requisitions_screen.dart`)
* `ApprovalTabView` (`lib/modules/requisitions/tabs/approval_tab_view.dart`)
* `DeliveryTabView` (`lib/modules/requisitions/tabs/delivery_tab_view.dart`)
* `RequisitionSignatureScreen` (`lib/modules/requisitions/screens/requisition_signature_screen.dart`)
* `RequisitionSignatureCaptureScreen` (`lib/modules/requisitions/screens/requisition_signature_capture_screen.dart`)
* `RequisitionFilterHeader` (`lib/modules/requisitions/widgets/requisition_filter_header.dart`)
* `RequisitionActionCard` (`lib/modules/requisitions/widgets/requisition_action_card.dart`)

### Especificaciones de Layout y UI/UX
1. **TabBar Institucional:**
   * Integrado en el AppBar primario con indicador de pestaña blanco nítido (`indicatorColor: Colors.white`).
   * Pestaña 1: `"Aprobación"` (asociada al permiso `areq`, estado `'in'`).
   * Pestaña 2: `"Entrega"` (asociada al permiso `aein`, estado `'ap'`).
2. **Cabecera de Filtros Institucional (`RequisitionFilterHeader`):**
   * **Superficie y Borde:** Contenedor superior con fondo blanco puro delimitado por `Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1))`.
   * **Persistencia Visual:** Se ubica como primer elemento dentro de la `Column` principal de cada pestaña, permaneciendo visible y operativo durante estados de carga (`CircularProgressIndicator`), errores de red o bandeja vacía.
   * **Orden Canónico de Controles:**
     - **1° Selector de Empresa:** `DropdownButtonFormField2<CompanyModel>` idéntico funcionalmente a Conteo Físico (opera con instancias `CompanyModel`, búsqueda interna mediante `DropdownTemplates.searchData` y control de carga reactivo), conservando la estética institucional de Requisiciones: esquinas `BorderRadius.circular(8)`, icono de negocio, botón de limpieza `clear` para deseleccionar y padding compacto.
     - **2° Selector de Fecha Inicial ("Desde"):** `TextFormField` de solo lectura con icono `Icons.calendar_today_outlined` que despliega `showDatePicker`. Muestra la fecha en formato legible `dd/MM/yyyy`, botón `clear` de limpieza y esquinas `r: 8`. Formatea internamente hacia la API en estándar estricto ISO `YYYY-MM-DD`.
3. **Tarjeta de Documento Master-Detail (`RequisitionActionCard`):**
   * **Nivel 1 (Cabecera Master):**
     * Franja vertical de 5px con color de estado canónico: ámbar (`Colors.amber.shade800`) para requisiciones pendientes (`in`), verde esmeralda (`Colors.green.shade700`) para aprobadas (`ap`), azul (`Colors.blue.shade700`) para entregadas (`en`).
     * Cabecera formal con ícono `Icons.description_outlined` y terna/identificador visible (`RS #10543`).
     * Subtítulo estructurado: Bodega de despacho con ícono de negocio (`Bodega: B01`), fecha de radicación en ERP (`dd/MM/yyyy`) y badge compacto con la cantidad total de artículos solicitados (`N artículos solicitados`).
     * Badge de estado en alto contraste (`PENDIENTE`, `APROBADA`, `ENTREGADA`) en fondo translúcido con borde temático.
   * **Nivel 2 (Movimientos y Líneas bajo Demanda):**
     * Contenedor expandible (`ExpansionTile`): al desplegar, si los detalles no residen en memoria, se invoca automáticamente `GET /api/v1/requisiciones/{empresa}/{tipo}/{num}` con indicador de progreso sutil o botón de reintento ante errores de red.
     * Metadatos ampliados: Tercero solicitante, fecha requerida y observación formal en contenedor blanco delimitado con comillas.
     * Barra de utilidades del documento con conteo de movimientos y botones de acción rápida (*"Seleccionar todo"* / *"Limpiar"*).
     * Líneas de movimiento individuales (`_RequisitionMovementRow`):
       - Checkbox para selección en bloque.
       - Código y descripción del artículo, secuencia, bodega y unidad.
       - Badges cuantitativos compactos: Solicitada (`Sol`), Aprobada (`Aprob`), Entregada (`Entr`) y Pendiente (`Pend`).
       - Campo de entrada numérico para capturar cantidades con validación en tiempo real: $> 0 \land \le \text{máximo permitido}$ (`solicitada` en aprobación, `aprobada` en entrega). Ante valores inválidos o cero, el borde se resalta en rojo y el checkbox se inhabilita.
4. **Franja Métrica y Estados Asíncronos (Fail-Fast UI):**
   * **Estado de Fecha Requerida (Lazy Fetch):** Cuando `desde` no ha sido seleccionado, se muestra un contenedor centrado con ícono de calendario en color primario (`Icons.calendar_month_outlined`, `64px`), título *"Consulta de Requisiciones"* y leyenda instructiva: *"Selecciona una fecha en el filtro superior para consultar las requisiciones vigentes."*.
   * **Franja Métrica de Resumen:** Situada inmediatamente bajo el panel de filtros persistente, muestra `"Documentos en lista: ${documents.length}"` en fondo blanco puro con divisor inferior continuo.
   * **Bandeja al Día:** Ícono neutro con mensaje informativo cuando no hay documentos pendientes con los filtros aplicados.
5. **Procesamiento Masivo (FAB):**
   * `FloatingActionButton.extended` centrado al pie, visible únicamente cuando `selectedCount > 0`.
   * Pestaña Aprobación: ícono `Icons.check_circle_outline` y texto `"Procesar Selección (N)"`.
   * Pestaña Entrega: ícono `Icons.local_shipping_outlined` y texto `"Registrar Entrega (N)"`.
   * Notificación mediante `SnackBar` institucional y recarga automática de bandeja tras confirmación del backend.
6. **Bandeja de Firma de Requisiciones Entregadas y Cierre ERP (`RequisitionSignatureScreen`):**
   * **Control de Acceso:** Protegida de forma exclusiva por el permiso **`areq`** (`AppPermission.requisiciones`), tanto en el acceso desde el Dashboard como en la defensa en profundidad de la pantalla con vista informativa de acceso restringido.
   * **Tarjeta de Requisición Entregada (`_RequisitionSignatureCard`):**
     * Franja lateral de 5px antichoques (`Stack` + `Positioned(left: 0, top: 0, bottom: 0, width: 5)` con `clipBehavior: Clip.antiAlias`):
       - **Azul (`Colors.blue.shade700`):** Para estado `"FIRMAS PENDIENTES"` (`!bothSigned`).
       - **Verde (`Colors.green.shade700`):** Para estado `"LISTA PARA ERP"` (`bothSigned`).
     * Badges semafóricos de firma (Salida SA y Recibo RE):
       - *Registrada:* Verde (`Colors.green.shade50`, borde `green.shade200`, texto `green.shade800`) indicando la cédula del firmante.
       - *Pendiente:* Naranja (`Colors.orange.shade50`, borde `orange.shade200`, texto `orange.shade800`).
     * Acciones Operativas con layout responsivo `Wrap` e Inferencia de Roles:
       - **Inferencia Automática:** El colaborador nunca escoge manualmente la firma; la interfaz determina `isReceiver` y `isDispatcher` a partir de `auth.currentCedula`.
       - Botón condicional único *"Firmar Salida (SA)"* (`Colors.blue.shade700`, `r: 8`): Visible únicamente si el usuario es el responsable de la bodega fuente (`isDispatcher`: coincidencia estricta `auth.currentCedula == detail.responsableBodega` sin fallback permisivo) y falta la firma SA.
       - Botón condicional único *"Firmar Recibo (RE)"* (`Colors.teal.shade700`, `r: 8`): Visible únicamente si el usuario es el receptor titular (`auth.currentCedula == detail.tercero`) o el responsable de la bodega destino (`auth.currentCedula == detail.responsableBodegaDestino`), y falta la firma RE.
       - Contenedor de espera de co-firmante (`Colors.blueGrey.shade50`, borde `blueGrey.shade200`, ícono `Icons.hourglass_top_rounded`): Informa que la firma del usuario ya fue registrada y se espera la contraparte.
       - Contenedor informativo de usuario sin rol (`Colors.grey.shade100`, borde `grey.shade300`, ícono `Icons.lock_outline`): Despliega *"Usted no es responsable de la bodega ni solicitante de este documento"*, impidiendo cualquier acción no autorizada.
       - Botón destacado *"Registrar Salida"* (`Colors.green.shade700`, `r: 8`): Visible cuando ambas firmas están completas (`bothSigned`) reservado estrictamente al responsable de la bodega fuente (`isDispatcher`). Si ambas firmas están completas pero el usuario autenticado no es el responsable, se despliega un contenedor informativo (`Colors.green.shade50`, borde `green.shade200`, ícono `Icons.check_circle`) indicando *"Firmas completas. Pendiente registro de salida por el responsable de la bodega."*. Al presionar, despliega diálogo modal advirtiendo el punto de no retorno e irreversibilidad de la transacción.
7. **Captura Interactiva de Firma Digital (`RequisitionSignatureCaptureScreen`):**
   * **Identificación y Banners Informativos de Rol:**
     - **Firma Recibo (RE):** Despliega banner verde agua (`Colors.teal.shade50`, borde `teal.shade300`) con `Icons.verified_user_rounded` certificando: *"Usted está firmando como receptor titular de esta requisición (<usuario>)"*.
     - **Firma Salida (SA):** Despliega banner azul (`Colors.blue.shade50`, borde `blue.shade300`) con `Icons.badge_outlined` certificando: *"Usted está firmando como despachador de almacén (<usuario>)"*.
   * **Campo de Cédula (Anti-Suplantación):** `TextFormField` bloqueado con `readOnly: true`, fondo atenuado (`fillColor: Colors.grey.shade100`), ícono de candado `Icons.lock_outline` y `helperText` explicativo, garantizando que la firma manuscrita quede vinculada de forma inalterable al usuario en sesión.
   * **Área de Lienzo (Canvas):** Widget `Signature` (alto 240px, fondo blanco, trazo negro ancho 3) con franja inferior que incluye botón de limpieza *"Limpiar trazo"*.
   * **Botón de Guardado:** `ElevatedButton.icon` en verde (`Colors.green.shade700`, padding vertical 14, `r: 8`) con bloqueo modal (`CircularProgressIndicator`) durante el registro asíncrono.

---

## Módulo 7: Conteo Físico Administrativo y en Piso

### Pantallas y Tabs Involucrados
* `PhysicalCountScreen` (`lib/modules/physical_count/screens/physical_count_screen.dart`)
* `PhysicalCountOpeningTab` (`lib/modules/physical_count/tabs/physical_count_opening_tab.dart`)
* `PhysicalCountAssignmentTab` (`lib/modules/physical_count/tabs/physical_count_assignment_tab.dart`)
* `PhysicalCountClosingTab` (`lib/modules/physical_count/tabs/physical_count_closing_tab.dart`)
* `ActiveCountScreen` (`lib/modules/physical_count/screens/active_count_screen.dart`)

### Especificaciones de Layout y UI/UX
1. **Administración del Conteo (`PhysicalCountScreen`):**
   * TabBar dinámico según permisos (`aacf`, `aacu`, `accf`):
     * **Pestaña Apertura:** Formulario ordenado en tarjetas blancas con selectores estándar en cascada (`DropdownTemplates`) de empresa, bodega y fecha de corte. Botón de apertura destacado al pie.
     * **Pestaña Asignación:** Selector de conteo activo y lista de colaboradores con casillas de verificación o chips interactivos (`r: 8`).
     * **Pestaña Cierre:** Panel de resumen con tarjeta semafórica de bodegas pendientes (icono de advertencia ámbar si hay bodegas sin cerrar) y botón de cierre definitivo con confirmación modal obligatoria.
   * **Manejo Estandarizado de Errores Transaccionales:** Los fallos en apertura (`PhysicalCountOpeningTab`), asignación (`PhysicalCountAssignmentTab`), cierre (`PhysicalCountClosingTab`) y consulta de bodegas se gestionan obligatoriamente mediante `DialogUtils.showErrorDialog` o `DialogUtils.showPendingWarehousesErrorDialog` (evitando SnackBars efímeros que se pierdan o desborden ante trazas de backend), garantizando la sanitización de errores vía `extractFriendlyMessage` y exponiendo el acordeón de soporte para desarrolladores.
2. **Ejecución en Piso / Conteo Offline (`ActiveCountScreen`):**
   * **Cabecera Fija de Sesión:** Contenedor blanco con ID de conteo, nombre de bodega actual y badge de conectividad (`Offline` en gris/ámbar, `Sincronizado` en verde).
   * **Campo de Captura Rápida:** Campo de texto de alta reactividad con `autofocus: true` persistente para pistolas lectoras de código de barras láser bluetooth.
   * **Feedback Visual Instantáneo (Flash):**
     * Lectura exitosa: Borde del contenedor o flash visual de 200ms en verde con confirmación háptica/sonora.
     * Lectura errónea o activo ajeno a la bodega: Flash visual en rojo corporativo con alerta de advertencia inmediata.
   * **Franja Métrica Inferior:** Conteo en tiempo real de artículos leídos vs esperados, y botón flotante/fijo de "Cerrar Conteo y Sincronizar".

---

## Módulo 8: Gestión de Cuenta y Utilidades de Diagnóstico

### Pantallas Involucradas
* `AccountScreen` (`lib/modules/debug/screens/account_screen.dart`)
* `ScannerScreen` (`lib/modules/debug/screens/scanner_screen.dart`)
* `HomeScreen` (`lib/modules/debug/screens/home_screen.dart`)

### Especificaciones de Layout y UI/UX
1. **Pantalla de Cuenta (`AccountScreen`):**
   * Tarjeta superior con avatar corporativo, nombre completo del colaborador, cédula institucional y versión oficial instalada (`vX.Y.Z (build N)`).
   * Sección estructurada de permisos asignados con badges informativos grises (`r: 6`) y descripción de cada permiso.
2. **Módulo Principal de Pruebas / Debug (`HomeScreen`, `ScannerScreen`):**
   * Visible únicamente cuando `kReleaseMode == false`.
   * Herramientas de diagnóstico de lectura de hardware y generación de QR de prueba.

---

## 7. Resumen de Referencias Cruzadas en el Código Fuente

Para revisar las implementaciones canónicas vigentes en el código fuente:

| Pantalla / Widget | Archivo | Patrón Destacado |
|---|---|---|
| **Renderizado de Errores** | `lib/shared/widgets/app_error_widget.dart` | Constructores canónicos `.inline`, `.banner` y `.view` con icono 48px, reintento y detalles técnicos. |
| **Modales de Error y Sanitización** | `lib/utils/dialog_utils.dart` | `showErrorDialog` y `showInferredErrorDialog` con extracción de mensajes de negocio y acordeón de depuración. |
| **Aprobación de Traspasos** | `lib/modules/inventory/screens/transfer_approval_screen.dart` | AppBar sólido, franja métrica, tarjetas con franja de 5px, flujo en una línea, botones `r: 8`. |
| **Panel de Filtros** | `lib/modules/inventory/widgets/transfer_filter_panel.dart` | Selectores rectangulares `r: 8`, código de color temático por estado, badge de filtros activos. |
| **Tarjeta de Inventario** | `lib/modules/inventory/widgets/inventory_article_tile.dart` | Franja vertical de 5px, badges de placa monoespacio, soporte modo individual y selección múltiple. |
| **Inventario Principal** | `lib/modules/inventory/screens/inventory_screen.dart` | Filtro cascada, barra de búsqueda, franja de resumen, modo selección con barra inferior. |
| **Dashboard Modular** | `lib/modules/dashboard/screens/dashboard_screen.dart` | Grid dinámico con permisos, badges de alerta de trámites pendientes, confirmación `PopScope`. |
| **Entrega y Firmas** | `lib/modules/inventory/screens/transfer_delivery_screen.dart`, `lib/modules/inventory/screens/signature_capture_screen.dart` | Checklist físico, canvas de firma con guía horizontal punteada y botones de guardado. |
| **Firma de Requisiciones** | `lib/modules/requisitions/screens/requisition_signature_screen.dart`, `lib/modules/requisitions/screens/requisition_signature_capture_screen.dart` | Franja de 5px (azul/verde), badges semafóricos, banners de titularidad, botones en Wrap y modal de punto de no retorno. |
| **Administración Conteo** | `lib/modules/physical_count/screens/physical_count_screen.dart` | TabBar modular por permisos, selectores `DropdownTemplates`, semáforo de cierre. |
| **Conteo en Piso** | `lib/modules/physical_count/screens/active_count_screen.dart` | Cabecera fija de sesión, campo para lector láser, feedback visual instantáneo (flash). |
