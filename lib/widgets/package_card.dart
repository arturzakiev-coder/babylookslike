import 'package:flutter/material.dart';

class PackageCard extends StatelessWidget {
  final String title;
  final int attempts;
  final int price;
  final double pricePerAttempt;
  final bool isPopular;
  final VoidCallback onPurchase;
  
  const PackageCard({
    required this.title,
    required this.attempts,
    required this.price,
    required this.pricePerAttempt,
    required this.isPopular,
    required this.onPurchase,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isPopular ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isPopular 
              ? Color(0xFFFF8A65) 
              : Colors.grey[200]!,
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (isPopular)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Color(0xFFFF8A65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'РЕКОМЕНДУЕМ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isPopular) SizedBox(height: 10),
            
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            SizedBox(height: 10),
            
            Text(
              '$attempts сравнений',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF4FC3F7),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 15),
            
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$price ',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                  ),
                  TextSpan(
                    text: '₽',
                    style: TextStyle(
                      fontSize: 24,
                      color: Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            ),
            
            Text(
              '${pricePerAttempt.toStringAsFixed(1)} ₽ / сравнение',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: onPurchase,
              child: Text('КУПИТЬ СЕЙЧАС'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4FC3F7),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}