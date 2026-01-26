import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4FC3F7);
  static const Color accent = Color(0xFFFF8A65);
  static const Color background = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF424242);
  static const Color textSecondary = Color(0xFF757575);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
}

class AppText {
  static const String appName = 'На кого похож малыш';
  static const String mainTitle = 'На кого похож малыш?';
  static const String compareBabyParents = 'Сравнить малыша с родителями';
  static const String compareTwoPeople = 'Сравнить двух людей';
  static const String shop = 'Магазин попыток';
  static const String availableAttempts = 'Доступно попыток';
  static const String freeAttempts = 'Бесплатные попытки';
  static const String purchasedAttempts = 'Купленные попытки';
}

class AppRoutes {
  static const String home = '/';
  static const String upload = '/upload';
  static const String processing = '/processing';
  static const String results = '/results';
  static const String purchase = '/purchase';
  static const String saveSuccess = '/save-success';
}