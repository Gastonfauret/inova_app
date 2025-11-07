# Flujo de Provisioning - Inova MDM

## Descripción General

Este documento describe el flujo completo de enrollment de dispositivos Android mediante Android Enterprise Device Owner Provisioning (Factory Reset).

## Requisitos Previos

### Backend (inova)
- Servidor Laravel funcionando
- APK `emm-installer.apk` disponible en `/public/emm/`
- Endpoint `/api/v1/emm/emm` accesible para descarga del APK
- Panel web accesible para generar códigos de dispositivo

### Dispositivo Android
- Android 6.0 o superior
- Conexión a internet (WiFi o datos móviles)
- Acceso a la cámara
- Dispositivo en estado de fábrica (Factory Reset)

---

## Flujo Completo de Provisioning

### FASE 1: Preparación (Panel Web)

**Responsable**: Manager/Administrator

1. Acceder al panel web de Inova MDM
2. Crear un nuevo dispositivo:
   - Asignar a un cliente
   - Generar código de dispositivo (ejemplo: `147760`)
   - El sistema genera automáticamente el QR de provisioning
3. **IMPORTANTE**: Tomar nota del código de 6 dígitos generado

**Output**:
- QR de provisioning de Android Enterprise (contiene URL del APK + checksum)
- Código de dispositivo de 6 dígitos

---

### FASE 2: Factory Reset Provisioning

**Responsable**: Técnico en campo

#### Paso 1: Reset del Dispositivo
```
1. Realizar Factory Reset del dispositivo Android
2. Esperar a que el dispositivo reinicie
3. Llegar a la pantalla de "Bienvenido" / "Welcome"
```

#### Paso 2: Activar Provisioning Mode
```
1. En la pantalla de bienvenida, tocar 6 veces en el mismo lugar
2. Aparecerá la opción de "Configuración corporativa" o "QR Code Setup"
3. Seleccionar escanear código QR
```

#### Paso 3: Escanear QR de Provisioning
```
1. Apuntar la cámara del dispositivo al QR generado en el panel web
2. El dispositivo escaneará automáticamente el QR
3. Android mostrará: "Descargando aplicación de administración..."
```

**¿Qué sucede en segundo plano?**
- Android extrae del QR:
  - URL de descarga: `https://inova.up.railway.app/api/v1/emm/emm`
  - Checksum SHA-256 del APK
  - Componente Device Admin: `inova.guard.mdm.receivers.OEMDeviceAdminReceiver`
- Android descarga el APK (64 MB) automáticamente
- Android verifica el checksum
- Android instala el APK con permisos de Device Owner
- Android inicia la aplicación Inova MDM

---

### FASE 3: Enrollment Automático

**Responsable**: Aplicación Inova MDM (automático)

#### Paso 1: Inicio de la Aplicación
```
La app inicia automáticamente después de la instalación.

Log en consola:
╔════════════════════════════════════════╗
║       INOVA MDM - INICIO DE APP      ║
╚════════════════════════════════════════╝

⚙️ Inicializando Flutter bindings...
✅ Flutter bindings inicializados

🔥 Inicializando Firebase...
✅ Firebase inicializado correctamente

📱 Inicializando FCM Service...
✅ FCM Service inicializado correctamente

💾 Verificando estado de enrollment...
📊 Estado de SharedPreferences:
   - isEnrolled: false
   - device_code: NULL

⚠️ Dispositivo NO está enrolado
   - El usuario verá la pantalla de enrollment
```

#### Paso 2: EnrollmentScreen
```
La app muestra la pantalla de enrollment con 3 opciones:

┌─────────────────────────────────────┐
│    📱 Enrollar Dispositivo          │
├─────────────────────────────────────┤
│                                     │
│  Ingrese el código de su dispositivo│
│  o escanee el código QR             │
│                                     │
│  ┌───────────────────────────────┐  │
│  │   [Código: ______]            │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📷 Escanear Código QR        │  │
│  └───────────────────────────────┘  │
│                                     │
│  ─────────── O ───────────         │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  ✓ Enrollar Dispositivo       │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

**OPCIÓN A: Ingreso Manual del Código**
```
1. Técnico ingresa el código de 6 dígitos (ejemplo: 147760)
2. Presiona "Enrollar Dispositivo"
3. La app ejecuta el enrollment (continúa en FASE 4)
```

**OPCIÓN B: Escaneo de QR Simple** ⭐ RECOMENDADO
```
1. Técnico presiona "Escanear Código QR"
2. Se abre el scanner de QR simple
3. Técnico escanea un QR que contiene solo el código (147760)
4. La app auto-completa el campo y ejecuta enrollment automáticamente
```

**Nota**: El QR simple puede ser:
- Un QR que contiene solo números: `147760`
- Un QR con texto: `CODE-147760` (se extraen solo los números)
- Puede ser generado con cualquier herramienta online (ejemplo: https://www.qr-code-generator.com/)

---

### FASE 4: Proceso de Enrollment

**Responsable**: API Backend + Aplicación

```
Log del proceso:

