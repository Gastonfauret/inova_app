# Guía de Deployment - Reemplazo de APK MDM

## Resumen

Esta aplicación Flutter (`inova_app`) está diseñada para reemplazar el APK existente `emm-installer.apk` utilizado en el sistema de Android Enterprise Device Owner Provisioning del backend MDM Inova.

## Arquitectura del Sistema

### Sistema Actual
- **Backend MDM**: Laravel (ubicado en `/Users/gastonfauret/developer/Inova/inova`)
- **APK Actual**: `public/emm/emm-installer.apk` (aplicación Java nativa para Android Enterprise)
- **Generación QR**: `DevicesController.php` método `getQrEnrollment()` (líneas 375-401)

### Sistema Nuevo
- **App Flutter**: `inova_app` con soporte completo de QR scanning
- **APK Nuevo**: Se generará desde esta aplicación Flutter
- **Funcionalidades**: Enrollment, FCM, Lock/Unlock, QR Scanner

---

## Paso 1: Configuración Previa

### 1.1 Actualizar Application ID y Package Name

Actualmente el app usa `com.example.inova_app`. Debe cambiarse para producción:

#### Archivo: `android/app/build.gradle.kts`

```kotlin
android {
    namespace = "inova.guard.mdm"  // Cambiar de com.example.inova_app

    defaultConfig {
        applicationId = "inova.guard.mdm"  // Cambiar de com.example.inova_app
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0.0"
    }
}
```

### 1.2 Configurar Device Admin Receiver (Requerido para Device Owner)

Crear el archivo receptor de administración del dispositivo:

#### Archivo: `android/app/src/main/kotlin/inova/guard/mdm/receivers/OEMDeviceAdminReceiver.kt`

```kotlin
package inova.guard.mdm.receivers

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent

class OEMDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        // Dispositivo configurado como Device Owner
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        // Device Owner deshabilitado
    }
}
```

### 1.3 Actualizar AndroidManifest.xml

#### Archivo: `android/app/src/main/AndroidManifest.xml`

Agregar después de las líneas de permisos existentes (línea 6):

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permisos requeridos para el escáner QR -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />

    <!-- AGREGAR ESTOS PERMISOS PARA MDM -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

    <application
        android:label="Inova MDM"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <!-- AGREGAR DEVICE ADMIN RECEIVER -->
        <receiver
            android:name=".receivers.OEMDeviceAdminReceiver"
            android:permission="android.permission.BIND_DEVICE_ADMIN"
            android:exported="true">
            <meta-data
                android:name="android.app.device_admin"
                android:resource="@xml/device_admin" />
            <intent-filter>
                <action android:name="android.app.action.DEVICE_ADMIN_ENABLED" />
            </intent-filter>
        </receiver>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>

    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

### 1.4 Crear device_admin.xml

#### Archivo: `android/app/src/main/res/xml/device_admin.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<device-admin xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-policies>
        <limit-password />
        <watch-login />
        <reset-password />
        <force-lock />
        <wipe-data />
        <expire-password />
        <encrypted-storage />
        <disable-camera />
    </uses-policies>
</device-admin>
```

---

## Paso 2: Generar la Clave de Firma (Keystore)

### 2.1 Crear Keystore

```bash
cd /Users/gastonfauret/developer/Inova/inova_app/android/app

keytool -genkey -v -keystore inova-mdm.keystore -alias inova-mdm \
  -keyalg RSA -keysize 2048 -validity 10000
```

**Datos sugeridos:**
- Password del keystore: [guardar en lugar seguro]
- Nombre y apellido: Inova MDM
- Unidad organizativa: MDM Development
- Organización: Inova
- Ciudad: [tu ciudad]
- Estado: [tu estado]
- Código de país: AR (o el que corresponda)

### 2.2 Configurar key.properties

#### Archivo: `android/key.properties`

```properties
storePassword=[password del keystore]
keyPassword=[password de la key]
keyAlias=inova-mdm
storeFile=inova-mdm.keystore
```

**IMPORTANTE**: Agregar `android/key.properties` al `.gitignore`

### 2.3 Actualizar build.gradle.kts para usar la firma

#### Archivo: `android/app/build.gradle.kts`

```kotlin
// AGREGAR AL INICIO (después de los plugins)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "inova.guard.mdm"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "inova.guard.mdm"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0.0"
    }

    // AGREGAR CONFIGURACIÓN DE FIRMA
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Habilitar minificación y ofuscación para producción
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
```

---

## Paso 3: Compilar el APK de Producción

### 3.1 Limpiar el proyecto

```bash
cd /Users/gastonfauret/developer/Inova/inova_app

