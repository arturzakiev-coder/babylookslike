class AttemptManager {
  static int _freeAttempts = 3;
  static int _purchasedAttempts = 0;
  
  static int get totalAttempts => _freeAttempts + _purchasedAttempts;
  static int get freeAttempts => _freeAttempts;
  static int get purchasedAttempts => _purchasedAttempts;
  
  static bool canCompare() {
    return totalAttempts > 0;
  }
  
  static bool useAttempt() {
    if (totalAttempts <= 0) return false;
    
    if (_purchasedAttempts > 0) {
      _purchasedAttempts--;
    } else {
      _freeAttempts--;
    }
    
    return true;
  }
  
  static void addAttempts(int amount, {bool isPurchased = true}) {
    if (isPurchased) {
      _purchasedAttempts += amount;
    } else {
      _freeAttempts += amount;
    }
  }
  
  static void reset() {
    _freeAttempts = 3;
    _purchasedAttempts = 0;
  }
}