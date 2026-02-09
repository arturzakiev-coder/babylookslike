import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';

class ContactUsScreen extends StatefulWidget {
  @override
  _ContactUsScreenState createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  
  bool _isSending = false;
  bool _isSent = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSending = true;
        _errorMessage = null;
      });
      
      try {
        final firebaseService = Provider.of<FirebaseService>(context, listen: false);
        
        // Проверяем инициализацию Firebase
        if (!firebaseService.isInitialized) {
          await firebaseService.initialize();
        }
        
        // Сохраняем обратную связь в Firebase
        await firebaseService.saveFeedback(
          message: _messageController.text.trim(),
          deviceId: firebaseService.deviceId,
        );
        
        setState(() {
          _isSending = false;
          _isSent = true;
        });
        
        // Очищаем форму после успешной отправки
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
        
        // Показываем сообщение об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Сообщение отправлено! Спасибо за обратную связь.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Автоматически возвращаемся назад через 2 секунды
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
        
      } catch (e) {
        setState(() {
          _isSending = false;
          _errorMessage = 'Ошибка отправки: $e';
        });
        
        if (kDebugMode) {
          print('❌ Error sending feedback: $e');
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Связаться с нами'),
        backgroundColor: Color(0xFF4FC3F7),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _isSent
            ? _buildSuccessScreen()
            : _buildFeedbackForm(),
      ),
    );
  }
  
  Widget _buildFeedbackForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Обратная связь',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Есть вопросы, предложения или нашли ошибку? Напишите нам!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 30),
      
          
          // Сообщение
          TextFormField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: 'Сообщение',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.message),
            ),
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Пожалуйста, введите сообщение';
              }
              if (value.trim().length < 10) {
                return 'Сообщение должно содержать не менее 10 символов';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          
          // Информация
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Что можно написать:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• Предложения по улучшению приложения\n'
                  '• Сообщения об ошибках\n'
                  '• Идеи для новых функций\n'
                  '• Отзывы о работе FaceCloud AI\n'
                  '• Любые другие вопросы',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          
          // Кнопка отправки
          if (_errorMessage != null) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[800]),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
          
          ElevatedButton(
            onPressed: _isSending ? null : _submitFeedback,
            child: _isSending
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('Отправка...'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send),
                      SizedBox(width: 10),
                      Text('Отправить сообщение'),
                    ],
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4FC3F7),
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Вернуться назад'),
            style: TextButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle,
          size: 80,
          color: Colors.green,
        ),
        SizedBox(height: 20),
        Text(
          'Спасибо!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        SizedBox(height: 15),
        Text(
          'Ваше сообщение успешно отправлено.',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Text(
          'Мы свяжемся с вами при необходимости.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Вернуться назад'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4FC3F7),
            foregroundColor: Colors.white,
            minimumSize: Size(200, 50),
          ),
        ),
      ],
    );
  }
}