import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/attempt_service_cloud.dart'; // <-- ИЗМЕНИТЬ ИМПОРТ

class PurchaseScreen extends StatelessWidget {
  final List<Map<String, dynamic>> packages = [
    {
      'name': 'МИНИ',
      'attempts': 10,
      'price': 99,
      'perAttempt': 9.9,
      'popular': false,
    },
    {
      'name': 'СТАНДАРТ',
      'attempts': 30,
      'price': 249,
      'perAttempt': 8.3,
      'popular': true,
    },
    {
      'name': 'ПРЕМИУМ',
      'attempts': 100,
      'price': 699,
      'perAttempt': 7.0,
      'popular': false,
    },
  ];
  
  final List<Map<String, dynamic>> subscriptions = [
    {
      'name': 'БЕЗЛИМИТ',
      'description': 'Неограниченно сравнений',
      'price': 299,
      'period': 'в месяц',
      'popular': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final attemptService = Provider.of<AttemptServiceCloud>(context); // <-- ИЗМЕНИТЬ ТИП
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Пополните баланс'),
        backgroundColor: Color(0xFF4FC3F7),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Текущий баланс
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFF4FC3F7),
                      size: 30,
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ваш баланс:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${attemptService.totalAttempts} попыток',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4FC3F7),
                            ),
                          ),
                          if (attemptService.freeAttempts > 0 || attemptService.purchasedAttempts > 0)
                            Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Row(
                                children: [
                                  if (attemptService.freeAttempts > 0)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      margin: EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.green[100]!),
                                      ),
                                      child: Text(
                                        'Бесплатные: ${attemptService.freeAttempts}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green[800],
                                        ),
                                      ),
                                    ),
                                  if (attemptService.purchasedAttempts > 0)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.blue[100]!),
                                      ),
                                      child: Text(
                                        'Купленные: ${attemptService.purchasedAttempts}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              
              // Бесплатные попытки
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.card_giftcard, color: Colors.green),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'БЕСПЛАТНО',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            attemptService.freeAttempts > 0
                                ? 'Осталось ${attemptService.freeAttempts} бесплатных попыток'
                                : 'Бесплатные попытки использованы',
                            style: TextStyle(color: Colors.green[800]),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      attemptService.freeAttempts > 0 
                          ? Icons.card_giftcard 
                          : Icons.check_circle,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              
              // Пакеты попыток
              Text(
                'ПАКЕТЫ ПОПЫТОК',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              SizedBox(height: 20),
              
              // Пакет 1
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'МИНИ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '10 сравнений',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF4FC3F7),
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        '99 ₽',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('9.9 ₽ / сравнение', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          attemptService.addAttempts(10);
                          print('Куплен пакет МИНИ');
                          Navigator.pop(context); // Вернуться назад
                        },
                        child: Text('КУПИТЬ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4FC3F7),
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              
              // Пакет 2 (рекомендуемый)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Color(0xFFFF8A65), width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF8A65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'САМЫЙ ВЫГОДНЫЙ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'СТАНДАРТ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '30 сравнений',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF4FC3F7),
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        '249 ₽',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('8.3 ₽ / сравнение', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          attemptService.addAttempts(30);
                          print('Куплен пакет СТАНДАРТ');
                          Navigator.pop(context);
                        },
                        child: Text('КУПИТЬ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4FC3F7),
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              
              // Пакет 3
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'ПРЕМИУМ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '100 сравнений',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF4FC3F7),
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        '699 ₽',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('7.0 ₽ / сравнение', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          attemptService.addAttempts(100);
                          print('Куплен пакет ПРЕМИУМ');
                          Navigator.pop(context);
                        },
                        child: Text('КУПИТЬ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4FC3F7),
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40),
              
              // Подписка
              Text(
                'ПОДПИСКА',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              SizedBox(height: 20),
              
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.purple[200]!, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.purple),
                          SizedBox(width: 10),
                          Text(
                            'БЕЗЛИМИТ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Неограниченно сравнений',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Text(
                        '299 ₽',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      Text('в месяц', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          print('Оформлена подписка БЕЗЛИМИТ');
                          // Для подписки сбросим счетчик и будем считать что безлимит
                          attemptService.addAttempts(999, isPurchased: true);
                          Navigator.pop(context);
                        },
                        child: Text('ПОДПИСАТЬСЯ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 30),
              Text(
                '• Тестовый режим - попытки добавляются без оплаты\n• В продакшене будет интеграция с App Store / Google Play',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}