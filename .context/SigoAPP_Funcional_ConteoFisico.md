# Documento Funcional: Módulo de Conteo Físico de Inventario

## 1. Propósito del Módulo
El Módulo de Conteo Físico permite a las empresas gestionar la auditoría periódica de sus activos y artículos. Facilita la planeación, selección del equipo auditor y el bloqueo lógico de la bodega para garantizar la integridad de las existencias mientras se ejecuta una revisión física real versus el sistema.

---

## 2. Historias de Usuario Principales

### 2.0 Fase Previa: Autenticación Administrativa y Entorno de Pruebas
**Rol:** Administrador o Jefe de Inventario.
**Descripción:** Como líder de inventarios, quiero poder iniciar sesión de manera segura con mis credenciales administrativas conectadas directamente a

**Criterios de Aceptación Desarrollados (App Frontend):**
- Pantalla inicial dual que presenta simultáneamente el acceso al "Servidor Real" y al "Entorno de Pruebas (Mock)".
- Diseño responsivo que adapta ambos formularios uno al lado del otro en pantallas anchas (escritorio/tableta), y apilados verticalmente en dispositivos móviles.
- Inyección de estados de sesión de forma global y unificada (`AuthProvider`), prescindiendo de servicios de simulación heredados (`MockAuthService`).
- Acceso secundario integrado en la misma pantalla para redirigir a los contadores de inventario a su ventana específica de conteo físico.

### 2.1 Fase 1: Apertura y Asignación de Conteo (Desarrollo Avanzado UI)
**Rol:** Administrador o Jefe de Inventario.
**Descripción:** Como líder de inventarios, quiero programar la apertura de un conteo físico para una bodega designada, indicando qué artículos se contarán y escogiendo las personas que apoyarán el conteo físico, para luego ordenar al sistema el bloqueo temporal de la bodega o artículos.

**Criterios de Aceptación Desarrollados (App Frontend):**
- **Flujo invertido de pestañas**: La pestaña de Selección de Personal es la primera (Tab 1), y la pestaña de Apertura (Empresa, Bodega, Fecha, Artículos) es la segunda (Tab 2), reflejando el orden natural del proceso.
- Selección dependiente en cascada de la Empresa hacia la Bodega y finalmente los Artículos.
- Soporte para incluir subconjuntos holísticos masivos (Opción: "Todos/Todas" enviando constante `"All"`).
- Selección de la Fecha esperada de la labor.
- Bandera de control para priorizar verificación estricta de existencias de sistema o contar desde 0.
- Búsqueda Avanzada de personal por coincidencias de Nombre, Apellido y/o Cédula a nivel servidor.
- Selección múltiple de estos responsables desde una lista interactiva de fácil borrado.
- **Acción unificada**: Un único botón "Generar Apertura y Asignar Personal" en la pestaña de Apertura ejecuta ambas operaciones HTTP en secuencia (POST creación → POST asignación). Si la creación falla, la asignación no se ejecuta.
- Informes claros al usuario en pantalla de errores 409 (Conflicto / Bodega Bloqueada) que garantizan que no haya cruce de conteos, y alertas de éxito de Creación.

