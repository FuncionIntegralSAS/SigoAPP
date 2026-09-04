# Matriz Rápida de Permisos y Módulos de SigoAPP

Esta referencia rápida permite al agente o desarrollador identificar en segundos los permisos de usuario, la pantalla destino y los providers involucrados en cada operación.

| Permiso | Nombre de Operación | Módulo de Negocio | Pantalla Principal | Provider(s) Clave |
|:---:|---|---|---|---|
| `avac` | Verificación de Activos | Inventario | `AssetVerificationScreen` | `AssetVerificationProvider`, `GeolocationProvider` |
| `agst` | Generar Solicitud de Traspaso | Inventario | `InventoryScreen` | `InventoryProvider`, `TransferFormProvider` |
| `agqr` | Generador de Códigos QR | Inventario / General | `GeneratorScreen` | N/A (StatefulWidget) |
| `aatr` | Aprobación / Rechazo de Traspasos | Inventario | `TransferApprovalScreen` | `TransferApprovalProvider` |
| `aein` | Entrega y Recepción de Inventario | Inventario / Requisiciones | `TransferDeliveryScreen`, `RequisitionsScreen` | `TransferDeliveryProvider`, `InventoryProvider`, `RequisitionsProvider` |
| `areq` | Gestión de Requisiciones | Requisiciones | `RequisitionsScreen` | `RequisitionsProvider` |
| `aacf` | Apertura de Conteo Físico | Conteo Físico | `PhysicalCountScreen` | `PhysicalCountProvider` |
| `aacu` | Asignación de Personal en Conteo | Conteo Físico | `PhysicalCountScreen` | `PhysicalCountProvider` |
| `accf` | Cierre de Conteo Físico | Conteo Físico | `PhysicalCountScreen` | `PhysicalCountProvider` |
| `arcf` | Ejecución / Reconteo (Modo Offline) | Conteo Físico | `ActiveCountScreen` | `ActiveCountProvider` |
| `asin` | Sincronización de Datos de Conteo | Conteo Físico | `PhysicalCountScreen` | `PhysicalCountProvider` |
| *Público* | Configuración de Dominio y Login | Autenticación | `DomainScannerScreen`, `AuthScreen` | `AuthProvider` |
| *Debug* | Escáner y utilidades de depuración | Solo en `!kReleaseMode` | `HomeScreen` | N/A |

### Métodos de Comprobación en Código
- **Extensión de Permisos:** `permisos.hasPermission('avac')` en `lib/utils/permission_utils.dart`
- **Modelo de Permisos:** `AppPermission` en `lib/models/auth_model.dart`
- **Evaluación en UI:** `Provider.of<AuthProvider>(context, listen: false).permisos`
