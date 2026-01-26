import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/facecloud_config.dart';
import 'package:http_parser/http_parser.dart'; // Добавьте этот импорт

// Вспомогательная функция
int min(int a, int b) => a < b ? a : b;

class FaceCloudService {
  static const String _baseUrl = 'https://backend.facecloud.tevian.ru';
  static const String _apiVersion = '/api/v1';
  
  String? _accessToken;
  bool _initialized = false;
  String? _lastError;
  
  // Инициализация сервиса
  Future<void> initialize() async {
    if (_initialized) return;
    
    if (kDebugMode) {
      print('🚀 FaceCloud: Initializing...');
      print('   Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
      print('   Using email: ${FaceCloudConfig.maskedEmail}');
    }
    
    try {
      // Загружаем сохраненный токен (для мобильных)
      await _loadToken();
      
      // Если нет токена - логинимся
      if (_accessToken == null) {
        if (kDebugMode) {
          print('🔐 FaceCloud: No saved token, attempting login...');
        }
        
        await _loginWithCredentials();
      } else {
        if (kDebugMode) {
          print('✅ FaceCloud: Using saved token');
        }
      }
      
      _initialized = true;
      
      if (kDebugMode) {
        print('🎯 FaceCloud: Initialization SUCCESS');
        print('   Authenticated: $isAuthenticated');
      }
    } catch (e) {
      _lastError = e.toString();
      _initialized = true;
      
      if (kDebugMode) {
        print('⚠️ FaceCloud: Initialization error: $e');
      }
    }
  }
  
  // Логин
  Future<void> _loginWithCredentials() async {
    try {
      final url = Uri.parse('$_baseUrl$_apiVersion/login');
      
      if (kDebugMode) {
        print('📤 FaceCloud: Sending login request...');
      }
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': FaceCloudConfig.email,
          'password': FaceCloudConfig.password,
        }),
      );
      
