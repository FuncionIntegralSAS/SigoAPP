# Documentación de Arquitectura de Software
Proyecto: SigoAPP
Versión: 1.9
Fecha de actualización: Marzo 2026

## 1. Estructura de Directorios (Mapping)
El proyecto organiza el código fuente bajo el directorio lib/, siguiendo principios de Clean Architecture para facilitar el mantenimiento y la inyección de dependencias hacia el backend (Spring Boot / Oracle).

lib/
 ├── models/        → Modelos de dominio (inmutables)
 ├── services/      → Servicios HTTP y Mocks (infraestructura)
 ├── repositories/  → Abstracciones de acceso a datos (Interfaces)
 ├── providers/     → Manejo de estado (ChangeNotifier)
 ├── screens/       → Pantallas orquestadoras y contenedores
 │    └── tabs/     → Vistas internas para controladores de pestañas
 ├── widgets/       → Componentes UI reutilizables

## 2. Definición Extendida de Modelos (lib/models/)
### 2.1 article_model.dart
Representa un activo físico del inventario. Incluye identidad, responsable asignado, ubicación y metadatos operativos, con integración para lectura QR.

### 2.2 transfer_request.dart
Modelo central para el traslado físico de activos. Mantiene el estado del flujo y garantiza la trazabilidad entre bodegas y responsables.

### 2.3 requisition_model.dart
Representa una solicitud administrativa de consumo o salida de inventario.
* Responsabilidades: Preservar la trazabilidad jerárquica de cantidades (Solicitada -> Aprobada -> Entregada).
* Llave Primaria: compositeId (generada a partir de empresa, tipo de documento, número, bodega y artículo).
* Estados soportados: 'pe' (Pendiente), 'ap' (Aprobada), 'na' (Rechazada/No aprobada), 'pr' (Procesada).

### 2.4 physical_count_model.dart y company_model.dart (Módulo de Conteo Físico)
Modelos encargados de la recolección de datos para la generación de la apertura de un conteo físico de inventario.
* `PhysicalCountRequest`: Capta empresa, bodega, fecha, artículos, bandera de verificación lógica/física y lista de participantes (solo IDs enviados en JSON para optimización).
* `CompanyModel`: Entidad simple para listar empresas base.

## 3. Capa de Repositorios (lib/repositories/)
### 3.1 TransferRepository
Contrato que define la creación, consulta y procesamiento de solicitudes de traspaso de activos.

### 3.2 RequisitionRepository
Contrato que define el acceso a las requisiciones de consumo.
* getRequisitionsByStatus(String status): Consulta filtrada de requerimientos.
* processBatch(Map<String, int> selectedItems, String targetStatus): Envío de múltiples identificadores y cantidades en bloque para optimización de transacciones.

## 4. Lógica de Negocio y Servicios (lib/services/)
### 4.1 mock_inventory_service.dart y mock_requisition_service.dart
Servicios que simulan las respuestas del servidor para habilitar el desarrollo frontend y pruebas offline, implementando latencia artificial.

### 4.2 Integración Spring Boot (Backend)
Capa de conexión real hacia los endpoints desarrollados en Spring Boot. 
* Formato de intercambio: JSON en formato camelCase.
* Reglas de catálogos: Carga jerárquica obligatoria (Búsqueda de empleado por identificador -> Obtención de divisionId -> Consulta de bodegas autorizadas por división).
* Lógica pesada: Delegada a procedimientos almacenados en Oracle (ej. PKGTRASPASO).

### 4.3 physical_count_service.dart
Simula la red para el módulo de Conteo Físico. Retorna listas maestras (empresas, bodegas, artículos, personal) con latencia y soporta la inyección simulada de errores HTTP (400, 409, 500) para comprobar el manejo robusto del Provider asociado.

## 5. Providers (lib/providers/)
### 5.1 TransferRequestProvider y TransferApprovalProvider
Orquestadores de estado para la creación y aprobación de traslados físicos de activos.

### 5.2 AssetVerificationProvider
Maneja la lógica de interpretación de códigos QR (separación de placa y artículo) y validación contra el servicio.

### 5.3 RequisitionApprovalProvider
Gestor de estado centralizado para el flujo de requisiciones administrativas.
* Mantiene la lista de requisiciones visibles según la pestaña activa.
* Administra un mapa temporal de ítems seleccionados para procesamiento en lote.
* Dispara el método processBatchSelection() hacia el repositorio.

### 5.4 PhysicalCountProvider
Orquestador de estado para el submódulo de Conteo Físico.
* Administra las listas maestras de selectores (dropdowns) y búsquedas reactivas en texto.
* Maneja los estados del submódulo de forma reaccionaria a eventos del usuario (`INITIAL`, `EN_PROCESO`, `CREADA`, `ERROR`).
* Implementa las validaciones estrictas de campos de la UI antes de derivar responsabilidades al service.

## 6. Componentes de UI y Navegación
### 6.1 RequisitionsScreen y Tabs
Pantalla principal de requisiciones construida sobre un TabController explícito. 
* ApprovalTabView: Consume la lista de requisiciones en estado pendiente ('pe').
* DeliveryTabView: Consume la lista de requisiciones en estado aprobado ('ap').

### 6.2 RequisitionActionCard
Componente visual tipo tarjeta expandible para iterar sobre listas de requisiciones.
* Utiliza las propiedades jerárquicas del modelo para limitar dinámicamente las cantidades que el usuario puede ingresar.
* Maneja checkboxes condicionales e indicadores visuales de requerimientos.

### 6.3 PhysicalCountScreen
Pantalla que implementa el formulario principal para generar un conteo físico. 
* Ofrece selectores con soporte de opción masiva "Todas/Todos".
* Implementa lista interactiva y búsqueda por cédula/nombre para la asignación múltiple de contadores.
* Despliega de forma limpia errores HTTP y modales de éxito informados por su Provider en tiempo real.

## 7. Flujo Funcional Integrado (Traspasos y Requisiciones)
El sistema opera bajo una premisa de desacoplamiento de interfaz y negocio. La UI solo despacha intenciones al Provider, quien delega al Repositorio. El inventario real o los estados de requisición solo se alteran tras la respuesta exitosa del servidor.

## 8. Principios de Diseño Consolidados
* Inmutabilidad en Modelos.
* Separación de responsabilidades (Clean Architecture).
* Optimización de red mediante Batch Processing (envío masivo).
* UI Reactiva mediante Provider.

---

## 9. Control de Cambios e Histórico (v1.7 a v1.8)

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

## 10. Control de Cambios e Histórico (v1.8 a v1.9)
1. Integración del Módulo de Conteo Físico: Se crearon los modelos `PhysicalCountRequest` y `CompanyModel` para envío de datos estructurados hacia el backend, logrando optimizar el ancho de banda enviando únicamente el `nationalId` en forma de arreglo numérico.
2. Gestión Reactiva de Estados con `PhysicalCountProvider`: Orquestación robusta de operaciones del UI y el servicio, integrando transiciones `INITIAL` -> `EN_PROCESO` -> `CREADA` / `ERROR`.
3. Pantalla de Conteo Físico Avanzada (`PhysicalCountScreen`): Formulario dinámico con capacidades de búsqueda en tiempo real (por nombre y cédula para contadores), así como soporte para asignaciones holísticas (valores `"All"`).
4. Manejo Expandido de Códigos HTTP Estrictos: Ampliación de las simulaciones y captación de arquitecturas de red con respuestas intencionales HTTP 400 (Bad Request), 409 (Conflict/Bodegas bloqueadas) y 500 (Internal Error).
