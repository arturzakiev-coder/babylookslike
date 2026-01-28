import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RevenueCatInitializer {
  static Future<void> initialize() async {
    try {
      print('🔄 Initializing RevenueCat...');
      
      // Получаем ключ из .env
      final apiKey = dotenv.env['REVENUECAT_ANDROID_KEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('RevenueCat API key not found in .env file');
      }
      
      // Маскируем ключ для логов
      final maskedKey = apiKey.length > 10 
          ? '${apiKey.substring(0, 10)}...' 
          : '***';
      print('🔑 Using RevenueCat key: $maskedKey');
      
      // Конфигурация
      final configuration = PurchasesConfiguration(apiKey);
      
      // Настройка
      await Purchases.configure(configuration);
      
      // Включаем логи для отладки
      await Purchases.setLogLevel(LogLevel.debug);
      
      print('✅ RevenueCat initialized successfully');
      
    } catch (e) {
      print('❌ Error initializing RevenueCat: $e');
      rethrow;
    }
  }
}