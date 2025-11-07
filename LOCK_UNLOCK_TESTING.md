# Guía de Testing - Lock/Unlock de Dispositivos

## Objetivo

Verificar que el flujo completo de bloqueo y desbloqueo de dispositivos funciona correctamente desde el panel web hasta la aplicación móvil.

---

## Requisitos Previos

### Backend (inova)
- ✅ Servidor Laravel funcionando
- ✅ Base de datos con dispositivo enrollado
- ✅ Firebase Cloud Messaging configurado
- ✅ Panel web accesible (Customer o Manager)

### App Móvil (inova_app)
- ✅ App instalada y enrollada en dispositivo Android
- ✅ FCM token registrado en backend
- ✅ Dispositivo con estado "Activo" (status = 1)
- ✅ Conexión a internet activa

### Credenciales de Testing
```
Panel Web:
- Usuario Customer: test@example.com
- Password: (tu contraseña)

Dispositivo:
- Device Code: 147760 (o el código que generaste)
```

---

## FLUJO 1: BLOQUEO REMOTO

### Test 1.1: Bloqueo desde Panel Web

**Objetivo**: Verificar que un dispositivo puede ser bloqueado remotamente desde el panel web.

**Pasos en Panel Web**:

1. **Login al Panel**
   ```
   - Ir a https://inova.up.railway.app (o tu servidor local)
   - Login como Customer o Manager
   - Navegar a "Dispositivos"
   ```

2. **Seleccionar Dispositivo**
   ```
   - Buscar el dispositivo de prueba
   - Verificar que su estado es "Activo"
   - Verificar que muestra último heartbeat reciente
   ```

3. **Ejecutar Bloqueo**
   ```
   - Click en botón "Bloquear" o icono de candado
   - (Opcional) Personalizar título y mensaje
   - Confirmar la acción
   ```

**Resultado Esperado en Panel Web**:
- ✅ Estado del dispositivo cambia a "Bloqueado" (status = 2)
- ✅ Timestamp de "última acción" se actualiza
- ✅ Se muestra mensaje de confirmación
- ✅ Badge o indicador visual de "Bloqueado"

**Verificación en Base de Datos**:
```sql
SELECT code, status, updated_at
FROM devices
WHERE code = '147760';

-- Debe mostrar:
-- status: 2 (LOCKED)
-- updated_at: timestamp reciente
```

---

### Test 1.2: Recepción en App Móvil

**Pasos en Dispositivo**:

1. **Observar la app** (debe estar abierta o en background)

**Resultado Esperado**:

**Si la app está en FOREGROUND**:
- ✅ Aparece notificación local con el mensaje
- ✅ La app detecta el comando automáticamente
- ✅ Se navega a LockScreen inmediatamente

**Si la app está en BACKGROUND**:
- ✅ Aparece notificación en la bandeja
- ✅ Al abrir la notificación, se procesa el comando
- ✅ Se navega a LockScreen

**Si la app está CERRADA**:
- ✅ Aparece notificación en la bandeja
- ✅ Al tocar la notificación, la app inicia
- ✅ La app detecta el estado bloqueado
- ✅ Se navega a LockScreen automáticamente

**Logs Esperados en Console** (si está conectado a Android Studio):
```
🔔 MENSAJE FCM EN FOREGROUND
   - Message ID: [ID]
   - Título: Dispositivo bloqueado
   - Cuerpo: Su dispositivo ha sido bloqueado...
   - Data: {command: lock, title: ..., body: ...}

⚙️ PROCESANDO COMANDO MDM
   - Data recibida: {...}
   - Comando: lock

🔒 COMANDO: BLOQUEAR DISPOSITIVO
✅ Dispositivo bloqueado
   - Título: Dispositivo bloqueado
   - Mensaje: Su dispositivo ha sido bloqueado...

📨 COMANDO RECIBIDO VIA FCM STREAM
   - Comando: lock
   - Dispositivo bloqueado via FCM
```

**Tiempo Estimado**: 2-10 segundos (depende de FCM)

---

### Test 1.3: Verificar LockScreen

**Objetivo**: Verificar que LockScreen se muestra correctamente y previene el uso del dispositivo.

**Elementos Visuales**:
- ✅ Pantalla roja de fondo
- ✅ Icono de candado grande y blanco
- ✅ Título personalizado (o "Dispositivo Bloqueado")
- ✅ Mensaje personalizado del bloqueo
- ✅ Campo para código de desbloqueo (5 dígitos)
- ✅ Botón "Verificar Código"
- ✅ Información de contacto al vendedor

