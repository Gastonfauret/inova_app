import 'dart:io';

class AppConfig {
  // URL del backend - Se detecta automáticamente según el entorno
  static String get baseUrl {
    // CONFIGURACIÓN: Cambiar esto a 'true' para usar servidor local en debug
    const bool useLocalServer = false;

    // En modo debug, detectar el entorno
    if (_isDebugMode && useLocalServer) {
      if (Platform.isAndroid) {
        // Para emulador Android: 10.0.2.2 apunta a localhost de la máquina host
        return 'http://10.0.2.2:8000/api/v1';
      } else if (Platform.isIOS) {
        // Para iOS simulator: localhost funciona directamente
        return 'http://localhost:8000/api/v1';
      }
      // Para dispositivos físicos en la misma red
      // return 'http://192.168.16.115:8000/api/v1';
    }

    // En todos los demás casos (debug sin local server, o producción), usar Railway
    return 'https://inova.up.railway.app/api/v1';
  }

  // Detectar si estamos en modo debug
  static bool get _isDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Configuración de la app
  static const String appName = 'Inova MDM';
  static const String appVersion = '1.0.0';

  // Para sobrescribir la URL manualmente si es necesario
  static String? _customBaseUrl;

  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url;
  }

  static String getBaseUrl() {
    return _customBaseUrl ?? baseUrl;
  }
}
