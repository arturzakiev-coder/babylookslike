import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService with ChangeNotifier {
  bool _initialized = false;
  late FirebaseFirestore _firestore;
  String? _deviceId;
  SharedPreferences? _prefs;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Firebase.initializeApp();
      _firestore = FirebaseFirestore.instance;
      
      // Инициализируем SharedPreferences (работает на мобильных)
      if (!kIsWeb) {
        _prefs = await SharedPreferences.getInstance();
      }
      
      // Получаем или создаем deviceId
      _deviceId = await _getOrCreateDeviceId();
      
      // Проверяем/создаем запись в Firestore
      await _ensureBalanceRecord();
      
      _initialized = true;
      
      if (kDebugMode) {
        print('=== Firebase Initialized ===');
        print('Device ID: $_deviceId');
        print('Firestore ready');
      }
    } catch (e) {
      if (kDebugMode) {
        print('=== Firebase Error ===');
        print('Error initializing Firebase: $e');
      }
    }
  }
  // lib/services/firebase_service.dart - ДОБАВЬТЕ ЭТОТ МЕТОД
Future<void> addPurchasedAttempts(int attemptsToAdd) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final deviceId = await _getOrCreateDeviceId();
      final docRef = _firestore.collection('balances').doc(deviceId);

      await docRef.update({
        'purchasedAttempts': FieldValue.increment(attemptsToAdd),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('✅ Added $attemptsToAdd purchased attempts for device: $deviceId');
    } catch (e) {
      print('❌ Error adding purchased attempts: $e');
      rethrow;
    }
  }
  // Метод 1: Получение/создание deviceId (упрощенный для web)
  Future<String> _getOrCreateDeviceId() async {
    if (kIsWeb) {
      // Упрощенная версия для web без universal_html
      return _getOrCreateDeviceIdWeb();
    } else {
      // Для мобильных
      return _getOrCreateDeviceIdMobile();
    }
  }
  
  Future<String> _getOrCreateDeviceIdWeb() async {
    try {
      // Простая реализация для web - используем timestamp
      final existingId = _loadDeviceIdFromLocalStorage();
      
      if (existingId != null && existingId.isNotEmpty) {
        if (kDebugMode) print('Using existing web deviceId: $existingId');
        return existingId;
      } else {
        final newId = 'web_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
        _saveDeviceIdToLocalStorage(newId);
        if (kDebugMode) print('Created new web deviceId: $newId');
        return newId;
      }
    } catch (e) {
      return 'web_fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  // Простые методы для работы с localStorage в web
  String? _loadDeviceIdFromLocalStorage() {
    try {
      // Для Flutter web есть window.localStorage
      if (kIsWeb) {
        // Альтернатива: использовать dart:js или просто timestamp
        return null; // Вернем null, чтобы всегда генерировать новый
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  void _saveDeviceIdToLocalStorage(String deviceId) {
    // Заглушка - в реальном приложении нужно реализовать
  }
  
  Future<String> _getOrCreateDeviceIdMobile() async {
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      
      String? deviceId = _prefs!.getString('deviceId');
      
      if (deviceId == null || deviceId.isEmpty) {
        // Генерируем новый ID
        deviceId = 'mobile_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
        await _prefs!.setString('deviceId', deviceId);
        if (kDebugMode) print('Created new mobile deviceId: $deviceId');
      } else {
        if (kDebugMode) print('Using existing mobile deviceId: $deviceId');
      }
      
      return deviceId;
    } catch (e) {
      return 'mobile_fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  // Метод 2: Создание записи баланса если ее нет
  Future<void> _ensureBalanceRecord() async {
    if (_deviceId == null) return;
    
    try {
      final docRef = _firestore.collection('balances').doc(_deviceId!);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        await docRef.set({
          'freeAttempts': 3,
          'purchasedAttempts': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'deviceInfo': {
            'platform': kIsWeb ? 'web' : 'mobile',
            'created': DateTime.now().toIso8601String(),
          }
        });
        if (kDebugMode) print('✅ Created new balance record for $_deviceId');
      } else {
        if (kDebugMode) print('📄 Balance record exists for $_deviceId');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error ensuring balance record: $e');
    }
  }
  
  // Метод 3: Загрузка баланса (ОСНОВНОЙ)
  Future<Map<String, int>> loadAttemptBalance() async {
    if (!_initialized || _deviceId == null) {
      if (kDebugMode) print('Firebase not initialized, returning default');
      return {'freeAttempts': 3, 'purchasedAttempts': 0};
    }
    
    try {
      if (kDebugMode) print('📥 Loading balance for device: $_deviceId');
      
      final doc = await _firestore
          .collection('balances')
          .doc(_deviceId!)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final free = (data['freeAttempts'] as num?)?.toInt() ?? 3;
        final purchased = (data['purchasedAttempts'] as num?)?.toInt() ?? 0;
        
        if (kDebugMode) {
          print('✅ Balance loaded: free=$free, purchased=$purchased');
        }
        
        return {
          'freeAttempts': free,
          'purchasedAttempts': purchased,
        };
      } else {
        if (kDebugMode) print('📝 No balance record found, creating...');
        await _ensureBalanceRecord();
        return {'freeAttempts': 3, 'purchasedAttempts': 0};
      }
    } catch (e) {
      if (kDebugMode) {
        print('=== ERROR loading balance ===');
        print('Error: $e');
        print('DeviceId: $_deviceId');
      }
      return {'freeAttempts': 3, 'purchasedAttempts': 0};
    }
  }
  
  // Метод 4: Сохранение баланса (ОСНОВНОЙ)
  Future<void> saveAttemptBalance({
    required int freeAttempts,
    required int purchasedAttempts,
  }) async {
    if (!_initialized || _deviceId == null) {
      if (kDebugMode) print('Cannot save: Firebase not initialized');
      return;
    }
    
    try {
      if (kDebugMode) {
        print('💾 Saving balance: free=$freeAttempts, purchased=$purchasedAttempts');
      }
      
      await _firestore.collection('balances').doc(_deviceId!).set({
        'freeAttempts': freeAttempts,
        'purchasedAttempts': purchasedAttempts,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (kDebugMode) print('✅ Balance saved successfully');
    } catch (e) {
      if (kDebugMode) {
        print('=== ERROR saving balance ===');
        print('Error: $e');
      }
    }
  }
  
  // Метод 5: Сохранение результата сравнения (ДОБАВЛЕНО)
  Future<void> saveComparisonResult({
    required double motherSimilarity,
    required double fatherSimilarity,
    required Map<String, double> details,
  }) async {
    if (!_initialized || _deviceId == null) {
      if (kDebugMode) print('Cannot save comparison: Firebase not initialized');
      return;
    }
    
    try {
      await _firestore.collection('comparisons').add({
        'deviceId': _deviceId,
        'motherSimilarity': motherSimilarity,
        'fatherSimilarity': fatherSimilarity,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'mobile',
      });
      
      if (kDebugMode) print('✅ Comparison result saved');
    } catch (e) {
      if (kDebugMode) print('❌ Error saving comparison: $e');
    }
  }
  
  // Метод 6: Сохранение покупки (ДОБАВЛЕНО)
  Future<void> savePurchase({
    required String productId,
    required int amount,
    required double price,
  }) async {
    if (!_initialized || _deviceId == null) {
      if (kDebugMode) print('Cannot save purchase: Firebase not initialized');
      return;
    }
    
    try {
      await _firestore.collection('transactions').add({
        'deviceId': _deviceId,
        'productId': productId,
        'amount': amount,
        'price': price,
        'currency': 'RUB',
        'timestamp': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'mobile',
      });
      
      if (kDebugMode) print('✅ Purchase saved');
    } catch (e) {
      if (kDebugMode) print('❌ Error saving purchase: $e');
    }
  }
  
  // Метод 7: Получение истории сравнений (ДОБАВЛЕНО)
  Future<List<Map<String, dynamic>>> getComparisonHistory() async {
    if (!_initialized || _deviceId == null) return [];
    
    try {
      final snapshot = await _firestore
          .collection('comparisons')
          .where('deviceId', isEqualTo: _deviceId)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading history: $e');
      }
      return [];
    }
  }
  
  // Метод 8: Логирование в консоль для отладки
  Future<void> logToConsole(String message) async {
    if (!_initialized || _deviceId == null) return;
    
    try {
      await _firestore.collection('debug_logs').add({
        'deviceId': _deviceId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'mobile',
      });
    } catch (e) {
      // Игнорируем ошибки логов
    }
  }
  
  // Вспомогательный метод: генерация случайной строки
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().microsecond;
    final buffer = StringBuffer();
    
    for (var i = 0; i < length; i++) {
      buffer.write(chars[(random + i) % chars.length]);
    }
    
    return buffer.toString();
  }
  
  // Геттеры для отладки
  bool get isInitialized => _initialized;
  String? get deviceId => _deviceId;
}