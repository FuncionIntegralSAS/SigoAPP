# Tech Mapping / Mapa Técnico - Módulo de Conteo Físico

Este documento es una guía destinada a desarrolladores Ssr/Sr. Sirve como un esquema de trazabilidad que conecta la experiencia de usuario (UI), la lógica de negocio temporal y el contrato que se espera firmar con la capa real de Spring Boot (API REST) y de Base de Datos (Oracle RDBMS).

---

## 1. Mapeo: Fase de Apertura de Conteo Físico

### Capa Frontend (Flutter - MVCS)
| Componente | Archivo Exacto en Directorio | Responsabilidad Técnica |
|---|---|---|
| **Contenedor UI** | `lib/screens/physical_count_screen.dart` | Renderiza los controles de entrada. Usa un modelo de layout de acordeón (ExpansionTile) e interactúa explícitamente usando estado inyectado por `Consumer<PhysicalCountProvider>`. Reacciona al enum local de Loading. |
| **State Management** | `lib/providers/physical_count_provider.dart` | Valida integridad y obligatoriedad. Centraliza la regla *fail-fast* (v1.9) evitando peticiones si no hay un requerimiento de búsqueda de personal. Parsea aserts de red de la API. |
| **Data Models (JSON)** | `lib/models/physical_count_model.dart`<br>`lib/models/company_model.dart` | Estructuran el cuerpo del Payload de red aplicando principios de "Economización de Petición". Solo se transforman a arreglos de ID numéricos (`nationalId`) aquellas asociaciones complejas como los asignados a contar. |
| **Endpoints Service** | `lib/services/physical_count_service.dart` | Capa `Dio`. Controladora simular excepciones y aplicar mapeos sobre endpoints de SpringBoot. |

### Capa Backend (Spring Boot / API REST Contract)
*Nota: Los siguientes métodos se asumen estandarizados en respuesta JSON 200 OK con camelCase de acuerdo a la documentación arquitectónica vigente, o en fase de construcción sobre el backend principal.*

| Método HTTP | Endpoint Relativo (Ruta) | Query Params o Body | Posibles Estados HTTP Propios del Flujo |
|---|---|---|---|
| **GET** | `/api/v1/personal/buscar` | `?nombre=X&apellido=Y&cedula=Z` (1 param. Mín) | `200 OK`, `400 Bad Request` (Falta un query de filtro). |
| **GET** | `/api/v1/empresas` | - | `200 OK` |
| **GET** | `/api/v1/bodegas/{companyId}` | Variable estática de ruta. | `200 OK` |
| **GET** | `/api/v1/articulos/{warehouseId}` | Variable estática de ruta. | `200 OK` |
| **POST** | `/api/v1/conteo-fisico` | Cuerpo JSON estricto (`PhysicalCountRequest`). | `201 Created`, `409 Conflict` (Bodega ocupada/bloquea con llave natural), `500 Internal` si el Procedure de SP Oracle falla. |

### Capa Persistencia de Datos (Oracle)
*Nota: Componentes nombrados como suposiciones lógicas para el equipo DBA de manera temporal (A falta de confirmación).*

| Tabla Máster / SP | Uso Práctico Supuesto |
|---|---|
| **Tabla principal `CONTARBO`** | Encabezado del bloqueo de inventario con llaves secundarias hacia el centro de acopio (Empresa / Bodega). |
| **Tabla detalle / Intersección** | Posible tabla para asignar N Empleados de Oracle a este Encabezado del conteo. |
| **Store Procedure: Lock** | Lógica compilada a nivel PL/SQL que imposibilite confirmación de requisiciones de las tablas subyacentes mientras este conteo se mantenga "Abierto" a nivel de base de datos. |

---
*Este documento es dinámico y sirve como base de diseño para la implementación de los servicios en Java/Spring Boot o actualización al recibir estructuras finales de Oracle.*
