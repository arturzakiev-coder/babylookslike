import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (kIsWeb) {
        return await _getWebDeviceInfo();
      } else {
        return await _getMobileDeviceInfo();
      }
    } catch (e) {
      print('❌ Error getting device info: $e');
      return _getFallbackDeviceInfo();
    }
  }
  
  static Future<Map<String, dynamic>> _getWebDeviceInfo() async {
    try {
      final webInfo = await deviceInfo.webBrowserInfo;
      return {
        'type': 'web',
        'browser': webInfo.browserName.name,
        'platform': webInfo.platform,
        'userAgent': webInfo.userAgent,
        'vendor': webInfo.vendor,
        'appVersion': webInfo.appVersion,
        'language': webInfo.language,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'type': 'web',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  static Future<Map<String, dynamic>> _getMobileDeviceInfo() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'type': 'android',
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'model': androidInfo.model,
          'product': androidInfo.product,
          'version': {
            'sdkInt': androidInfo.version.sdkInt,
            'release': androidInfo.version.release,
            'codename': androidInfo.version.codename,
          },
          'manufacturer': androidInfo.manufacturer,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
          'board': androidInfo.board,
          'bootloader': androidInfo.bootloader,
          'display': androidInfo.display,
          'fingerprint': androidInfo.fingerprint,
          'hardware': androidInfo.hardware,
          'host': androidInfo.host,
          'id': androidInfo.id,
          'tags': androidInfo.tags,
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'type': 'ios',
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'model': iosInfo.model,
          'localizedModel': iosInfo.localizedModel,
          'identifierForVendor': iosInfo.identifierForVendor,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
          'utsname': {
            'sysname': iosInfo.utsname.sysname,
            'nodename': iosInfo.utsname.nodename,
            'release': iosInfo.utsname.release,
            'version': iosInfo.utsname.version,
            'machine': iosInfo.utsname.machine,
          },
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'type': 'unknown_mobile',
          'platform': defaultTargetPlatform.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      return {
        'type': 'mobile_error',
        'error': e.toString(),
        'platform': defaultTargetPlatform.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  static Map<String, dynamic> _getFallbackDeviceInfo() {
    return {
      'type': kIsWeb ? 'web' : 'mobile',
      'platform': defaultTargetPlatform.toString(),
      'error': 'could_not_detect',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  // Метод для получения краткой информации об устройстве
  static Future<Map<String, dynamic>> getSimpleDeviceInfo() async {
    final fullInfo = await getDeviceInfo();
    
    if (kIsWeb) {
      return {
        'platform': 'web',
        'browser': fullInfo['browser'] ?? 'unknown',
        'os': fullInfo['platform'] ?? 'unknown',
        'deviceType': 'web_browser',
      };
    } else {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return {
          'platform': 'android',
          'brand': fullInfo['brand'] ?? 'unknown',
          'model': fullInfo['model'] ?? 'unknown',
          'androidVersion': fullInfo['version']?['release'] ?? 'unknown',
          'deviceType': fullInfo['isPhysicalDevice'] == true ? 'physical' : 'emulator',
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return {
          'platform': 'ios',
          'model': fullInfo['model'] ?? 'unknown',
          'iosVersion': fullInfo['systemVersion'] ?? 'unknown',
          'deviceName': fullInfo['name'] ?? 'unknown',
          'deviceType': fullInfo['isPhysicalDevice'] == true ? 'physical' : 'simulator',
        };
      } else {
        return {
          'platform': 'other_mobile',
          'type': fullInfo['type'] ?? 'unknown',
        };
      }
    }
  }
}