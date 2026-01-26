class FaceCloudConfig {
  // ЗАМЕНИТЕ ЭТИ ДАННЫЕ НА ВАШИ РЕАЛЬНЫЕ
  static const String email = 'arturzakiev@mail.ru';
  static const String password = 'aehius1M';
  
  static String get maskedEmail {
    if (email.isEmpty) return 'not configured';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    return '${parts[0].substring(0, 1)}***@${parts[1]}';
  }
}