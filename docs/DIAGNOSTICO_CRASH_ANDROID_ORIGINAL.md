# Diagnóstico Técnico: Causa del Cierre Instantáneo en Android (SigoAPP y SigoAPP_Mock)

**Fecha:** 7 de Octubre de 2026  
**Autor:** Antigravity AI  
**Estado:** Diagnóstico Confirmado, Solucionado y Verificado  
**Afecta a:** `SigoAPP` (Proyecto Original) y `SigoAPP_Mock` (Previamente corregido)

---

## 1. Resumen Ejecutivo

Al instalar el APK en un dispositivo físico Android, la aplicación se cerraba de forma instantánea al abrirse (en 0 ms) mostrando el aviso del sistema: *"La aplicación se cerró de forma continua"* o *"SIGAPP continúa fallando"*, sin llegar a mostrar la pantalla de inicio ni la barra superior (AppBar).

**Causa Raíz:** Se comprobó que en el proyecto original `SigoAPP`, existía una incompatibilidad nativa crítica: **desalineación entre el `namespace` de Gradle y la declaración de paquete y ruta de `MainActivity.kt`**.

---

## 2. Evidencia Técnica en `SigoAPP` (Proyecto Original)

### A. Configuración en `android/app/build.gradle.kts`
En el archivo de Gradle del proyecto original se configuró:
```kotlin
android {
    namespace = "com.funcionintegralsas.sigoapp"
    ...
    defaultConfig {
        applicationId = "com.funcionintegralsas.sigoapp"
    }
}
```

### B. Declaración en `android/app/src/main/AndroidManifest.xml`
El manifiesto define la actividad principal con notación relativa por punto:
```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop">
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
</activity>
```
Durante el empaquetado y la ejecución, el sistema operativo Android resuelve `.MainActivity` concatenándolo con el `namespace`:
> 🔍 **Actividad esperada por Android OS:** `com.funcionintegralsas.sigoapp.MainActivity`

### C. Archivo real de Kotlin en `SigoAPP` (Estado Previo)
Al inspeccionar el árbol de código nativo en `SigoAPP/android/app/src/main/kotlin/`:
```
android/app/src/main/kotlin/com/example/flutter_application_1/MainActivity.kt
```
Y el contenido del archivo era:
```kotlin
package com.example.flutter_application_1

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

---

## 3. Mecánica del Fallo en el Sistema Operativo Android

1. El usuario toca el ícono de `SIGAPP` en el lanzador del teléfono.
2. El servicio del sistema Android (`ActivityManager` / `PackageManager`) intenta instanciar el componente principal registrado:
   `ComponentInfo{com.funcionintegralsas.sigoapp/com.funcionintegralsas.sigoapp.MainActivity}`.
3. El cargador de clases nativo de la máquina virtual (ART / Dalvik) busca `com/funcionintegralsas/sigoapp/MainActivity.class` dentro de los archivos `classes.dex` del APK.
4. **Fallo:** La clase **no existía** en ese paquete (solo existía `com.example.flutter_application_1.MainActivity`).
5. Android abortaba inmediatamente con:
   ```
   FATAL EXCEPTION: main
   java.lang.RuntimeException: Unable to instantiate activity ComponentInfo{com.funcionintegralsas.sigoapp/com.funcionintegralsas.sigoapp.MainActivity}: java.lang.ClassNotFoundException: Didn't find class "com.funcionintegralsas.sigoapp.MainActivity" on path: DexPathList[...]
   ```
6. El proceso moría antes de que el motor de Flutter (C++) o la máquina virtual Dart pudieran inicializarse. Por ello:
   - No se registraban logs en Flutter.
   - No se mostraba la pantalla de carga ni el Splash.
   - El sistema Android mostraba el aviso genérico de cierre forzoso.

---

## 4. Procedimiento de Corrección Aplicado en `SigoAPP`

Para corregir este error en el proyecto original `SigoAPP`, se aplicaron las siguientes modificaciones:

### Paso 1: Crear la estructura de carpetas correspondiente al namespace
En `SigoAPP/android/app/src/main/kotlin/`:
Se creó el directorio:
`com/funcionintegralsas/sigoapp/`

### Paso 2: Crear / Mover `MainActivity.kt`
Se ubicó `MainActivity.kt` en:
`SigoAPP/android/app/src/main/kotlin/com/funcionintegralsas/sigoapp/MainActivity.kt`

Con el paquete debidamente alineado:
```kotlin
package com.funcionintegralsas.sigoapp

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

### Paso 3: Eliminar la carpeta obsoleta
Se eliminó por completo el directorio legado:
`SigoAPP/android/app/src/main/kotlin/com/example/`

### Paso 4: Limpiar y compilar
Ejecutar en la raíz de `SigoAPP`:
```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

## 5. Estado en `SigoAPP_Mock`
Este problema fue identificado y corregido previamente en `SigoAPP_Mock`:
- `MainActivity.kt` se ubicó en `android/app/src/main/kotlin/com/funcionintegralsas/sigoapp/demo/MainActivity.kt`.
- El paquete se alineó a `package com.funcionintegralsas.sigoapp.demo`.
- Se añadió defensa en profundidad en `lib/main.dart` con pantalla de error visible ante excepciones de arranque.
- El APK release funciona y abre de inmediato en dispositivos físicos.
