import 'package:flutter/material.dart';

class AttemptCounter extends StatelessWidget {
  final int attempts;
  
  const AttemptCounter({super.key, required this.attempts});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        children: [
          Text(
            'Доступно попыток',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 10),
          Text(
            '$attempts',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4FC3F7),
            ),
          ),
        ],
      ),
    );
  }
}