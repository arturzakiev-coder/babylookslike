import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'save_success_screen.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> results;
  final List<XFile?> photoFiles;
  
  const ResultsScreen({
    Key? key,
    required this.results,
    required this.photoFiles,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final motherPercent = results['mother'] as double;
    final fatherPercent = results['father'] as double;
    final details = results['details'] as Map<String, double>;
    final isRealApi = results['isRealApi'] ?? false;
    final hasApiError = results['hasApiError'] ?? false;
    final metadata = results['metadata'] as Map<String, dynamic>? ?? {};
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Результат сравнения'),
        backgroundColor: Color(0xFF4FC3F7),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Заголовок
              Text(
                'Результат сравнения',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Индикатор API
              SizedBox(height: 10),
              _buildApiStatusIndicator(isRealApi, hasApiError),
              
              SizedBox(height: 20),
              
              // Сравнение с мамой
              _buildResultCard(
                'Малыш → Мама',
                motherPercent,
                Color(0xFFFF8A65),
              ),
              SizedBox(height: 20),
              
              // Сравнение с папой
              _buildResultCard(
                'Малыш → Папа',
                fatherPercent,
                Color(0xFF4FC3F7),
              ),
              SizedBox(height: 40),
              
              // Детализация
              _buildDetailsSection(details),
              SizedBox(height: 30),
              
              // Вывод
              _buildConclusion(motherPercent, fatherPercent, isRealApi),
              SizedBox(height: 40),
              
              // Кнопки действий
              _buildActionButtons(context, isRealApi, hasApiError, metadata),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildApiStatusIndicator(bool isRealApi, bool hasApiError) {
    if (hasApiError) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange[100]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, size: 16, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'API временно недоступен',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    if (isRealApi) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green[100]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 16, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Результаты FaceCloud AI',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud, size: 16, color: Colors.blue),
          SizedBox(width: 8),
          Text(
            'Тестовые данные',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultCard(String title, double percentage, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF424242),
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailsSection(Map<String, double> details) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Детальный анализ:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          SizedBox(height: 15),
          ...details.entries.map((entry) => 
            _buildDetailRow(entry.key, entry.value)
          ).toList(),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String feature, double percentage) {
    Color color;
    if (percentage > 0.7) color = Colors.green;
    else if (percentage > 0.5) color = Colors.orange;
    else color = Colors.red;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              feature,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Container(
            width: 100,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Text(
            '${(percentage * 100).toInt()}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConclusion(double motherPercent, double fatherPercent, bool isRealApi) {
    String conclusion;
    Color color = Color(0xFF4FC3F7);
    
    if (motherPercent - fatherPercent > 0.2) {
      conclusion = 'Малыш больше похож на маму!';
      color = Color(0xFFFF8A65);
    } else if (fatherPercent - motherPercent > 0.2) {
      conclusion = 'Малыш больше похож на папу!';
      color = Color(0xFF4FC3F7);
    } else {
      conclusion = 'Малыш одинаково похож на обоих родителей!';
      color = Colors.purple;
    }
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            isRealApi ? Icons.psychology : Icons.emoji_emotions,
            size: 40,
            color: color,
          ),
          SizedBox(height: 10),
          Text(
            'Наш вывод:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 10),
          Text(
            conclusion,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF424242),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context, bool isRealApi, bool hasApiError, Map<String, dynamic> metadata) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SaveSuccessScreen(),
              ),
            );
          },
          icon: Icon(Icons.save),
          label: Text('Сохранить в галерею'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4FC3F7),
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
          ),
        ),
        SizedBox(height: 15),
        OutlinedButton.icon(
          onPressed: () {
            _showShareDialog(context, isRealApi, hasApiError);
          },
          icon: Icon(Icons.share),
          label: Text('Поделиться результатом'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Color(0xFF4FC3F7)),
            foregroundColor: Color(0xFF4FC3F7),
            minimumSize: Size(double.infinity, 50),
          ),
        ),
        SizedBox(height: 15),
        TextButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            );
          },
          child: Text('Сравнить еще раз'),
        ),
        
        // Техническая информация
        if (hasApiError || !isRealApi)
          Container(
            margin: EdgeInsets.only(top: 20),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Техническая информация:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  hasApiError 
                      ? 'API FaceCloud временно недоступен. Используются тестовые данные.'
                      : 'Используется демо-режим с тестовыми данными.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  void _showShareDialog(BuildContext context, bool isRealApi, bool hasApiError) {
    final motherPercent = results['mother'] as double;
    final fatherPercent = results['father'] as double;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Поделиться результатом'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Малыш похож на маму: ${(motherPercent * 100).toInt()}%'),
            Text('Малыш похож на папу: ${(fatherPercent * 100).toInt()}%'),
            SizedBox(height: 10),
            if (!isRealApi || hasApiError)
              Text(
                '⚠️ Используются тестовые данные',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Реализовать реальный шеринг
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Функция поделиться в разработке'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: Text('Поделиться'),
          ),
        ],
      ),
    );
  }
}