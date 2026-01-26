import 'package:flutter/foundation.dart';

class PurchaseService with ChangeNotifier {
  // TODO: Интеграция с RevenueCat
  
  Future<bool> purchasePackage(String productId) async {
    await Future.delayed(Duration(seconds: 2));
    return true;
  }
  
  Future<bool> purchaseSubscription(String productId) async {
    await Future.delayed(Duration(seconds: 2));
    return true;
  }
  
  Future<bool> restorePurchases() async {
    await Future.delayed(Duration(seconds: 2));
    return true;
  }
}