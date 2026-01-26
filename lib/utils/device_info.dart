import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceInfo {
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return _getAndroidInfo();
      } else if (Platform.isIOS) {
        return _getIosInfo();
      }
    } catch (e) {
      print('Error getting device info: $e');
    }
    
    return {};
  }
  
  static Future<Map<String, dynamic>> _getAndroidInfo() async {
    final androidInfo = await deviceInfoPlugin.androidInfo;
    
    return {
      'platform': 'android',
      'deviceId': androidInfo.id,
      'model': androidInfo.model,
      'brand': androidInfo.brand,
      'version': androidInfo.version.release,
      'sdk': androidInfo.version.sdkInt,
      'manufacturer': androidInfo.manufacturer,
    };
  }
  
  static Future<Map<String, dynamic>> _getIosInfo() async {
    final iosInfo = await deviceInfoPlugin.iosInfo;
    
    return {
      'platform': 'ios',
      'deviceId': iosInfo.identifierForVendor,
      'model': iosInfo.model,
      'systemVersion': iosInfo.systemVersion,
      'name': iosInfo.name,
      'utsname': {
        'sysname': iosInfo.utsname.sysname,
        'nodename': iosInfo.utsname.nodename,
        'release': iosInfo.utsname.release,
        'version': iosInfo.utsname.version,
        'machine': iosInfo.utsname.machine,
      },
    };
  }
  
  static Future<String> getDeviceId() async {
    final info = await getDeviceInfo();
    return info['deviceId'] ?? 'unknown';
  }
  
  static Future<String> getPlatform() async {
    final info = await getDeviceInfo();
    return info['platform'] ?? 'unknown';
  }
}