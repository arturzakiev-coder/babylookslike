import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FirebaseConfig {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Конфигурация для веба
      return FirebaseOptions(
        apiKey: "AIzaSyB_zRuPZS-HvxIkCPcGl6XKiBoKGsY-5v8",
        authDomain: "whobabylike-f9525.firebaseapp.com",
        projectId: "whobabylike-f9525",
        storageBucket: "whobabylike-f9525.firebasestorage.app",
        messagingSenderId: "209528512712",
        appId: "1:209528512712:web:e55fa830ef519d0ab505fd",
      );
    } else {
      // Для iOS/Android - автоматически из конфиг файлов
      return FirebaseOptions(
        apiKey: "auto",
        authDomain: "auto",
        projectId: "auto",
        storageBucket: "auto",
        messagingSenderId: "auto",
        appId: "auto",
      );
    }
  }
}