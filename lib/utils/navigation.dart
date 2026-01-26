import 'package:flutter/material.dart';

class Navigation {
  // Переход с анимацией
  static Future<void> push(BuildContext context, Widget page) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
  
  // Замена текущего экрана
  static Future<void> pushReplacement(BuildContext context, Widget page) async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
  
  // Переход на главный экран
  static void goToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }
  
  // Показать bottom sheet
  static Future<T?> showBottomSheet<T>(
    BuildContext context,
    Widget child,
  ) async {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => child,
    );
  }
  
  // Показать диалог выбора
  static Future<T?> showChoiceDialog<T>(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> choices,
  ) async {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: choices.map((choice) => ListTile(
            leading: Icon(choice['icon']),
            title: Text(choice['title']),
            onTap: () => Navigator.pop(context, choice['value']),
          )).toList(),
        ),
      ),
    );
  }
}