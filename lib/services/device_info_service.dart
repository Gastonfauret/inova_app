import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

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
        };

        print('📱 Información del dispositivo Android:');
        print('   Dispositivo: ${androidInfo.model}');
        print('   Marca: ${androidInfo.brand}');
        print('   Modelo: ${androidInfo.model}');
        print('   Fabricante: ${androidInfo.manufacturer}');
        print('   ID: ${androidInfo.id}');
        print('   Versión Android: ${androidInfo.version.release}');

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
        };

        print('📱 Información del dispositivo iOS:');
        print('   Dispositivo: ${iosInfo.name}');
        print('   Modelo: ${iosInfo.model}');
        print('   ID: ${iosInfo.identifierForVendor}');
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