flutter clean
flutter pub get
```

### 3.2 Compilar APK Release

```bash
flutter build apk --release
```

El APK se generará en:
```
build/app/outputs/flutter-apk/app-release.apk
```

### 3.3 Verificar la firma del APK

```bash
# Verificar que el APK esté correctamente firmado
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

Debe mostrar: `jar verified.`

### 3.4 Obtener información del APK

```bash
# Ver información del certificado
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

---

## Paso 4: Reemplazar APK en el Backend

### 4.1 Backup del APK anterior

```bash
cd /Users/gastonfauret/developer/Inova/inova/public/emm

# Crear backup
cp emm-installer.apk emm-installer.apk.backup.$(date +%Y%m%d_%H%M%S)
```

### 4.2 Copiar nuevo APK

```bash
# Copiar el APK compilado al backend
cp /Users/gastonfauret/developer/Inova/inova_app/build/app/outputs/flutter-apk/app-release.apk \
   /Users/gastonfauret/developer/Inova/inova/public/emm/emm-installer.apk
```

### 4.3 Verificar permisos

```bash
cd /Users/gastonfauret/developer/Inova/inova/public/emm

# El archivo debe ser accesible por el servidor web
chmod 644 emm-installer.apk

# Verificar
ls -lh emm-installer.apk
```

---

## Paso 5: Actualizar el Backend (DevicesController)

El código del backend ya está preparado para generar el QR correctamente. Solo verificar que apunte al componente correcto:

#### Archivo: `app/Http/Controllers/Customer/DevicesController.php` (líneas 375-401)

```php
function getQrEnrollment()
{
    $apkPath = public_path('emm/emm-installer.apk');

    // Verificar que el APK existe
    if (!file_exists($apkPath)) {
        return response()->json(['error' => 'APK no encontrado'], 404);
    }

    // Calcular checksum del nuevo APK
    $sha256Hex = hash_file('sha256', $apkPath);
    $checksumB64 = base64_encode(hex2bin($sha256Hex));

    $apkUrl = url('emm/emm-installer.apk');

    // El component name debe coincidir con el nuevo package
    $payload = [
        "android.app.extra.PROVISIONING_DEVICE_ADMIN_COMPONENT_NAME" =>
            "inova.guard.mdm/.receivers.OEMDeviceAdminReceiver",  // IMPORTANTE: Verificar
        "android.app.extra.PROVISIONING_DEVICE_ADMIN_PACKAGE_DOWNLOAD_LOCATION" => $apkUrl,
        "android.app.extra.PROVISIONING_DEVICE_ADMIN_PACKAGE_CHECKSUM" => $checksumB64,
        "android.app.extra.PROVISIONING_LEAVE_ALL_SYSTEM_APPS_ENABLED" => true,
    ];

    // Generar QR Code
    $qr = QrCode::format('png')
        ->size(512)
        ->margin(2)
        ->errorCorrection('H')
        ->generate(json_encode($payload));

    return response($qr)->header('Content-Type', 'image/png');
}
```

---

## Paso 6: Probar el Sistema Completo

### 6.1 Generar nuevo QR Code

1. Acceder al panel web MDM
2. Ir a la sección de dispositivos
3. Generar QR de enrollment
4. El QR ahora apuntará al nuevo APK con checksum actualizado

### 6.2 Probar Device Owner Provisioning

**IMPORTANTE**: Este proceso requiere un dispositivo en estado de fábrica.

1. **Factory Reset del dispositivo de prueba**
   ```
   Settings > System > Reset options > Erase all data (factory reset)
   ```

2. **Activar modo provisioning**
   - En la pantalla de bienvenida (Welcome/Hello)
   - Tocar 6 veces en el mismo lugar
   - Aparecerá el escáner QR

3. **Escanear el QR Code**
   - Escanear el QR generado desde el panel web
   - El sistema descargará automáticamente el APK desde:
     ```
     https://[tu-dominio]/emm/emm-installer.apk
     ```
   - Verificará el checksum SHA-256
   - Instalará la app
   - Configurará la app como Device Owner

4. **Verificar instalación**
   - La app debe abrirse automáticamente
   - Debe mostrar la pantalla de enrollment
   - El dispositivo debe quedar configurado como "Managed Device"

### 6.3 Verificar funcionalidades

Una vez instalado como Device Owner:

1. **Enrollment**
   - La app debe recopilar info del dispositivo
   - Enviar al backend y recibir código de dispositivo

2. **FCM (Notificaciones)**
   - Desde el panel web, enviar una notificación de prueba
   - Debe recibirse en el dispositivo

3. **Lock/Unlock**
   - Desde el panel web, bloquear el dispositivo
   - La app debe mostrar la pantalla de bloqueo
   - Desbloquear desde el panel
   - La app debe volver a enrollment screen

---

## Troubleshooting

### Error: "APK no se descarga durante provisioning"

**Solución:**
- Verificar que el servidor esté accesible desde Internet
- Comprobar certificado SSL (debe ser válido)
- Verificar URL en el QR Code

### Error: "Checksum verification failed"

**Solución:**
```bash
# Regenerar checksum manualmente
sha256sum /Users/gastonfauret/developer/Inova/inova/public/emm/emm-installer.apk

