import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:inova_app/screens/enrollment_screen.dart';
import 'package:inova_app/screens/lock_screen.dart';
import 'package:inova_app/config/app_config.dart';
import 'package:inova_app/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FCMService? fcmService;

  // Inicializar Firebase
  try {
    await Firebase.initializeApp();
    print('✅ Firebase inicializado correctamente');

    // Inicializar FCM solo si Firebase está configurado
    fcmService = FCMService();
    await fcmService.initialize();
  } catch (e) {
    print('❌ Error al inicializar Firebase: $e');
    print('⚠️ La app funcionará sin notificaciones FCM');
  }

  runApp(MyApp(fcmService: fcmService));
}

class MyApp extends StatefulWidget {
  final FCMService? fcmService;

  const MyApp({super.key, this.fcmService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockStatus();

    // Escuchar comandos de FCM (solo si está disponible)
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Cuando la app vuelve al foreground, verificar el estado de bloqueo
      _checkLockStatus();
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
      home: _isLocked ? _buildLockScreen() : const EnrollmentScreen(),
    );
  }

  Widget _buildLockScreen() {
    if (widget.fcmService == null) {
      return const EnrollmentScreen();
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
