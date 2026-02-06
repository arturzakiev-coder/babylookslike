class FaceCloudConfig {
  // ВАШИ РЕАЛЬНЫЕ ДАННЫЕ FACECLOUD
  static const String email = 'arturzakiev@mail.ru';
  static const String password = 'aehius1M'; // <-- ВАШ ПАРОЛЬ ЗДЕСЬ
  
  // Для отладки (безопасный вывод)
  static String get maskedEmail {
    if (email.isEmpty) return 'not configured';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    return '${parts[0].substring(0, 1)}***@${parts[1]}';
  }
}