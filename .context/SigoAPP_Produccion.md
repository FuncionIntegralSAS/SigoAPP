# Preparación para Producción — SigoAPP
Versión: 1.0  
Fecha: Julio 2026

Este documento centraliza todas las decisiones, cambios implementados y pendientes relacionados con el despliegue de SigoAPP en Google Play Store y otros entornos de producción.

---

## 1. Estado Actual de Preparación

| Área | Estado | Notas |
|------|--------|-------|
| Variables de entorno | ✅ Implementado | `flutter_dotenv` + `.env` / `.env.production` |
| Target SDK | ✅ OK | Delegado al Flutter SDK (resuelve API 35+) |
| Permiso INTERNET (release) | ✅ Implementado | Agregado a `AndroidManifest.xml` principal |
| Application ID | ✅ Implementado | `com.funcionintegralsas.sigoapp` |
| Nombre de la app | ✅ Implementado | `"SIGAPP"` en todas las plataformas |
| Logger centralizado | ✅ Implementado | `AppLogger` con `kDebugMode` |
| Credenciales mock en UI | ✅ Implementado | Eliminadas de la pantalla de login |
| Logs de tokens en producción | ✅ Implementado | Protegidos con `kDebugMode` |
| Signing config de release | ⏳ Pendiente | Requiere generar keystore `.jks` |
| Ícono adaptativo | ✅ Implementado | Generado con `flutter_launcher_icons` usando `LOGO_SIN_FONDO.png` |
| URL de producción | ⏳ Pendiente | Backend de producción no disponible aún |
| Login de operadores real | ✅ Implementado | `HttpAuthRepository.login()` conecta a `POST /login` |

---

## 2. Variables de Entorno

### Estrategia
La app usa `flutter_dotenv` para gestionar la URL base del API. Existen dos archivos de entorno:

| Archivo | Propósito | ¿En `.gitignore`? |
|---------|-----------|:-----------------:|
| `.env` | Entorno de desarrollo local | ✅ Sí |
| `.env.production` | Plantilla para producción | ✅ Sí |
| `.env.example` | Plantilla pública para nuevos devs | ❌ No (se sube a Git) |

Ambos archivos están declarados como `assets` en `pubspec.yaml`.

### `AppConfig` — Configuración centralizada
**Archivo**: [`lib/utils/app_config.dart`](../lib/utils/app_config.dart)

Clase estática que:
- Valida que `API_URL` esté definida. Si está ausente, lanza una `Exception` con mensaje claro (no usa fallback silencioso).
- Provee el método `AppConfig.createDio()` que retorna una instancia de `Dio` con:
  - `baseUrl` obtenida de `dotenv`
  - `connectTimeout`, `receiveTimeout` y `sendTimeout` de 15 segundos
  - `JsonInterceptor` precargado
- Es la **única fuente de creación de instancias de `Dio`** en el proyecto.

```dart
// Uso correcto en main.dart:
final backendDio = AppConfig.createDio();
final physicalCountRepository = HttpPhysicalCountRepository(backendDio);
final authRepository = HttpAuthRepository(backendDio);
```

> ⚠️ **Regla de oro**: Ningún repositorio debe crear su propia instancia de `Dio`. Todos reciben la instancia centralizada por inyección de dependencias desde `main.dart`.

### Cuando el backend de producción esté disponible
1. Actualizar `.env.production` con la URL real:
   ```
   API_URL=https://api.tudominio.com
   ```
2. Si se usan múltiples entornos (staging, producción), se puede cargar el archivo condicionalmente en `main()`:
   ```dart
   await dotenv.load(fileName: kReleaseMode ? '.env.production' : '.env');
   ```

---

## 3. Configuración Android

### 3.1 Application ID y Namespace
**Archivo**: [`android/app/build.gradle.kts`](../android/app/build.gradle.kts)

```kotlin
namespace = "com.funcionintegralsas.sigoapp"
applicationId = "com.funcionintegralsas.sigoapp"
```

> ⚠️ **Crítico**: Google Play rechaza cualquier app con `com.example.*` en el `applicationId`. Este cambio ya fue aplicado.

