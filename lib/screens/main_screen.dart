import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/attempt_service_cloud.dart'; // <-- ИЗМЕНИТЬ ИМПОРТ
import 'photo_upload_screen.dart';
import 'purchase_screen.dart';
import '../widgets/attempt_counter.dart';
//import 'purchase_screen.dart'; // если еще нет

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final attemptService = Provider.of<AttemptServiceCloud>(context); // <-- ИЗМЕНИТЬ ТИП
    
    return Scaffold(
      appBar: AppBar(
        title: Text('На кого похож малыш?'),
        backgroundColor: Color(0xFF4FC3F7),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            
            // Счетчик попыток
            AttemptCounter(attempts: attemptService.totalAttempts),
            SizedBox(height: 40),
            
            // Основная кнопка
            ElevatedButton.icon(
              onPressed: () {
                if (attemptService.canCompare()) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoUploadScreen(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PurchaseScreen(),
                    ),
                  );
                }
              },
              icon: Icon(Icons.family_restroom, size: 28),
              label: Text(
                'Сравнить малыша с родителями',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4FC3F7),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                minimumSize: Size(double.infinity, 70),
              ),
            ),
            SizedBox(height: 20),
            
            // Вторичная кнопка
            ElevatedButton.icon(
              onPressed: () {
                print('Сравнить двух людей');
              },
              icon: Icon(Icons.people, size: 28),
              label: Text(
                'Сравнить двух людей',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF8A65),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                minimumSize: Size(double.infinity, 70),
              ),
            ),
            SizedBox(height: 40),
            
            // Кнопка магазина
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PurchaseScreen(),
                  ),
                );
              },
              icon: Icon(Icons.shopping_cart),
              label: Text('Магазин попыток'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Color(0xFF4FC3F7)),
                foregroundColor: Color(0xFF4FC3F7),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}