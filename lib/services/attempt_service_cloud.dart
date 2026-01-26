import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class AttemptServiceCloud with ChangeNotifier {
  final FirebaseService _firebaseService;
  
  int _freeAttempts = 3;
  int _purchasedAttempts = 0;
  
  AttemptServiceCloud(this._firebaseService) {
    _loadFromCloud();
  }
  
  int get freeAttempts => _freeAttempts;
  int get purchasedAttempts => _purchasedAttempts;
  int get totalAttempts => _freeAttempts + _purchasedAttempts;
  
  bool canCompare() => totalAttempts > 0;
  
  Future<void> _loadFromCloud() async {
    try {
      final balance = await _firebaseService.loadAttemptBalance();
      _freeAttempts = balance['freeAttempts'] ?? 3;
      _purchasedAttempts = balance['purchasedAttempts'] ?? 0;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading from cloud: $e');
      }
    }
  }
  
  Future<bool> useAttempt() async {
    if (totalAttempts <= 0) return false;
    
    if (_purchasedAttempts > 0) {
      _purchasedAttempts--;
    } else {
      _freeAttempts--;
    }
    
    await _saveToCloud();
    notifyListeners();
    return true;
  }
  
  Future<void> addAttempts(int amount, {bool isPurchased = true}) async {
    if (isPurchased) {
      _purchasedAttempts += amount;
    } else {
      _freeAttempts += amount;
    }
    
    await _saveToCloud();
    notifyListeners();
  }
  
  Future<void> reset() async {
    _freeAttempts = 3;
    _purchasedAttempts = 0;
    await _saveToCloud();
    notifyListeners();
  }
  
  Future<void> _saveToCloud() async {
    await _firebaseService.saveAttemptBalance(
      freeAttempts: _freeAttempts,
      purchasedAttempts: _purchasedAttempts,
    );
  }
  
  // Сохраняем результат сравнения в облако
  Future<void> saveComparisonResult({
    required double motherSimilarity,
    required double fatherSimilarity,
    required Map<String, double> details,
  }) async {
    await _firebaseService.saveComparisonResult(
      motherSimilarity: motherSimilarity,
      fatherSimilarity: fatherSimilarity,
      details: details,
    );
  }
  
  // Сохраняем покупку в облако
  Future<void> savePurchase({
    required String productId,
    required int amount,
    required double price,
  }) async {
    await _firebaseService.savePurchase(
      productId: productId,
      amount: amount,
      price: price,
    );
  }
  
  // Получаем историю сравнений
  Future<List<Map<String, dynamic>>> getComparisonHistory() async {
    return await _firebaseService.getComparisonHistory();
  }
}