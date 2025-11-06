
import 'package:flutter/material.dart';
import 'package:inova_app/screens/home_screen.dart';
import 'package:inova_app/services/api_service.dart';
import 'package:inova_app/services/fcm_service.dart';
import 'package:inova_app/services/device_info_service.dart';
import 'package:inova_app/services/heartbeat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnrollmentScreen extends StatefulWidget {
  final String? deviceCode; // Este código puede venir del lado nativo (UID)
  final FCMService? fcmService;

  const EnrollmentScreen({
    super.key,
    this.deviceCode,
    this.fcmService,
  });

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
    // widget.deviceCode se usará como el UID del dispositivo (del Platform Channel).
    print('📱 EnrollmentScreen iniciado');
    print('   - FCM Service disponible: ${widget.fcmService != null}');
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
          print('   - Enviando información del dispositivo al backend...');

          // Enviar heartbeat inmediatamente para actualizar los datos del dispositivo
          // (marca, modelo, serie, IMEI) en la página web
          try {
            // Crear instancia temporal de HeartbeatService y asignar el FCMService
            final heartbeatService = HeartbeatService();
            // Inicializar con FCMService pero no iniciar el timer (solo enviar una vez)
            heartbeatService.start(widget.fcmService);
            // Detener el timer inmediatamente para que no envíe heartbeats periódicos
            heartbeatService.stop();
            print('   - ✅ Datos del dispositivo enviados al backend');
          } catch (e) {
            print('   - ⚠️ Error al enviar datos del dispositivo: $e');
            print('   - Los datos se enviarán en el próximo heartbeat automático');
          }

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
                      MaterialPageRoute(builder: (context) => HomeScreen(fcmService: widget.fcmService)),
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
        title: const Text('Inova MDM - Enrollment'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Icono
                const Icon(
                  Icons.phone_android,
                  size: 80,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 24),

                // Título
                const Text(
                  'Enrollar Dispositivo',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Descripción
                const Text(
                  'Ingrese el código de su dispositivo para comenzar el proceso de enrollment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // Campo de código
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Código del Dispositivo',
                    hintText: 'Ej: 147760',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code),
                    helperText: 'Código de 6 dígitos proporcionado por el administrador',
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El código no puede estar vacío';
                    }
                    if (value.trim().length < 4) {
                      return 'El código debe tener al menos 4 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botón de enrollment
                if (_isLoading)
                  Column(
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Enrollando dispositivo...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _enrollDevice,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Enrollar Dispositivo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                // Mensaje de error
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
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
