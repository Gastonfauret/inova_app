import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Obtener el Android ID único del dispositivo
  Future<String> getDeviceId() async {
    try {
      print('\n📱 Obteniendo Device ID único...');

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        final androidId = androidInfo.id;

        print('✅ Android ID obtenido:');
        print('   - ID: $androidId');
        print('   - Longitud: ${androidId.length} caracteres');

        return androidId;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        final iosId = iosInfo.identifierForVendor ?? 'unknown';

        print('✅ iOS Identifier obtenido:');
        print('   - ID: $iosId');

        return iosId;
      }

      print('⚠️ Plataforma no soportada, usando ID genérico');
      return 'unknown_${DateTime.now().millisecondsSinceEpoch}';

    } catch (e) {
      print('❌ Error al obtener Device ID: $e');
      print('   Usando ID de fallback basado en timestamp');
      return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    Map<String, dynamic> deviceData = {};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;

        deviceData = {
          'device': androidInfo.model,
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'type': 1, // 1 = Android
          // IMEI no está disponible en Android moderno por restricciones de seguridad
          // Se puede usar el ID único del dispositivo en su lugar
          'imei': androidInfo.id, // AndroidID como alternativa
          'serie': androidInfo.id, // Usar androidId como número de serie
          'android_version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
        };

        print('📱 Información del dispositivo Android:');
        print('   Dispositivo: ${androidInfo.model}');
        print('   Marca: ${androidInfo.brand}');
        print('   Modelo: ${androidInfo.model}');
        print('   Fabricante: ${androidInfo.manufacturer}');
        print('   ID: ${androidInfo.id}');
        print('   Versión Android: ${androidInfo.version.release}');
        print('   SDK: ${androidInfo.version.sdkInt}');

      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;

        deviceData = {
          'device': iosInfo.name,
          'brand': 'Apple',
          'model': iosInfo.model,
          'manufacturer': 'Apple',
          'type': 2, // 2 = iOS
          'imei': iosInfo.identifierForVendor ?? 'unknown',
          'serie': iosInfo.identifierForVendor ?? 'unknown',
          'ios_version': iosInfo.systemVersion,
        };

        print('📱 Información del dispositivo iOS:');
        print('   Dispositivo: ${iosInfo.name}');
        print('   Modelo: ${iosInfo.model}');
        print('   ID: ${iosInfo.identifierForVendor}');
        print('   iOS: ${iosInfo.systemVersion}');
      }

      return deviceData;

    } catch (e) {
      print('❌ Error al obtener información del dispositivo: $e');
      rethrow;
    }
  }

  // Obtener información legible para mostrar en UI
  Future<Map<String, String>> getReadableDeviceInfo() async {
    Map<String, String> info = {};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;

        info = {
          'Dispositivo': androidInfo.model,
          'Marca': androidInfo.brand.toUpperCase(),
          'Modelo': androidInfo.model,
          'Fabricante': androidInfo.manufacturer.toUpperCase(),
          'Android': 'Versión ${androidInfo.version.release}',
          'ID del Dispositivo': androidInfo.id,
          'Número de Serie': androidInfo.id, // Usar AndroidID
        };

      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;

        info = {
          'Dispositivo': iosInfo.name,
          'Marca': 'Apple',
          'Modelo': iosInfo.model,
          'Sistema': 'iOS ${iosInfo.systemVersion}',
          'ID del Dispositivo': iosInfo.identifierForVendor ?? 'No disponible',
        };
      }

      return info;

    } catch (e) {
      print('❌ Error al obtener información legible: $e');
      return {'Error': 'No se pudo obtener la información del dispositivo'};
    }
  }
}