╔════════════════════════════════════════╗
║  ENROLLMENT SCREEN - INICIO           ║
╚════════════════════════════════════════╝

📋 Estado inicial:
   - Widget deviceCode: NULL
   - FCM Service disponible: true

✅ FCM Service disponible
   - FCM Token: eR3kL...h4Kj (148 caracteres)

📝 Código ingresado por el usuario:
   - Código: "147760"
   - Longitud: 6 caracteres
   - Es vacío: false

🔧 Obteniendo Android ID real del dispositivo...
✅ Device ID obtenido: abc123def456789

🚀 Llamando a ApiService.enrollDevice()...
   - enrollmentCode: 147760
   - deviceId (Android ID real): abc123def456789
   - fcmService: Instance of 'FCMService'

════════════════════════════════════════
🚀 INICIANDO PROCESO DE ENROLLMENT
════════════════════════════════════════

📋 Datos de entrada:
   - Enrollment Code: 147760
   - Device UID: abc123def456789
   - FCM Token: eR3kL...h4Kj
   - FCM Token length: 148

🌐 Información de conexión:
   - Base URL: https://inova.up.railway.app/api/v1
   - Endpoint: /emm/settings/147760/abc123def456789/eR3kL...h4Kj
   - URL Completa: https://inova.up.railway.app/api/v1/emm/settings/147760/abc123def456789/eR3kL...

📤 Realizando petición GET al servidor...

📥 Respuesta recibida:
   - Status Code: 200
   - Data: {customer settings...}

✅ RESPUESTA EXITOSA (200 OK)

💾 Guardando configuración local...
   ✓ isEnrolled = true
   ✓ device_code = 147760

💾 Procesando configuraciones (formato map)...
   ✓ setting_enterprise (String) = Gustavo Admin
   ✓ setting_status (int) = 1
   ✓ setting_primary_message (String) = Bienvenido a Inova MDM
   ... (más configuraciones)

✅ ¡ENROLLMENT COMPLETADO EXITOSAMENTE!
════════════════════════════════════════

✅ ¡ENROLLMENT EXITOSO!
   - Enviando información del dispositivo al backend...

💓 ENVIANDO HEARTBEAT AL BACKEND
   - Device Code: 147760
   - Data keys: device_id, fcm_token, brand, model, manufacturer, battery, status, lat, lng

✅ Heartbeat enviado exitosamente
   - ✅ Datos del dispositivo enviados al backend
```

---

### FASE 5: Finalización

**Responsable**: Aplicación

```
┌─────────────────────────────────────┐
│    ✅ Éxito                         │
├─────────────────────────────────────┤
│                                     │
│  Dispositivo enlazado correctamente │
│                                     │
│  ┌───────────────────────────────┐  │
│  │      [Continuar]              │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘

Usuario presiona "Continuar"

Navegación a HomeScreen:

┌─────────────────────────────────────┐
│    📱 Inova MDM                     │
├─────────────────────────────────────┤
│                                     │
│  Estado: ✅ Activo                  │
│  Cliente: Gustavo Admin             │
│  Código: 147760                     │
│                                     │
│  Dispositivo:                       │
│  - Marca: Samsung                   │
│  - Modelo: Galaxy A52               │
│  - Android ID: abc123...            │
│                                     │
│  Última sincronización:             │
│  - Hace 1 minuto                    │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  🔄 Sincronizar ahora         │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

**El dispositivo ahora**:
- ✅ Está enrollado como Device Owner
- ✅ Recibe comandos remotos (lock, unlock, wipe)
- ✅ Envía heartbeat cada 15 minutos
- ✅ Reporta ubicación GPS (si está habilitado)
- ✅ Puede ser gestionado desde el panel web

---

## Resumen del Flujo

