# Guía de Testing - Provisioning con Factory Reset

## Objetivo

Verificar que el flujo completo de enrollment vía Factory Reset funciona correctamente desde la generación del QR hasta el dispositivo completamente enrollado.

---

## Requisitos Previos

### Hardware
- ✅ Dispositivo Android de prueba (Android 6.0+)
- ✅ Dispositivo para mostrar el QR de provisioning (PC, tablet, otro teléfono)
- ✅ Conexión a internet estable (WiFi preferentemente)

### Software
- ✅ Backend Laravel funcionando y accesible
- ✅ APK compilado y disponible en `/public/emm/emm-installer.apk`
- ✅ Panel web accesible
- ✅ Usuario con permisos de Manager o Administrator

### Preparación
1. Asegurarse de que el backend está funcionando:
   ```bash
   cd /Users/gastonfauret/developer/Inova/inova
   php artisan serve
   ```

2. Verificar que el APK existe:
   ```bash
   ls -lh /Users/gastonfauret/developer/Inova/inova/public/emm/
   # Debe mostrar: emm-installer.apk (aprox 64 MB)
   ```

3. Verificar que el endpoint del APK es accesible:
   ```bash
   curl -I https://inova.up.railway.app/api/v1/emm/emm
   # Debe retornar: HTTP/1.1 200 OK
   ```

---

## Plan de Testing

### Test 1: Generación del QR de Provisioning

**Objetivo**: Verificar que el panel web genera correctamente el QR de provisioning.

**Pasos**:
1. Iniciar sesión en el panel web como Manager
2. Navegar a "Dispositivos" → "Agregar Dispositivo"
3. Llenar el formulario:
   - Cliente: Seleccionar un cliente de prueba
   - Nombre: "Test Device Factory Reset"
   - Tipo: "Smartphone Android"
4. Click en "Generar QR de Enrollment"

**Resultado Esperado**:
- ✅ El sistema genera un código de 6 dígitos (ejemplo: `147760`)
- ✅ Se muestra un QR code en pantalla
- ✅ El dispositivo se crea en la base de datos
- ✅ El estado del dispositivo es "Pendiente de Enrollment"

**Verificación en Base de Datos**:
```sql
SELECT id, code, name, status, customer_id
FROM devices
WHERE code = '147760';

-- Debe retornar:
-- id: 123
-- code: 147760
-- name: Test Device Factory Reset
-- status: 0 (pendiente)
-- customer_id: 1
```

**Nota**: Tomar captura de pantalla del QR y del código de 6 dígitos.

---

### Test 2: Factory Reset del Dispositivo

**Objetivo**: Preparar el dispositivo para el provisioning.

**Pasos**:
1. En el dispositivo Android, ir a "Ajustes" → "Sistema" → "Restablecer"
2. Seleccionar "Restablecimiento de datos de fábrica"
3. Confirmar y esperar a que el dispositivo reinicie
4. Esperar a que aparezca la pantalla de "Bienvenido" / "Welcome"

**Resultado Esperado**:
- ✅ El dispositivo se resetea completamente
- ✅ Aparece la pantalla de configuración inicial
- ✅ El dispositivo está conectado a WiFi (si es posible, conectar antes del reset)

**Tiempo Estimado**: 2-3 minutos

**IMPORTANTE**:
- ⚠️ Asegurarse de tener respaldo de datos importantes
- ⚠️ El dispositivo quedará como nuevo (sin apps, sin datos)
- ⚠️ Mantener el dispositivo cargado (mínimo 50% batería)

---

### Test 3: Activación del Provisioning Mode

**Objetivo**: Activar el modo de provisioning corporativo de Android.

**Pasos**:
1. En la pantalla de "Bienvenido", tocar 6 veces en el mismo lugar
   - Ubicación recomendada: Centro de la pantalla
   - Tocar de forma rápida pero deliberada
2. Observar si aparece la opción de "Configuración corporativa" o "QR Code Scanner"

**Resultado Esperado**:
- ✅ Después de 6 toques, aparece un mensaje
- ✅ Se muestra la opción de escanear código QR
- ✅ La cámara se activa automáticamente

**Variantes por fabricante**:
- Samsung: Puede mostrar "Knox Enrollment"
- Google Pixel: Muestra "Setup with QR code"
- Xiaomi/Redmi: Puede requerir tocar en esquina superior

