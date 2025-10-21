import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inova_app/config/app_config.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Interceptor para agregar el token automáticamente
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        print('Error en API: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  // Guardar token de autenticación
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Obtener token guardado
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Login (para pruebas)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/customer/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.data['token'] != null) {
        await saveToken(response.data['token']);
      }

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Enrollar dispositivo
  Future<Map<String, dynamic>> enrollDevice(Map<String, dynamic> deviceData) async {
    try {
      final response = await _dio.post(
        '/customer/devices/enroll',
        data: deviceData,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Obtener lista de dispositivos
  Future<Map<String, dynamic>> getDevices() async {
    try {
      final response = await _dio.get('/customer/devices');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
