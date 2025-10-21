# Guía de Testing - Enrollment de Dispositivos

## Configuración Previa

### 1. Configurar el Backend (Laravel)

```bash
cd inova

# Asegurarse de que el servidor esté corriendo
php artisan serve

# En otra terminal, ejecutar el worker de colas
php artisan queue:listen --tries=1
```

### 2. Preparar Base de Datos

Necesitas tener en la base de datos:
- Un usuario customer con credenciales conocidas
- Una empresa (GoogleEnterprise) asociada al customer

```sql
-- Ejemplo de verificación
SELECT * FROM users WHERE email = 'customer@test.com';
SELECT * FROM customers;
SELECT * FROM google_enterprises;
```

### 3. Configurar la App Flutter

Edita `lib/services/api_service.dart` y cambia la URL del servidor:

```dart
// Para emulador Android (apunta a localhost de tu PC)
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

// Para dispositivo físico (usa la IP de tu PC en la red local)
static const String baseUrl = 'http://TU-IP-LOCAL:8000/api/v1';
// Ejemplo: static const String baseUrl = 'http://192.168.1.100:8000/api/v1';

// Para iOS simulator
static const String baseUrl = 'http://localhost:8000/api/v1';
```

## Prueba del Enrollment

### Opción 1: Con Token de Prueba (Más Fácil)

1. Obtén un token de autenticación desde Postman o curl:

```bash
curl -X POST http://localhost:8000/api/v1/customer/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "customer@test.com",
    "password": "password"
  }'
```

2. Guarda el token manualmente en la app:

Modifica temporalmente `enrollment_screen.dart` para guardar el token:

```dart
@override
void initState() {
  super.initState();
  _saveTestToken(); // Agregar esta línea
  _loadDeviceInfo();
}

Future<void> _saveTestToken() async {
  // Reemplaza con tu token real
  await _apiService.saveToken('TU_TOKEN_AQUI');
}
```

### Opción 2: Implementar Login en la App

Puedes crear una pantalla de login temporal usando el método `login()` del ApiService.

## Pasos para Probar

1. **Iniciar el backend**:
   ```bash
   cd inova
   php artisan serve
   ```

2. **Ejecutar la app Flutter**:
   ```bash
   cd inova_app
   flutter run
   ```

3. **Verificar la información del dispositivo**:
   - La app debe mostrar automáticamente la información del dispositivo
   - Verifica que los datos sean correctos (marca, modelo, etc.)

4. **Presionar "Enrollar Dispositivo"**:
   - La app enviará los datos al backend
   - Debes ver un diálogo de éxito con el código de dispositivo

5. **Verificar en la base de datos**:
   ```sql
   SELECT * FROM devices ORDER BY created_at DESC LIMIT 1;
   ```

## Troubleshooting

### Error de conexión

Si ves errores de conexión:
- Verifica que `php artisan serve` esté corriendo
- Confirma que la URL en `api_service.dart` sea correcta
- En emulador Android, usa `10.0.2.2` en lugar de `localhost`
- En dispositivo físico, asegúrate de estar en la misma red WiFi

### Error 401 (Unauthorized)

- Verifica que el token esté guardado correctamente
- Comprueba que el customer exista y esté activo
- Revisa que el middleware de autenticación esté funcionando

### Error 500 del servidor

Verifica los logs de Laravel:
```bash
cd inova
tail -f storage/logs/laravel.log
```

### No se obtiene información del dispositivo

En Android >= 10, el IMEI no está disponible por restricciones de seguridad.
La app usa el Android ID como alternativa.

## Verificar Resultados

### En la App

Deberías ver:
- ✅ Información del dispositivo cargada
- ✅ Botón "Enrollar Dispositivo" habilitado
- ✅ Diálogo de éxito después del enrollment
- ✅ Código de dispositivo de 6 dígitos

### En el Backend

```bash
# Ver el último dispositivo enrollado
cd inova
php artisan tinker

>>> \App\Models\Device::latest()->first()
```

### En la Base de Datos

```sql
-- Ver todos los dispositivos
SELECT id, code, device, brand, model, status, customer_id, created_at
FROM devices
ORDER BY created_at DESC
LIMIT 5;

-- Verificar el enrollment más reciente
SELECT d.*, c.name as customer_name
FROM devices d
JOIN customers c ON d.customer_id = c.id
ORDER BY d.created_at DESC
LIMIT 1;
```

## Prueba Completa End-to-End

1. Backend corriendo ✅
2. App Flutter ejecutándose ✅
3. Token de autenticación guardado ✅
4. Información del dispositivo mostrada ✅
5. Enrollment exitoso ✅
6. Código generado en el backend ✅
7. Registro en base de datos ✅
8. Status del dispositivo = 1 (ACTIVE) ✅

## Datos de Prueba Recomendados

### Crear un Customer de Prueba

```sql
-- Insertar un customer de prueba si no existe
INSERT INTO users (name, email, password, role, created_at, updated_at)
VALUES ('Customer Test', 'customer@test.com', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'customer', NOW(), NOW());

-- Password: 'password'
```

## Métricas de Éxito

- ✅ Tiempo de respuesta < 2 segundos
- ✅ Código de 6 dígitos único generado
- ✅ Status = 1 (ACTIVE)
- ✅ customer_id y enterprise_id asignados correctamente
- ✅ Todos los campos del dispositivo guardados
