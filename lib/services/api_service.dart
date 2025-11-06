import 'package:dio/dio.dart';
import 'package:inova_app/config/app_config.dart';
import 'package:inova_app/services/fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.getBaseUrl(),
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
    ));

    // Agregar interceptor para logging en modo debug
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('🌐 API: $obj'),
    ));
  }

  // Este método es el que se llamará desde la EnrollmentScreen
  Future<bool> enrollDevice({
    required String enrollmentCode,
    required String? deviceUid,
    required FCMService fcmService,
  }) async {
    print('\n════════════════════════════════════════');
    print('🚀 INICIANDO PROCESO DE ENROLLMENT');
    print('════════════════════════════════════════');

    // 1. Asegurarse de que tenemos los datos necesarios
    print('📋 Datos de entrada:');
    print('   - Enrollment Code: $enrollmentCode');
    print('   - Device UID (del Platform Channel): $deviceUid');

    final String? fcmToken = fcmService.fcmToken;
    print('   - FCM Token: ${fcmToken ?? "NULL"}');
    print('   - FCM Token length: ${fcmToken?.length ?? 0}');

    // Si no hay deviceUid del Platform Channel, usar el enrollment code como fallback
    String finalDeviceUid = deviceUid ?? enrollmentCode;
    print('\n🔧 Procesamiento:');
    print('   - Device UID final (después de fallback): $finalDeviceUid');

    if (finalDeviceUid.isEmpty) {
      print('❌ ERROR CRÍTICO: Device UID es nulo o vacío después del fallback.');
      return false;
    }

    if (fcmToken == null || fcmToken.isEmpty) {
      print('❌ ERROR CRÍTICO: FCM Token es nulo o vacío.');
      print('   - Verifica que Firebase esté inicializado correctamente');
      print('   - Verifica google-services.json');
      return false;
    }

    final String endpoint = '/emm/settings/$enrollmentCode/$finalDeviceUid/$fcmToken';
    final String fullUrl = '${AppConfig.getBaseUrl()}$endpoint';

    print('\n🌐 Información de conexión:');
    print('   - Base URL: ${AppConfig.getBaseUrl()}');
    print('   - Endpoint: $endpoint');
    print('   - URL Completa: $fullUrl');

    try {
      print('\n📤 Realizando petición GET al servidor...');
      final response = await _dio.get(endpoint);

      print('\n📥 Respuesta recibida:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Headers: ${response.headers}');
      print('   - Data Type: ${response.data.runtimeType}');
      print('   - Data: ${response.data}');

      // 3. Procesar la respuesta
      if (response.statusCode == 200 && response.data != null) {
        print('\n✅ RESPUESTA EXITOSA (200 OK)');
        print('📦 Datos recibidos del servidor:');
        print(response.data);

        // 4. Guardar la configuración y el estado de enrolamiento
        print('\n💾 Guardando configuración local...');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isEnrolled', true);
        await prefs.setString('device_code', enrollmentCode);
        print('   ✓ isEnrolled = true');
        print('   ✓ device_code = $enrollmentCode');

        // Opcional: Guardar cualquier configuración recibida del backend
        // El backend puede enviar los datos en dos formatos:
        // 1. Map directo: {key: value, ...}
        // 2. Lista de objetos: [{key: "name", value: "val"}, ...]

        Map<String, dynamic> settingsMap = {};

        if (response.data is List) {
          // Formato: [{key: "enterprise", value: "Gustavo Admin"}, ...]
          print('\n💾 Procesando configuraciones (formato lista)...');
          for (var item in response.data) {
            if (item is Map && item.containsKey('key') && item.containsKey('value')) {
              final key = item['key'];
              final value = item['value'];
              if (key != null && value != null) {
                settingsMap[key] = value;
              }
            }
          }
        } else if (response.data is Map<String, dynamic>) {
          // Formato: {enterprise: "Gustavo Admin", status: 1, ...}
          print('\n💾 Procesando configuraciones (formato map)...');
          settingsMap = response.data;
        }

        // Guardar todas las configuraciones
        if (settingsMap.isNotEmpty) {
          print('\n💾 Guardando configuraciones adicionales del servidor...');
          for (var entry in settingsMap.entries) {
            final key = entry.key;
            final value = entry.value;
            if (value is String) {
              await prefs.setString('setting_$key', value);
              print('   ✓ setting_$key (String) = $value');
            } else if (value is bool) {
              await prefs.setBool('setting_$key', value);
              print('   ✓ setting_$key (bool) = $value');
            } else if (value is int) {
              await prefs.setInt('setting_$key', value);
              print('   ✓ setting_$key (int) = $value');
            } else if (value != null) {
              // Para otros tipos, convertir a string
              await prefs.setString('setting_$key', value.toString());
              print('   ✓ setting_$key (${value.runtimeType}) = $value');
            }
          }
        }

        print('\n✅ ¡ENROLLMENT COMPLETADO EXITOSAMENTE!');
        print('════════════════════════════════════════\n');
        return true;
      } else {
        print('\n❌ ERROR: Respuesta inesperada del servidor');
        print('   - Status Code: ${response.statusCode}');
        print('   - Se esperaba 200, se recibió: ${response.statusCode}');
        print('════════════════════════════════════════\n');
        return false;
      }
    } on DioException catch (e) {
      print('\n❌ ERROR DE RED (DioException)');
      print('   - Tipo de error: ${e.type}');
      print('   - Mensaje: ${e.message}');

      if (e.response != null) {
        print('\n📥 Respuesta de error del servidor:');
        print('   - Status Code: ${e.response?.statusCode}');
        print('   - Status Message: ${e.response?.statusMessage}');
        print('   - Headers: ${e.response?.headers}');
        print('   - Data: ${e.response?.data}');
        print('   - Data Type: ${e.response?.data.runtimeType}');

        // Extraer mensaje específico si existe
        if (e.response?.data is Map) {
          final errorData = e.response?.data as Map;
          if (errorData.containsKey('error')) {
            print('\n⚠️ Mensaje de error del servidor:');
            print('   ${errorData['error']}');
          }
          if (errorData.containsKey('message')) {
            print('\n⚠️ Mensaje del servidor:');
            print('   ${errorData['message']}');
          }
        }
      } else {
        print('\n⚠️ No hay respuesta del servidor');
        print('   - Posibles causas:');
        print('     • Sin conexión a internet');
        print('     • El servidor no está disponible');
        print('     • Timeout de conexión');
        print('     • Problema de DNS');
      }

      print('════════════════════════════════════════\n');
      return false;
    } catch (e) {
      print('\n❌ ERROR INESPERADO');
      print('   - Tipo: ${e.runtimeType}');
      print('   - Mensaje: $e');
      print('   - Stack trace disponible en logs completos');
      print('════════════════════════════════════════\n');
      return false;
    }
  }

  // Placeholder para el método que la pantalla de enrolamiento usaba antes.
  // Lo dejamos para evitar errores de compilación, pero no se usará.
  Future<bool> validateEnrollmentCode(String code) async {
    return false;
  }

  Future<Map<String, dynamic>> verifyUnlockCode(String deviceCode, String code) async {
    // Endpoint correcto: /emm/unlock-code/{deviceCode}
    // Este endpoint NO requiere autenticación
    final String endpoint = '/emm/unlock-code/$deviceCode';
    print('🚀 Realizando petición a: $endpoint');
    print('🔑 Código de desbloqueo: $code');

    try {
      final response = await _dio.post(
        endpoint,
        data: {'unlock_code': code}, // Nombre correcto del parámetro
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

  // Actualizar FCM Token en el backend
  Future<bool> updateFcmToken(String deviceCode, String fcmToken) async {
    print('\n📤 ACTUALIZANDO FCM TOKEN EN BACKEND');
    print('   - Device Code: $deviceCode');
    print('   - FCM Token: ${fcmToken.substring(0, 20)}...');

    final String endpoint = '/emm/device/$deviceCode/fcm-token';

    try {
      final response = await _dio.put(
        endpoint,
        data: {'fcm_token': fcmToken},
      );

      if (response.statusCode == 200) {
        print('✅ FCM Token actualizado en backend');
        return true;
      } else {
        print('⚠️ Backend respondió con código: ${response.statusCode}');
        return false;
      }

    } catch (e) {
      print('❌ Error al actualizar FCM token: $e');
      return false;
    }
  }

  // Enviar heartbeat al backend
  Future<bool> sendHeartbeat(String deviceCode, Map<String, dynamic> data) async {
    print('\n💓 ENVIANDO HEARTBEAT AL BACKEND');
    print('   - Device Code: $deviceCode');
    print('   - Data keys: ${data.keys.join(", ")}');

    final String endpoint = '/emm/device/$deviceCode/heartbeat';

    try {
      final response = await _dio.post(
        endpoint,
        data: data,
      );

      if (response.statusCode == 200) {
        print('✅ Heartbeat enviado exitosamente');
        print('   - Response: ${response.data}');
        return true;
      } else {
        print('⚠️ Backend respondió con código: ${response.statusCode}');
        return false;
      }

    } catch (e) {
      print('❌ Error al enviar heartbeat: $e');
      return false;
    }
  }

  // Obtener configuración actualizada del dispositivo
  Future<Map<String, dynamic>?> getDeviceConfig(String deviceCode) async {
    print('\n⚙️ OBTENIENDO CONFIGURACIÓN DEL DISPOSITIVO');
    print('   - Device Code: $deviceCode');

    final String endpoint = '/emm/device/$deviceCode/config';

    try {
      final response = await _dio.get(endpoint);

      if (response.statusCode == 200 && response.data != null) {
        print('✅ Configuración obtenida');
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener configuración: $e');
      return null;
    }
  }

  // Reportar estado del dispositivo
  Future<bool> reportDeviceStatus(String deviceCode, Map<String, dynamic> status) async {
    print('\n📊 REPORTANDO ESTADO DEL DISPOSITIVO');
    print('   - Device Code: $deviceCode');
    print('   - Status: ${status['status']}');

    final String endpoint = '/emm/device/$deviceCode/status';

    try {
      final response = await _dio.post(
        endpoint,
        data: status,
      );

      if (response.statusCode == 200) {
        print('✅ Estado del dispositivo reportado exitosamente');
        print('   - Response: ${response.data}');
        return true;
      } else {
        print('⚠️ Backend respondió con código: ${response.statusCode}');
        return false;
      }

    } catch (e) {
      print('❌ Error al reportar estado: $e');
      return false;
    }
  }

  /// Login de cliente para enrollment
  /// Retorna el token de autenticación si es exitoso
  Future<String?> login({
    required String client,
    required String secret,
  }) async {
    print('\n🔐 LOGIN API');
    print('   - Client: $client');
    final String endpoint = '/customer/auth/login';

    try {
      final response = await _dio.post(
        endpoint,
        data: {
          'client': client,
          'secret': secret,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final token = response.data['token'];
        print('✅ Login exitoso, token recibido');
        return token;
      } else {
        print('⚠️ Login falló: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      print('❌ Error DioException en login: ${e.message}');
      if (e.response != null) {
        print('   - Status: ${e.response?.statusCode}');
        print('   - Data: ${e.response?.data}');
      }
      return null;
    } catch (e) {
      print('❌ Error general en login: $e');
      return null;
    }
  }

  /// Obtener lista de dispositivos del customer autenticado
  Future<List<dynamic>> getCustomerDevices() async {
    print('\n📱 OBTENIENDO DISPOSITIVOS DEL CUSTOMER');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      print('❌ No hay token de autenticación');
      throw Exception('No authenticated');
    }

    final String endpoint = '/customer/devices';

    try {
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        print('✅ Dispositivos obtenidos');

        // El backend puede retornar la lista directamente o en data.data
        if (response.data is List) {
          return response.data as List;
        } else if (response.data['data'] is List) {
          return response.data['data'] as List;
        } else {
          print('⚠️ Formato de respuesta inesperado');
          return [];
        }
      } else {
        print('⚠️ Backend respondió con: ${response.statusCode}');
        return [];
      }
    } on DioException catch (e) {
      print('❌ Error DioException al obtener dispositivos: ${e.message}');
      if (e.response != null) {
        print('   - Status: ${e.response?.statusCode}');
        print('   - Data: ${e.response?.data}');
      }
      throw Exception('Failed to load devices: ${e.message}');
    } catch (e) {
      print('❌ Error general al obtener dispositivos: $e');
      throw Exception('Failed to load devices: $e');
    }
  }
}
