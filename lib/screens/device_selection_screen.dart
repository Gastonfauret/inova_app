import 'package:flutter/material.dart';
import 'package:inova_app/models/device_model.dart';
import 'package:inova_app/screens/enrollment_screen.dart';
import 'package:inova_app/services/api_service.dart';
import 'package:inova_app/services/fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pantalla que muestra la lista de dispositivos del cliente
/// El usuario selecciona un dispositivo para completar el enrollment
class DeviceSelectionScreen extends StatefulWidget {
  final FCMService? fcmService;

  const DeviceSelectionScreen({super.key, this.fcmService});

  @override
  State<DeviceSelectionScreen> createState() => _DeviceSelectionScreenState();
}

class _DeviceSelectionScreenState extends State<DeviceSelectionScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  List<DeviceModel> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    print('\n╔════════════════════════════════════════╗');
    print('║  DEVICE SELECTION - CARGANDO          ║');
    print('╚════════════════════════════════════════╝');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verificar que tenemos token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null || token.isEmpty) {
        print('❌ No hay token de autenticación');
        setState(() {
          _errorMessage = 'No estás autenticado. Por favor vuelve a iniciar sesión.';
          _isLoading = false;
        });
        return;
      }

      print('✅ Token encontrado: ${token.substring(0, 20)}...');
      print('🚀 Obteniendo lista de dispositivos...');

      // Obtener lista de dispositivos del API
      final devicesData = await _apiService.getCustomerDevices();

      // Convertir los datos a modelos
      final devices = devicesData.map((json) => DeviceModel.fromJson(json)).toList();

      print('✅ Dispositivos obtenidos: ${devices.length}');

      setState(() {
        _devices = devices;
        _isLoading = false;
      });

      print('╚════════════════════════════════════════╝\n');
    } catch (e) {
      print('❌ Error al cargar dispositivos: $e');
      setState(() {
        _errorMessage = 'Error al cargar dispositivos: $e';
        _isLoading = false;
      });
      print('╚════════════════════════════════════════╝\n');
    }
  }

  void _selectDevice(DeviceModel device) async {
    print('\n╔════════════════════════════════════════╗');
    print('║  DEVICE SELECTION - SELECCIONADO      ║');
    print('╚════════════════════════════════════════╝');
    print('📱 Dispositivo seleccionado:');
    print('   - ID: ${device.id}');
    print('   - Código: ${device.code}');
    print('   - Nombre: ${device.device}');
    print('   - Marca: ${device.brand}');
    print('   - Modelo: ${device.model}');

    // Guardar el código del dispositivo
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_device_code', device.code!);

    print('   - Código guardado en SharedPreferences');
    print('   - Navegando a EnrollmentScreen');
    print('╚════════════════════════════════════════╝\n');

    if (!mounted) return;

    // Navegar a EnrollmentScreen (ya no se usa este flujo, pero se mantiene por compatibilidad)
    // NOTA: Este flujo ya no está activo. La app ahora va directo a EnrollmentScreen.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => EnrollmentScreen(
          deviceCode: device.code,
          fcmService: widget.fcmService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Dispositivo'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadDevices,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _devices.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.devices_other,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No tienes dispositivos disponibles',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Por favor crea un dispositivo desde el panel web antes de continuar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadDevices,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Actualizar'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDevices,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          final device = _devices[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(device.status),
                                child: Icon(
                                  _getDeviceIcon(device.type),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                device.device ?? 'Dispositivo sin nombre',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Código: ${device.code ?? "N/A"}'),
                                  Text('${device.brand ?? "Marca"} ${device.model ?? "Modelo"}'),
                                  Text(
                                    'Estado: ${device.statusName}',
                                    style: TextStyle(
                                      color: _getStatusColor(device.status),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => _selectDevice(device),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1: // ACTIVE
        return Colors.green;
      case 2: // LOCKED
        return Colors.red;
      case 3: // REMOVED
        return Colors.grey;
      case 4: // KIOSK
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getDeviceIcon(int type) {
    switch (type) {
      case 1: // ANDROID
        return Icons.phone_android;
      case 2: // IOS
        return Icons.phone_iphone;
      case 3: // ANDROID_TV
        return Icons.tv;
      default:
        return Icons.devices;
    }
  }
}
