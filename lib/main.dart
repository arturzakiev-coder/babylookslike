// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

import 'services/attempt_service_cloud.dart';
import 'services/firebase_service.dart';
import 'services/revenuecat_service.dart';
import 'screens/main_screen.dart';
import 'screens/purchase_screen.dart'; // ДОБАВЬТЕ ИМПОРТ
import 'firebase_config.dart';
import 'services/revenuecat_initializer.dart';
import 'services/revenuecat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('=== APPLICATION STARTING ===');

  // 1. ЗАГРУЗКА .env ФАЙЛА
  try {
    if (kIsWeb) {
      await dotenv.load(fileName: 'assets/.env');
      print('🌐 Web platform detected, loaded .env from assets');
    } else {
      await dotenv.load(fileName: '.env');
      print('📱 Mobile platform detected, loaded .env from root');
    }

    final revenueCatKey = dotenv.env['REVENUECAT_ANDROID_KEY'];
    if (revenueCatKey != null && revenueCatKey.isNotEmpty) {
      final keyPreview = revenueCatKey.substring(
        0,
        revenueCatKey.length > 10 ? 10 : revenueCatKey.length,
      );
      print('🔑 RevenueCat Key loaded: $keyPreview...');
    } else {
      print('⚠️ RevenueCat key not found in .env file');
    }
  } catch (e) {
    print('⚠️ Could not load .env file: $e');
    print('ℹ️ Continuing without .env file');
  }

  // 2. ИНИЦИАЛИЗАЦИЯ FIREBASE
  try {
    await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
  }

  try {
    await RevenueCatInitializer.initialize();
  } catch (e) {
    print('⚠️ RevenueCat init failed: $e');
    // Продолжаем работу
  }

  final revenueCatService = RevenueCatService();

  // 3. ИНИЦИАЛИЗАЦИЯ СЕРВИСОВ
  final firebaseService = FirebaseService();
  //final revenueCatService = RevenueCatService(firebaseService);

  try {
  // Проверяем не инициализирован ли уже Firebase
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: FirebaseConfig.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } else {
    print('ℹ️ Firebase already initialized');
  }
} catch (e) {
  print('❌ Error initializing Firebase: $e');
}

  runApp(
    MyApp(
      firebaseService: firebaseService,
      revenueCatService: revenueCatService,
    ),
  );
  // ИНИЦИАЛИЗАЦИЯ RevenueCat ПОСЛЕ запуска приложения
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      print('🔄 Starting RevenueCat initialization...');
      await revenueCatService.initialize();
      
      if (revenueCatService.isInitialized) {
        print('✅ RevenueCatService initialized successfully');
      } else {
        print('⚠️ RevenueCatService NOT initialized');
      }
    } catch (e) {
      print('❌ Error during RevenueCat initialization: $e');
    }
  });
}

  

class MyApp extends StatelessWidget {
  final FirebaseService firebaseService;
  final RevenueCatService revenueCatService;
  
  MyApp({
    required this.firebaseService,
    required this.revenueCatService,
  });
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. AttemptService
        ChangeNotifierProvider(
          create: (_) {
            final attemptService = AttemptServiceCloud(firebaseService);
            
            // Отложенная инициализация
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (firebaseService.isInitialized) {
                try {
                  final balance = await firebaseService.loadAttemptBalance();
                  print('\n=== BALANCE INFORMATION ===');
                  print('📊 Free attempts: ${balance['freeAttempts']}');
                  print('💰 Purchased attempts: ${balance['purchasedAttempts']}');
                  print('🧮 Total: ${balance['freeAttempts']! + balance['purchasedAttempts']!}');
                  print('🆔 Device: ${firebaseService.deviceId}');
                  print('===========================\n');
                } catch (e) {
                  print('❌ Error loading balance: $e');
                }
              }
            });
            
            return attemptService;
          },
        ),
        
        // 2. RevenueCatService - ПРОСТОЙ создатель
        ChangeNotifierProvider<RevenueCatService>(
  create: (_) => revenueCatService,
),
      ],
      child: MaterialApp(
        title: 'На кого похож малыш',
        theme: ThemeData(
          primaryColor: Color(0xFF4FC3F7),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blue,
          ).copyWith(secondary: Color(0xFFFF8A65)),
          fontFamily: 'Roboto',
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF4FC3F7),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4FC3F7),
              foregroundColor: Colors.white,
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: MainScreen(),
        debugShowCheckedModeBanner: false,

        // Маршруты
        routes: {'/purchase': (context) => PurchaseScreen()},

        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child!,
          );
        },
      ),
    );
  }
}
