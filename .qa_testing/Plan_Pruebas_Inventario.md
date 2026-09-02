# Plan de Pruebas y Verificación: Módulo de Inventario

**Dirigido a:** Usuarios Intermedios (Key Users) y Analistas QA.
**Módulo:** Inventario y Verificación de Activos
**Versión de Prueba:** 1.0

Este documento contiene los casos de prueba manuales diseñados para certificar que el módulo de inventario interactúa correctamente con el backend, especialmente tras la reciente integración de geolocalización.

---

## 1. Verificación de Activos (Escáner QR)
**Objetivo:** Validar que la lectura del QR reconozca correctamente la información del activo y valide contra el responsable esperado.

* **Paso 1:** En el Dashboard, seleccionar "Verificación de Activos".
* **Paso 2:** Seleccionar un responsable de la lista (ej: "Juan Pérez").
* **Paso 3:** Pulsar "Escanear Activo". Escanear un QR físico o generado.
* **Resultado Esperado:** 
  * Si el código corresponde a "Juan Pérez", se muestra un mensaje de éxito verde.
  * Si corresponde a otra persona, aparece un mensaje de advertencia naranja con el botón de sugerencia "Se sugiere realizar un traspaso".
  * Si la distancia al punto guardado en backend supera 1 metro, se muestra un diálogo preguntando si se desea actualizar la ubicación.

## 2. Actualización Manual y Geolocalización (Listado de Inventario)
**Objetivo:** Asegurar que la captura de ubicación y los cambios en estado funcionen localmente y notifiquen al servidor.

* **Paso 1:** Ir a "Generar solicitud de traspaso" (Inventario General).
* **Paso 2:** Filtrar por bodega o ver todos los artículos.
* **Paso 3:** Pulsar sobre un activo para abrir el formulario modal de "Actualizar Estado".
* **Paso 4:** Pulsar en el ícono de GPS (Geolocalización).
* **Resultado Esperado 1:** Si el artículo ya tenía ubicación, la app debe preguntar: *"El activo ya cuenta con una ubicación registrada. ¿Desea reemplazarla...?"*.
* **Paso 5:** Pulsar "Sí", capturar ubicación y luego pulsar "ACTUALIZAR DATOS".
* **Resultado Esperado 2:** El activo se actualiza y la app invoca el backend para guardar la nueva ubicación.
* **Manejo de Errores (Prueba de estrés):** Si se apaga el servidor local de backend y se pulsa "ACTUALIZAR DATOS", la app debe advertir "No se pudo guardar la ubicación en el servidor" pero debe continuar y cerrar la ventana mostrando que el dato local sí se modificó.

## 3. Generación de Código QR y PDF
**Objetivo:** Validar que al generar un QR, su ubicación quede asociada al activo y enviada al backend.

* **Paso 1:** Ir al Módulo Principal y seleccionar "Generar QR".
* **Paso 2:** Seleccionar una bodega y un activo.
* **Paso 3:** Pulsar "Generar QR".
* **Resultado Esperado:**
  * Se obtiene la ubicación GPS del dispositivo.
  * La app notifica al backend sobre la nueva ubicación.
  * Se genera exitosamente el archivo PDF.
  * En caso de no tener el backend en línea, debe aparecer un recuadro de aviso, pero **el PDF debe generarse independientemente del fallo de red**.

## 4. Creación de Solicitud de Traspaso
**Objetivo:** Asegurar que la búsqueda de empleados (backend real) funciona al traspasar activos.

* **Paso 1:** En Inventario General, pulsar el botón naranja de traspaso de algún activo.
* **Paso 2:** En la sección "Asignación Propuesta", teclear un número de cédula válido.
* **Resultado Esperado:** El sistema debe buscar contra la BD real (`/api/v1/personal/buscar`) y mostrar el nombre completo y división del empleado. De lo contrario, indicar "Empleado no encontrado".
