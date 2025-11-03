
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:inova_app/config/app_config.dart';
import 'package:inova_app/screens/enrollment_screen.dart';
import 'package:inova_app/screens/home_screen.dart';
import 'package:inova_app/screens/lock_screen.dart';
import 'package:inova_app/services/fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  WidgetsFlutterBinding.ensureInitialized();

  FCMService? fcmService;
  try {
    await Firebase.initializeApp();
    print('✅ Firebase inicializado correctamente');
    fcmService = FCMService();
    await fcmService.initialize();
  } catch (e) {
    print('❌ Error al inicializar Firebase: $e');
    print('⚠️ La app funcionará sin notificaciones FCM');
  }

  // Chequea si el dispositivo ya está enrolado
  final prefs = await SharedPreferences.getInstance();
  final bool isEnrolled = prefs.getBool('isEnrolled') ?? false;

  runApp(MyApp(fcmService: fcmService, isEnrolled: isEnrolled));
}

class MyApp extends StatefulWidget {
  final FCMService? fcmService;
  final bool isEnrolled;

  const MyApp({super.key, this.fcmService, required this.isEnrolled});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static const platform = MethodChannel('inova.guard.mdm/provisioning');
  String? _deviceCode;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Solo realizar estas acciones si el dispositivo está enrolado
    if (widget.isEnrolled) {
      _getDeviceCodeFromNative();
      _checkLockStatus();

      if (widget.fcmService != null) {
        widget.fcmService!.commandStream.listen((command) {
          if (command['command'] == 'lock') {
            setState(() {
              _isLocked = true;
            });
          } else if (command['command'] == 'unlock') {
            setState(() {
              _isLocked = false;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.isEnrolled && state == AppLifecycleState.resumed) {
      _checkLockStatus();
    }
  }

  Future<void> _getDeviceCodeFromNative() async {
    try {
      final String? code = await platform.invokeMethod('getDeviceCode');
      if (code != null && mounted) {
        print('✅ DeviceCode recibido de Kotlin: $code');
        setState(() {
          _deviceCode = code;
        });
      }
    } on PlatformException catch (e) {
      print("❌ Error al obtener deviceCode: '${e.message}'.");
    }
  }

  Future<void> _checkLockStatus() async {
    if (widget.fcmService != null) {
      final isLocked = await widget.fcmService!.isDeviceLocked();
      if (mounted) {
        setState(() {
          _isLocked = isLocked;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _buildInitialScreen(),
    );
  }

  Widget _buildInitialScreen() {
    if (!widget.isEnrolled) {
      // Si no está enrolado, siempre va a la pantalla de enrolamiento.
      // El deviceCode nativo y el fcmService se pasan para el proceso.
      return EnrollmentScreen(
        deviceCode: _deviceCode,
        fcmService: widget.fcmService,
      );
    }

    if (_isLocked) {
      return _buildLockScreen();
    }

    // Si está enrolado y no bloqueado, va a la pantalla principal.
    return const HomeScreen();
  }

  Widget _buildLockScreen() {
    // Si el servicio de notificaciones no está disponible, no se puede desbloquear.
    // En este caso, podría ser útil mostrar la pantalla de enrolamiento
    // o una pantalla de error específica.
    if (widget.fcmService == null) {
      return EnrollmentScreen(deviceCode: _deviceCode);
    }

    return FutureBuilder<Map<String, String>>(
      future: widget.fcmService!.getLockInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return LockScreen(
          title: snapshot.data!['title']!,
          message: snapshot.data!['message']!,
        );
      },
    );
  }
}