# Comparar con el checksum en el QR
# Regenerar el QR si no coinciden
```

### Error: "Device admin receiver not found"

**Solución:**
- Verificar que el package name sea exactamente: `inova.guard.mdm`
- Verificar que la clase `OEMDeviceAdminReceiver` exista
- Verificar que el path en AndroidManifest.xml sea correcto
- Revisar que `device_admin.xml` exista en `res/xml/`

### Error: "App instalada pero no es Device Owner"

**Causa**: El provisioning QR solo funciona en dispositivos sin cuentas configuradas.

**Solución:**
- Asegurarse de hacer Factory Reset completo
- No agregar cuenta Google antes del provisioning
- El QR debe escanearse en la pantalla de bienvenida inicial

---

## Checklist de Deployment

- [ ] Cambiar `applicationId` a `inova.guard.mdm`
- [ ] Crear `OEMDeviceAdminReceiver.kt`
- [ ] Actualizar `AndroidManifest.xml` con receiver y permisos MDM
- [ ] Crear `device_admin.xml`
- [ ] Generar keystore de producción
- [ ] Configurar `key.properties`
- [ ] Actualizar `build.gradle.kts` con firma
- [ ] Compilar APK release: `flutter build apk --release`
- [ ] Verificar firma del APK
- [ ] Hacer backup de `emm-installer.apk`
- [ ] Copiar nuevo APK al backend
- [ ] Verificar permisos del archivo (644)
- [ ] Probar generación de QR Code desde panel web
- [ ] Probar provisioning en dispositivo factory reset
- [ ] Verificar enrollment
- [ ] Probar FCM notifications
- [ ] Probar lock/unlock desde panel web

---

## Notas de Seguridad

1. **Keystore**: Guardar en lugar seguro, nunca en repositorio Git
2. **Passwords**: Usar gestor de contraseñas para almacenar credentials
3. **APK Firmado**: Solo distribuir APKs firmados con keystore de producción
4. **Checksum**: El backend calcula automáticamente, no hardcodear
5. **HTTPS**: El servidor debe usar HTTPS válido para provisioning

---

## Mantenimiento Futuro

### Actualizar la app:

1. Incrementar `versionCode` y `versionName` en `build.gradle.kts`
2. Compilar nuevo APK
3. Reemplazar en backend
4. Los dispositivos ya provisionados pueden actualizar via:
   - Google Play (si se publica)
   - APK directo desde panel MDM
   - Forced update via policy

### Logs y Debugging:

```bash
# Ver logs del dispositivo Android
adb logcat | grep -E "inova|mdm|FCM|enrollment"

# Verificar si es Device Owner
adb shell dpm list-owners
```

---

## Referencias

- Android Enterprise Provisioning: https://developers.google.com/android/work/prov-devices
- Device Admin API: https://developer.android.com/guide/topics/admin/device-admin
- Flutter Build Modes: https://docs.flutter.dev/deployment/android
- Firebase Cloud Messaging: https://firebase.google.com/docs/cloud-messaging/android/client
