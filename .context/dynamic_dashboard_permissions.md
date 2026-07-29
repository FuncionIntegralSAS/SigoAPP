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
      "forma": "string", // <-- CÓDIGO DEL PERMISO (Ej: "avac", "aacf")
      "tipoRol": "string",
      "tipoForma": "string",
      "producto": "string"
    }
  ]
}
```

## Mapeo de Permisos (Enum `AppPermission`)
En lugar de manejar cadenas de texto sueltas, SigoAPP utiliza el enum `AppPermission` para asegurar los tipos.
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

## Estrategia de Persistencia
- Los permisos (`Permiso`) se recuperan en el payload de login y se guardan en el `FlutterSecureStorage` en la clave `'auth_permissions'` codificados como un `String` JSON.
- Al iniciar la app o restaurar la sesión, el `AuthProvider` deserializa este JSON y carga la lista en memoria.
- Para verificar el acceso a cualquier función, la vista (UI) consume el método `context.read<AuthProvider>().hasPermission(AppPermission.x)`.

## Configuración del `DashboardScreen`
Se mantiene un `GridView` plano. Cada acceso principal comprueba si el usuario tiene permiso (o al menos un permiso dentro de una categoría en caso de pantallas agrupadas) antes de renderizar el `_DashboardItem`.
- **Módulo Principal:** Es independiente del backend. Solo se muestra a desarrolladores cuando `!kReleaseMode`.

## Configuración de Sub-Módulos (`PhysicalCountScreen`)
La pantalla `PhysicalCountScreen` inicializa sus `Tab` y vistas dinámicamente filtrando aquellas a las que el usuario no tiene permiso. Esto garantiza que la navegación de la interfaz de usuario se adapte exactamente a los permisos otorgados por el backend.
