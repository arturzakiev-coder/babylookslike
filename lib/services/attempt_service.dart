import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttemptService with ChangeNotifier {
  static const String _storageKey = 'attempt_data';
  
  int _freeAttempts = 3;
  int _purchasedAttempts = 0;
  
  AttemptService() {
    _loadFromStorage();
  }
  
  int get freeAttempts => _freeAttempts;
  int get purchasedAttempts => _purchasedAttempts;
  int get totalAttempts => _freeAttempts + _purchasedAttempts;
  
  bool canCompare() => totalAttempts > 0;
  
  Future<bool> useAttempt() async {
    if (totalAttempts <= 0) return false;
    
    if (_purchasedAttempts > 0) {
      _purchasedAttempts--;
    } else {
      _freeAttempts--;
    }
    
    await _saveToStorage();
    notifyListeners();
    return true;
  }
  
  Future<void> addAttempts(int amount, {bool isPurchased = true}) async {
    if (isPurchased) {
      _purchasedAttempts += amount;
    } else {
      _freeAttempts += amount;
    }
    
    await _saveToStorage();
    notifyListeners();
  }
  
  Future<void> reset() async {
    _freeAttempts = 3;
    _purchasedAttempts = 0;
    await _saveToStorage();
    notifyListeners();
  }
  
  Future<void> _saveToStorage() async {
    if (kIsWeb) return; // В вебе shared_preferences не работает
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'freeAttempts': _freeAttempts,
        'purchasedAttempts': _purchasedAttempts,
      };
      await prefs.setString(_storageKey, json.encode(data));
    } catch (e) {
      print('Error saving attempts: $e');
    }
  }
  
  Future<void> _loadFromStorage() async {
    if (kIsWeb) return; // В вебе shared_preferences не работает
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      
      if (data != null) {
        final map = json.decode(data) as Map<String, dynamic>;
        _freeAttempts = map['freeAttempts'] ?? 3;
        _purchasedAttempts = map['purchasedAttempts'] ?? 0;
      }
    } catch (e) {
      print('Error loading attempts: $e');
    }
    
    notifyListeners();
  }
}