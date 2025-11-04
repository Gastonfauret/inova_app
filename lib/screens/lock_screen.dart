import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inova_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockScreen extends StatefulWidget {
  final String title;
  final String message;

  const LockScreen({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _unlockCodeController = TextEditingController();
  bool _isCheckingCode = false;
  String? _errorMessage;
  String? _deviceCode;

  @override
  void initState() {
    super.initState();
    // Ocultar la barra de navegación y hacer pantalla completa
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadDeviceCode();
  }

  Future<void> _loadDeviceCode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _deviceCode = prefs.getString('device_code');
    });
    print('📱 Device code loaded: $_deviceCode');
  }

  @override
  void dispose() {
    _unlockCodeController.dispose();
    // Restaurar la UI del sistema
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _checkUnlockCode() async {
    setState(() {
      _isCheckingCode = true;
      _errorMessage = null;
    });

    final code = _unlockCodeController.text.trim();

    // Validar que el código tenga 5 dígitos
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingrese el código de desbloqueo.';
        _isCheckingCode = false;
      });
      return;
    }

    if (code.length != 5) {
      setState(() {
        _errorMessage = 'El código debe tener 5 dígitos.';
        _isCheckingCode = false;
      });
      return;
    }

    // Verificar que tengamos el código del dispositivo
    if (_deviceCode == null || _deviceCode!.isEmpty) {
      setState(() {
        _errorMessage = 'Error: Código de dispositivo no encontrado. Por favor contacte al soporte.';
        _isCheckingCode = false;
      });
      print('❌ Device code not found in SharedPreferences');
      return;
    }

    try {
      print('🔓 Attempting to unlock device $_deviceCode with code $code');

      // Llamar al API para verificar el código
      final response = await _apiService.verifyUnlockCode(_deviceCode!, code);

      print('📥 Unlock response: $response');

      // Verificar si la respuesta fue exitosa
      if (response['err'] == false) {
        // Código correcto - limpiar estado de bloqueo
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('device_locked', false);

        print('✅ Device unlocked successfully');

        // Salir de la pantalla de bloqueo
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        // Código incorrecto
        setState(() {
          _errorMessage = response['message'] ?? 'Código incorrecto. Intente nuevamente.';
          _isCheckingCode = false;
        });
        print('❌ Invalid unlock code: ${response['message']}');
      }
    } catch (e) {
      print('❌ Error verifying unlock code: $e');
      setState(() {
        _errorMessage = 'Error al verificar el código. Verifique su conexión a Internet.';
        _isCheckingCode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevenir que el usuario salga con el botón de atrás
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono de bloqueo
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock,
                      size: 80,
                      color: Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Título
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mensaje
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Sección de código de desbloqueo
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Código de Desbloqueo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Contacte a su vendedor para obtener el código',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Campo de código
                        TextField(
                          controller: _unlockCodeController,
                          enabled: !_isCheckingCode,
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '•••••',
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red.shade900, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red.shade900, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),

                        // Mensaje de error
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.red.shade900, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Botón de desbloqueo
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isCheckingCode ? null : _checkUnlockCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade900,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isCheckingCode
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Verificar Código',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Información de contacto
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '¿Necesita ayuda?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Contacte a su vendedor',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