**Comportamiento**:
- ✅ Botón de "Atrás" no funciona (canPop: false)
- ✅ Barra de navegación oculta (fullscreen)
- ✅ No se puede salir de la pantalla
- ✅ Solo se puede desbloquear con código válido

**Verificar SharedPreferences**:
```bash
# Si tienes acceso a adb:
adb shell run-as inova.guard.mdm cat /data/data/inova.guard.mdm/shared_prefs/FlutterSecureStorage.xml | grep device_locked

# Debe mostrar:
# device_locked: true
# lock_title: Dispositivo bloqueado
# lock_message: [mensaje personalizado]
# locked_at: [timestamp ISO8601]
```

---

## FLUJO 2: DESBLOQUEO CON CÓDIGO

### Test 2.1: Generar Código de Desbloqueo

**Objetivo**: Generar un código temporal de 5 dígitos desde el panel web.

**Pasos en Panel Web**:

1. **Seleccionar dispositivo bloqueado**
   ```
   - Ir a "Dispositivos"
   - Buscar dispositivo con estado "Bloqueado"
   - Click en el dispositivo
   ```

2. **Generar código**
   ```
   - Click en "Generar Código de Desbloqueo"
   - Configurar validez (ej: 7 días)
   - Click en "Generar"
   ```

3. **Copiar código**
   ```
   - Se muestra código de 5 dígitos (ej: 12345)
   - Copiar el código
   - Nota: El código es válido por X días
   ```

**Resultado Esperado**:
- ✅ Se genera código aleatorio de 5 dígitos
- ✅ Se muestra en pantalla
- ✅ Se registra en sistema con fecha de expiración

**Verificación en Backend** (logs):
```bash
# En Laravel logs:
[INFO] Código de desbloqueo generado
   - Device Code: 147760
   - Unlock Code: 12345
   - Valid Until: 2025-11-14
```

---

### Test 2.2: Ingresar Código Incorrecto

**Objetivo**: Verificar validación de código incorrecto.

**Pasos en Dispositivo**:

1. En LockScreen, ingresar código incorrecto: `99999`
2. Click en "Verificar Código"

**Resultado Esperado**:
- ✅ Se muestra spinner de carga
- ✅ Llamada al endpoint `/emm/unlock-code/147760`
- ✅ Backend retorna error 401
- ✅ Se muestra mensaje: "Código de desbloqueo inválido o expirado"
- ✅ El dispositivo permanece bloqueado

**Logs en App**:
```
🔓 Attempting to unlock device 147760 with code 99999
📥 Unlock response: {err: true, message: "Código de desbloqueo inválido o expirado"}
❌ Invalid unlock code: Código de desbloqueo inválido o expirado
```

**Logs en Backend**:
```
[WARNING] Invalid unlock code attempt
   - device_code: 147760
   - attempted_code: 99999
   - ip: 192.168.1.100
```

---

### Test 2.3: Ingresar Código Correcto

**Objetivo**: Verificar desbloqueo exitoso con código válido.

**Pasos en Dispositivo**:

1. En LockScreen, ingresar código correcto: `12345`
2. Click en "Verificar Código"

**Resultado Esperado**:
- ✅ Se muestra spinner de carga
- ✅ Llamada al endpoint `/emm/unlock-code/147760`
- ✅ Backend valida y retorna éxito
- ✅ Device::unlock() se ejecuta en backend
- ✅ Se envía notificación FCM con command: 'unlock'
- ✅ SharedPreferences actualizado (device_locked = false)
- ✅ LockScreen se cierra
- ✅ Se navega a HomeScreen
- ✅ Dispositivo funcional nuevamente

**Logs en App**:
```
🔓 Attempting to unlock device 147760 with code 12345
📥 Unlock response: {err: false, message: "Device unlocked"}
✅ Device unlocked successfully

🔔 MENSAJE FCM EN FOREGROUND
   - Comando: unlock

🔓 COMANDO: DESBLOQUEAR DISPOSITIVO
✅ Dispositivo desbloqueado

📨 COMANDO RECIBIDO VIA FCM STREAM
   - Comando: unlock
   - Dispositivo desbloqueado via FCM
```

**Verificación en Base de Datos**:
```sql
SELECT code, status, updated_at
FROM devices
WHERE code = '147760';

-- Debe mostrar:
-- status: 1 (ACTIVE)
-- updated_at: timestamp reciente
```

**Tiempo Estimado**: 2-5 segundos

---

## FLUJO 3: DESBLOQUEO DIRECTO DESDE PANEL WEB

