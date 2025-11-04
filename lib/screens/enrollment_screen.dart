
import 'package:flutter/material.dart';
import 'package:inova_app/screens/home_screen.dart';
import 'package:inova_app/services/api_service.dart';
import 'package:inova_app/services/fcm_service.dart';
import 'package:inova_app/services/device_info_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnrollmentScreen extends StatefulWidget {
  final String? deviceCode; // Este código puede venir del lado nativo (UID)
  final FCMService? fcmService;

  const EnrollmentScreen({super.key, this.deviceCode, this.fcmService});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final ApiService _apiService = ApiService();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // No pre-rellenamos el código, el usuario debe introducir el que ve en la web.
    // widget.deviceCode se usará como el UID del dispositivo.
  }

  Future<void> _enrollDevice() async {
    if (_formKey.currentState!.validate()) {
      print('\n╔════════════════════════════════════════╗');
      print('║  ENROLLMENT SCREEN - INICIO           ║');
      print('╚════════════════════════════════════════╝');

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('\n📋 Estado inicial:');
      print('   - Widget deviceCode: ${widget.deviceCode ?? "NULL"}');
      print('   - FCM Service disponible: ${widget.fcmService != null}');

      // Verificar FCM Service
      if (widget.fcmService == null) {
        print('\n❌ ERROR CRÍTICO: FCM Service es NULL');
        print('   - Firebase no se inicializó correctamente');
        print('   - Revisa los logs de inicialización de Firebase en main.dart');
        setState(() {
          _errorMessage = 'El servicio de notificaciones no está disponible. No se puede enrolar.';
          _isLoading = false;
        });
        print('╚════════════════════════════════════════╝\n');
        return;
      }

      print('✅ FCM Service disponible');
      print('   - FCM Token: ${widget.fcmService!.fcmToken ?? "NULL"}');

      final code = _codeController.text.trim();
      print('\n📝 Código ingresado por el usuario:');
      print('   - Código: "$code"');
      print('   - Longitud: ${code.length} caracteres');
      print('   - Es vacío: ${code.isEmpty}');

      // Obtener el Android ID real del dispositivo
      print('\n🔧 Obteniendo Android ID real del dispositivo...');
      final String deviceId = await _deviceInfoService.getDeviceId();
      print('✅ Device ID obtenido: $deviceId');

      try {
        print('\n🚀 Llamando a ApiService.enrollDevice()...');
        print('   - enrollmentCode: $code');
        print('   - deviceUid (Platform Channel): ${widget.deviceCode}');
        print('   - deviceId (Android ID real): $deviceId');
        print('   - fcmService: ${widget.fcmService}');

        final isSuccess = await _apiService.enrollDevice(
          enrollmentCode: code,
          deviceUid: deviceId, // Usamos el Android ID real
          fcmService: widget.fcmService!,
        );

        print('\n📊 RESULTADO DE ENROLLMENT:');
        print('   - Éxito: $isSuccess');

        if (!mounted) {
          print('⚠️ Widget no está montado, abortando navegación');
          print('╚════════════════════════════════════════╝\n');
          return;
        }

        setState(() {
          _isLoading = false;
        });

        if (isSuccess) {
          print('\n✅ ¡ENROLLMENT EXITOSO!');
          print('   - Mostrando diálogo de éxito al usuario');
          print('   - Preparando navegación a HomeScreen');

          // Mostrar diálogo de éxito
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('✅ Éxito'),
              content: const Text('Dispositivo enlazado correctamente'),
              actions: [
                TextButton(
                  onPressed: () {
                    print('👤 Usuario presionó "Continuar"');
                    print('   - Cerrando diálogo');
                    print('   - Navegando a HomeScreen');
                    Navigator.of(context).pop(); // Cerrar diálogo
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                    print('╚════════════════════════════════════════╝\n');
                  },
                  child: const Text('Continuar'),
                ),
              ],
            ),
          );
        } else {
          print('\n❌ ENROLLMENT FALLÓ');
          print('   - El servidor rechazó el enrollment');
          print('   - Revisa los logs de ApiService para más detalles');
          setState(() {
            _errorMessage = 'El código no es válido o hubo un error al conectar con el servidor.';
          });
          print('╚════════════════════════════════════════╝\n');
        }
      } catch (e, stackTrace) {
        print('\n❌ EXCEPCIÓN DURANTE ENROLLMENT');
        print('   - Tipo: ${e.runtimeType}');
        print('   - Mensaje: $e');
        print('   - Stack Trace:');
        print(stackTrace.toString().split('\n').take(5).join('\n'));

        if (mounted) {
          setState(() {
            _errorMessage = 'Error inesperado: $e';
            _isLoading = false;
          });
        }
        print('╚════════════════════════════════════════╝\n');
      }
    } else {
      print('\n⚠️ Validación de formulario falló');
      print('   - El código ingresado no es válido o está vacío');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enrolamiento de Dispositivo'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Por favor, ingrese su código de enlace para continuar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Código de Enlace',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El código no puede estar vacío';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _enrollDevice,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('Enlazar Dispositivo'),
                  ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
