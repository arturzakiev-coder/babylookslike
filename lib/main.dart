import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/attempt_service_cloud.dart';
import 'services/firebase_service.dart';
import 'screens/main_screen.dart';
import 'firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== APPLICATION STARTING ===');
  
  try {
    await Firebase.initializeApp(
      options: FirebaseConfig.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
    // Продолжаем работу даже без Firebase для отладки
  }
  
  // Инициализируем FirebaseService
  final firebaseService = FirebaseService();
  
  try {
    await firebaseService.initialize();
    
    if (firebaseService.isInitialized) {
      print('✅ FirebaseService initialized');
      print('📱 Device ID: ${firebaseService.deviceId}');
    } else {
      print('⚠️ FirebaseService NOT initialized (using fallback)');
    }
  } catch (e) {
    print('❌ Error initializing FirebaseService: $e');
  }
  
  runApp(MyApp(firebaseService: firebaseService));
}

class MyApp extends StatelessWidget {
  final FirebaseService firebaseService;
  
  MyApp({required this.firebaseService});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Создаем AttemptServiceCloud с передачей FirebaseService
      create: (_) {
        final attemptService = AttemptServiceCloud(firebaseService);
        
        // Отладочная информация после инициализации UI
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
              
              // Логируем в Firestore для отладки
              await firebaseService.logToConsole('App started - Balance loaded');
            } catch (e) {
              print('❌ Error loading balance: $e');
            }
          } else {
            print('⚠️ Using local storage only (Firebase not available)');
          }
        });
        
        return attemptService;
      },
      child: MaterialApp(
        title: 'На кого похож малыш',
        theme: ThemeData(
          primaryColor: Color(0xFF4FC3F7),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blue,
          ).copyWith(
            secondary: Color(0xFFFF8A65),
          ),
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
        
        // Настройки для лучшего отображения в браузере
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0, // Фиксируем масштаб текста
            ),
            child: child!,
          );
        },
      ),
    );
  }
}