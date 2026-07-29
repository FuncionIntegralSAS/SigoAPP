# Visualización Dinámica del Dashboard (Basado en Permisos)

## Contexto de Negocio
El endpoint `/login` del backend retorna una lista de permisos por cada aspecto o módulo al que el usuario tiene acceso. El objetivo es que la aplicación (SigoAPP) oculte o muestre las opciones del menú en el `DashboardScreen` y las pestañas de submódulos (como `PhysicalCountScreen`) basándose estrictamente en esta lista.

## Payload del Backend
El backend incluye una lista de objetos en la propiedad `permisos` de la respuesta:
```json
{
  "permisos": [
    {
      "usuario": "string",
      "forma": "string", // <-- CÓDIGO DEL PERMISO (Ej: "AVAC", "AACF")
      "tipoRol": "string",
      "tipoForma": "string",
      "producto": "string"
    }
  ]
}
```

## Mapeo de Permisos (Enum `AppPermission`)
En lugar de manejar cadenas de texto sueltas, SigoAPP utiliza el enum `AppPermission` (`lib/models/auth_model.dart`) para asegurar los tipos.
Cada valor del Enum se asocia con el código de "forma":

### 1. Inventario Control de Activos
- **avac**: Verificación de Activos (`AssetVerificationScreen`)
- **agqr**: Generación Código QR (Asociado internamente o futuro módulo)
- **agst**: Generar Solicitudes de Traspaso (`InventoryScreen`)
- **aatr**: Aprobación de Traspasos (`TransferApprovalScreen`)

### 2. Inventario de Existencias Almacén
- **aacf**: Apertura Conteo Físico (Pestaña "Apertura" en `PhysicalCountScreen`)
- **aacu**: Asignación Conteo por Usuario (Pestaña "Asignar Personal" en `PhysicalCountScreen`)
- **arcf**: Realizar Conteo Físico (`ActiveCountScreen`)
- **asin**: Sincronizar Conteo (Pestaña o botón interno)
- **accf**: Cerrar Conteo Físico (Pestaña "Cierre" en `PhysicalCountScreen`)

### 3. Aprobación de Trámites
- **areq**: Requisiciones (`RequisitionsScreen`)
- **aein**: Entrega Inventario (Asociado internamente o futuro módulo)

---

## Componentes Técnicos y Arquitectura de Permisos

### 1. Modelo de Datos (`Permiso` y `AuthResponse`)
- La clase `Permiso` en `lib/models/auth_model.dart` representa cada elemento del array `permisos` retornado por la API (`usuario`, `forma`, `tipoRol`, `tipoForma`, `producto`).
- `AuthResponse.fromJson` parsea la lista completa de objetos `Permiso` y la expone en el modelo de autenticación.

### 2. Desacoplamiento y Utilitarios (`PermissionUtils`)
Para mantener el `AuthProvider` limpio y enfocado exclusivamente en la gestión del estado de la sesión, la lógica de transformación y verificación de permisos se encuentra centralizada en `lib/utils/permission_utils.dart`:

- **`PermissionUtils.parsePermissions(String? jsonString)`**: Deserializa la cadena de texto de permisos leída de `FlutterSecureStorage` convirtiéndola nuevamente en una lista `List<Permiso>`.
- **`PermissionUtils.encodePermissions(List<Permiso> permissions)`**: Serializa la lista de permisos a formato JSON para ser almacenada de forma persistente en `FlutterSecureStorage`.
- **`PermissionListExtension` (`extension on List<Permiso>`)**: Extiende la funcionalidad de las listas de permisos para proveer métodos de consulta directos:
  - `hasPermission(AppPermission permission)`
  - `hasAnyPermission(List<AppPermission> permissions)`

### 3. Evaluación Insensible a Mayúsculas/Minúsculas (Case-Insensitive)
Dado que el backend puede enviar el atributo `forma` en mayúsculas (ej: `"AVAC"`, `"AEIN"`) mientras que los códigos del enum en la app están en minúsculas (`"avac"`), la verificación mediante `PermissionListExtension` normaliza ambas cadenas utilizando `.toLowerCase()`:
```dart
bool hasPermission(AppPermission permission) {
  return any((p) => p.forma?.toLowerCase() == permission.code.toLowerCase());
}
```

---

## Persistencia y Consumo en UI

### Estrategia de Persistencia
- Al iniciar sesión en `AuthProvider`, la lista completa de objetos `Permiso` se serializa con `PermissionUtils.encodePermissions` y se guarda en `FlutterSecureStorage` bajo la clave `'auth_permissions'`.
- Al restaurar la sesión (`_checkSavedSession`), se recupera dicha clave y se reconstruye la lista en memoria usando `PermissionUtils.parsePermissions`.

### Configuración del `DashboardScreen`
Se mantiene un `GridView` plano. Cada acceso principal comprueba si el usuario tiene permiso consultando la lista a través de la extensión: `auth.permisos.hasPermission(AppPermission.x)` (o `hasAnyPermission` para módulos con submódulos agrupados) antes de renderizar el `_DashboardItem`.
- **Módulo Principal:** Es independiente del backend. Solo se muestra a desarrolladores cuando `!kReleaseMode`.

### Configuración de Sub-Módulos (`PhysicalCountScreen`)
La pantalla `PhysicalCountScreen` inicializa sus `Tab` y vistas dinámicamente filtrando aquellas a las que el usuario no tiene permiso mediante `auth.permisos.hasPermission()`. Si el usuario no tiene permisos para ninguna pestaña, se muestra una vista de estado con aviso de falta de permisos.
