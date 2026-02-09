// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

import 'services/attempt_service_cloud.dart';
import 'services/firebase_service.dart';
import 'screens/main_screen.dart';
import 'screens/purchase_screen.dart';
import 'firebase_config.dart';

void main() async {

    // Отключаем проверку типа Provider
  Provider.debugCheckInvalidValueType = null;
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
  } catch (e) {
    print('⚠️ Could not load .env file: $e');
    print('ℹ️ Continuing without .env file');
  }

  // 2. ИНИЦИАЛИЗАЦИЯ FIREBASE (ОДИН РАЗ!)
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
    // Продолжаем работу даже без Firebase для отладки
  }

  // 3. ИНИЦИАЛИЗАЦИЯ СЕРВИСОВ
  final firebaseService = FirebaseService();

  runApp(
    MyApp(
      firebaseService: firebaseService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final FirebaseService firebaseService;
  
  MyApp({
    required this.firebaseService,
  });
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Добавляем FirebaseService в провайдеры
        Provider<FirebaseService>.value(value: firebaseService),
        
        ChangeNotifierProvider(
          create: (_) {
            final attemptService = AttemptServiceCloud(firebaseService);
            
            // Отложенная инициализация FirebaseService
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                await firebaseService.initialize();
                
                if (firebaseService.isInitialized) {
                  print('✅ FirebaseService initialized');
                  print('📱 Device ID: ${firebaseService.deviceId}');
                  
                  final balance = await firebaseService.loadAttemptBalance();
                  print('\n=== BALANCE INFORMATION ===');
                  print('📊 Free attempts: ${balance['freeAttempts']}');
                  print('💰 Purchased attempts: ${balance['purchasedAttempts']}');
                  print('🧮 Total: ${balance['freeAttempts']! + balance['purchasedAttempts']!}');
                  print('===========================\n');
                } else {
                  print('⚠️ FirebaseService NOT initialized (using fallback)');
                }
              } catch (e) {
                print('❌ Error initializing FirebaseService: $e');
              }
            });
            
            return attemptService;
          },
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
        routes: {
          '/purchase': (context) => PurchaseScreen(),
        },
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