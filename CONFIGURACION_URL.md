# Configuración de URL - Inova App

## Cambios Realizados

### 1. AppConfig Mejorado (`lib/config/app_config.dart`)

Se actualizó el `AppConfig` para detectar automáticamente el entorno y usar la URL correcta según la plataforma:

**Detección Automática:**
- **Emulador Android**: `http://10.0.2.2:8000/api/v1`
- **iOS Simulator**: `http://localhost:8000/api/v1`
- **Dispositivo Físico (desarrollo)**: `http://192.168.16.115:8000/api/v1`
- **Producción**: `https://tu-dominio.com/api/v1`

**Características:**
- Detección automática del entorno (Debug vs Release)
- Detección automática de la plataforma (Android vs iOS)
- Posibilidad de sobrescribir la URL manualmente

### 2. ApiService Actualizado (`lib/services/api_service.dart`)

**Cambios principales:**

#### a) Uso de Configuración Dinámica
```dart
// ANTES (hardcoded)
final Dio _dio = Dio(BaseOptions(
  baseUrl: 'http://127.0.0.1:8000/api/v1',
  // ...
));

// DESPUÉS (dinámico)
late final Dio _dio;

ApiService() {
  _dio = Dio(BaseOptions(
    baseUrl: AppConfig.getBaseUrl(),
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
  ));
}
```

#### b) Logging Mejorado
Se agregó un interceptor para hacer debugging más fácil:
```dart
_dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
  logPrint: (obj) => print('🌐 API: $obj'),
));
```

#### c) Método verifyUnlockCode Corregido
```dart
// ANTES (endpoint incorrecto)
Future<Map<String, dynamic>> verifyUnlockCode(String deviceId, String code) async {
  final String endpoint = '/customer/devices/unlock-code/$deviceId';
  data: {'code': code},
}

// DESPUÉS (endpoint correcto)
Future<Map<String, dynamic>> verifyUnlockCode(String deviceCode, String code) async {
  final String endpoint = '/emm/unlock-code/$deviceCode';
  data: {'unlock_code': code},
}
```

**Cambios en el método:**
- ✅ Endpoint corregido: `/emm/unlock-code/{deviceCode}` (no requiere autenticación)
- ✅ Parámetro del body corregido: `unlock_code` en lugar de `code`
- ✅ Mejor manejo de errores con logging detallado
- ✅ Retorna la respuesta del servidor en caso de error para mostrar mensajes personalizados

## Cómo Usar

### Desarrollo en Emulador Android
```dart
// La configuración se detecta automáticamente
// URL usada: http://10.0.2.2:8000/api/v1
```

### Desarrollo en iOS Simulator
```dart
// La configuración se detecta automáticamente
// URL usada: http://localhost:8000/api/v1
```

### Desarrollo en Dispositivo Físico
```dart
// Asegúrate de que el dispositivo esté en la misma red WiFi
// La app usará: http://192.168.16.115:8000/api/v1

// Si tu IP es diferente, puedes cambiarla manualmente en app_config.dart
// Línea 16: return 'http://TU-IP-AQUI:8000/api/v1';
```

### Sobrescribir URL Manualmente
```dart
// En main.dart o donde inicialices la app:
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Sobrescribir la URL si es necesario
  AppConfig.setCustomBaseUrl('http://192.168.1.100:8000/api/v1');

  runApp(MyApp());
}
```

## Verificar la URL Actual

Para ver qué URL está usando tu app, revisa los logs. Cada petición ahora muestra:

```
🌐 API: *** Request ***
uri: http://10.0.2.2:8000/api/v1/customer/auth/login
method: POST
...
```

## Testing

### Test de Conexión Básico

Puedes probar la conexión desde la pantalla de login con credenciales de prueba:
- **Client ID**: `mobile-app-test`
- **Secret**: `test-secret-123`

Si la conexión es exitosa, verás en los logs:
```
🚀 Realizando petición de login a: /customer/auth/login
✅ Login exitoso
```

### Test de Desbloqueo

Para probar el nuevo método de verificación de código:
1. El dispositivo debe estar bloqueado
2. Ingresa un código de 5 dígitos
3. Los logs mostrarán:
```
🚀 Realizando petición a: /emm/unlock-code/DEVICE-CODE
🔑 Código de desbloqueo: 12345
✅ Respuesta de verificación: {...}
```

## Endpoints del Backend

Asegúrate de que tu backend Laravel esté corriendo en:
- **Local**: `http://127.0.0.1:8000` o `http://localhost:8000`
- **Red Local**: `http://192.168.16.115:8000` (o tu IP local)

Para verificar que el backend está activo:
```bash
php artisan serve --host=0.0.0.0 --port=8000
```

Luego prueba desde tu navegador:
```
http://localhost:8000/api/v1/customer/auth/login
```

## Troubleshooting

### Error: "Connection refused" o "Failed host lookup"

**Problema**: La app no puede conectarse al backend

**Soluciones**:

1. **Para Emulador Android**:
   - Verifica que el backend esté corriendo en `localhost:8000`
   - Usa `http://10.0.2.2:8000` (no `localhost` o `127.0.0.1`)

2. **Para iOS Simulator**:
   - Usa `http://localhost:8000` directamente

3. **Para Dispositivo Físico**:
   - Asegúrate de que el dispositivo y la computadora estén en la misma red WiFi
   - Verifica tu IP local: `ipconfig` (Windows) o `ifconfig` (Mac/Linux)
   - Usa `http://TU-IP-LOCAL:8000`
   - El backend debe estar sirviendo en todas las interfaces: `php artisan serve --host=0.0.0.0`

### Error: "timeout" en las peticiones

**Solución**: Aumenta los timeouts en `app_config.dart`:
```dart
static const Duration connectTimeout = Duration(seconds: 60);
static const Duration receiveTimeout = Duration(seconds: 60);
```

### Error 404 en endpoints

**Problema**: El endpoint no existe o la ruta es incorrecta

**Verificar**:
- La URL base termina en `/api/v1`
- Los endpoints no deben duplicar `/api/v1`
- Ejemplo correcto: base + `/customer/auth/login` = `http://10.0.2.2:8000/api/v1/customer/auth/login`

## Producción

Antes de compilar para producción:

1. **Actualiza la URL de producción** en `app_config.dart` línea 20:
   ```dart
   return 'https://tu-dominio-real.com/api/v1';
   ```

2. **Compila en modo Release**:
   ```bash
   flutter build apk --release
   # o
   flutter build appbundle --release
   ```

3. **Verifica que el modo debug esté desactivado** - El código usa `assert()` para detectarlo automáticamente.

## Notas Importantes

- ⚠️ **Nunca** commits credenciales o URLs de producción en el código
- ⚠️ Usa variables de entorno o archivos `.env` para configuraciones sensibles
- ✅ Los logs de API solo se muestran en modo debug
- ✅ La detección de entorno es automática y no requiere cambios manuales

---

**Última actualización**: 30 de Octubre, 2025
