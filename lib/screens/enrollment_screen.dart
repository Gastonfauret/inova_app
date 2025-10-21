import 'package:flutter/material.dart';
import 'package:inova_app/services/api_service.dart';
import 'package:inova_app/services/device_info_service.dart';
import 'package:inova_app/models/device_model.dart';

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final ApiService _apiService = ApiService();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  Map<String, String> _deviceInfo = {};
  bool _isLoading = false;
  bool _isEnrolled = false;
  DeviceModel? _enrolledDevice;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final info = await _deviceInfoService.getReadableDeviceInfo();
      setState(() {
        _deviceInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar información del dispositivo: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _enrollDevice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obtener información del dispositivo
      final deviceData = await _deviceInfoService.getDeviceInfo();

      print('📤 Enviando datos de enrollment: $deviceData');

      // Enrollar dispositivo en el backend
      final response = await _apiService.enrollDevice(deviceData);

      print('📥 Respuesta del servidor: $response');

      if (response['err'] == false && response['data'] != null) {
        final enrolledDevice = DeviceModel.fromJson(response['data']);

        setState(() {
          _isEnrolled = true;
          _enrolledDevice = enrolledDevice;
          _isLoading = false;
        });

        _showSuccessDialog();
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Error desconocido';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error en enrollment: $e');
      setState(() {
        _errorMessage = 'Error al enrollar dispositivo: $e';
        _isLoading = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('¡Enrollment Exitoso!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('El dispositivo ha sido enrollado correctamente.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Código de Dispositivo:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _enrolledDevice?.code ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ID: ${_enrolledDevice?.id}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              'Estado: ${_enrolledDevice?.statusName}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Error de Enrollment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('No se pudo enrollar el dispositivo:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade900,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enrollment de Dispositivo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título y descripción
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            _isEnrolled ? Icons.check_circle : Icons.phone_android,
                            size: 64,
                            color: _isEnrolled ? Colors.green : Colors.deepPurple,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isEnrolled
                                ? '✅ Dispositivo Enrollado'
                                : 'Información del Dispositivo',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isEnrolled
                                ? 'El dispositivo ha sido registrado exitosamente en el sistema MDM.'
                                : 'Revisa la información y presiona "Enrollar Dispositivo" para continuar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Información del dispositivo
                  if (!_isEnrolled) ...[
                    const Text(
                      'Datos del Dispositivo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: _deviceInfo.entries
                              .map((entry) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 140,
                                          child: Text(
                                            entry.key,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            entry.value,
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],

                  // Información del dispositivo enrollado
                  if (_isEnrolled && _enrolledDevice != null) ...[
                    const Text(
                      'Detalles del Enrollment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('ID', '${_enrolledDevice!.id}'),
                            _buildInfoRow('Código', _enrolledDevice!.code ?? 'N/A'),
                            _buildInfoRow('Dispositivo', _enrolledDevice!.device ?? 'N/A'),
                            _buildInfoRow('Marca', _enrolledDevice!.brand ?? 'N/A'),
                            _buildInfoRow('Modelo', _enrolledDevice!.model ?? 'N/A'),
                            _buildInfoRow('Tipo', _enrolledDevice!.typeName),
                            _buildInfoRow('Estado', _enrolledDevice!.statusName),
                            _buildInfoRow('IMEI', _enrolledDevice!.imei ?? 'N/A'),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Mensajes de error
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Botón de enrollment
                  if (!_isEnrolled)
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _enrollDevice,
                      icon: const Icon(Icons.upload),
                      label: const Text('Enrollar Dispositivo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),

                  // Botón de reintentar
                  if (_isEnrolled)
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEnrolled = false;
                          _enrolledDevice = null;
                        });
                        _loadDeviceInfo();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Enrollar Otro Dispositivo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
