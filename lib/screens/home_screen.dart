import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inova_app/services/device_info_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  // Información del dispositivo
  String? _deviceCode;
  String? _enterprise;
  String? _deviceId;
  bool _isLoading = true;
  Map<String, dynamic>? _deviceInfo;
  Map<String, dynamic>? _enrollmentConfig;
  DateTime? _enrolledAt;
  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    _loadDeviceInformation();
  }

  Future<void> _loadDeviceInformation() async {
    print('\n📊 Cargando información del dispositivo...');

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Información básica del enrollment
      _deviceCode = prefs.getString('device_code');
      _enterprise = prefs.getString('setting_enterprise');
      _deviceId = await _deviceInfoService.getDeviceId();

      // Información del dispositivo
      _deviceInfo = await _deviceInfoService.getDeviceInfo();

      // Configuración del enrollment
      _enrollmentConfig = {
        'status': prefs.getString('setting_status'),
        'next_lock_date': prefs.getString('setting_next_lock_date'),
        'code_unlock_days': prefs.getInt('setting_code_unlock_days'),
        'enterprise': prefs.getString('setting_enterprise'),
        'enterpriseid': prefs.getString('setting_enterpriseid'),
      };

      // Fechas
      _lastSync = DateTime.now();

      print('✅ Información cargada:');
      print('   - Device Code: $_deviceCode');
      print('   - Enterprise: $_enterprise');
      print('   - Device ID: $_deviceId');

    } catch (e) {
      print('❌ Error al cargar información: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar información del dispositivo'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _loadDeviceInformation,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    print('🔄 Refrescando datos...');
    await _loadDeviceInformation();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Datos actualizados'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showDeviceInfo() async {
    final readableInfo = await _deviceInfoService.getReadableDeviceInfo();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone_android, color: Colors.blue),
            SizedBox(width: 10),
            Text('Información del Dispositivo'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: readableInfo.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inova MDM'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estado
              _buildStatusCard(),
              const SizedBox(height: 16),

              // Información del dispositivo
              _buildInfoSection(),
              const SizedBox(height: 16),

              // Configuración del enrollment
              _buildEnrollmentConfig(),
              const SizedBox(height: 16),

              // Acciones
              _buildActionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'Dispositivo Enrolado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _enterprise ?? 'Sin empresa asignada',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Código: ${_deviceCode ?? "N/A"}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.phone_android, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Información del Dispositivo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Marca', _deviceInfo?['brand'] ?? 'N/A'),
            _buildInfoRow('Modelo', _deviceInfo?['model'] ?? 'N/A'),
            _buildInfoRow('Fabricante', _deviceInfo?['manufacturer'] ?? 'N/A'),
            _buildInfoRow('ID del Dispositivo', _deviceId ?? 'N/A', monospace: true),
            if (_deviceInfo?['android_version'] != null)
              _buildInfoRow('Android', _deviceInfo!['android_version']),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showDeviceInfo,
                icon: const Icon(Icons.info_outline),
                label: const Text('Ver Detalles Completos'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentConfig() {
    final nextLockDate = _enrollmentConfig?['next_lock_date'];
    final unlockDays = _enrollmentConfig?['code_unlock_days'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Configuración MDM',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (nextLockDate != null)
              _buildInfoRow(
                'Próximo Bloqueo',
                _formatDate(nextLockDate),
                icon: Icons.calendar_today,
              ),
            if (unlockDays != null)
              _buildInfoRow(
                'Días para Código de Desbloqueo',
                '$unlockDays días',
                icon: Icons.lock_clock,
              ),
            _buildInfoRow(
              'Última Sincronización',
              _formatDateTime(_lastSync),
              icon: Icons.sync,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.touch_app, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Acciones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text('Sincronizar Ahora'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Información'),
                      content: const Text(
                        'El dispositivo está activo y recibiendo comandos remotos.\n\n'
                        'Las actualizaciones se realizan automáticamente.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Entendido'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('Ayuda'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon, bool monospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Nunca';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Hace ${difference.inSeconds} segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} horas';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
