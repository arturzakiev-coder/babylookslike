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

      // Автоматически сохраняем информацию о покупке в Firebase
      // Определяем productId и price на основе amount
      final purchaseInfo = _getPurchaseInfo(amount);

      await _firebaseService.savePurchase(
        productId: purchaseInfo['productId'],
        amount: amount,
        price: purchaseInfo['price'],
      );

      if (kDebugMode) {
        print(
          '✅ Покупка сохранена: ${purchaseInfo['productId']}, $amount попыток, ${purchaseInfo['price']} руб.',
        );
      }
    } else {
      _freeAttempts += amount;
    }

    await _saveToCloud();
    notifyListeners();
  }

  // Вспомогательный метод для определения информации о покупке
  Map<String, dynamic> _getPurchaseInfo(int amount) {
    switch (amount) {
      case 10:
        return {'productId': 'package_mini', 'price': 99.0};
      case 30:
        return {'productId': 'package_standard', 'price': 249.0};
      case 100:
        return {'productId': 'package_premium', 'price': 699.0};
      case 999: // Для подписки
        return {'productId': 'subscription_unlimited', 'price': 299.0};
      default:
        return {'productId': 'custom_package_$amount', 'price': 0.0};
    }
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
 

  // Получаем историю сравнений
  Future<List<Map<String, dynamic>>> getComparisonHistory() async {
    return await _firebaseService.getComparisonHistory();
  }
}
