import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SimpleQRScanner extends StatefulWidget {
  const SimpleQRScanner({super.key});

  @override
  State<SimpleQRScanner> createState() => _SimpleQRScannerState();
}

class _SimpleQRScannerState extends State<SimpleQRScanner> {
  final MobileScannerController controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _hasScanned = true;
    });

    controller.stop();

    print('📷 QR Code escaneado: $code');

    // Intentar extraer solo números (device code)
    final cleanCode = code.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanCode.length >= 4) {
      // Código válido encontrado
      print('✅ Device code extraído: $cleanCode');
      Navigator.pop(context, cleanCode);
    } else {
      // El QR no contiene un código válido
      print('⚠️ QR no contiene un código de dispositivo válido');
      _showError('El código QR no contiene un código de dispositivo válido.\n\nCódigo escaneado: $code');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('QR No Válido'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _hasScanned = false;
              });
              controller.start();
            },
            child: const Text('Reintentar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código QR'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          // Overlay de guía
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Instrucciones superiores
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Código de Dispositivo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Escanea el código QR con el número de 6 dígitos',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Instrucciones inferiores
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Apunta la cámara hacia el código QR\nque contiene tu código de dispositivo',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Botón de ayuda
          Positioned(
            bottom: 140,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Row(
                        children: [
                          Icon(Icons.help_outline, color: Colors.blue),
                          SizedBox(width: 10),
                          Text('Ayuda'),
                        ],
                      ),
                      content: const SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¿Qué QR debo escanear?',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Debes escanear el código QR que contiene tu código de dispositivo de 6 dígitos.',
                            ),
                            SizedBox(height: 16),
                            Text(
                              '¿Dónde obtengo este código?',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Tu administrador te proporcionó un código QR o un código numérico de 6 dígitos. Si tienes el código numérico, puedes ingresarlo manualmente en la pantalla anterior.',
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Formatos aceptados:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text('• QR con solo números: 147760'),
                            Text('• QR con texto y números: CODE-147760'),
                            Text('• Código de 4 a 8 dígitos'),
                          ],
                        ),
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
                icon: const Icon(Icons.help_outline, color: Colors.white),
                label: const Text(
                  '¿Qué código escanear?',
                  style: TextStyle(color: Colors.white),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
