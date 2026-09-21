# Documentación Funcional: Módulo de Inventario y Activos

**Ubicación de Referencia (UI):** Dashboard Principal -> Botones "Generar Solicitud de Traspaso", "Verificación de Activos", "Generar QR".

## 1. Propósito General del Módulo
El módulo de inventario tiene como objetivo principal gestionar la visibilidad, ubicación y estado físico de los activos fijos de la compañía. Se subdivide en tres flujos clave que interactúan entre sí:
1. **Inventario General y Traspasos:** Lista los activos por empresa y bodega, incorpora filtrado especializado por **Colaborador / Responsable**, permite la actualización de su estado y ubicación, y facilita la creación de solicitudes de traspaso de activos entre empleados de forma directa o desde un activo específico.
2. **Generador QR:** Permite la creación e impresión de códigos QR únicos que actúan como "placa de inventario" de un activo. Cada vez que se genera un QR, se registra obligatoriamente su última posición GPS.
3. **Verificación de Activos:** Utiliza el escáner del dispositivo para leer el QR de un activo, comprobar en tiempo real quién es el empleado responsable actual en sistema y emitir alarmas si existe una discrepancia o si el activo ha sido desplazado de su ubicación original registrada.

## 2. Flujo de Consulta y Filtrado en Cascada (`InventoryScreen`)
1. **Filtro por Empresa:** Selección obligatoria inicial que carga las bodegas autorizadas de la compañía.
2. **Filtro por Bodega (Bodegas Personales `PE`):**
   - La carga de bodegas para inventario y traspasos consulta exclusivamente bodegas de tipo personal (`'PE'`) mediante `InventoryRepository.getWarehouses(companyId, tipo: 'PE')` (`GET /api/v1/bodegas/empresa/{empresa}/PE`). Esta regla garantiza la coherencia con el backend de traspasos (`PKG_FI_MOVITRAS`), el cual exige que las bodegas origen y destino correspondan a custodios individuales (`BODETIBO = 'PE'`).
   - Al seleccionar la bodega, se limpian las listas de artículos y se dispara únicamente la consulta de colaboradores asociados (`TransferRepository.getPersonsByWarehouse`). **No se ejecutan búsquedas de activos por bodega**.
3. **Filtro por Colaborador / Responsable:**
   - La consulta remota de activos se ejecuta **exclusivamente al seleccionar un colaborador específico** (`TransferRepository.getAssetsByPerson(persona, bodega, empresa)`), requiriendo que la empresa y la bodega hayan sido seleccionadas previamente.
   - Si no se ha seleccionado un colaborador (o si se deselecciona / selecciona *"Todos"*), la lista de activos permanece vacía y la interfaz despliega un mensaje orientativo solicitando la selección del colaborador.
   - **Sincronización y Refresco Automático al Ingresar (`initState`):** Al navegar hacia `InventoryScreen` (por ejemplo, desde el botón *"Generar solicitud de traspaso"* del Dashboard), si el usuario ya posee un colaborador seleccionado en sesión (`selectedCollaborator != null && selectedCollaborator.cedula != 'ALL'`), la pantalla dispara automáticamente `InventoryProvider.refreshArticles()` en tiempo real para obtener sus activos asignados frescos.
4. **Acceso a Traspasos (Diferenciación Individual vs Múltiple):**
   - **Traspaso Individual (Icono `⇄`):** Disponible en cada tarjeta de activo en modo normal (`InventoryArticleTile`). Abre `TransferFormWidget` en modo contextualizado compacto, pre-cargando la empresa, bodega origen, colaborador fuente y focalizado exclusivamente en ese activo seleccionado.
   - **Traspaso Múltiple (Floating Action Button con permiso `agst`):** Activa el modo de selección múltiple interactivo (`_isSelectionMode = true`):
     - Oculta los botones individuales `⇄` y despliega casillas de verificación (checkboxes) en cada tarjeta de activo, aplicando resaltado visual a los elementos seleccionados.
     - Valida la coherencia de origen (todos los activos seleccionados deben pertenecer al mismo colaborador responsable; restringe a máximo 50 activos por lote según contrato del backend).
     - Despliega una barra inferior contextual (`bottomNavigationBar`) con acciones de *"Cancelar"*, *"Marcar todos / Deseleccionar"* y *"Realizar traspaso (N)"*.
     - **Apertura en modo contextualizado:** El modal `TransferFormWidget` presenta los activos en una tarjeta compacta con componente desplegable interactivo para consultar placas y códigos. Si se cancela o cierra el modal sin completar el trámite, regresa a `InventoryScreen` conservando los artículos marcados y el modo de selección activo.
     - **Finalización y refresco automático:** Al completarse la creación exitosa del traspaso (`POST /api/v1/traspasos/crear`), el modal retorna confirmación, `InventoryScreen` sale del modo selección, desmarca los artículos y refresca automáticamente el inventario.

