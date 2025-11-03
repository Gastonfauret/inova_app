
import 'package:flutter/material.dart';
import 'package:inova_app/screens/home_screen.dart';
import 'package:inova_app/services/api_service.dart';
import 'package:inova_app/services/fcm_service.dart';
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
      print('🔵 Iniciando proceso de enrollment...');

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Verificar FCM Service
      if (widget.fcmService == null) {
        print('❌ FCM Service es NULL');
        setState(() {
          _errorMessage = 'El servicio de notificaciones no está disponible. No se puede enrolar.';
          _isLoading = false;
        });
        return;
      }

      print('✅ FCM Service disponible');

      final code = _codeController.text.trim();
      print('📝 Código ingresado: $code');

      try {
        print('🚀 Llamando a enrollDevice...');
        final isSuccess = await _apiService.enrollDevice(
          enrollmentCode: code,
          deviceUid: widget.deviceCode,
          fcmService: widget.fcmService!,
        );

        print('📊 Resultado de enrollment: $isSuccess');

        if (!mounted) {
          print('⚠️ Widget no está montado, abortando navegación');
          return;
        }

        setState(() {
          _isLoading = false;
        });

        if (isSuccess) {
          print('✅ Enrollment exitoso, mostrando mensaje...');

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
                    Navigator.of(context).pop(); // Cerrar diálogo
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  },
                  child: const Text('Continuar'),
                ),
              ],
            ),
          );
        } else {
          print('❌ Enrollment falló');
          setState(() {
            _errorMessage = 'El código no es válido o hubo un error al conectar con el servidor.';
          });
        }
      } catch (e) {
        print('❌ Excepción durante enrollment: $e');
        if (mounted) {
          setState(() {
            _errorMessage = 'Error inesperado: $e';
            _isLoading = false;
          });
        }
      }
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
