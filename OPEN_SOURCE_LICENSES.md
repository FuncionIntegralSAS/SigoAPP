# Manifiesto de Licencias de Código Abierto y Atribución de Créditos
Proyecto: **SigoAPP** (SIGAPP)  
Versión: **1.0.0**  
Fecha de auditoría: **Agosto 2026**

---

## 1. Resumen Ejecutivo de Licenciamiento y Tarifas

Tras realizar la auditoría exhaustiva de todas las dependencias, frameworks y librerías declaradas en el proyecto:

1. **Costo y Tarifas:** **0 $ (100% Gratuitas)**. Ninguna de las librerías o dependencias utilizadas tiene costo de licencia, tarifas por uso, cobros ocultos ni modelos de suscripción de pago.
2. **Tipo de Licencias:** Todas las dependencias operan bajo **Licencias Permisivas de Código Abierto** (*Permissive Open Source Licenses*):
   - **MIT License**
   - **BSD 2-Clause / BSD 3-Clause**
   - **Apache License 2.0**
3. **Compatibilidad Comercial:** Todas estas licencias permiten explícitamente el **uso comercial**, modificación, empaquetado y distribución de la aplicación (en Google Play, Windows, etc.) sin exigir pagos de regalías (*royalty-free*) y **sin obligar a liberar el código fuente privativo de la empresa** (a diferencia de licencias copyleft como GPL/AGPL).
4. **Hardware y Servicios Locales:**
   - `geolocator`: Opera directamente sobre los sensores de hardware GPS del dispositivo vía APIs nativas del SO (Android LocationManager / iOS CoreLocation). No consume servicios web de mapas pagados (Google Maps API, Mapbox).
   - `mobile_scanner`: Utiliza el motor On-Device de Google ML Kit Barcode Scanning que se procesa localmente en el procesador del dispositivo sin consumo de cuota ni APIs en la nube.
   - `flutter_pos_printer_platform_image_3` & `esc_pos_utils_plus`: Conexión de socket Bluetooth / USB directa con el hardware de la impresora térmica física; sin intermediarios ni cobros en la nube.
   - `flutter_secure_storage`: Cifrado por hardware local (Android KeyStore y iOS Keychain).

---

## 2. Tabla de Dependencias y Créditos

### 2.1 Dependencias Principales de Producción (`dependencies`)

| Paquete | Versión | Tipo de Licencia | Autor / Titular de Copyright | Propósito en SigoAPP |
|---------|---------|------------------|------------------------------|----------------------|
| **Flutter SDK** | ^3.9.2 | BSD 3-Clause | Google LLC & The Flutter Authors | Framework base de la aplicación |
| **provider** | ^6.0.5 | MIT License | Remi Rousselet | Gestión reactiva de estado (ChangeNotifier) |
| **flutter_dotenv** | ^5.2.1 | MIT License | James Bligh | Carga de variables de entorno (.env) |
| **mobile_scanner** | ^7.1.3 | MIT License | Julian Steenbakker | Escaneo de códigos QR y códigos de barras |
| **qr_flutter** | ^4.1.0 | BSD 3-Clause | Luke Freeman | Generación y renderizado de códigos QR |
| **equatable** | ^2.0.5 | MIT License | Felix Angelov | Comparación de objetos por valor |
| **pdf** | ^3.7.1 | Apache License 2.0 | David PHAM-VAN | Creación y formateo de documentos PDF |
| **path_provider** | ^2.0.11 | BSD 3-Clause | Flutter Team / Google LLC | Rutas de almacenamiento local del dispositivo |
| **open_filex** | ^4.3.0 | BSD 3-Clause | crazecoder | Visualización/apertura nativa de archivos PDF |
| **geolocator** | 14.0.1 | MIT License | Baseflow (Maurits van Beusekom & Florian Krauthan) | Captura de coordenadas GPS en piso |
| **json_annotation** | ^4.11.0 | BSD 3-Clause | Google LLC / The Dart Authors | Anotaciones para serialización JSON |
| **dio** | ^5.9.2 | MIT License | flutterchina.club / Alex Li | Cliente HTTP para consumo de APIs REST |
| **intl** | ^0.20.2 | BSD 3-Clause | Google LLC / The Dart Authors | Internacionalización y formateo de fechas |
| **sqflite** | ^2.4.2 | BSD 2-Clause | Alexandre Roux (tekartik) | Base de datos SQLite local para modo offline |
| **path** | ^1.9.1 | BSD 3-Clause | Google LLC / The Dart Authors | Manejo y unión de rutas del sistema de archivos |
| **sqflite_common_ffi**| ^2.4.0+2 | BSD 2-Clause | Alexandre Roux (tekartik) | Soporte FFI de SQLite para Windows / Desktop |
| **dropdown_button2** | ^3.1.0 | MIT License | Ahmed Al-Khulaidi | Menús desplegables con barra de búsqueda |
| **flutter_secure_storage**| ^10.3.1 | BSD 3-Clause | German Saprykin & Contributors | Almacenamiento seguro de tokens JWT |
| **flutter_pos_printer_platform_image_3** | ^1.2.4 | MIT License | anfe007 & Contributors | Comunicación Bluetooth con impresoras térmicas POS |
| **esc_pos_utils_plus** | ^2.0.4 | MIT License | Andrey Ushakov & Flutter Community | Formateo de comandos binarios ESC/POS para impresión |
| **permission_handler**| ^13.0.1 | MIT License | Baseflow | Gestión de permisos en tiempo de ejecución (Cámara, GPS, Bluetooth) |

