# Licenciamiento, Atribución de Créditos y Análisis de Costos
Proyecto: **SigoAPP** (SIGAPP)  
Fecha: **Agosto 2026**

> [!NOTE]
> El manifiesto legal completo se encuentra en el archivo raíz: [`OPEN_SOURCE_LICENSES.md`](../OPEN_SOURCE_LICENSES.md).

---

## 1. Conclusión de Costos y Tarifas

| Aspecto | Evaluación |
|---------|------------|
| **Costo total de librerías** | **$0.00 USD (100% Gratuitas)** |
| **Tarifas de consumo / APIs** | **$0.00 USD** (Sin servicios de pago en la nube) |
| **Tipo de Licenciamiento** | Permisivo: **MIT**, **BSD 2-Clause**, **BSD 3-Clause**, **Apache 2.0** |
| **Uso Comercial** | **Totalmente permitido** sin pago de regalías |
| **Protección del Código Propietario** | **100% Protegido** (Ninguna licencia es copyleft / GPL / AGPL, por lo que no se exige abrir el código fuente de la empresa) |

---

## 2. Matriz de Dependencias y Licencias

### 2.1 Dependencias de Ejecución (`dependencies`)

| Dependencia | Versión | Licencia | Autor / Titular | Detalle de Operación / Costo |
|-------------|---------|----------|-----------------|-------------------------------|
| `flutter` | SDK | BSD-3-Clause | Google LLC | Framework base gratuito |
| `provider` | ^6.0.5 | MIT | Remi Rousselet | Estado reactivo en memoria |
| `flutter_dotenv` | ^5.2.1 | MIT | James Bligh | Lectura de archivos `.env` locales |
| `mobile_scanner` | ^7.1.3 | MIT | Julian Steenbakker | Escaneo on-device (ML Kit local, sin costo de nube) |
| `qr_flutter` | ^4.1.0 | BSD-3-Clause | Luke Freeman | Renderizado vectorial de QR en cliente |
| `equatable` | ^2.0.5 | MIT | Felix Angelov | Comparación por valor de objetos |
| `pdf` | ^3.7.1 | Apache-2.0 | David PHAM-VAN | Motor de dibujo y maquetación PDF en memoria |
| `path_provider` | ^2.0.11 | BSD-3-Clause | Flutter Team | Directorios del sistema de archivos local |
| `open_filex` | ^4.3.0 | BSD-3-Clause | crazecoder | Lanzador nativo de visor de archivos del SO |
| `geolocator` | 14.0.1 | MIT | Baseflow | Acceso directo a antenas GPS de hardware (sin API de Google Maps) |
| `json_annotation` | ^4.11.0 | BSD-3-Clause | Google LLC | Metadatos de serialización |
| `dio` | ^5.9.2 | MIT | flutterchina / Alex Li | Cliente HTTP REST |
| `intl` | ^0.20.2 | BSD-3-Clause | Google LLC | Formateo de fechas y números |
| `sqflite` | ^2.4.2 | BSD-2-Clause | Alexandre Roux | Motor SQLite local embebido |
| `path` | ^1.9.1 | BSD-3-Clause | Google LLC | Manipulación de strings de rutas |
| `sqflite_common_ffi` | ^2.4.0+2 | BSD-2-Clause | Alexandre Roux | Driver FFI SQLite para Desktop (Windows) |
| `dropdown_button2` | ^3.1.0 | MIT | Ahmed Al-Khulaidi | UI de dropdowns con filtrado |
| `flutter_secure_storage` | ^10.3.1 | BSD-3-Clause | German Saprykin | Cifrado con Android Keystore / iOS Keychain |
| `flutter_pos_printer_platform_image_3` | ^1.2.4 | MIT | anfe007 | Socket Bluetooth directo a impresora física |
| `esc_pos_utils_plus` | ^2.0.4 | MIT | Andrey Ushakov / Flutter Community | Generador de bytes ESC/POS en cliente |
| `permission_handler` | ^13.0.1 | MIT | Baseflow | Diálogos de permisos del sistema operativo |

### 2.2 Dependencias de Desarrollo (`dev_dependencies`)

| Dependencia | Versión | Licencia | Autor / Titular |
|-------------|---------|----------|-----------------|
| `flutter_test` | SDK | BSD-3-Clause | Google LLC |
| `flutter_lints` | ^6.0.0 | BSD-3-Clause | Google LLC |
| `build_runner` | ^2.11.1 | BSD-3-Clause | Google LLC |
| `json_serializable` | ^6.13.0 | BSD-3-Clause | Google LLC |
| `flutter_launcher_icons` | ^0.14.3 | MIT | Mark O'Sullivan |

---

## 3. Cumplimiento de Atribución en la Aplicación

Para dar cumplimiento en runtime a las cláusulas de atribución de las licencias MIT y BSD, se puede invocar la ventana estándar provista por Flutter:

```dart
showLicensePage(
  context: context,
  applicationName: 'SIGAPP',
  applicationVersion: '1.0.0',
  applicationLegalese: '© 2026 Funcion Integral SAS',
);
```
