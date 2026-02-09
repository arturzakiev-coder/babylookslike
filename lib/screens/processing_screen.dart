import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'results_screen.dart';
import '../services/facecloud_service.dart';
import '../services/attempt_service_cloud.dart';
import '../services/firebase_service.dart';

class ProcessingScreen extends StatefulWidget {
  final List<XFile?> photoFiles;
  final List<Uint8List?> photoBytes;
  final List<String> photoNames;

  const ProcessingScreen({
    super.key,
    required this.photoFiles,
    required this.photoBytes,
    required this.photoNames,
  });

  @override
  _ProcessingScreenState createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<String> _messages = [
    'Загружаем фотографии...',
    'Анализируем черты лица...',
    'Сравниваем с мамой...',
    'Сравниваем с папой...',
    'Формируем результат...',
  ];
  int _currentMessageIndex = 0;
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);

    // Начинаем обработку
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    // Получаем сервис попыток
    final attemptService = Provider.of<AttemptServiceCloud>(
      context,
      listen: false,
    );
    bool attemptUsed = false;

    try {
      // 1. Инициализируем сервис FaceCloud
      setState(() => _currentMessageIndex = 0);

      final faceService = FaceCloudService();
      await faceService.initialize();

      if (faceService.lastError != null) {
        if (kDebugMode) {
          print(
            'FaceCloud initialization had issues: ${faceService.lastError}',
          );
        }
      }

      if (!faceService.isAuthenticated) {
        if (kDebugMode) {
          print('FaceCloud: Not authenticated, will use fallback');
        }
      } else {
        if (kDebugMode) {
          print('FaceCloud: Authenticated with API');
        }
      }

      // 2. Анализируем черты лица
      setState(() => _currentMessageIndex = 1);
      await Future.delayed(Duration(seconds: 1));

      // 3. Сравниваем с мамой (РЕАЛЬНЫЙ API-запрос)
      setState(() => _currentMessageIndex = 2);

      final motherComparison = await faceService.compareTwoFaces(
        imagePath1: widget.photoFiles[0]?.path ?? '',
        imagePath2: widget.photoFiles[1]?.path ?? '',
        imageBytes1: widget.photoBytes[0],
        imageBytes2: widget.photoBytes[1],
        imageName1: widget.photoNames[0],
        imageName2: widget.photoNames[1],
      );

      // 4. Сравниваем с папой (РЕАЛЬНЫЙ API-запрос)
      setState(() => _currentMessageIndex = 3);

      final fatherComparison = await faceService.compareTwoFaces(
        imagePath1: widget.photoFiles[0]?.path ?? '',
        imagePath2: widget.photoFiles[2]?.path ?? '',
        imageBytes1: widget.photoBytes[0],
        imageBytes2: widget.photoBytes[2],
        imageName1: widget.photoNames[0],
        imageName2: widget.photoNames[2],
      );

      // 5. Формируем результат
      setState(() => _currentMessageIndex = 4);
      await Future.delayed(Duration(milliseconds: 500));

      // Проверяем успешность обоих сравнений
      final bool isMotherSuccessful = motherComparison['success'] == true;
      final bool isFatherSuccessful = fatherComparison['success'] == true;

      if (kDebugMode) {
        print('📊 Mother comparison success: $isMotherSuccessful');
        print('📊 Father comparison success: $isFatherSuccessful');
        print('📊 Mother error: ${motherComparison['error']}');
        print('📊 Father error: ${fatherComparison['error']}');
      }

      // Если ОБА сравнения успешны
      if (isMotherSuccessful && isFatherSuccessful) {
  // ВАЖНО: Списание попытки происходит ТОЛЬКО здесь, если оба сравнения успешны
  final canProceed = await attemptService.useAttempt();
  if (!canProceed) {
    // Если по какой-то причине не удалось списать попытку
    throw Exception('Не удалось списать попытку. Пожалуйста, попробуйте снова.');
  }
  attemptUsed = true;
  
  final results = _prepareResults(
    motherComparison, 
    fatherComparison,
  );
  
  // Сохраняем результаты в Firebase (добавлено)
try {
  final firebaseService = Provider.of<FirebaseService>(context, listen: false);
  
  // Убедимся, что FirebaseService инициализирован
  if (!firebaseService.isInitialized) {
    await firebaseService.initialize();
  }
  
  if (firebaseService.isInitialized) {
    await firebaseService.saveComparisonResult(
      motherSimilarity: motherComparison['score'] ?? 0.0,
      fatherSimilarity: fatherComparison['score'] ?? 0.0,
      details: _calculateDetails(
        motherComparison['score'] ?? 0.0,
        fatherComparison['score'] ?? 0.0,
      ),
    );
    
    if (kDebugMode) {
      print('✅ Comparison results saved to Firebase');
    }
  } else {
    if (kDebugMode) {
      print('⚠️ FirebaseService not initialized, skipping save');
    }
  }
} catch (e) {
  if (kDebugMode) {
    print('⚠️ Failed to save comparison to Firebase: $e');
  }
  // Не прерываем выполнение, если не удалось сохранить в Firebase
}
  
  if (mounted) {
    _navigateToResults(results);
  }
} else {
        // Если хотя бы одно сравнение неуспешно, НЕ списываем попытку
        // и показываем ошибку пользователю
        if (kDebugMode) {
          print('⚠️ API returned errors, NOT deducting attempt');
        }

        // Показываем понятную ошибку пользователю
        if (mounted) {
          _showApiError(motherComparison, fatherComparison);
        }
        return; // ВАЖНО: Прекращаем выполнение
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Processing error: $e');
      }

      if (mounted) {
        // Если попытка была списана, но произошла ошибка
        if (attemptUsed) {
          _showErrorWithRetry('Ошибка обработки: $e');
        } else {
          // Если попытка НЕ была списана, показываем общую ошибку
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text('Ошибка', style: TextStyle(color: Colors.red)),
              content: Text(
                'Произошла ошибка при обработке. Попробуйте еще раз.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Закрыть диалог
                    Navigator.pop(context); // Вернуться к загрузке фото
                  },
                  child: Text(
                    'Вернуться',
                    style: TextStyle(color: Color(0xFF4FC3F7)),
                  ),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Map<String, dynamic> _prepareResults(
    Map<String, dynamic> motherComparison,
    Map<String, dynamic> fatherComparison,
  ) {
    if (kDebugMode) {
      print('🚨 _prepareResults called!');
      print('   Mother success: ${motherComparison['success']}');
      print('   Father success: ${fatherComparison['success']}');
      print('   Stack trace:');
      print(StackTrace.current);
    }

    final motherScore = motherComparison['score'] ?? 0.5;
    final fatherScore = fatherComparison['score'] ?? 0.5;
    final isRealApi =
        motherComparison['isRealApi'] == true &&
        fatherComparison['isRealApi'] == true;
    final hasApiError =
        motherComparison['api_error'] == true ||
        fatherComparison['api_error'] == true;

    if (kDebugMode) {
      print('📊 FINAL RESULTS:');
      print('   Mother similarity: ${(motherScore * 100).toInt()}%');
      print('   Father similarity: ${(fatherScore * 100).toInt()}%');
      print('   Is real API: $isRealApi');
      print('   Has API error: $hasApiError');
    }

    // Создаем детализацию на основе результатов
    final details = _calculateDetails(motherScore, fatherScore);

    return {
      'mother': motherScore,
      'father': fatherScore,
      'details': details,
      'isRealApi': isRealApi && !hasApiError,
      'hasApiError': hasApiError,
      'metadata': {
        'motherData': motherComparison,
        'fatherData': fatherComparison,
        'motherScoreRaw': motherScore,
        'fatherScoreRaw': fatherScore,
      },
    };
  }

  Map<String, double> _calculateDetails(
    double motherScore,
    double fatherScore,
  ) {
    final avgScore = (motherScore + fatherScore) / 2;

    return {
      'Глаза': 0.5 + avgScore * 0.4,
      'Нос': 0.5 + avgScore * 0.3,
      'Рот': 0.5 + avgScore * 0.35,
      'Форма лица': 0.5 + avgScore * 0.45,
      'Общие черты': avgScore,
    };
  }

  void _showApiError(
    Map<String, dynamic> motherComparison,
    Map<String, dynamic> fatherComparison,
  ) {
    String errorMessage = 'Не удалось сравнить лица';
    String detailedMessage = '';
    int stepToReturn = 0; // 0 - малыш, 1 - мама, 2 - папа

    // Проверяем ошибки в обоих сравнениях
    bool motherHasError = motherComparison['success'] == false;
    bool fatherHasError = fatherComparison['success'] == false;

    if (motherHasError && fatherHasError) {
      // Ошибки в обоих сравнениях - вероятно проблема с малышом
      errorMessage = 'Не удалось распознать лица';
      detailedMessage =
          'Проверьте качество фото малыша. Убедитесь, что лицо хорошо видно.';
      stepToReturn = 0; // Возвращаем к фото малыша
    } else if (motherHasError) {
      // Ошибка только в сравнении с мамой
      final errorType = motherComparison['error_type'];
      final failedImage = motherComparison['failed_image'];

      if (errorType == 'no_face_found') {
        if (failedImage == 'image1') {
          errorMessage = 'Не найдено лицо на фото малыша';
          detailedMessage =
              'Пожалуйста, загрузите фото малыша, где хорошо видно лицо.';
          stepToReturn = 0; // Возвращаем к фото малыша
        } else if (failedImage == 'image2') {
          errorMessage = 'Не найдено лицо на фото мамы';
          detailedMessage =
              'Пожалуйста, загрузите фото мамы, где хорошо видно лицо.';
          stepToReturn = 1; // Возвращаем к фото мамы
        } else {
          errorMessage = 'Не найдено лицо на фото мамы или малыша';
          detailedMessage = 'Проверьте, что на фото видны лица.';
          stepToReturn = 0; // По умолчанию возвращаем к малышу
        }
      } else {
        errorMessage =
            motherComparison['error']?.toString() ?? 'Ошибка сравнения с мамой';
        stepToReturn = 0; // По умолчанию возвращаем к малышу
      }
    } else if (fatherHasError) {
      // Ошибка только в сравнении с папой
      final errorType = fatherComparison['error_type'];
      final failedImage = fatherComparison['failed_image'];

      if (errorType == 'no_face_found') {
        if (failedImage == 'image1') {
          errorMessage = 'Не найдено лицо на фото малыша';
          detailedMessage =
              'Пожалуйста, загрузите фото малыша, где хорошо видно лицо.';
          stepToReturn = 0; // Возвращаем к фото малыша
        } else if (failedImage == 'image2') {
          errorMessage = 'Не найдено лицо на фото папы';
          detailedMessage =
              'Пожалуйста, загрузите фото папы, где хорошо видно лицо.';
          stepToReturn = 2; // Возвращаем к фото папы
        } else {
          errorMessage = 'Не найдено лицо на фото папы или малыша';
          detailedMessage = 'Проверьте, что на фото видны лица.';
          stepToReturn = 0; // По умолчанию возвращаем к малышу
        }
      } else {
        errorMessage =
            fatherComparison['error']?.toString() ?? 'Ошибка сравнения с папой';
        stepToReturn = 0; // По умолчанию возвращаем к малышу
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Ошибка', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMessage, style: TextStyle(fontSize: 16)),
            if (detailedMessage.isNotEmpty) ...[
              SizedBox(height: 10),
              Text(detailedMessage, style: TextStyle(color: Colors.grey[600])),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Закрываем диалог
              Navigator.of(context).pop();
            },
            child: Text('OK', style: TextStyle(color: Color(0xFF4FC3F7))),
          ),
        ],
      ),
    ).then((_) {
      // После закрытия диалога возвращаемся на нужный шаг загрузки фото
      if (mounted) {
        _returnToPhotoUploadScreen(stepToReturn);
      }
    });
  }

  void _returnToPhotoUploadScreen(int stepToReturn) {
    // Создаем объект с результатами для передачи обратно
    final result = {
      'error_step': stepToReturn,
      // Передаем только пути и имена, так как XFile не сериализуем
      'photo_paths': widget.photoFiles.map((file) => file?.path).toList(),
      'photo_names': widget.photoNames,
    };

    // Возвращаемся на предыдущий экран с результатом
    Navigator.of(context).pop(result);
  }

  void _navigateToResults(Map<String, dynamic> results) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ResultsScreen(results: results, photoFiles: widget.photoFiles),
      ),
    );
  }

  void _showErrorWithRetry(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Попробовать снова
              _startProcessing();
            },
            child: Text('Повторить'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Анимированная иконка
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF4FC3F7).withOpacity(_animation.value),
                          Color(0xFF4FC3F7).withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: _isProcessing
                          ? Icon(
                              Icons.face_retouching_natural,
                              size: 80,
                              color: Colors.white,
                            )
                          : Icon(Icons.error, size: 80, color: Colors.white),
                    ),
                  );
                },
              ),
              SizedBox(height: 40),

              // Отображение процесса
              Text(
                _messages[_currentMessageIndex],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF424242),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Прогресс бар
              LinearProgressIndicator(
                value: (_currentMessageIndex + 1) / _messages.length,
                backgroundColor: Colors.grey[200],
                color: Color(0xFF4FC3F7),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              SizedBox(height: 10),

              // Процент выполнения
              Text(
                '${((_currentMessageIndex + 1) / _messages.length * 100).toInt()}%',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 30),

              // Индикатор API
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: _currentMessageIndex >= 2
                      ? Colors.green[50]
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _currentMessageIndex >= 2
                        ? Colors.green[100]!
                        : Colors.blue[100]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentMessageIndex >= 2
                          ? Icons.cloud_done
                          : Icons.cloud,
                      size: 14,
                      color: _currentMessageIndex >= 2
                          ? Colors.green
                          : Colors.blue,
                    ),
                    SizedBox(width: 8),
                    Text(
                      _currentMessageIndex >= 2
                          ? 'FaceCloud AI активен'
                          : 'Подключение к FaceCloud',
                      style: TextStyle(
                        fontSize: 14,
                        color: _currentMessageIndex >= 2
                            ? Colors.green[800]
                            : Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Информация
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Обработано фото:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${_currentMessageIndex >= 1 ? widget.photoFiles.length : 0}/${widget.photoFiles.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (_currentMessageIndex >= 2) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Сравнений выполнено:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _currentMessageIndex == 2 ? '1/2' : '2/2',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Подсказка
              Text(
                _currentMessageIndex >= 2
                    ? 'Идет сравнение лиц с помощью AI...'
                    : 'Пожалуйста, подождите...',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
