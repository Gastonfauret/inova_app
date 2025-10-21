# Configuración de Inova App

## Cambios Realizados

Se ha limpiado el código de prueba y configurado la aplicación para conectarse con el backend Laravel en producción.

### Archivos Modificados

1. **`lib/main.dart`**
   - Cambiada la pantalla inicial de `EnrollmentScreen` a `LoginScreen`
   - Agregado uso de `AppConfig` para configuración centralizada

2. **`lib/screens/enrollment_screen.dart`**
   - Eliminado el método `_saveTestToken()` que guardaba un token hardcodeado
   - Eliminada la llamada a `_saveTestToken()` en `initState()`

3. **`lib/services/api_service.dart`**
   - Eliminadas URLs hardcodeadas y comentarios de configuración manual
   - Ahora usa `AppConfig` para la URL base y timeouts

### Archivos Nuevos

1. **`lib/config/app_config.dart`**
   - Configuración centralizada de la aplicación
   - Define la URL base del backend
   - Configuración de timeouts y constantes de la app

2. **`lib/screens/login_screen.dart`**
   - Pantalla de login funcional con validación
   - Conecta con el endpoint `/api/v1/customer/auth/login`
   - Maneja errores de autenticación
   - Navega a `EnrollmentScreen` después del login exitoso

## Configuración del Backend

### Cambiar la URL del Backend

Edita el archivo `lib/config/app_config.dart` y modifica la constante `baseUrl`:

```dart
class AppConfig {
  // Opciones según tu entorno:

  // Para emulador Android (localhost del host)
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // Para iOS simulator (localhost)
  // static const String baseUrl = 'http://localhost:8000/api/v1';

  // Para dispositivo físico (usar IP de tu computadora)
  // static const String baseUrl = 'http://192.168.1.100:8000/api/v1';

  // Para producción
  // static const String baseUrl = 'https://tu-dominio.com/api/v1';
}
```

### Obtener tu IP Local

**Windows:**
```bash
ipconfig
# Busca "IPv4 Address" en tu adaptador de red activo
```

**macOS/Linux:**
```bash
ifconfig
# o
ip addr show
```

## Flujo de la Aplicación

1. **Login** (`LoginScreen`)
   - Usuario ingresa email y contraseña
   - Se validan los campos
   - Se envía petición a `/api/v1/customer/auth/login`
   - Si es exitoso, se guarda el token y navega a Enrollment

2. **Enrollment** (`EnrollmentScreen`)
   - Obtiene información del dispositivo
   - Muestra los datos al usuario
   - Permite enrollar el dispositivo en el sistema MDM
   - Requiere autenticación previa (token guardado)

## Pruebas

### Requisitos previos

1. El backend Laravel debe estar corriendo:
   ```bash
   cd inova
   composer dev  # o php artisan serve
   ```

2. Debes tener un usuario de tipo "Customer" creado en la base de datos

### Ejecutar la app

```bash
cd inova_app

# Instalar dependencias
flutter pub get

# Ejecutar en emulador/dispositivo
flutter run

# Ejecutar en web (para desarrollo rápido)
flutter run -d chrome
```

### Credenciales de prueba

Usa las credenciales de un cliente registrado en el backend Laravel:
- Email: (del cliente en la base de datos)
- Password: (del cliente en la base de datos)

## Endpoints del Backend Utilizados

- **POST** `/api/v1/customer/auth/login`
  - Body: `{ "email": "...", "password": "..." }`
  - Response: `{ "err": false, "token": "...", "data": {...} }`

- **POST** `/api/v1/customer/devices/enroll`
  - Headers: `Authorization: Bearer {token}`
  - Body: `{ "device": "...", "brand": "...", "model": "...", ... }`
  - Response: `{ "err": false, "data": {...} }`

- **GET** `/api/v1/customer/devices`
  - Headers: `Authorization: Bearer {token}`
  - Response: `{ "err": false, "data": [...] }`

## Notas Importantes

- El token se guarda automáticamente en SharedPreferences después del login
- El interceptor de Dio agrega el token automáticamente a todas las peticiones
- La URL base se debe cambiar según el entorno (desarrollo/producción)
- Para dispositivos físicos, asegúrate de que el dispositivo y el servidor estén en la misma red
