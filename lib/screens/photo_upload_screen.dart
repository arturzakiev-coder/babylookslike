import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'processing_screen.dart';
import 'package:provider/provider.dart';
import '../services/attempt_service_cloud.dart';
//import '../services/facecloud_service.dart';

class PhotoUploadScreen extends StatefulWidget {
  @override
  _PhotoUploadScreenState createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  int _currentStep = 0;
  final ImagePicker _picker = ImagePicker();

  // Для WEB храним bytes, для Mobile - пути
   List<XFile?> _selectedFiles = [null, null, null];
   List<Uint8List?> _imageBytes = [null, null, null];
   List<String> _imageNames = ['', '', ''];

  final List<Map<String, dynamic>> _steps = [
    {'title': 'Загрузите фото малыша', 'icon': Icons.child_care, 'key': 'baby'},
    {'title': 'Загрузите фото мамы', 'icon': Icons.woman, 'key': 'mother'},
    {'title': 'Загрузите фото папы', 'icon': Icons.man, 'key': 'father'},
  ];

  // Метод выбора фото (универсальный для web/mobile)
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image != null) {
        await _processSelectedImage(image);
      }
    } catch (e) {
      _showError('Ошибка при выборе фото: $e');
    }
  }

  // Метод съемки фото (только для mobile)
  Future<void> _takePhotoWithCamera() async {
    try {
      if (kIsWeb) {
        _showError('Камера не доступна в браузере');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image != null) {
        await _processSelectedImage(image);
      }
    } catch (e) {
      _showError('Ошибка при съемке фото: $e');
    }
  }

  // Обработка выбранного изображения
  // Обработка выбранного изображения
  Future<void> _processSelectedImage(XFile image) async {
    try {
      if (kDebugMode) {
        print('Processing image: ${image.name}');
        print('MIME type: ${image.mimeType}');
        print('Size: ${await image.length()} bytes');
      }

      // Для WEB: читаем bytes
      if (kIsWeb) {
        final bytes = await image.readAsBytes();

        // Проверяем тип файла
        final fileName = image.name.toLowerCase();
        if (!fileName.endsWith('.jpg') &&
            !fileName.endsWith('.jpeg') &&
            !fileName.endsWith('.png')) {
          _showError('Пожалуйста, используйте JPG или PNG файлы');
          return;
        }

        setState(() {
          _selectedFiles[_currentStep] = image;
          _imageBytes[_currentStep] = bytes;
          _imageNames[_currentStep] = image.name;
        });

        if (kDebugMode) {
          print('✅ Web image processed: ${bytes.length} bytes');
        }
      } else {
        // Для Mobile: сохраняем путь
        final fileName = image.name.toLowerCase();
        if (!fileName.endsWith('.jpg') &&
            !fileName.endsWith('.jpeg') &&
            !fileName.endsWith('.png')) {
          _showError('Пожалуйста, используйте JPG или PNG файлы');
          return;
        }

        setState(() {
          _selectedFiles[_currentStep] = image;
          _imageBytes[_currentStep] = null;
          _imageNames[_currentStep] = image.name;
        });
      }
    } catch (e) {
      _showError('Ошибка обработки фото: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Проверка готовности к сравнению
  bool get _isReadyForComparison {
    return _selectedFiles.every((file) => file != null);
  }

  // Проверка, можно ли перейти дальше
  bool get _canGoNext {
    return _selectedFiles[_currentStep] != null;
  }

  // Получение превью для текущего шага
  Uint8List? get _currentImageBytes => _imageBytes[_currentStep];
  String? get _currentImagePath => _selectedFiles[_currentStep]?.path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Шаг ${_currentStep + 1} из ${_steps.length}'),
        backgroundColor: Color(0xFF4FC3F7),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (_isReadyForComparison)
            IconButton(
              icon: Icon(Icons.check, color: Colors.white),
              onPressed: () async {  // Добавили async
        await _startComparison(context);  // Добавили await
      },
              tooltip: 'Все фото загружены',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Прогресс бар
            LinearProgressIndicator(
              value: (_currentStep + 1) / _steps.length,
              backgroundColor: Colors.grey[200],
              color: Color(0xFF4FC3F7),
            ),
            SizedBox(height: 30),

            // Текущий шаг
            Icon(
              _steps[_currentStep]['icon'],
              size: 60,
              color: Color(0xFF4FC3F7),
            ),
            SizedBox(height: 20),

            Text(
              _steps[_currentStep]['title'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),

            // Отображение выбранного фото или плейсхолдера
            Expanded(
              child: GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedFiles[_currentStep] != null
                          ? Color(0xFF4FC3F7)
                          : Colors.grey[300]!,
                      width: _selectedFiles[_currentStep] != null ? 3 : 1,
                    ),
                  ),
                  child: _selectedFiles[_currentStep] != null
                      ? _buildImagePreview()
                      : _buildPlaceholder(),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Индикаторы загруженных фото
            if (_selectedFiles.any((file) => file != null))
              Column(
                children: [
                  Text(
                    'Загружено фото:',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isLoaded = _selectedFiles[index] != null;
                      final isCurrent = index == _currentStep;

                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLoaded
                              ? (isCurrent ? Color(0xFF4FC3F7) : Colors.green)
                              : Colors.grey[300],
                          border: isCurrent
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 20),
                ],
              ),

            // Кнопки выбора
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: Icon(Icons.photo_library),
                    label: Text('Из галереи'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4FC3F7),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: kIsWeb ? null : _takePhotoWithCamera,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Камера'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kIsWeb
                          ? Colors.grey[400]!
                          : Color(0xFFFF8A65),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Кнопки навигации
            Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      child: Text('Назад'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.grey[800],
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                if (_currentStep > 0) SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentStep < _steps.length - 1
                        ? _canGoNext
                              ? () {
                                  setState(() {
                                    _currentStep++;
                                  });
                                }
                              : null
                        : _isReadyForComparison
                        ? () async {  // Добавили async
                await _startComparison(context);  // Добавили await
              }
                        : null,
                    child: Text(
                      _currentStep < _steps.length - 1 ? 'Далее' : 'Сравнить',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStep < _steps.length - 1
                          ? (_canGoNext ? Color(0xFF4FC3F7) : Colors.grey[400])
                          : (_isReadyForComparison
                                ? Color(0xFF4FC3F7)
                                : Colors.grey[400]),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Построение превью изображения
  Widget _buildImagePreview() {
    final file = _selectedFiles[_currentStep]!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: kIsWeb && _currentImageBytes != null
          ? Image.memory(
              _currentImageBytes!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorPlaceholder();
              },
            )
          : Image.file(
              File(file.path),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorPlaceholder();
              },
            ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF4FC3F7).withOpacity(0.1),
            border: Border.all(
              color: Color(0xFF4FC3F7).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(Icons.add_a_photo, size: 40, color: Color(0xFF4FC3F7)),
        ),
        SizedBox(height: 20),
        Text(
          'Нажмите, чтобы выбрать фото',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 10),
        Text(
          kIsWeb
              ? 'Поддерживаются JPG, PNG (рекомендуется JPG)'
              : 'Можно сфотографировать или выбрать из галереи',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.grey, size: 50),
          SizedBox(height: 10),
          Text(
            'Не удалось загрузить фото',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Запуск сравнения
  // Запуск сравнения
  // Запуск сравнения
Future<void> _startComparison(BuildContext context) async {  // Добавили async
  if (!_isReadyForComparison) {
    _showError('Пожалуйста, загрузите все три фото');
    return;
  }

  final attemptService = Provider.of<AttemptServiceCloud>(context, listen: false);
  
  // Только проверяем баланс, но НЕ списываем попытку
  if (!attemptService.canCompare()) {
    _showError('Недостаточно попыток. Купите дополнительные попытки.');
    return;
  }

  try {
    // Переход на экран обработки БЕЗ списания попытки
    // Списание произойдет только после успешного сравнения в ProcessingScreen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProcessingScreen(
          photoFiles: _selectedFiles,
          photoBytes: _imageBytes,
          photoNames: _imageNames,
        ),
      ),
    );

    // Проверяем, вернулись ли мы с ошибкой
    // Проверяем, вернулись ли мы с ошибкой
if (result != null && result is Map) {
  if (result.containsKey('error_step')) {
    final errorStep = result['error_step'] as int;
    
    // Восстанавливаем состояние (только имена и пути)
    if (result.containsKey('photo_names') && result['photo_names'] is List) {
      _imageNames = List<String>.from(result['photo_names']);
    }
    
    if (result.containsKey('photo_paths') && result['photo_paths'] is List) {
      final paths = result['photo_paths'] as List;
      
      // Для WEB: нужно восстанавливать bytes, но это сложно
      // Для Mobile: можно попробовать восстановить файлы по путям
      if (!kIsWeb) {
        // Для Mobile пытаемся восстановить файлы
        for (int i = 0; i < paths.length; i++) {
          final path = paths[i] as String?;
          if (path != null && path.isNotEmpty) {
            try {
              _selectedFiles[i] = XFile(path);
              _imageBytes[i] = null;
            } catch (e) {
              if (kDebugMode) {
                print('Could not restore file from path: $path');
              }
              _selectedFiles[i] = null;
              _imageBytes[i] = null;
            }
          } else {
            _selectedFiles[i] = null;
            _imageBytes[i] = null;
          }
        }
      } else {
        // Для WEB: очищаем файлы, так как не можем восстановить bytes
        _selectedFiles = [null, null, null];
        _imageBytes = [null, null, null];
      }
    }
    
    // Устанавливаем нужный шаг
    setState(() {
      _currentStep = errorStep;
    });
  }
}
  } catch (e) {
    if (kDebugMode) {
      print('Error during comparison: $e');
    }
  }
}

  // Показать диалог выбора источника
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: Color(0xFF4FC3F7)),
              title: Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: Icon(Icons.camera_alt, color: Color(0xFF4FC3F7)),
                title: Text('Сделать фото'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhotoWithCamera();
                },
              ),
            if (_selectedFiles[_currentStep] != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Удалить фото',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedFiles[_currentStep] = null;
                    _imageBytes[_currentStep] = null;
                    _imageNames[_currentStep] = '';
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}
