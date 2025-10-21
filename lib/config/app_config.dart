class AppConfig {
  // URL del backend - Cambiar según tu entorno
  // Para emulador Android: http://10.0.2.2:8000
  // Para iOS simulator: http://localhost:8000
  // Para dispositivo físico: http://TU-IP-LOCAL:8000
  // Para producción: https://tu-dominio.com
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Configuración de la app
  static const String appName = 'Inova MDM';
  static const String appVersion = '1.0.0';
}
