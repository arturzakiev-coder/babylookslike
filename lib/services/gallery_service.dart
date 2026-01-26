import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class GalleryService {
  Future<bool> saveComparisonResult({
    required double motherSimilarity,
    required double fatherSimilarity,
    required Map<String, double> details,
  }) async {
    try {
      // Создаем виджет с результатом
      final widget = _buildResultWidget(
        motherSimilarity,
        fatherSimilarity,
        details,
      );
      
      // Конвертируем виджет в изображение
      final imageBytes = await _widgetToImage(widget);
      
      if (imageBytes == null) return false;
      
      // Сохраняем в галерею
      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(imageBytes),
        quality: 100,
        name: 'Сравнение_Малыш_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      return result['isSuccess'] == true;
    } catch (e) {
      print('Error saving to gallery: $e');
      return false;
    }
  }
  
  Widget _buildResultWidget(
    double motherSimilarity,
    double fatherSimilarity,
    Map<String, double> details,
  ) {
    return Material(
      child: Container(
        width: 1080,
        height: 1920,
        color: Colors.white,
        padding: EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Заголовок
            Text(
              'НА КОГО ПОХОЖ МАЛЫШ?',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4FC3F7),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Результат сравнения',
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 40),
            
            // Разделитель
            Container(
              height: 2,
              color: Colors.grey[300],
            ),
            SizedBox(height: 40),
            
            // Основные результаты
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildComparisonItem('МАЛЫШ', '👶', Colors.blue),
                _buildComparisonItem('МАМА', '👩', Colors.pink),
                _buildComparisonItem('ПАПА', '👨', Colors.blue),
              ],
            ),
            SizedBox(height: 30),
            
            // Проценты
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildPercentageCard(
                    'Малыш → Мама',
                    motherSimilarity,
                    Color(0xFFFF8A65),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: _buildPercentageCard(
                    'Малыш → Папа',
                    fatherSimilarity,
                    Color(0xFF4FC3F7),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            
            // Детализация
            Text(
              'ДЕТАЛЬНЫЙ АНАЛИЗ:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            
            ...details.entries.map((entry) => 
              _buildDetailRow(entry.key, entry.value)
            ).toList(),
            
            Spacer(),
            
            // Подвал
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.grey[50],
              child: Column(
                children: [
                  Text(
                    'Сравнение сделано: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'в приложении "На кого похож малыш"',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildComparisonItem(String title, String emoji, Color color) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              emoji,
              style: TextStyle(fontSize: 40),
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPercentageCard(String title, double percentage, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '${(percentage * 100).toInt()}%',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String feature, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature.toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              color: _getColorForPercentage(percentage),
              minHeight: 10,
            ),
          ),
          SizedBox(width: 10),
          Text(
            '${(percentage * 100).toInt()}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getColorForPercentage(double percentage) {
    if (percentage > 0.7) return Colors.green;
    if (percentage > 0.5) return Colors.orange;
    return Colors.red;
  }
  
  Future<List<int>?> _widgetToImage(Widget widget) async {
    try {
      final RenderRepaintBoundary boundary = RenderRepaintBoundary();
      final view = ui.PlatformDispatcher.instance.views.first;
      
      final pipelineOwner = PipelineOwner();
      final buildOwner = BuildOwner(
        focusManager: FocusManager(),
        onBuildScheduled: () {},
      );
      
      final root = RenderObjectToWidgetAdapter<RenderBox>(
        container: boundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: widget,
        ),
      );
      
      final widgetBinding = WidgetsBinding.instance;
      widgetBinding.rootElement = root.attachToRenderTree(
        buildOwner, 
        RenderObjectToWidgetElement(root)
      );
      
      buildOwner.buildScope(widgetBinding.rootElement!);
      buildOwner.finalizeTree();
      
      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error converting widget to image: $e');
      return null;
    }
  }
}