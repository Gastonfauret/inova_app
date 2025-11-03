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
    // 1. Asegurarse de que tenemos los datos necesarios
    final String? fcmToken = fcmService.fcmToken;

    // Si no hay deviceUid del Platform Channel, usar el enrollment code como fallback
    String finalDeviceUid = deviceUid ?? enrollmentCode;
    if (finalDeviceUid.isEmpty) {
      print('❌ Error: Device UID es nulo o vacío.');
      return false;
    }

    if (fcmToken == null || fcmToken.isEmpty) {
      print('❌ Error: FCM Token es nulo o vacío.');
      return false;
    }

    print('📱 Using deviceUid: $finalDeviceUid');

    final String endpoint = '/emm/settings/$enrollmentCode/$finalDeviceUid/$fcmToken';
    print('🚀 Realizando petición a: $endpoint');

    try {
      // 2. Realizar la petición GET
      final response = await _dio.get(endpoint);

      // 3. Procesar la respuesta
      if (response.statusCode == 200 && response.data != null) {
        print('✅ Respuesta recibida del servidor:');
        print(response.data);

        // 4. Guardar la configuración y el estado de enrolamiento
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isEnrolled', true);
        await prefs.setString('device_code', enrollmentCode);

        // Opcional: Guardar cualquier configuración recibida del backend
        if (response.data is Map<String, dynamic>) {
          response.data.forEach((key, value) async {
            if (value is String) {
              await prefs.setString('setting_$key', value);
            } else if (value is bool) {
              await prefs.setBool('setting_$key', value);
            } else if (value is int) {
              await prefs.setInt('setting_$key', value);
            }
          });
        }
        
        print('💾 Dispositivo enrolado y configuración guardada.');
        return true;
      } else {
        print('❌ Error: El servidor respondió con un estado inesperado: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      print('❌ Error de red al intentar enrolar el dispositivo: $e');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
      }
      return false;
    } catch (e) {
      print('❌ Error inesperado: $e');
      return false;
    }
  }

  // Método de autenticación con client credentials
  Future<Map<String, dynamic>> login(String clientId, String secret) async {
    final String endpoint = '/customer/auth/login';
    print('🚀 Realizando petición de login a: $endpoint');

    try {
      final response = await _dio.post(
        endpoint,
        data: {
          'client': clientId,
          'secret': secret,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        print('✅ Login exitoso');

        // Guardar el token en SharedPreferences
        if (response.data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', response.data['token']);
        }

        return response.data as Map<String, dynamic>;
      } else {
        return {
          'token': null,
          'message': 'Respuesta inesperada del servidor'
        };
      }
    } on DioException catch (e) {
      print('❌ Error de autenticación: $e');
      if (e.response != null && e.response?.statusCode == 404) {
        return {
          'token': null,
          'message': 'Credenciales inválidas'
        };
      }
      return {
        'token': null,
        'message': 'Error de conexión'
      };
    } catch (e) {
      print('❌ Error inesperado: $e');
      return {
        'token': null,
        'message': 'Ocurrió un error inesperado'
      };
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
  }
  