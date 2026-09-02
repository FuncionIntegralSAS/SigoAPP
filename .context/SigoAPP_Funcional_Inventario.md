# Documentación Funcional: Módulo de Inventario y Activos

**Ubicación de Referencia (UI):** Dashboard Principal -> Botones "Generar Solicitud de Traspaso", "Verificación de Activos", "Generar QR".

## 1. Propósito General del Módulo
El módulo de inventario tiene como objetivo principal gestionar la visibilidad, ubicación y estado físico de los activos fijos de la compañía. Se subdivide en tres flujos clave que interactúan entre sí:
1. **Inventario General y Traspasos:** Lista los activos por bodega, permite la actualización de su estado y ubicación, y facilita la creación de solicitudes de traspaso de activos entre empleados.
2. **Generador QR:** Permite la creación e impresión de códigos QR únicos que actúan como "placa de inventario" de un activo. Cada vez que se genera un QR, se registra obligatoriamente su última posición GPS.
3. **Verificación de Activos:** Utiliza el escáner del dispositivo para leer el QR de un activo, comprobar en tiempo real quién es el empleado responsable actual en sistema y emitir alarmas si existe una discrepancia o si el activo ha sido desplazado de su ubicación original registrada.

## 2. Flujo de Geolocalización (Importante)
El aplicativo guarda la geolocalización de un activo bajo las siguientes acciones:
- **Al Generar QR:** Se exige la ubicación obligatoria.
- **Al Editar un Activo manualmente:** Desde la lista de inventario, si el usuario pulsa el botón del GPS.
- **Al Aprobar / Recibir un Traspaso (Próximamente):** Idealmente cada vez que un artículo cambie de manos.

> **Nota Técnica:** La geolocalización funciona bajo el patrón "Tolerancia a fallos". Si el backend está caído, se mostrará un aviso al usuario informándole que no se pudo sincronizar, pero **no** se bloqueará el proceso en curso (por ejemplo, el QR se imprimirá de todas formas).

## 3. Flujo de Generación de Traspasos (Workflow)
1. **Petición Inicial:** Un usuario inicia el traspaso de un activo. El sistema consulta en base de datos al nuevo responsable (empleado).
2. **Registro de Novedad:** Se crea la solicitud (`NovedadTraspasoModel`) en estado "Pendiente".
3. **Aprobaciones (Mock actual):** Se planea un flujo donde el receptor deba "Aceptar" el activo mediante firma electrónica o un PIN. Actualmente, en la simulación, la aprobación se lista en "Mis Aprobaciones" del módulo de pruebas.

## 4. Verificación de Discrepancias (Auditoría)
Durante la lectura del código QR:
* **Discrepancia de Usuario:** Si el escaneo revela que el activo lo posee alguien distinto a su titular oficial. El sistema arroja alerta visual naranja.
* **Discrepancia Geográfica:** La aplicación calcula mediante `Geolocator.distanceBetween` la distancia entre la ubicación actual de lectura y la última ubicación persistida en backend. Si supera 1 metro, advierte del desplazamiento no reportado.