### Test 3.1: Desbloqueo sin Código

**Objetivo**: Verificar que Manager/Admin puede desbloquear directamente sin código.

**Pasos en Panel Web**:

1. **Seleccionar dispositivo bloqueado**
   ```
   - Ir a "Dispositivos"
   - Buscar dispositivo con estado "Bloqueado"
   - Click en el dispositivo
   ```

2. **Ejecutar Desbloqueo**
   ```
   - Click en botón "Desbloquear" o icono de candado abierto
   - Confirmar la acción
   ```

**Resultado Esperado en Panel Web**:
- ✅ Estado del dispositivo cambia a "Activo" (status = 1)
- ✅ Se muestra mensaje de confirmación
- ✅ Badge o indicador visual de "Activo"

**Resultado Esperado en Dispositivo**:
- ✅ Llega notificación FCM con command: 'unlock'
- ✅ Si está en LockScreen, se cierra automáticamente
- ✅ SharedPreferences actualizado (device_locked = false)
- ✅ Se navega a HomeScreen

**Logs en App**:
```
🔔 MENSAJE FCM EN FOREGROUND
   - Comando: unlock

🔓 COMANDO: DESBLOQUEAR DISPOSITIVO
✅ Dispositivo desbloqueado

📨 COMANDO RECIBIDO VIA FCM STREAM
   - Comando: unlock
   - Dispositivo desbloqueado via FCM
```

---

## FLUJO 4: REINICIO DE APP CON DISPOSITIVO BLOQUEADO

### Test 4.1: Reiniciar App Bloqueada

**Objetivo**: Verificar que la app detecta estado bloqueado al iniciar.

**Pasos**:

1. Dispositivo está bloqueado (LockScreen visible)
2. Cerrar la app completamente (force stop)
3. Abrir la app nuevamente

**Resultado Esperado**:
- ✅ App inicia normalmente
- ✅ En main.dart, lee SharedPreferences
- ✅ Detecta device_locked = true
- ✅ Navega directamente a LockScreen
- ✅ No muestra HomeScreen

**Logs en Console**:
```
╔════════════════════════════════════════╗
║       INOVA MDM - INICIO DE APP      ║
╚════════════════════════════════════════╝

💾 Verificando estado de enrollment...
📊 Estado de SharedPreferences:
   - isEnrolled: true
   - device_code: 147760

🔍 Verificando estado de bloqueo: BLOQUEADO

🚀 Navegando a LockScreen...
```

---

## FLUJO 5: TESTING DE CASOS EXTREMOS

### Test 5.1: Dispositivo Sin Conexión

**Escenario**: Dispositivo bloqueado pero sin internet.

**Pasos**:
1. Bloquear dispositivo desde panel web
2. Desactivar WiFi y datos móviles en dispositivo
3. Intentar ingresar código de desbloqueo

**Resultado Esperado**:
- ✅ Notificación FCM no llega (sin internet)
- ✅ Al intentar verificar código, muestra error de conexión
- ✅ Mensaje: "Error al verificar el código. Verifique su conexión a Internet."
- ✅ Dispositivo permanece bloqueado

---

### Test 5.2: Código Expirado

**Escenario**: Intentar usar código después de su fecha de expiración.

**Pasos**:
1. Generar código con validez de 7 días
2. Modificar manualmente la fecha en backend (opcional, para testing rápido)
3. Intentar usar el código

**Resultado Esperado**:
- ✅ Backend valida fecha de expiración
- ✅ Retorna error: "Código de desbloqueo inválido o expirado"
- ✅ Dispositivo permanece bloqueado

---

### Test 5.3: Múltiples Intentos de Código

**Escenario**: Probar protección contra fuerza bruta.

**Pasos**:
1. Ingresar código incorrecto 5 veces consecutivas
2. Observar comportamiento

**Resultado Esperado**:
- ✅ Cada intento es validado por el backend
- ✅ Backend registra intentos fallidos en logs
- ✅ (Opcional) Backend puede bloquear temporalmente después de X intentos

---

## CHECKLIST DE VERIFICACIÓN FINAL

### Backend
- [ ] Dispositivo cambia status correctamente (1 ↔ 2)
- [ ] FCM notificación se envía sin errores
- [ ] Logs muestran comandos lock/unlock
- [ ] API endpoint `/emm/unlock-code/{code}` funciona
- [ ] Código de desbloqueo se genera correctamente
- [ ] Validación de código funciona

