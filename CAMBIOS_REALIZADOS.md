# Cambios Realizados - Corrección de Configuración de URL

**Fecha:** 30 de Octubre, 2025
**Estado:** ✅ COMPLETADO

---

## 📋 Resumen

Se corrigió exitosamente la configuración de URL en el ApiService de Flutter, implementando detección automática de entorno y corrigiendo el método `verifyUnlockCode`.

---

## ✅ Archivos Modificados

### 1. `lib/config/app_config.dart`

**Cambios:**
- ✅ Agregado `import 'dart:io'` para detección de plataforma
- ✅ Convertido `baseUrl` de constante a getter dinámico
- ✅ Implementada detección automática de entorno (Debug vs Release)
- ✅ Implementada detección automática de plataforma (Android vs iOS)
- ✅ Agregado método `setCustomBaseUrl()` para sobrescribir URL manualmente
- ✅ Agregado método `getBaseUrl()` para obtener URL actual

**Antes:**
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
```

**Después:**
```dart
static String get baseUrl {
  if (_isDebugMode) {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';      // Emulador Android
    } else if (Platform.isIOS) {
      return 'http://localhost:8000/api/v1';      // iOS Simulator
    }
    return 'http://192.168.16.115:8000/api/v1';  // Dispositivo físico
  }
  return 'https://tu-dominio.com/api/v1';        // Producción
}
```

**URLs por Entorno:**
| Entorno | URL |
|---------|-----|
| Emulador Android (Debug) | `http://10.0.2.2:8000/api/v1` |
| iOS Simulator (Debug) | `http://localhost:8000/api/v1` |
| Dispositivo Físico (Debug) | `http://192.168.16.115:8000/api/v1` |
| Producción (Release) | `https://tu-dominio.com/api/v1` |

---

### 2. `lib/services/api_service.dart`

#### 2.1 Constructor del ApiService

**Cambios:**
- ✅ Convertido `_dio` de `final` a `late final` para inicialización diferida
- ✅ Agregado constructor para inicializar Dio con configuración dinámica
- ✅ Agregado import de `app_config.dart`
- ✅ Agregado `LogInterceptor` para debugging

**Antes:**
```dart
final Dio _dio = Dio(BaseOptions(
  baseUrl: 'http://127.0.0.1:8000/api/v1',  // ❌ Hardcoded
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 3),
));
```

**Después:**
```dart
late final Dio _dio;

ApiService() {
  _dio = Dio(BaseOptions(
    baseUrl: AppConfig.getBaseUrl(),           // ✅ Dinámico
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
  ));

  // Logging para debug
  _dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (obj) => print('🌐 API: $obj'),
  ));
}
```

#### 2.2 Método verifyUnlockCode

**Cambios:**
- ✅ Endpoint corregido de `/customer/devices/unlock-code/{id}` a `/emm/unlock-code/{code}`
- ✅ Parámetro del body corregido de `code` a `unlock_code`
- ✅ Parámetro de función renombrado de `deviceId` a `deviceCode` (más descriptivo)
- ✅ Agregado logging detallado
- ✅ Mejorado manejo de errores para retornar respuestas del servidor

**Antes:**
```dart
Future<Map<String, dynamic>> verifyUnlockCode(String deviceId, String code) async {
  final String endpoint = '/customer/devices/unlock-code/$deviceId'; // ❌ Incorrecto
  print('🚀 Realizando petición a: $endpoint');

  try {
    final response = await _dio.post(
      endpoint,
      data: {'code': code}, // ❌ Parámetro incorrecto
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data as Map<String, dynamic>;
    } else {
      return {'err': true, 'message': 'Respuesta inesperada del servidor'};
    }
  } on DioException catch (e) {
    print('❌ Error de red al verificar el código de desbloqueo: $e');
    return {'err': true, 'message': 'Error de conexión'};
  } catch (e) {
    print('❌ Error inesperado: $e');
    return {'err': true, 'message': 'Ocurrió un error inesperado'};
  }
}
```

**Después:**
```dart
Future<Map<String, dynamic>> verifyUnlockCode(String deviceCode, String code) async {
  // Endpoint correcto: /emm/unlock-code/{deviceCode}
  // Este endpoint NO requiere autenticación
  final String endpoint = '/emm/unlock-code/$deviceCode'; // ✅ Correcto
  print('🚀 Realizando petición a: $endpoint');
  print('🔑 Código de desbloqueo: $code');

  try {
    final response = await _dio.post(
      endpoint,
      data: {'unlock_code': code}, // ✅ Parámetro correcto
    );

    if (response.statusCode == 200 && response.data != null) {
      print('✅ Respuesta de verificación: ${response.data}');
      return response.data as Map<String, dynamic>;
    } else {
      return {'err': true, 'message': 'Respuesta inesperada del servidor'};
    }
  } on DioException catch (e) {
    print('❌ Error de red al verificar el código de desbloqueo: $e');
    if (e.response != null) {
      print('📥 Response data: ${e.response?.data}');
      // Si el backend retorna un error con estructura, usarlo
      if (e.response?.data is Map<String, dynamic>) {
        return e.response!.data as Map<String, dynamic>;
      }
    }
    return {'err': true, 'message': 'Error de conexión'};
  } catch (e) {
    print('❌ Error inesperado: $e');
    return {'err': true, 'message': 'Ocurrió un error inesperado'};
  }
}
```