### 2.2 Fase 2: Autenticación de Asignados y Descarga Offline (Implementado Localmente)
*(Los contadores asignados reciben un código temporal por correo. Inician sesión mediante un login alterno desde el `AccountScreen`. Se comunican con la API para descargar las asignaciones, basándose en la respuesta real de la base de datos (mapeando correctamente el campo `descripcion` proporcionado por el backend).*

**Regla de Acceso al Conteo (Doble Vía):**
La opción **"Ejecutar Conteo"** en la aplicación es accesible a través de dos perfiles diferenciados, pero bajo una condición común: **tener una descarga activa de artículos en la base de datos local (SQLite).**

| Perfil | Autenticación | Condición de Acceso |
|---|---|---|
| **Contador Externo** | Login alterno (cédula + código temporal) en `AccountScreen`. Puede NO ser usuario del sistema ERP. | Debe haber descargado previamente la lista de asignaciones mediante "Descargar Asignaciones". |
| **Usuario del Sistema (con permiso `arcf`)** | Login normal en `AuthScreen`. Es un usuario del ERP con permiso `realizarConteo`. | Debe haber descargado previamente la lista de asignaciones. |

**Estado Vacío:** Si cualquiera de los dos perfiles accede al módulo **sin** haber descargado el listado activo, la pantalla de ejecución del conteo muestra el mensaje:

> *"No tienes ningún formulario de conteo descargado y activo."*

La acción "Continuar Conteo" o equivalente debe permanecer deshabilitada hasta que exista una descarga local válida.

### 2.3 Fase 3: Escaneo y Conteo de Activos (Implementado Parcialmente)
Se introducen reglas estrictas respecto a cómo el empleado afronta el conteo:
- **Conteo Ciego:** A nivel UI está prohibido el renderizado o transmisión de cantidades esperadas hacia el usuario auditor. El conteo es ciego para no sesgar sus auditorías físicas.
- **Modalidad Grilla y Solo Enteros:** Para los *"Conteos por lista"*, la información se dispuso bajo una cuadricula (`DataTable`). Cuando la celda represente una adición o imputación de datos (la fila interactiva), se le debe presentar al contador el concepto visual de **'Cantidad Física'** requiriendo y bloqueando el teclado netamente a números `(Enteros)`. En adición siempre que se presenta al empleado el nombre de los ítems en su grilla, lo precede de código concatenado visualmente (`ID - Nombre/Descripción`).
- **Enmascaramiento de Artículos Contados en Vista de Lista:** En la pestaña *"Conteos por Lista"* (`ListCountView`), una vez registrado un artículo en la iteración actual (`provider.currentIterationRecords.containsKey(articleId)`), la celda de descripción se enmascara visualmente reemplazándose por un ícono verde de verificación (`Icons.check_circle`) y la etiqueta `"Registrado"`, evitando exponer descripciones de manera reiterada en auditorías físicas.

### 2.4 Fase 4: Conciliación y Cierre (Flujo 3 Conteos)
- Se manejan ciclos lógicos de conteo mediante comparativas iterativas. Una vez se comprueben diferencias hasta culminar el tercer conteo de activos, se debe emitir un bloqueo terminante y **realizar el cierre o finalización lógica del formulario completo del conteo**.

### 2.5 Fase 5: Cierre Administrativo del Conteo (Implementado)
**Rol:** Administrador o Jefe de Inventario.
**Descripción:** Como líder de inventarios, quiero poder cerrar formalmente un conteo físico activo para una bodega, liberando su bloqueo lógico y notificando al sistema que el proceso ha concluido.

**Criterios de Aceptación Desarrollados (App Frontend):**
- Pestaña independiente "Cierre" en `PhysicalCountScreen` (Tab 3), completamente desacoplada del estado de Apertura/Asignación.
- Campo de texto para ingresar el código de la bodega a cerrar (campo provisional; se reemplazará por selector de lista de valores en iteración futura).
- **Diálogo de confirmación** antes de ejecutar la acción: muestra el código de bodega interpolado y requiere confirmación explícita del usuario mediante botones horizontales (`StadiumBorder`) con jerarquía visual clara (Cancelar: contorno deepPurple / Confirmar: rojo sólido).
- Manejo diferenciado de errores 400 (solicitud incorrecta) y 403 (no autorizado).
- **Diálogo de resultado** que muestra el `message` retornado por el backend (`ConteoFisicoResponse`) con título en mayúsculas. Al aceptar, limpia el formulario y resetea el estado de cierre.
- Endpoint consumido: `POST /api/v1/conteo-fisico/cerrar` con header `Authorization` y body `{ "bodega": "..." }`.

---

## ❓ Preguntas de Negocio (Para Stakeholders o Product Owner)
A nivel de desarrollo de producto, para evitar re-procesos o que la solución final no coincida con el proceso físico real, requerimos aclaraciones funcionales:

1. **Flujo de Asignados:** Una vez realizado y aceptado el paso de "Apertura", de qué forma sabrán las "Personas Asignadas/Participantes" qué deben buscar? ¿Verán una bandeja de entrada nueva en su SigoAPP cuando inicien sesión, con una opción de "Realizar Conteo"?
2. **Uso de Scanners:** A la hora de realizar el conteo en sí como Fase 2, ¿El personal lo hará a mano apuntando cifras de manera abierta, o vamos a usar la cámara del dispositivo móvil para escanear los QR de los artículos uno a uno como en el módulo de Traspasos?
3. **Rol de Aprobador:** ¿Las diferencias/sobrantes/faltantes que arroje el sistema al finalizar el conteo se enviarán directo a base de datos, o requerimos una "Aprobación de Ajuste de Sistema" realizada por el jefe antes de aplicarlas?
4. **Desbloqueo de Bodega:** ¿El desbloqueo lógico es automático apenas se cierra el conteo desde la base de datos o desde Oracle lo manejan a través de otro proceso administrativo existente?