**Troubleshooting**:
- Si no aparece después de 6 toques, intentar en esquina superior derecha
- Si sigue sin aparecer, el dispositivo puede no soportar Device Owner provisioning
- Verificar que el dispositivo tiene Android 6.0 o superior

---

### Test 4: Escaneo del QR de Provisioning

**Objetivo**: Escanear el QR generado en el Test 1.

**Pasos**:
1. Mostrar el QR de provisioning en una pantalla o imprimir
2. Apuntar la cámara del dispositivo al QR
3. Mantener estable hasta que el QR sea escaneado

**Resultado Esperado**:
- ✅ El dispositivo escanea el QR automáticamente
- ✅ Aparece mensaje: "Descargando aplicación de administración..."
- ✅ Se muestra una barra de progreso

**Logs en el servidor (si está en desarrollo local)**:
```bash
# En el servidor Laravel, deberías ver:
[2025-11-07 15:30:45] INFO: Headers: {...}
[2025-11-07 15:30:45] INFO: Descargando APK: emm-installer.apk
```

**Tiempo Estimado**: 2-5 minutos (depende de la velocidad de conexión)

**Troubleshooting**:
- Si no escanea, verificar iluminación
- Si da error de checksum, regenerar el QR
- Si da error 404, verificar que el APK existe en el servidor

---

### Test 5: Instalación Automática del APK

**Objetivo**: Verificar que Android instala el APK automáticamente.

**Pasos**:
1. Observar el proceso de descarga en el dispositivo
2. Esperar a que termine la descarga
3. Android verificará el checksum
4. Android instalará automáticamente el APK

**Resultado Esperado**:
- ✅ Descarga completa: "64 MB de 64 MB"
- ✅ Verificación exitosa del checksum
- ✅ Instalación automática (sin permisos manuales)
- ✅ La app "Inova MDM" se instala

**Indicadores visuales**:
- Barra de progreso de descarga
- Mensaje de "Verificando aplicación"
- Mensaje de "Instalando aplicación"
- Logo de Inova MDM aparece

**Tiempo Estimado**: 3-5 minutos

---

### Test 6: Inicio Automático de Inova MDM

**Objetivo**: Verificar que la app inicia automáticamente después de la instalación.

**Pasos**:
1. Esperar a que termine la instalación
2. La app debe iniciarse automáticamente
3. Observar los logs en la consola (si está conectado a Android Studio)

**Resultado Esperado**:
- ✅ La app Inova MDM inicia automáticamente
- ✅ Se muestra el splash screen (si existe)
- ✅ Firebase se inicializa correctamente

**Logs esperados en consola**:
```
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

**Tiempo Estimado**: 10-20 segundos

---

### Test 7: EnrollmentScreen - Ingreso Manual del Código

**Objetivo**: Verificar el flujo de enrollment con ingreso manual.

**Pasos**:
1. La app muestra EnrollmentScreen
2. Ingresar el código de 6 dígitos generado en Test 1 (ejemplo: `147760`)
3. Click en "Enrollar Dispositivo"
4. Observar el proceso

**Resultado Esperado**:
- ✅ Campo de código acepta números
- ✅ Validación funciona (mínimo 4 dígitos)
- ✅ Aparece spinner de carga: "Enrollando dispositivo..."
- ✅ Se realiza petición al backend

**Logs esperados**:
```
╔════════════════════════════════════════╗
║  ENROLLMENT SCREEN - INICIO           ║
╚════════════════════════════════════════╝

📋 Estado inicial:
   - Widget deviceCode: NULL
   - FCM Service disponible: true

📝 Código ingresado por el usuario:
   - Código: "147760"
   - Longitud: 6 caracteres

🔧 Obteniendo Android ID real del dispositivo...
✅ Device ID obtenido: abc123def456789

🚀 Llamando a ApiService.enrollDevice()...

════════════════════════════════════════
🚀 INICIANDO PROCESO DE ENROLLMENT
════════════════════════════════════════

🌐 Información de conexión:
   - Base URL: https://inova.up.railway.app/api/v1
   - Endpoint: /emm/settings/147760/abc123def456789/[FCM_TOKEN]

📤 Realizando petición GET al servidor...

📥 Respuesta recibida:
   - Status Code: 200

✅ RESPUESTA EXITOSA (200 OK)

