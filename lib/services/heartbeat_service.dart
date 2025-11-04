import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inova_app/services/api_service.dart';
import 'package:inova_app/services/device_info_service.dart';
import 'package:inova_app/services/fcm_service.dart';

class HeartbeatService {
  Timer? _timer;
  final ApiService _apiService = ApiService();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  FCMService? _fcmService;

  // Intervalo de heartbeat (15 minutos por defecto)
  static const Duration defaultInterval = Duration(minutes: 15);

  bool _isRunning = false;
  DateTime? _lastHeartbeat;

  Future<void> start(FCMService? fcmService) async {
    if (_isRunning) {
      print('⚠️ Heartbeat ya está corriendo');
      return;
    }

    _fcmService = fcmService;
    _isRunning = true;

    print('\n╔════════════════════════════════════════╗');
    print('║  HEARTBEAT SERVICE - INICIO           ║');
    print('╚════════════════════════════════════════╝');
    print('⏰ Intervalo: ${defaultInterval.inMinutes} minutos');

    // Enviar heartbeat inicial
    await sendHeartbeat();

    // Configurar timer periódico
    _timer = Timer.periodic(defaultInterval, (timer) async {
      await sendHeartbeat();
    });

    print('✅ Heartbeat service iniciado');
    print('╚════════════════════════════════════════╝\n');
  }

  Future<void> sendHeartbeat() async {
    print('\n💓 ENVIANDO HEARTBEAT...');
    print('════════════════════════════════════════');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Verificar que el dispositivo esté enrolado
      final isEnrolled = prefs.getBool('isEnrolled') ?? false;
      if (!isEnrolled) {
        print('⚠️ Dispositivo no enrolado, saltando heartbeat');
        return;
      }

      // Obtener información del dispositivo
      final deviceCode = prefs.getString('device_code');
      final deviceId = await _deviceInfoService.getDeviceId();
      final deviceInfo = await _deviceInfoService.getDeviceInfo();
      final fcmToken = _fcmService?.fcmToken;

      if (deviceCode == null) {
        print('❌ No hay código de dispositivo, no se puede enviar heartbeat');
        return;
      }

      // Preparar datos del heartbeat
      final heartbeatData = {
        'device_code': deviceCode,
        'device_id': deviceId,
        'fcm_token': fcmToken,
        'device_info': deviceInfo,
        'status': 'active',
        'timestamp': DateTime.now().toIso8601String(),
        'battery_level': await _getBatteryLevel(),
        'is_locked': await _fcmService?.isDeviceLocked() ?? false,
        'last_sync': _lastHeartbeat?.toIso8601String(),
      };

      print('📦 Datos del heartbeat:');
      print('   - Device Code: $deviceCode');
      print('   - Device ID: $deviceId');
      print('   - Status: active');
      print('   - FCM Token: ${fcmToken != null ? "✅" : "❌"}');

      // Enviar heartbeat al backend
      final success = await _apiService.sendHeartbeat(deviceCode, heartbeatData);

      if (success) {
        // Guardar timestamp del último heartbeat
        _lastHeartbeat = DateTime.now();
        await prefs.setString('last_heartbeat', _lastHeartbeat!.toIso8601String());

        print('✅ Heartbeat enviado exitosamente');
        print('   - Timestamp: ${_lastHeartbeat!.toIso8601String()}');
      } else {
        print('⚠️ Heartbeat falló, se reintentará en el próximo ciclo');
      }

      print('════════════════════════════════════════\n');

    } catch (e, stackTrace) {
      print('❌ Error al enviar heartbeat: $e');
      print('   Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      print('════════════════════════════════════════\n');
    }
  }

  Future<int> _getBatteryLevel() async {
    // Placeholder - En producción usa battery_plus package
    // O implementa via platform channel
    return -1;
  }

  void stop() {
    if (!_isRunning) {
      return;
    }

    print('\n🛑 Deteniendo Heartbeat Service...');

    _timer?.cancel();
    _timer = null;
    _isRunning = false;

    print('✅ Heartbeat Service detenido\n');
  }

  bool get isRunning => _isRunning;
  DateTime? get lastHeartbeat => _lastHeartbeat;
}
