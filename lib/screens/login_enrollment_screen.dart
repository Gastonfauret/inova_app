import 'package:flutter/material.dart';
import 'package:inova_app/screens/device_selection_screen.dart';
import 'package:inova_app/services/api_service.dart';
import 'package:inova_app/services/fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pantalla de login para el proceso de enrollment
/// El usuario debe autenticarse con client_id y secret antes de seleccionar un dispositivo
class LoginEnrollmentScreen extends StatefulWidget {
  final FCMService? fcmService;

  const LoginEnrollmentScreen({super.key, this.fcmService});

  @override
  State<LoginEnrollmentScreen> createState() => _LoginEnrollmentScreenState();
}

class _LoginEnrollmentScreenState extends State<LoginEnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientIdController = TextEditingController();
  final _secretController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _clientIdController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      print('\n╔════════════════════════════════════════╗');
      print('║  LOGIN ENROLLMENT - INICIO            ║');
      print('╚════════════════════════════════════════╝');

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final clientId = _clientIdController.text.trim();
      final secret = _secretController.text.trim();

      print('📝 Credenciales ingresadas:');
      print('   - Client ID: $clientId');
      print('   - Secret: ${secret.substring(0, 3)}...');

      try {
        print('\n🚀 Llamando a ApiService.login()...');
        final token = await _apiService.login(
          client: clientId,
          secret: secret,
        );

        if (token != null && token.isNotEmpty) {
          print('✅ Login exitoso!');
          print('   - Token recibido: ${token.substring(0, 20)}...');

          // Guardar el token en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('api_token', token);
          print('   - Token guardado en SharedPreferences');

          if (!mounted) {
            print('⚠️ Widget no está montado, abortando navegación');
            print('╚════════════════════════════════════════╝\n');
            return;
          }

          setState(() {
            _isLoading = false;
          });

          print('   - Navegando a DeviceSelectionScreen');
          print('╚════════════════════════════════════════╝\n');

          // Navegar a la pantalla de selección de dispositivos
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DeviceSelectionScreen(fcmService: widget.fcmService),
            ),
          );
        } else {
          print('❌ Login falló: Token vacío o null');
          setState(() {
            _errorMessage = 'Credenciales inválidas. Por favor verifica tu Client ID y Secret.';
            _isLoading = false;
          });
          print('╚════════════════════════════════════════╝\n');
        }
      } catch (e) {
        print('❌ Error durante login: $e');
        if (mounted) {
          setState(() {
            _errorMessage = 'Error al conectar con el servidor: $e';
            _isLoading = false;
          });
        }
        print('╚════════════════════════════════════════╝\n');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login - Enrollment'),
        centerTitle: true,
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
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),

                // Título
                const Text(
                  'Autenticación Requerida',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Descripción
                const Text(
                  'Por favor ingresa tus credenciales de cliente para continuar con el enrollment del dispositivo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Campo Client ID
                TextFormField(
                  controller: _clientIdController,
                  decoration: const InputDecoration(
                    labelText: 'Client ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Ingresa tu Client ID',
                  ),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El Client ID no puede estar vacío';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Secret
                TextFormField(
                  controller: _secretController,
                  decoration: InputDecoration(
                    labelText: 'Secret',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.key),
                    hintText: 'Ingresa tu Secret',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El Secret no puede estar vacío';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Botón de Login
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Iniciar Sesión'),
                    ),
                  ),

                // Mensaje de error
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
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
