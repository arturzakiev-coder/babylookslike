// lib/screens/purchase_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenuecat_service.dart';

class PurchaseScreen extends StatefulWidget {
  @override
  _PurchaseScreenState createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  @override
  void initState() {
    super.initState();
    // Инициализируем RevenueCat при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final revenueCatService = context.read<RevenueCatService>();
      if (!revenueCatService.isInitialized && !revenueCatService.isLoading) {
        await revenueCatService.initialize();
      }
    });
  }
  
  // В purchase_screen.dart, в методе build:
@override
Widget build(BuildContext context) {
  // Используем watch, но с проверкой на null
  final revenueCatService = context.watch<RevenueCatService?>();
  
  return Scaffold(
    appBar: AppBar(
      title: Text('Покупка попыток'),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: revenueCatService == null 
        ? _buildLoading() 
        : _buildBody(revenueCatService),
  );
}

Widget _buildLoading() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text('Загрузка сервиса покупок...'),
      ],
    ),
  );
}
  
  Widget _buildBody(RevenueCatService service) {
    if (service.isLoading && !service.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (!service.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 50, color: Colors.orange),
            SizedBox(height: 20),
            Text('RevenueCat не инициализирован'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => service.initialize(),
              child: Text('Повторить'),
            ),
          ],
        ),
      );
    }
    
    final packages = service.availablePackages;
    
    if (packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 50, color: Colors.grey),
            SizedBox(height: 20),
            Text('Нет доступных пакетов'),
            Text('Настройте продукты в RevenueCat', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Заголовок
        _buildHeader(),
        SizedBox(height: 20),
        
        // Список пакетов
        ...packages.map((package) => 
          _buildPackageCard(package, service)
        ).toList(),
        
        SizedBox(height: 30),
        
        // Кнопка восстановления покупок
        _buildRestoreButton(service),
        
        SizedBox(height: 20),
        
        // Информация
        _buildInfoCard(),
      ],
    );
  }
  
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Выберите пакет попыток',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Каждое сравнение расходует 1 попытку',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPackageCard(Package package, RevenueCatService service) {
    // Используем правильные свойства Package
    final product = package.storeProduct; // ИЛИ package.product в зависимости от версии
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и цена
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _getPackageTitle(package.identifier),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  product.priceString,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            // Описание
            Text(
              _getPackageDescription(package.identifier),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Кнопка покупки
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _purchasePackage(package, service),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Купить',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Методы для получения названий и описаний
  String _getPackageTitle(String identifier) {
    switch (identifier) {
      case 'mini_pack':
        return 'Мини-пакет (10 попыток)';
      case 'standard_pack':
        return 'Стандартный пакет (30 попыток)';
      case 'premium_pack':
        return 'Премиум-пакет (100 попыток)';
      default:
        return identifier;
    }
  }
  
  String _getPackageDescription(String identifier) {
    switch (identifier) {
      case 'mini_pack':
        return '10 попыток сравнения лиц';
      case 'standard_pack':
        return '30 попыток сравнения лиц';
      case 'premium_pack':
        return '100 попыток сравнения лиц';
      default:
        return 'Пакет попыток для сравнения';
    }
  }
  
  Widget _buildRestoreButton(RevenueCatService service) {
    return OutlinedButton(
      onPressed: () => _restorePurchases(service),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restore, size: 20),
          SizedBox(width: 8),
          Text(
            'Восстановить покупки',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ℹ️ Информация',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '• Покупки привязаны к вашему аккаунту в магазине приложений\n'
            '• Нажмите "Восстановить покупки" если попытки не появились\n'
            '• Для отмены подписки обратитесь в магазин приложений',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _purchasePackage(Package package, RevenueCatService service) async {
  try {
    final success = await service.purchasePackage(package); // Передаем Package
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Покупка успешна!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Future.delayed(Duration(seconds: 2), () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Покупка не завершена'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ошибка: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  
  Future<void> _restorePurchases(RevenueCatService service) async {
    final success = await service.restorePurchases();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Покупки восстановлены!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не найдено активных покупок'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}