💾 Guardando configuración local...
   ✓ isEnrolled = true
   ✓ device_code = 147760

✅ ¡ENROLLMENT COMPLETADO EXITOSAMENTE!
```

**Tiempo Estimado**: 5-10 segundos

---

### Test 8: EnrollmentScreen - Escaneo de QR Simple

**Objetivo**: Verificar el flujo de enrollment con QR Scanner.

**Preparación**:
1. Generar un QR simple con el código (ejemplo: `147760`)
   - Usar https://www.qr-code-generator.com/
   - Texto: `147760`
   - Descargar QR

**Pasos**:
1. En EnrollmentScreen, click en "Escanear Código QR"
2. Se abre SimpleQRScanner
3. Apuntar cámara al QR simple con el código
4. El scanner detecta el código
5. La app auto-completa el campo y ejecuta enrollment

**Resultado Esperado**:
- ✅ SimpleQRScanner se abre correctamente
- ✅ Cámara funciona
- ✅ Se muestra overlay de guía
- ✅ QR es detectado automáticamente
- ✅ Campo de código se auto-completa
- ✅ Enrollment inicia automáticamente

**Logs esperados**:
```
📷 Abriendo QR Scanner...
📷 QR Code escaneado: 147760
✅ Device code extraído: 147760
🚀 Iniciando auto-enrollment...
[... logs de enrollment ...]
```

**Tiempo Estimado**: 3-5 segundos

**Casos de prueba adicionales**:
- QR con texto: `CODE-147760` → debe extraer `147760`
- QR con espacios: `  147760  ` → debe extraer `147760`
- QR inválido: `abcdef` → debe mostrar error

---

### Test 9: Heartbeat Inicial

**Objetivo**: Verificar que el heartbeat inicial se envía correctamente.

**Resultado Esperado**:
- ✅ Heartbeat se envía inmediatamente después del enrollment
- ✅ Backend recibe información del dispositivo

**Logs esperados**:
```
💓 ENVIANDO HEARTBEAT AL BACKEND
   - Device Code: 147760
   - Data keys: device_id, fcm_token, brand, model, manufacturer, battery, status, lat, lng

✅ Heartbeat enviado exitosamente
   - ✅ Datos del dispositivo enviados al backend
```

**Verificación en Base de Datos**:
```sql
SELECT code, brand, model, manufacturer, battery_level, last_heartbeat
FROM devices
WHERE code = '147760';

-- Debe mostrar:
-- brand: Samsung (o la marca real)
-- model: Galaxy A52 (o el modelo real)
-- manufacturer: Samsung
-- battery_level: 85 (o nivel actual)
-- last_heartbeat: 2025-11-07 15:35:42
```

---

### Test 10: Navegación a HomeScreen

**Objetivo**: Verificar que la app navega a HomeScreen después del enrollment.

**Resultado Esperado**:
- ✅ Aparece diálogo: "✅ Éxito - Dispositivo enlazado correctamente"
- ✅ Usuario hace click en "Continuar"
- ✅ Se navega a HomeScreen
- ✅ HomeScreen muestra información correcta

**Contenido de HomeScreen**:
```
┌─────────────────────────────────────┐
│    📱 Inova MDM                     │
├─────────────────────────────────────┤
│ Estado: ✅ Activo                   │
│ Cliente: [Nombre del Cliente]       │
│ Código: 147760                      │
│                                     │
│ Dispositivo:                        │
│ - Marca: Samsung                    │
│ - Modelo: Galaxy A52                │
│ - Android ID: abc123...             │
│                                     │
│ Última sincronización:              │
│ - Hace 1 minuto                     │
└─────────────────────────────────────┘
```

---

### Test 11: Verificación en Panel Web

**Objetivo**: Verificar que el dispositivo aparece enrollado en el panel web.

**Pasos**:
1. Refrescar el panel web
2. Navegar a "Dispositivos"
3. Buscar el dispositivo por código o nombre

**Resultado Esperado**:
- ✅ El dispositivo aparece en la lista
- ✅ Estado: "Activo" (status = 1)
- ✅ Información completa:
  - Código: 147760
  - Marca: Samsung
  - Modelo: Galaxy A52
  - Android ID: abc123def456789
  - FCM Token: eR3kL...h4Kj
  - Último heartbeat: Hace menos de 5 minutos

**Verificación de datos**:
```sql
SELECT
    code,
    name,
    status,
    brand,
    model,
    identifier,
    fcm_token,
    last_heartbeat,
    TIMESTAMPDIFF(MINUTE, last_heartbeat, NOW()) as minutes_ago
