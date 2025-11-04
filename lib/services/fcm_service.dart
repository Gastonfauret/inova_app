import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Handler para mensajes en background (debe ser top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('\n🔔 MENSAJE FCM EN BACKGROUND');
  print('   - Message ID: ${message.messageId}');
  print('   - Data: ${message.data}');

  // Procesar el comando
  await FCMService.processCommand(message.data);
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;

  // StreamController para enviar comandos a la app
  final _commandStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get commandStream => _commandStreamController.stream;

  Future<void> initialize() async {
    print('\n╔════════════════════════════════════════╗');
    print('║  FCM SERVICE - INICIALIZACIÓN        ║');
    print('╚════════════════════════════════════════╝\n');

    try {
      // 1. Solicitar permisos
      print('📱 Solicitando permisos de notificaciones...');
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('✅ Permisos de notificaciones:');
      print('   - Authorization Status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('⚠️ ADVERTENCIA: Permisos denegados');
      }

      // 2. Configurar notificaciones locales
      await _initializeLocalNotifications();

      // 3. Obtener FCM token
      print('\n📲 Obteniendo FCM Token...');
      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        print('✅ FCM Token obtenido:');
        print('   - Token: $_fcmToken');
        print('   - Longitud: ${_fcmToken!.length} caracteres');
      } else {
        print('❌ ERROR: No se pudo obtener el FCM Token');
      }

      // 4. Configurar handler de background
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      print('✅ Handler de background configurado');

      // 5. Configurar handlers de foreground
      _configureForegroundHandlers();

      // 6. Listener de refresh de token
      print('\n🔄 Configurando listener de refresh...');
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('\n🔄 FCM Token refreshed: $_fcmToken');
        _updateTokenInBackend(newToken);
      });

      print('\n✅ FCM Service inicializado completamente');
      print('╚════════════════════════════════════════╝\n');

    } catch (e, stackTrace) {
      print('\n❌ ERROR AL INICIALIZAR FCM SERVICE');
      print('   - Mensaje: $e');
      print('   - Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      print('╚════════════════════════════════════════╝\n');
      rethrow;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    print('🔔 Inicializando notificaciones locales...');

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        print('👆 Usuario tocó la notificación: ${response.payload}');
      },
    );

    print('✅ Notificaciones locales inicializadas');
  }

  void _configureForegroundHandlers() {
    print('📱 Configurando handlers de foreground...');

    // Handler cuando la app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('\n🔔 MENSAJE FCM EN FOREGROUND');
      print('   - Message ID: ${message.messageId}');
      print('   - Título: ${message.notification?.title}');
      print('   - Cuerpo: ${message.notification?.body}');
      print('   - Data: ${message.data}');

      // Mostrar notificación local
      if (message.notification != null) {
        _showLocalNotification(message);
      }

      // Procesar comando
      processCommand(message.data).then((_) {
        // Emitir comando al stream para que la app lo procese
        _commandStreamController.add(message.data);
      });
    });

    // Handler cuando usuario toca notificación (app en background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('\n👆 USUARIO ABRIÓ APP DESDE NOTIFICACIÓN');
      print('   - Data: ${message.data}');

      // Procesar comando
      processCommand(message.data);
    });

    print('✅ Handlers de foreground configurados');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'mdm_channel',
      'MDM Commands',
      channelDescription: 'Comandos de gestión de dispositivo',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Inova MDM',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  // Procesar comandos MDM
  static Future<void> processCommand(Map<String, dynamic> data) async {
    print('\n⚙️ PROCESANDO COMANDO MDM');
    print('   - Data recibida: $data');

    if (!data.containsKey('command')) {
      print('⚠️ No hay comando en el mensaje');
      return;
    }

    final String command = data['command'].toString().toLowerCase();
    print('   - Comando: $command');

    final prefs = await SharedPreferences.getInstance();

    switch (command) {
      case 'lock':
        await _handleLockCommand(data, prefs);
        break;

      case 'unlock':
        await _handleUnlockCommand(prefs);
        break;

      case 'wipe':
        await _handleWipeCommand(prefs);
        break;

      case 'update_config':
        await _handleUpdateConfig(data, prefs);
        break;

      case 'heartbeat_request':
        await _handleHeartbeatRequest(prefs);
        break;

      default:
        print('⚠️ Comando desconocido: $command');
    }
  }

  static Future<void> _handleLockCommand(Map<String, dynamic> data, SharedPreferences prefs) async {
    print('🔒 COMANDO: BLOQUEAR DISPOSITIVO');

    final String title = data['title'] ?? 'Dispositivo Bloqueado';
    final String message = data['message'] ?? 'Este dispositivo ha sido bloqueado remotamente.';

    await prefs.setBool('device_locked', true);
    await prefs.setString('lock_title', title);
    await prefs.setString('lock_message', message);
    await prefs.setString('locked_at', DateTime.now().toIso8601String());

    print('✅ Dispositivo bloqueado');
    print('   - Título: $title');
    print('   - Mensaje: $message');
  }

  static Future<void> _handleUnlockCommand(SharedPreferences prefs) async {
    print('🔓 COMANDO: DESBLOQUEAR DISPOSITIVO');

    await prefs.setBool('device_locked', false);
    await prefs.remove('lock_title');
    await prefs.remove('lock_message');
    await prefs.remove('locked_at');

    print('✅ Dispositivo desbloqueado');
  }

  static Future<void> _handleWipeCommand(SharedPreferences prefs) async {
    print('⚠️ COMANDO: BORRAR DATOS DEL DISPOSITIVO');

    // Marcar para wipe
    await prefs.setBool('pending_wipe', true);
    await prefs.setString('wipe_scheduled_at', DateTime.now().toIso8601String());

    print('✅ Wipe programado - requiere reinicio de app');

    // Aquí podrías implementar el wipe real usando platform channels
    // para llamar a DevicePolicyManager.wipeData() desde Android
  }

  static Future<void> _handleUpdateConfig(Map<String, dynamic> data, SharedPreferences prefs) async {
    print('⚙️ COMANDO: ACTUALIZAR CONFIGURACIÓN');

    // Actualizar configuraciones recibidas
    data.forEach((key, value) async {
      if (key != 'command') {
        if (value is String) {
          await prefs.setString('config_$key', value);
        } else if (value is bool) {
          await prefs.setBool('config_$key', value);
        } else if (value is int) {
          await prefs.setInt('config_$key', value);
        }
        print('   - Actualizado: $key = $value');
      }
    });

    print('✅ Configuración actualizada');
  }

  static Future<void> _handleHeartbeatRequest(SharedPreferences prefs) async {
    print('💓 COMANDO: SOLICITUD DE HEARTBEAT');

    await prefs.setString('last_heartbeat_request', DateTime.now().toIso8601String());

    print('✅ Heartbeat registrado');
    // Aquí podrías enviar un heartbeat al backend inmediatamente
  }

  Future<void> _updateTokenInBackend(String newToken) async {
    print('📤 Actualizando token en backend...');

    // Aquí deberías llamar a tu API para actualizar el token
    // Por ejemplo:
    // await ApiService().updateFcmToken(newToken);

    print('✅ Token actualizado (implementar llamada al backend)');
  }

  // Verificar si el dispositivo está bloqueado
  Future<bool> isDeviceLocked() async {
    final prefs = await SharedPreferences.getInstance();
    final isLocked = prefs.getBool('device_locked') ?? false;

    print('🔍 Verificando estado de bloqueo: ${isLocked ? "BLOQUEADO" : "DESBLOQUEADO"}');

    return isLocked;
  }

  // Obtener información del bloqueo
  Future<Map<String, String>> getLockInfo() async {
    final prefs = await SharedPreferences.getInstance();

    final title = prefs.getString('lock_title') ?? 'Dispositivo Bloqueado';
    final message = prefs.getString('lock_message') ?? 'Este dispositivo ha sido bloqueado. Contacte al administrador.';

    return {
      'title': title,
      'message': message,
    };
  }

  // Getter del token
  String? get fcmToken {
    return _fcmToken;
  }

  // Limpiar recursos
  void dispose() {
    _commandStreamController.close();
  }
}