      if (kDebugMode) {
        print('📥 FaceCloud: Response status: ${response.statusCode}');
      }
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData.containsKey('data')) {
          final data = responseData['data'] as Map<String, dynamic>;
          
          if (data.containsKey('access_token')) {
            final token = data['access_token'] as String;
            
            if (token.isNotEmpty) {
              await _saveToken(token);
              
              if (kDebugMode) {
                print('🎉 FaceCloud: Login SUCCESSFUL!');
                print('   Token length: ${token.length} chars');
              }
              
              return;
            }
          }
        }
        
        throw Exception('Invalid response format');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _lastError = 'Login failed: $e';
      rethrow;
    }
  }
  
  // Основной метод: сравнение двух лиц (универсальный)
  Future<Map<String, dynamic>> compareTwoFaces({
    required String imagePath1,
    required String imagePath2,
    List<int>? imageBytes1,
    List<int>? imageBytes2,
    String? imageName1,
    String? imageName2,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    
    if (!isAuthenticated) {
      if (kDebugMode) {
        print('⚠️ FaceCloud: Not authenticated, using mock data');
      }
      return _getMockComparisonResult();
    }
    
    try {
      if (kDebugMode) {
        print('🔄 FaceCloud: Starting REAL comparison...');
      }
      
      // Всегда используем реальный API вызов
      return await _makeApiRequest(
        imagePath1: imagePath1,
        imagePath2: imagePath2,
        imageBytes1: imageBytes1,
        imageBytes2: imageBytes2,
        imageName1: imageName1,
        imageName2: imageName2,
      );
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ FaceCloud: Comparison error: $e');
      }
      return _getMockComparisonResult();
    }
  }
  
  // Универсальный API запрос
  Future<Map<String, dynamic>> _makeApiRequest({
    required String imagePath1,
    required String imagePath2,
    List<int>? imageBytes1,
    List<int>? imageBytes2,
    String? imageName1,
    String? imageName2,
  }) async {
    try {
      if (kDebugMode) {
        print('📤 Preparing API request to /api/v1/match...');
      }
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$_apiVersion/match'),
      );
      
      // Заголовок авторизации
      request.headers['Authorization'] = 'Bearer $_accessToken';
      
      // Параметры API
      request.fields['fd_threshold'] = '0.8';
      request.fields['fd_min_size'] = '0';
      request.fields['fd_max_size'] = '0';
      request.fields['rotate_until_faces_found'] = 'false';
      request.fields['orientation_classifier'] = 'false';
      
      // Добавляем первое изображение
      await _addImageToRequest(
        request: request,
        fieldName: 'image1',
        imagePath: imagePath1,
        imageBytes: imageBytes1,
        imageName: imageName1 ?? 'image1.jpg',
      );
      
      // Добавляем второе изображение
      await _addImageToRequest(
        request: request,
        fieldName: 'image2',
        imagePath: imagePath2,
        imageBytes: imageBytes2,
        imageName: imageName2 ?? 'image2.jpg',
      );
      
      if (kDebugMode) {
        print('🚀 Sending request to FaceCloud API...');
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (kDebugMode) {
        print('📥 API Response status: ${response.statusCode}');
      }
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (kDebugMode) {
          print('✅ FaceCloud API: Comparison successful!');
        }
        
        return _parseApiResponse(responseData);
      } else {
        if (kDebugMode) {
          print('❌ FaceCloud API: Error ${response.statusCode}');
          print('Response: ${response.body}');
        }
        
        return _getMockComparisonResultWithError('API Error ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ API request failed: $e');
      }
      return _getMockComparisonResultWithError('Exception: $e');
    }
  }
  
  // Добавление изображения в запрос (универсальное)
  Future<void> _addImageToRequest({
  required http.MultipartRequest request,
  required String fieldName,
  required String imagePath,
  List<int>? imageBytes,
  required String imageName,
}) async {
  if (kIsWeb) {
    // Для WEB
    if (imageBytes != null && imageBytes.isNotEmpty) {
      // Определяем MIME-тип по имени файла или данным
      String contentType = 'image/jpeg'; // По умолчанию
      
      if (imageName.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (imageName.toLowerCase().endsWith('.gif')) {
        contentType = 'image/gif';
      }
      
      if (kDebugMode) {
        print('   Adding $fieldName as $contentType (${imageBytes.length} bytes)');
      }
      
      final file = http.MultipartFile.fromBytes(
        fieldName,
        imageBytes,
        filename: imageName,
        contentType: MediaType.parse(contentType),
      );
      request.files.add(await file);
    } else if (imagePath.startsWith('data:image')) {
      // Base64 изображение
      try {
        final parts = imagePath.split(';');
        String contentType = 'image/jpeg';
        
        if (parts.isNotEmpty && parts[0].startsWith('data:')) {
          final mimeType = parts[0].replaceFirst('data:', '');
          if (mimeType.isNotEmpty) {
            contentType = mimeType;
          }
        }
        
        final base64Data = imagePath.split(',').last;
        final bytes = base64.decode(base64Data);
        
        if (kDebugMode) {
          print('   Adding $fieldName from base64 as $contentType (${bytes.length} bytes)');
        }
        
        final file = http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: imageName,
          contentType: MediaType.parse(contentType),
        );
        request.files.add(await file);
      } catch (e) {
        throw Exception('Failed to process base64 image: $e');
      }
    } else {
      throw Exception('Web: No valid image data provided for $fieldName');
    }
  } else {
    // Для MOBILE
    final file = File(imagePath);
    if (await file.exists()) {
      // Определяем MIME-тип по расширению
      String contentType = 'image/jpeg';
      
      if (imagePath.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (imagePath.toLowerCase().endsWith('.gif')) {
        contentType = 'image/gif';
      }
      
      if (kDebugMode) {
        print('   Adding $fieldName from path as $contentType: $imagePath');
      }
      
      final filePart = await http.MultipartFile.fromPath(
        fieldName,
        imagePath,
        filename: imageName,
        contentType: MediaType.parse(contentType),
      );
      request.files.add(filePart);
    } else {
      throw Exception('Mobile: File not found: $imagePath');
    }
  }
}
  
  // Парсинг ответа API
  Map<String, dynamic> _parseApiResponse(Map<String, dynamic> responseData) {
  if (responseData.containsKey('data')) {
    final data = responseData['data'] as Map<String, dynamic>;
    
    final score = (data['score'] as num).toDouble();
    
    if (kDebugMode) {
      print('✅ FaceCloud API: Comparison successful!');
        print('📦 Full response structure:');
        responseData.forEach((key, value) {
          if (key == 'data' && value is Map) {
            print('   data:');
            (value as Map).forEach((k, v) {
              print('     $k: $v (${v.runtimeType})');
            });
          } else {
            print('   $key: $value');
          }
        });
      print('🎯 FaceCloud API Score: $score (${(score * 100).toInt()}%)');
      print('📊 Response details:');
      print('   - face1_bbox: ${data['face1_bbox']}');
      print('   - face2_bbox: ${data['face2_bbox']}');
      print('   - rotation1: ${data['rotation1']}');
      print('   - rotation2: ${data['rotation2']}');
    }
    
    return {
      'score': score,
      'face1_bbox': data['face1_bbox'] ?? {},
      'face2_bbox': data['face2_bbox'] ?? {},
      'rotation1': data['rotation1'] ?? 0,
      'rotation2': data['rotation2'] ?? 0,
      'success': true,
      'isMock': false,
      'isRealApi': true,
      'timestamp': DateTime.now().toIso8601String(),
      'raw_response': responseData,
    };
  } else {
    if (kDebugMode) {
      print('❌ Unexpected response format: ${responseData.keys}');
    }
    return _getMockComparisonResultWithError('Unexpected response format');
  }
}
  
  // Тестовые данные
  Map<String, dynamic> _getMockComparisonResult() {
    final randomScore = 0.3 + (DateTime.now().millisecond % 70) / 100.0;
    
    return {
      'score': randomScore,
      'success': true,
      'isMock': true,
      'isRealApi': false,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  Map<String, dynamic> _getMockComparisonResultWithError(String error) {
    final result = _getMockComparisonResult();
    result['error'] = error;
    result['api_error'] = true;
    return result;
  }
  
  // Вспомогательные методы
  Future<void> _saveToken(String token) async {
    _accessToken = token;
    
    try {
      if (!kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('facecloud_token', token);
      }
    } catch (e) {
      if (kDebugMode) print('Warning: Could not save token: $e');
    }
  }
  
  Future<void> _loadToken() async {
    try {
      if (!kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        _accessToken = prefs.getString('facecloud_token');
      }
    } catch (e) {
      if (kDebugMode) print('Warning: Could not load token: $e');
    }
  }
  
  // Геттеры
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;
  bool get isInitialized => _initialized;
  String? get lastError => _lastError;
}