FROM devices
WHERE code = '147760';

-- Verificar que todos los campos tienen valores
```

---

### Test 12: Comandos Remotos - Lock

**Objetivo**: Verificar que el dispositivo puede ser bloqueado remotamente.

**Pasos**:
1. En el panel web, seleccionar el dispositivo
2. Click en "Bloquear Dispositivo"
3. Ingresar mensaje de bloqueo: "Dispositivo bloqueado por prueba"
4. Confirmar

**Resultado Esperado en el Panel Web**:
- ✅ Se envía notificación FCM
- ✅ Estado del dispositivo cambia a "Bloqueado" (status = 2)

**Resultado Esperado en el Dispositivo**:
- ✅ El dispositivo recibe la notificación FCM
- ✅ Se muestra LockScreen con el mensaje
- ✅ El usuario no puede salir de la pantalla de bloqueo

**Logs esperados en el dispositivo**:
```
📨 COMANDO RECIBIDO VIA FCM STREAM
   - Comando: lock
   - Dispositivo bloqueado via FCM

🔒 Navegando a LockScreen...
   - Título: Dispositivo Bloqueado
   - Mensaje: Dispositivo bloqueado por prueba
```

**Tiempo Estimado**: 5-10 segundos (depende de FCM)

---

### Test 13: Comandos Remotos - Unlock con Código

**Objetivo**: Verificar que el dispositivo puede ser desbloqueado con código.

**Preparación**:
1. Dispositivo debe estar bloqueado (Test 12)
2. En el panel web, generar código de desbloqueo de 5 dígitos

**Pasos en Panel Web**:
1. Seleccionar el dispositivo bloqueado
2. Click en "Generar Código de Desbloqueo"
3. Configurar expiración (ejemplo: 7 días)
4. Click en "Generar"
5. Copiar el código de 5 dígitos generado (ejemplo: `12345`)

**Pasos en el Dispositivo**:
1. En LockScreen, ingresar el código de 5 dígitos
2. Click en "Verificar Código"

**Resultado Esperado**:
- ✅ El código es validado contra el backend
- ✅ Si es correcto, el dispositivo se desbloquea
- ✅ Se navega de vuelta a HomeScreen
- ✅ Estado cambia a "Activo"

**Logs esperados**:
```
🔑 Verificando código de desbloqueo...
   - Código ingresado: 12345
   - Device Code: 147760

POST /emm/unlock-code/147760
   - unlock_code: 12345

✅ Código válido - Desbloqueando dispositivo
   - Navegando a HomeScreen
```

**Casos de prueba adicionales**:
- Código incorrecto → debe mostrar error
- Código expirado → debe mostrar error
- Código ya usado → debe mostrar error

---

### Test 14: Heartbeat Periódico

**Objetivo**: Verificar que el dispositivo envía heartbeat cada 15 minutos.

**Pasos**:
1. Dejar el dispositivo enrollado y activo
2. Esperar 15 minutos
3. Verificar en el panel web el timestamp del último heartbeat

**Resultado Esperado**:
- ✅ Cada 15 minutos se envía un heartbeat automáticamente
- ✅ El timestamp en la base de datos se actualiza
- ✅ Los datos del dispositivo (batería, ubicación) se actualizan

**Verificación**:
```sql
SELECT
    code,
    battery_level,
    last_heartbeat,
    TIMESTAMPDIFF(MINUTE, last_heartbeat, NOW()) as minutes_ago
FROM devices
WHERE code = '147760'
ORDER BY last_heartbeat DESC;

-- minutes_ago debe ser menor a 16
```

**Logs esperados (cada 15 min)**:
```
💓 HEARTBEAT TIMER - Ejecutando heartbeat programado
💓 ENVIANDO HEARTBEAT AL BACKEND
   - Device Code: 147760
   - Battery: 82%
   - Status: active
   - Lat: -34.6037
   - Lng: -58.3816