### App Móvil
- [ ] FCM service recibe notificaciones
- [ ] Comando 'lock' se procesa correctamente
- [ ] Comando 'unlock' se procesa correctamente
- [ ] LockScreen se muestra en bloqueo
- [ ] LockScreen previene navegación
- [ ] Código incorrecto muestra error
- [ ] Código correcto desbloquea
- [ ] App detecta estado al reiniciar
- [ ] Navegación automática funciona

### UX
- [ ] Mensajes de error son claros
- [ ] Feedback visual es inmediato
- [ ] Tiempo de respuesta < 10 segundos
- [ ] No hay bloqueos o crashes
- [ ] UI responde correctamente

---

## MÉTRICAS DE ÉXITO

| Métrica | Objetivo | Resultado |
|---------|----------|-----------|
| Latencia FCM (lock) | < 10 seg | ______ seg |
| Latencia FCM (unlock) | < 10 seg | ______ seg |
| Tiempo verificación código | < 5 seg | ______ seg |
| Tasa de éxito FCM | > 95% | ______% |
| Intentos hasta desbloqueo | 1-2 intentos | ______ |

---

## LOGS COMPLETOS PARA DEBUGGING

### Verificar FCM Token
```bash
# En la app, buscar en logs:
✅ FCM Token obtenido:
   - Token: [TOKEN_LARGO]
```

### Verificar en Firebase Console
```
1. Ir a Firebase Console
2. Cloud Messaging → Enviar mensaje de prueba
3. Pegar FCM token
4. Enviar mensaje de prueba
5. Verificar que llega a la app
```

### Verificar Estado en SharedPreferences
```bash
# Conectar dispositivo con adb
adb devices

# Ver SharedPreferences
adb shell run-as inova.guard.mdm
cd shared_prefs
cat FlutterSecureStorage.xml

# Buscar:
# - device_locked: true/false
# - lock_title: [título]
# - lock_message: [mensaje]
```

---

## TROUBLESHOOTING COMÚN

| Problema | Causa Probable | Solución |
|----------|----------------|----------|
| FCM no llega | Token no registrado o inválido | Verificar FCM token en BD, reiniciar app |
| Código no válido siempre | Código expirado o no generado | Generar nuevo código en panel |
| LockScreen no aparece | Estado no sincronizado | Verificar SharedPreferences |
| No puede desbloquear | Error en API o sin conexión | Verificar logs del backend y conexión |
| App crashea al bloquear | Excepción no capturada | Revisar logs de Dart/Flutter |

---

## EVIDENCIA DE TESTING

**Capturas de Pantalla Requeridas**:
1. Panel web - Dispositivo activo
2. Panel web - Acción de bloqueo
3. Panel web - Dispositivo bloqueado
4. App - Notificación FCM recibida
5. App - LockScreen mostrado
6. Panel web - Generación de código
7. App - Ingreso de código
8. App - Código incorrecto (error)
9. App - Código correcto (desbloqueo)
10. App - HomeScreen después de desbloqueo

---

## REPORTE FINAL DE TESTING

**Fecha de testing**: __________
**Tester**: __________
**Dispositivo**: __________
**Versión de Android**: __________
**Versión de App**: 1.0.0+1

### Resultados

**Flujo 1 - Bloqueo Remoto**:
- Test 1.1: [ ] Pasó  [ ] Falló
- Test 1.2: [ ] Pasó  [ ] Falló
- Test 1.3: [ ] Pasó  [ ] Falló

**Flujo 2 - Desbloqueo con Código**:
- Test 2.1: [ ] Pasó  [ ] Falló
- Test 2.2: [ ] Pasó  [ ] Falló
- Test 2.3: [ ] Pasó  [ ] Falló

**Flujo 3 - Desbloqueo Directo**:
- Test 3.1: [ ] Pasó  [ ] Falló

**Flujo 4 - Reinicio de App**:
- Test 4.1: [ ] Pasó  [ ] Falló

**Flujo 5 - Casos Extremos**:
- Test 5.1: [ ] Pasó  [ ] Falló
- Test 5.2: [ ] Pasó  [ ] Falló
- Test 5.3: [ ] Pasó  [ ] Falló

**Tests aprobados**: _____ / 11
**Tests fallidos**: _____ / 11

### Observaciones
__________________________________________________
__________________________________________________
__________________________________________________

### ¿El flujo de lock/unlock está listo para producción?
- [ ] Sí, todos los tests críticos pasaron
- [ ] No, se requieren correcciones (especificar)

---

**Firma del Tester**: __________________
**Fecha**: __________________

---

**Última actualización**: 2025-11-07
**Versión del documento**: 1.0