```
┌─────────────┐
│ Panel Web   │
│ Genera QR   │
│ + Código    │
└──────┬──────┘
       │
       v
┌─────────────────────────────────────┐
│ TÉCNICO EN CAMPO                    │
├─────────────────────────────────────┤
│ 1. Factory Reset                    │
│ 2. Tocar 6 veces pantalla           │
│ 3. Escanear QR de Provisioning      │
└──────┬──────────────────────────────┘
       │
       v
┌─────────────────────────────────────┐
│ ANDROID (Automático)                │
├─────────────────────────────────────┤
│ 1. Descarga APK (64 MB)             │
│ 2. Verifica checksum                │
│ 3. Instala APK                      │
│ 4. Otorga permisos Device Owner     │
│ 5. Inicia Inova MDM                 │
└──────┬──────────────────────────────┘
       │
       v
┌─────────────────────────────────────┐
│ INOVA MDM APP (Automático)          │
├─────────────────────────────────────┤
│ 1. Inicializa Firebase/FCM          │
│ 2. Muestra EnrollmentScreen         │
└──────┬──────────────────────────────┘
       │
       v
┌─────────────────────────────────────┐
│ TÉCNICO EN CAMPO                    │
├─────────────────────────────────────┤
│ OPCIÓN A: Ingresar código manual    │
│ OPCIÓN B: Escanear QR simple ⭐     │
└──────┬──────────────────────────────┘
       │
       v
┌─────────────────────────────────────┐
│ INOVA MDM APP (Automático)          │
├─────────────────────────────────────┤
│ 1. GET /emm/settings/{code}/{uid}   │
│ 2. Guarda configuración local       │
│ 3. Envía heartbeat inicial          │
│ 4. Navega a HomeScreen              │
└──────┬──────────────────────────────┘
       │
       v
┌─────────────────────────────────────┐
│ ✅ DISPOSITIVO ENROLLADO            │
│ Ready para gestión remota           │
└─────────────────────────────────────┘
```

---

## Tiempos Estimados

| Fase | Tiempo Estimado |
|------|----------------|
| 1. Generación de QR en panel web | 1-2 minutos |
| 2. Factory Reset del dispositivo | 2-3 minutos |
| 3. Tocar 6 veces + escanear QR provisioning | 30 segundos |
| 4. Descarga e instalación automática del APK | 2-5 minutos (depende de conexión) |
| 5. Inicio de app + enrollment | 30 segundos |
| 6. Ingreso de código (manual o QR) | 10-30 segundos |
| **TOTAL** | **6-12 minutos** |

---

## Ventajas de Este Flujo

✅ **Device Owner desde el primer momento**
- La app tiene permisos completos de administración
- No requiere intervención del usuario para permisos

✅ **Instalación automática**
- Android descarga e instala el APK automáticamente
- No requiere fuentes desconocidas habilitadas
- No requiere Play Store

✅ **Seguro**
- Checksum SHA-256 verifica la integridad del APK
- Solo funciona con APK autorizado por Google

✅ **Rápido**
- Todo el proceso toma 6-12 minutos
- La mayoría del tiempo es automático

✅ **Escalable**
- Puede enrollar múltiples dispositivos en paralelo
- Cada técnico puede gestionar varios dispositivos

---

## Troubleshooting

### Problema: El dispositivo no muestra la opción de escanear QR

**Solución**:
- Asegurarse de que el dispositivo está en Factory Reset completo
- Tocar exactamente 6 veces en el mismo lugar de la pantalla de bienvenida
- Algunos dispositivos requieren tocar en la esquina superior derecha

### Problema: Error al descargar el APK

**Solución**:
- Verificar conexión a internet del dispositivo
- Verificar que el servidor backend está accesible
- Verificar que el APK existe en `/public/emm/emm-installer.apk`

### Problema: El enrollment falla con error 404

**Solución**:
- Verificar que el código de dispositivo fue generado en el backend
- Verificar que el código es correcto (6 dígitos)
- Verificar que el servidor backend está funcionando

### Problema: No puedo escanear el QR simple del código

**Solución**:
- Generar un nuevo QR con solo el código numérico
- Asegurarse de que el QR contiene al menos 4 dígitos
- Intentar ingreso manual si el QR no funciona

---

## Generación de QR Simple para Código

Para generar un QR simple que contenga solo el código de dispositivo:

**Opción 1: Online**
1. Ir a https://www.qr-code-generator.com/
2. Seleccionar "Texto"
3. Ingresar el código: `147760`
4. Generar y descargar QR

**Opción 2: Linux/Mac**
```bash
# Instalar qrencode
sudo apt-get install qrencode  # Ubuntu/Debian
brew install qrencode          # macOS

# Generar QR
echo "147760" | qrencode -o device_code.png
```

**Opción 3: Python**
```python
import qrcode

code = "147760"
img = qrcode.make(code)
img.save('device_code.png')
```

---

## Contacto y Soporte

Para soporte técnico o dudas sobre el proceso de provisioning, contactar al equipo de desarrollo de Inova MDM.

---

**Última actualización**: 2025-11-07
**Versión del documento**: 1.0
