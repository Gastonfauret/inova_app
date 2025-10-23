import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Handler para notificaciones en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Notificación en background: ${message.messageId}');

  final data = message.data;
  final command = data['command'];

  print('🔔 Comando recibido: $command');

  // Guardar el estado en SharedPreferences para que la app lo lea al abrirse
  final prefs = await SharedPreferences.getInstance();

  if (command == 'lock') {
    await prefs.setBool('device_locked', true);
    await prefs.setString('lock_title', data['title'] ?? 'Dispositivo bloqueado');
    await prefs.setString('lock_message', data['body'] ?? 'Su dispositivo ha sido bloqueado');
  } else if (command == 'unlock') {
    await prefs.setBool('device_locked', false);
  }
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Stream controller para comandos
  final StreamController<Map<String, dynamic>> _commandController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get commandStream => _commandController.stream;

  Future<void> initialize() async {
    try {
      // Solicitar permisos
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('✅ Permisos de notificación: ${settings.authorizationStatus}');

      // Configurar notificaciones locales
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('📲 Notificación tocada: ${response.payload}');
        },
      );

      // Obtener el token FCM
      String? token = await _firebaseMessaging.getToken();
      print('🔑 FCM Token: $token');

      // Guardar el token
      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString('fcm_token', token);
      }

      // Handler para mensajes en foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📨 Mensaje recibido en foreground: ${message.messageId}');
        _handleMessage(message);
      });

      // Handler para cuando la app se abre desde una notificación
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📬 App abierta desde notificación');
        _handleMessage(message);
      });

      // Configurar handler de background
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    } catch (e) {
      print('❌ Error al inicializar FCM: $e');
    }
  }

  void _handleMessage(RemoteMessage message) async {
    final data = message.data;
    final command = data['command'];

    print('🔔 Comando recibido: $command');
    print('📦 Data: $data');

    // Guardar estado en SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    switch (command) {
      case 'lock':
        await prefs.setBool('device_locked', true);
        await prefs.setString('lock_title', data['title'] ?? 'Dispositivo bloqueado');
        await prefs.setString('lock_message', data['body'] ?? 'Su dispositivo ha sido bloqueado');
        _showNotification(
          data['title'] ?? 'Dispositivo Bloqueado',
          data['body'] ?? 'Su dispositivo ha sido bloqueado por el administrador',
        );
        break;

      case 'unlock':
        await prefs.setBool('device_locked', false);
        _showNotification(
          data['title'] ?? 'Dispositivo Desbloqueado',
          data['body'] ?? 'Su dispositivo ha sido desbloqueado',
        );
        break;

      case 'notify':
        _showNotification(
          data['title'] ?? 'Notificación',
          data['body'] ?? 'Tienes una nueva notificación',
        );
        break;
    }

    // Emitir el comando al stream
    _commandController.add(data);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'inova_mdm_channel',
      'Inova MDM',
      channelDescription: 'Notificaciones del sistema MDM',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
    );
  }

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<bool> isDeviceLocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('device_locked') ?? false;
  }

  Future<Map<String, String>> getLockInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'title': prefs.getString('lock_title') ?? 'Dispositivo Bloqueado',
      'message': prefs.getString('lock_message') ?? 'Su dispositivo ha sido bloqueado',
    };
  }

  void dispose() {
    _commandController.close();
  }
}