### 3.2 Permiso INTERNET
**Archivo**: [`android/app/src/main/AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Agregado al manifest **principal** (no solo al de debug/profile). Sin este permiso, las llamadas HTTP no funcionan en builds de release.

### 3.3 Target/Compile SDK
Se delega al Flutter SDK mediante:
```kotlin
compileSdk = flutter.compileSdkVersion
targetSdk = flutter.targetSdkVersion
```
Con Flutter 3.9.2+, esto resuelve a API 35, cumpliendo los requisitos actuales de Google Play.

### 3.4 Firma de Release (Signing Config) — ⏳ PENDIENTE
**Archivo de referencia**: [`android/app/build.gradle.kts`](../android/app/build.gradle.kts)

La configuración actual usa firma de debug como fallback temporal:
```kotlin
signingConfig = signingConfigs.getByName("debug") // Temporal
```

#### Pasos para configurar la firma de producción:

**Paso 1 — Generar el keystore** (ejecutar una sola vez):
```bash
keytool -genkey -v -keystore sigoapp-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sigoapp
```

**Paso 2 — Mover el archivo** a `android/sigoapp-release.jks`

**Paso 3 — Crear `android/key.properties`**:
```properties
storePassword=TU_CONTRASEÑA_DEL_KEYSTORE
keyPassword=TU_CONTRASEÑA_DEL_ALIAS
keyAlias=sigoapp
storeFile=../sigoapp-release.jks
```

**Paso 4 — Actualizar `build.gradle.kts`** para leer `key.properties` condicionalmente:
```kotlin
// Al inicio del archivo, antes de android {}:
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

// Dentro de android {}:
signingConfigs {
    create("release") {
        if (keystorePropertiesFile.exists()) {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
}

buildTypes {
    release {
        signingConfig = if (keystorePropertiesFile.exists()) {
            signingConfigs.getByName("release")
        } else {
            signingConfigs.getByName("debug") // Fallback para desarrollo local
        }
    }
}
```

> ⚠️ **NUNCA** subir `sigoapp-release.jks` ni `key.properties` a Git.  
> Agregar a `.gitignore`:
> ```
> *.jks
> *.keystore
> android/key.properties
> ```

> ✅ **Convivencia debug/release**: Si `key.properties` no existe (máquinas de desarrollo), la app firma con debug automáticamente. Solo cuando el archivo existe (máquina de build/CI) se usa la firma de producción.

---

## 4. Seguridad

### 4.1 Logger Centralizado (`AppLogger`)
**Archivo**: [`lib/utils/app_logger.dart`](../lib/utils/app_logger.dart)

```dart
AppLogger.d('mensaje debug');  // Solo en debug
AppLogger.i('información');    // Solo en debug
AppLogger.w('advertencia');    // Solo en debug
AppLogger.e('error', error);   // Solo en debug
```

**Regla**: Ningún `print()` directo debe existir en el código de producción. La regla `avoid_print: true` en `analysis_options.yaml` hace que el linter marque cualquier `print()` como error.

### 4.2 Protección de Tokens
**Archivo**: [`lib/providers/auth_provider.dart`](../lib/providers/auth_provider.dart)

Los logs del token JWT y refresh token están envueltos con `if (kDebugMode)`, garantizando que nunca se impriman en builds de release.

### 4.3 Almacenamiento Seguro
Los tokens JWT se almacenan con `flutter_secure_storage` (cifrado AES en Android, Keychain en iOS). **No** se usa `shared_preferences` para datos sensibles.

### 4.4 Credenciales Mock
El formulario de login real no contiene credenciales prellenadas. El formulario Mock (solo visible en modo debug con `!kReleaseMode`) contiene credenciales hardcodeadas solo para desarrollo.

---

## 5. Nombre de la Aplicación ("SIGAPP")

El nombre de la app fue actualizado de `flutter_application_1` a `"SIGAPP"` en todos los archivos nativos:

| Plataforma | Archivo | Campo |
|------------|---------|-------|
| **Android** | `android/app/src/main/AndroidManifest.xml` | `android:label` |
| **iOS** | `ios/Runner/Info.plist` | `CFBundleDisplayName`, `CFBundleName` |
| **Windows** | `windows/runner/main.cpp` | `window.Create(L"SIGAPP", ...)` |
| **Windows** | `windows/runner/Runner.rc` | `FileDescription`, `InternalName`, `ProductName`, `OriginalFilename` |
| **Linux** | `linux/runner/my_application.cc` | `gtk_window_set_title(...)` |
| **macOS** | `macos/Runner/Configs/AppInfo.xcconfig` | `PRODUCT_NAME` |
| **Web** | `web/index.html` | `<title>` y `apple-mobile-web-app-title` |
| **Web** | `web/manifest.json` | `name`, `short_name` |
| **Flutter** | `lib/main.dart` | `MaterialApp(title: 'SIGAPP')` |

> ⚠️ Los cambios en archivos C++ de Windows (`main.cpp`, `Runner.rc`) requieren **recompilar** la app (no basta con hot-reload o hot-restart). Detén y reinicia `flutter run -d windows`.

---

## 6. UX Nativa

### 6.1 SafeArea
`AuthScreen` envuelve su `body` con `SafeArea` para proteger el contenido en dispositivos con notch, punch-hole o barras de navegación gestual.

### 6.2 Botón Atrás de Android (PopScope)
`DashboardScreen` implementa `PopScope(canPop: false)` con un diálogo de confirmación "¿Deseas salir de la aplicación?" al presionar el botón atrás de Android.

### 6.3 Ícono Adaptativo y de Aplicación

Se integró el logo oficial (`assets/images/LOGO_SIN_FONDO.png`) utilizando la librería `flutter_launcher_icons` (v0.14.3).

#### Configuración Aplicada (`pubspec.yaml`)

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.3

flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/LOGO_SIN_FONDO.png" 
  windows:
    generate: true
    image_path: "assets/images/LOGO_SIN_FONDO.png"
  min_sdk_android: 21
```

#### Comandos ejecutados para generación:
```bash
flutter pub get
dart run flutter_launcher_icons
```

Esto generó automáticamente los íconos para Android (`mipmap-*/launcher_icon.png`), iOS y Windows.

---

## 7. Calidad de Código

### 7.1 Linter
**Archivo**: [`analysis_options.yaml`](../analysis_options.yaml)

Regla habilitada:
```yaml
rules:
  avoid_print: true  # Fuerza el uso de AppLogger en lugar de print()
```

Esto hace que cualquier `print()` olvidado sea marcado como error por el linter, previniendo fugas de información en producción.

### 7.2 Verificación Continua
Ejecutar antes de cada release candidato:
```bash
# 1. Análisis estático (debe resultar 0 errores, 0 warnings)
flutter analyze

# 2. Build de release para verificar compilación exitosa
flutter build apk --release            # Android APK
flutter build appbundle --release      # Android AAB (para Google Play)
```

---

## 8. Servicios Mock vs. Producción

| Módulo | Estado actual | Archivo |
|--------|--------------|---------|
| **Conteo Físico** | ✅ HTTP real | `HttpPhysicalCountRepository` + `physical_count_service.dart` |
| **Autenticación (Operadores)** | ✅ HTTP real | `HttpAuthRepository.login()` → `POST /login` |
| **Autenticación (Contadores)** | ✅ HTTP real | `HttpAuthRepository.loginContador()` → `POST /login/contador` |
| **Inventario** | 🔶 Mock | `MockInventoryService` |
| **Requisiciones** | 🔶 Mock | `MockRequisitionService` |
| **Traspasos** | 🔶 Mock + HTTP | `MockTransferRepository` / `HttpTransferRepository` |

> 📌 **Regla**: Ningún flujo de usuario en producción debe pasar por un servicio Mock. El `DashboardScreen` oculta el "Módulo Principal" (que usa mocks) en builds de release con `if (!kReleaseMode)`.

---

## 9. Checklist de Release

Completar antes de subir a Google Play:

- [ ] `API_URL` en `.env.production` actualizada con el endpoint real
- [ ] Keystore `.jks` generado y configurado en `key.properties`
- [ ] `build.gradle.kts` actualizado con `signingConfigs.release`
- [x] Ícono adaptativo y ejecutable generado con `flutter_launcher_icons` (`LOGO_SIN_FONDO.png`)
- [ ] `flutter analyze` sin errores ni warnings
- [ ] `flutter build appbundle --release` exitoso
- [ ] Probado en dispositivo físico Android (no solo emulador)
- [ ] Probado sin conexión a internet (mensajes de error amigables)
- [ ] Probado el botón atrás en todas las pantallas del árbol de navegación