---

### 2.2 Dependencias de Desarrollo y Compilación (`dev_dependencies`)

| Paquete | Versión | Tipo de Licencia | Autor / Titular de Copyright | Propósito |
|---------|---------|------------------|------------------------------|-----------|
| **flutter_test** | SDK | BSD 3-Clause | Google LLC & The Flutter Authors | Pruebas unitarias y de integración |
| **flutter_lints** | ^6.0.0 | BSD 3-Clause | Google LLC / The Dart Authors | Reglas de análisis estático y calidad de código |
| **build_runner** | ^2.11.1 | BSD 3-Clause | Google LLC / The Dart Authors | Generador de código en tiempo de compilación |
| **json_serializable**| ^6.13.0 | BSD 3-Clause | Google LLC / The Dart Authors | Generación automática de código `fromJson`/`toJson` |
| **flutter_launcher_icons**| ^0.14.3 | MIT License | Mark O'Sullivan & Flutter Community | Generación automática de íconos adaptativos multiplataforma |

---

## 3. Textos de Licencias de Terceros

### 3.1 The MIT License (MIT)
*Aplica a: `provider`, `flutter_dotenv`, `mobile_scanner`, `equatable`, `geolocator`, `dio`, `dropdown_button2`, `flutter_pos_printer_platform_image_3`, `esc_pos_utils_plus`, `permission_handler`, `flutter_launcher_icons`.*

```text
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

### 3.2 The 3-Clause BSD License (BSD-3-Clause)
*Aplica a: `Flutter SDK`, `qr_flutter`, `path_provider`, `open_filex`, `json_annotation`, `intl`, `path`, `flutter_secure_storage`, `flutter_lints`, `build_runner`, `json_serializable`.*

```text
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

---

### 3.3 The 2-Clause BSD License (BSD-2-Clause)
*Aplica a: `sqflite`, `sqflite_common_ffi`.*

```text
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

---

### 3.4 Apache License, Version 2.0
*Aplica a: `pdf`, `Material Icons Font`.*

```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## 4. Visualización Nativa de Licencias en la Aplicación

Flutter compila automáticamente un registro de todas las licencias de código abierto de los paquetes utilizados. Si deseas incluir una pantalla de créditos y licencias dentro de la UI de la aplicación (por ejemplo en un botón "Acerca de" o en `AccountScreen`), Flutter proporciona la función nativa:

```dart
showLicensePage(
  context: context,
  applicationName: 'SIGAPP',
  applicationVersion: '1.0.0',
  applicationLegalese: '© 2026 Funcion Integral SAS. Todos los derechos reservados.',
);
```

Esta función compila y muestra en pantalla de forma automática todas las licencias de las dependencias incluidas en el ejecutable, cumpliendo al 100% con los requerimientos de atribución exigidos por las licencias BSD y MIT.
