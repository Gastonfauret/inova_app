
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:inova_app/config/app_config.dart';
import 'package:inova_app/screens/enrollment_screen.dart';
import 'package:inova_app/screens/login_enrollment_screen.dart';
import 'package:inova_app/screens/home_screen.dart';
import 'package:inova_app/screens/lock_screen.dart';
import 'package:inova_app/services/fcm_service.dart';
import 'package:inova_app/services/heartbeat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('\n╔════════════════════════════════════════╗');
  print('║       INOVA MDM - INICIO DE APP      ║');
  print('╚════════════════════════════════════════╝\n');

  print('⚙️ Inicializando Flutter bindings...');
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ Flutter bindings inicializados\n');

  FCMService? fcmService;
  try {
    print('🔥 Inicializando Firebase...');
    await Firebase.initializeApp();
    print('✅ Firebase inicializado correctamente\n');

    print('📱 Inicializando FCM Service...');
    fcmService = FCMService();
    await fcmService.initialize();
    print('✅ FCM Service inicializado correctamente\n');

  } catch (e, stackTrace) {
    print('❌ ERROR AL INICIALIZAR FIREBASE/FCM');
    print('   - Tipo de error: ${e.runtimeType}');
    print('   - Mensaje: $e');
    print('   - Stack Trace:');
    print(stackTrace.toString().split('\n').take(5).join('\n'));
    print('\n⚠️ ADVERTENCIA: La app funcionará sin notificaciones FCM');
    print('   - El enrollment podría fallar si FCM es requerido');
    print('   - Verifica la configuración de Firebase:');
    print('     • android/app/google-services.json existe y es válido');
    print('     • Firebase está habilitado en el proyecto');
    print('     • Las dependencias están correctamente instaladas\n');
  }

  // Chequea si el dispositivo ya está enrolado
  print('💾 Verificando estado de enrollment...');
  final prefs = await SharedPreferences.getInstance();
  final bool isEnrolled = prefs.getBool('isEnrolled') ?? false;
  final String? deviceCode = prefs.getString('device_code');

  print('📊 Estado de SharedPreferences:');
  print('   - isEnrolled: $isEnrolled');
  print('   - device_code: ${deviceCode ?? "NULL"}');

  if (isEnrolled) {
    print('✅ Dispositivo ya está enrolado');
    print('   - El usuario verá la pantalla principal (HomeScreen o LockScreen)');
  } else {
    print('⚠️ Dispositivo NO está enrolado');
    print('   - El usuario verá la pantalla de enrollment');
  }

  print('\n🚀 Iniciando aplicación...');
  print('   - fcmService disponible: ${fcmService != null}');
  print('   - isEnrolled: $isEnrolled');
  print('╚════════════════════════════════════════╝\n');

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
  final HeartbeatService _heartbeatService = HeartbeatService();

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

      // Iniciar heartbeat service
      _heartbeatService.start(widget.fcmService);
      print('✅ Heartbeat service iniciado');

      if (widget.fcmService != null) {
        widget.fcmService!.commandStream.listen((command) {
          print('\n📨 COMANDO RECIBIDO VIA FCM STREAM');
          print('   - Comando: ${command['command']}');

          if (command['command'] == 'lock') {
            setState(() {
              _isLocked = true;
            });
            print('   - Dispositivo bloqueado via FCM');
          } else if (command['command'] == 'unlock') {
            setState(() {
              _isLocked = false;
            });
            print('   - Dispositivo desbloqueado via FCM');
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatService.stop();
    widget.fcmService?.dispose();
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
      // Si no está enrolado, ir directo a ingresar código de dispositivo
      return EnrollmentScreen(
        deviceCode: _deviceCode,
        fcmService: widget.fcmService,
      );
    }

    if (_isLocked) {
      return _buildLockScreen();
    }

    // Si está enrolado y no bloqueado, va a la pantalla principal.
    return HomeScreen(fcmService: widget.fcmService);
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