## 3. Flujo de Geolocalización y Actualización de Activos (`ArticleEditModal`)
El aplicativo gestiona la geolocalización y actualización física de un activo bajo las siguientes acciones:
- **Al Generar QR:** Se exige la ubicación obligatoria.
- **Al Editar un Activo manualmente:** Al tocar una tarjeta (`InventoryArticleTile`) en modo normal en la lista de inventario, se abre el modal desacoplado `ArticleEditModal`, permitiendo:
  - Modificar el estado operativo del activo (`Operativo`, `En Mantenimiento`, `Dañado`, `Baja`).
  - Registrar comentarios del estado y simular la captura de fotos.
  - Capturar coordenadas GPS actuales mediante `Geolocator`, con diálogo de confirmación si ya poseía coordenadas previas.
  - Sincronización remota mediante `GeolocationProvider.syncGeolocation` y actualización en memoria con `InventoryProvider.updateArticleLocally`.
- **Al Aprobar / Recibir un Traspaso (Próximamente):** Idealmente cada vez que un artículo cambie de manos.

> **Nota Técnica:** La geolocalización funciona bajo el patrón "Tolerancia a fallos". Si el backend está caído, se mostrará un aviso al usuario informándole que no se pudo sincronizar en el servidor, pero **no** se bloqueará el proceso en curso (por ejemplo, los cambios locales continúan y el QR se imprimirá de todas formas).

## 4. Flujo de Generación de Traspasos (Workflow)
1. **Petición Inicial:** Un usuario inicia el traspaso (vía Traspaso Individual `⇄` o Traspaso Múltiple con selección interactiva). `TransferFormWidget` orquesta el flujo dinámico multi-artículo en presentación completa o compacta preseleccionada.
2. **Registro de Novedad:** Se crea la solicitud (`TransferCreateRequest` / `TransferRequest`) en estado "Pendiente".
3. **Aprobación y Entrega:** Flujo completo documentado en [`SigoAPP_Funcional_Traspasos.md`](./SigoAPP_Funcional_Traspasos.md).

## 5. Verificación de Discrepancias (Auditoría)
Durante la lectura del código QR:
* **Discrepancia de Usuario:** Si el escaneo revela que el activo lo posee alguien distinto a su titular oficial. El sistema arroja alerta visual naranja.
* **Discrepancia Geográfica:** La aplicación calcula mediante `Geolocator.distanceBetween` la distancia entre la ubicación actual de lectura y la última ubicación persistida en backend. Si supera 1 metro, advierte del desplazamiento no reportado.

## 6. Gestión de Sesión y Manejo de Expiración (Seguridad)
- **Cierre de Sesión Seguro:** En la barra superior (`AppBar`), el botón de logout invoca la utilidad global `AuthUtils.logout(context)`, la cual limpia credenciales y token JWT en `AuthProvider`, y vacía completamente la pila de navegación mediante `Navigator.pushAndRemoveUntil` hacia la pantalla raíz (`AuthWrapper` / `AuthScreen`), desmontando la pantalla de inventario para evitar rutas huérfanas en el stack.
- **Detección de Sesión Expirada (HTTP 401 / 403):** Si una petición falla por credenciales expiradas o falta de permisos, el banner de error (`_buildErrorBanner`) detecta esta condición y provee un botón interactivo de reautenticación directa (`IconButton(Icons.logout)`) que ejecuta `AuthUtils.logout(context)`, permitiendo al usuario volver a iniciar sesión con un solo toque, además del botón de reintento (`Icons.refresh`).


