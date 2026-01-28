import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService with ChangeNotifier {
  bool _isInitialized = false;
  bool _isLoading = false;
  CustomerInfo? _customerInfo;
  List<Package> _availablePackages = [];
  
  // Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      print('🔄 Initializing RevenueCatService...');
      
      // Загружаем информацию о покупателе
      _customerInfo = await Purchases.getCustomerInfo();
      
      // Загружаем доступные пакеты
      await _loadAvailablePackages();
      
      // Устанавливаем слушатель обновлений
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
      
      _isInitialized = true;
      print('✅ RevenueCatService initialized successfully');
      
    } catch (e) {
      print('❌ Error initializing RevenueCatService: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Загрузка доступных пакетов
  Future<void> _loadAvailablePackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      
      if (offerings.current != null) {
        _availablePackages = offerings.current!.availablePackages;
        print('📦 Loaded ${_availablePackages.length} packages');
      } else {
        print('⚠️ No offerings available in RevenueCat');
      }
    } catch (e) {
      print('Error loading packages: $e');
    }
  }
  
  // Обработчик обновлений
  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    _customerInfo = customerInfo;
    print('👤 Customer info updated');
    notifyListeners();
  }
  
  // Покупка пакета
  Future<bool> purchasePackage(Package package) async {
  try {
    print('🛒 Purchasing package: ${package.identifier}');
    
    // В версии 9.x возвращает PurchaseResult
    final purchaseResult = await Purchases.purchasePackage(package);
    
    // Проверяем успешность через customerInfo
    final hasAccess = purchaseResult.customerInfo.entitlements.active.isNotEmpty;
    
    if (hasAccess) {
      print('✅ Purchase successful!');
      return true;
    } else {
      print('❌ Purchase failed');
      return false;
    }
    
  } catch (e) {
    print('Purchase error: $e');
    return false;
  }
}
  
  // Восстановление покупок
  Future<bool> restorePurchases() async {
  try {
    print('🔄 Restoring purchases...');
    
    // В версии 9.x
    final customerInfo = await Purchases.restorePurchases();
    final hasActivePurchases = customerInfo.entitlements.active.isNotEmpty;
    
    if (hasActivePurchases) {
      print('✅ Purchases restored successfully');
      return true;
    } else {
      print('ℹ️ No active purchases found');
      return false;
    }
    
  } catch (e) {
    print('❌ Error restoring purchases: $e');
    return false;
  }
}
  
  // Геттеры
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  CustomerInfo? get customerInfo => _customerInfo;
  List<Package> get availablePackages => _availablePackages;
  
  // Проверка активной подписки/покупки
  bool get hasActivePurchase {
    return _customerInfo?.entitlements.active.isNotEmpty ?? false;
  }
  
  // Получение пакета по ID
  Package? getPackageById(String identifier) {
    try {
      return _availablePackages.firstWhere(
        (p) => p.identifier == identifier
      );
    } catch (e) {
      return null;
    }
  }

  Package? getPackageByIdentifier(String identifier) {
  try {
    return _availablePackages.firstWhere(
      (p) => p.identifier == identifier
    );
  } catch (e) {
    return null;
  }
}
}