✅ Heartbeat enviado exitosamente
```

---

### Test 15: Tracking GPS (Opcional)

**Objetivo**: Verificar que el dispositivo envía ubicación GPS si está habilitado.

**Prerequisitos**:
- Permisos de ubicación otorgados a la app
- GPS habilitado en el dispositivo
- Tracking GPS habilitado en la configuración del cliente

**Pasos**:
1. Verificar que la app tiene permisos de ubicación
2. Esperar al próximo heartbeat
3. Verificar en el panel web la ubicación

**Resultado Esperado**:
- ✅ La app obtiene coordenadas GPS
- ✅ Coordenadas se envían en el heartbeat
- ✅ Panel web muestra ubicación en mapa

**Verificación**:
```sql
SELECT lat, lng, created_at
FROM device_locations
WHERE device_id = (SELECT id FROM devices WHERE code = '147760')
ORDER BY created_at DESC
LIMIT 5;

-- Debe mostrar ubicaciones recientes
```

---

## Checklist Final de Verificación

Antes de dar el testing como completo, verificar:

### Backend
- [ ] Servidor Laravel funcionando
- [ ] APK accesible vía URL pública
- [ ] Endpoint `/emm/settings` funciona
- [ ] Endpoint `/emm/device/*/heartbeat` funciona
- [ ] Endpoint `/emm/unlock-code/*` funciona
- [ ] Base de datos actualizada con información del dispositivo

### Dispositivo
- [ ] App instalada con permisos de Device Owner
- [ ] Firebase/FCM inicializado correctamente
- [ ] Dispositivo enrollado (isEnrolled = true)
- [ ] Información del dispositivo guardada localmente
- [ ] Heartbeat se envía cada 15 minutos
- [ ] Comandos remotos (lock/unlock) funcionan
- [ ] FCM recibe notificaciones

### Panel Web
- [ ] Dispositivo visible en lista
- [ ] Estado correcto (Activo/Bloqueado)
- [ ] Información completa (marca, modelo, Android ID)
- [ ] Último heartbeat reciente (< 16 minutos)
- [ ] Comandos remotos ejecutables

---

## Métricas de Éxito

| Métrica | Objetivo | Resultado |
|---------|----------|-----------|
| Tiempo total de provisioning | < 15 minutos | ______ min |
| Tiempo de descarga del APK | < 5 minutos | ______ min |
| Tiempo de enrollment | < 10 segundos | ______ seg |
| Latencia FCM (lock command) | < 10 segundos | ______ seg |
| Frecuencia de heartbeat | Cada 15 min ± 30 seg | ______ |
| Tasa de éxito del QR scanner | > 90% | ____% |

---

## Logs Completos para Debugging

Si algún test falla, recopilar los siguientes logs:

### Android (Logcat)
```bash
# Conectar dispositivo y ejecutar:
adb logcat | grep -i "inova"
```

### Backend Laravel
```bash
# Ver logs en tiempo real:
tail -f storage/logs/laravel.log
```

### FCM
```bash
# Verificar que FCM está funcionando:
# En Firebase Console → Cloud Messaging → Enviar mensaje de prueba
```

---

## Casos de Error Comunes y Soluciones

| Error | Causa Probable | Solución |
|-------|----------------|----------|
| QR de provisioning no escanea | Mala iluminación o QR dañado | Regenerar QR, mejorar iluminación |
| Error 404 al descargar APK | APK no existe o URL incorrecta | Verificar que el APK existe en `/public/emm/` |
| Error 401 al hacer enrollment | Código de dispositivo inválido | Verificar código en base de datos |
| FCM no recibe notificaciones | Firebase mal configurado | Verificar google-services.json |
| Heartbeat no se envía | Servicio detenido | Reiniciar app |
| GPS no funciona | Permisos no otorgados | Otorgar permisos de ubicación |

---

## Conclusión del Testing

**Fecha de testing**: __________
**Tester**: __________
**Dispositivo usado**: __________
**Versión de Android**: __________

**Tests aprobados**: _____ / 15
**Tests fallidos**: _____ / 15

**Observaciones**:
_________________________________________________
_________________________________________________
_________________________________________________

**¿El flujo de provisioning está listo para producción?**
- [ ] Sí, todos los tests pasaron
- [ ] No, se requieren ajustes (especificar)

---

**Firma del Tester**: __________________
**Firma del Líder Técnico**: __________________

---

**Última actualización**: 2025-11-07
**Versión del documento**: 1.0
