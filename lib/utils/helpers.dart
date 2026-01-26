import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  // Форматирование даты
  static String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }
  
  // Форматирование цены
  static String formatPrice(double price) {
    return NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    ).format(price);
  }
  
  // Получение цвета по проценту
  static Color getColorByPercentage(double percentage) {
    if (percentage >= 0.7) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }
  
  // Получение текста по проценту
  static String getTextByPercentage(double percentage) {
    if (percentage >= 0.7) return 'Высокое сходство';
    if (percentage >= 0.5) return 'Среднее сходство';
    return 'Низкое сходство';
  }
  
  // Проверка email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  // Показать диалог
  static Future<void> showInfoDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  // Показать SnackBar
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Генерация имени файла
  static String generateFileName(String prefix) {
    final now = DateTime.now();
    return '${prefix}_${now.day}_${now.month}_${now.year}_${now.hour}_${now.minute}.jpg';
  }
  
  // Расчет стоимости за сравнение
  static double calculatePricePerAttempt(int attempts, int price) {
    return price / attempts;
  }
}