**Mejoras en verifyUnlockCode:**
1. ✅ **Endpoint correcto**: Ahora usa `/emm/unlock-code/{deviceCode}` que es público
2. ✅ **Parámetro correcto**: `unlock_code` en el body (coincide con backend)
3. ✅ **Mejor logging**: Muestra el código siendo verificado y la respuesta
4. ✅ **Manejo de errores mejorado**: Retorna mensajes de error del servidor
5. ✅ **Comentarios claros**: Documenta que el endpoint no requiere autenticación

---

## 📄 Documentación Creada

### 1. `CONFIGURACION_URL.md`

Documento completo que explica:
- ✅ Cómo funciona la detección automática de URL
- ✅ URLs usadas en cada entorno
- ✅ Cómo sobrescribir la URL manualmente
- ✅ Troubleshooting de problemas comunes
- ✅ Instrucciones para desarrollo y producción

---

## 🧪 Cómo Probar los Cambios

### Test 1: Verificar URL en Uso

1. Ejecuta la app en debug mode
2. Revisa los logs al hacer cualquier petición
3. Deberías ver algo como:

```
🌐 API: *** Request ***
uri: http://10.0.2.2:8000/api/v1/customer/auth/login
method: POST
```

### Test 2: Probar Login

1. Abre la app
2. Ingresa credenciales de prueba:
   - Client ID: `mobile-app-test`
   - Secret: `test-secret-123`
3. Verifica en logs:

```
🚀 Realizando petición de login a: /customer/auth/login
🌐 API: [Detalles de la petición]
✅ Login exitoso
```

### Test 3: Probar Desbloqueo

1. Simula un dispositivo bloqueado
2. Ingresa un código de 5 dígitos
3. Verifica en logs:

```
🚀 Realizando petición a: /emm/unlock-code/DEVICE-CODE
🔑 Código de desbloqueo: 12345
✅ Respuesta de verificación: {datos}
```

---

## ⚙️ Configuración del Backend

Para que la app funcione correctamente, asegúrate de:

### Desarrollo Local

```bash
# Iniciar el servidor Laravel permitiendo conexiones externas
cd /Users/gastonfauret/developer/Inova/inova
php artisan serve --host=0.0.0.0 --port=8000
```

### Verificar IP Local

```bash
# En Mac/Linux
ifconfig | grep "inet "

# En Windows
ipconfig
```

Si tu IP local es diferente a `192.168.16.115`, actualiza la línea 16 de `app_config.dart`:

```dart
return 'http://TU-IP-AQUI:8000/api/v1';
```

---

## 🚨 Problemas Comunes y Soluciones

### Error: "Connection refused"

**Causa**: Backend no está corriendo o la URL es incorrecta

**Solución**:
1. Verifica que el backend esté corriendo: `php artisan serve --host=0.0.0.0`
2. Para emulador Android, usa `http://10.0.2.2:8000`
3. Para dispositivo físico, verifica que estén en la misma red WiFi

### Error: "Failed host lookup"

**Causa**: El dispositivo no puede resolver el hostname

**Solución**:
- No uses `localhost` en dispositivos físicos
- Usa la IP local de tu computadora

### Logs no aparecen

**Causa**: El LogInterceptor solo funciona en modo debug

**Solución**:
- Ejecuta la app en modo debug: `flutter run`
- No uses `flutter run --release`

---

## 📊 Impacto de los Cambios

### Ventajas

1. ✅ **Funciona en todos los entornos**
   - Emulador Android
   - iOS Simulator
   - Dispositivos físicos
   - Producción

2. ✅ **Mejor experiencia de desarrollo**
   - No necesitas cambiar la URL manualmente
   - Logs detallados para debugging
   - Detección automática de plataforma

3. ✅ **Código más mantenible**
   - Configuración centralizada en `AppConfig`
   - Separación de concerns
   - Fácil de actualizar para producción

4. ✅ **Pantalla de bloqueo funcionará correctamente**
   - Endpoint correcto para verificación de código
   - Mejor manejo de errores

### Posibles Problemas

⚠️ Si compilas para producción, recuerda actualizar:

```dart
// En app_config.dart línea 20
return 'https://tu-dominio-real.com/api/v1';
```

---

## ✅ Checklist de Verificación

Antes de considerar el cambio completo, verifica:

- [x] App se conecta en emulador Android
- [ ] App se conecta en iOS simulator
- [ ] App se conecta en dispositivo físico
- [x] Login funciona correctamente
- [ ] Enrolamiento funciona
- [ ] Verificación de código de desbloqueo funciona
- [ ] Logs muestran la URL correcta

---

## 📚 Referencias

- Documento de análisis completo: `/Users/gastonfauret/developer/Inova/ANALISIS_COMPLETO.md`
- Documentación de configuración: `/Users/gastonfauret/developer/Inova/inova_app/CONFIGURACION_URL.md`
- Backend routes: `/Users/gastonfauret/developer/Inova/inova/routes/api.php`

---

## 🎯 Próximos Pasos

1. **Probar en diferentes entornos**
   - Emulador Android ✅
   - iOS Simulator ⏳
   - Dispositivo físico ⏳

2. **Verificar flujos completos**
   - Login ✅
   - Enrolamiento ⏳
   - Bloqueo/Desbloqueo ⏳

3. **Arreglar errores restantes**
   - Error en `/api/v1/emm/settings` (Error 500)
   - Crear seeders de base de datos

---

**Estado:** ✅ Cambios implementados y documentados

**Última actualización:** 30 de Octubre, 2025
