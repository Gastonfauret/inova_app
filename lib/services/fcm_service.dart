import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;

  Future<void> initialize() async {
    // Solicitar permiso para notificaciones (importante para iOS y Android 13+)
    await _firebaseMessaging.requestPermission();

    // Obtener el token FCM
    _fcmToken = await _firebaseMessaging.getToken();
    print('✅ FCM Token: $_fcmToken');

    // Listener para cuando el token se refresca
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print('🔄 FCM Token refreshed: $_fcmToken');
      // Aquí podrías enviar el nuevo token a tu backend si es necesario
    });
  }

  String? get fcmToken => _fcmToken;

  // El resto de la lógica de FCM (manejo de notificaciones, etc.) que ya existía
  // o que se podría añadir iría aquí. Por ahora, nos centramos en obtener el token.
  Stream<Map<String, dynamic>> get commandStream => const Stream.empty(); // Placeholder
  Future<bool> isDeviceLocked() async => false; // Placeholder
  Future<Map<String, String>> getLockInfo() async => {'title': '', 'message': ''}; // Placeholder
}