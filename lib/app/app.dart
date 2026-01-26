import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../screens/main_screen.dart';
import '../screens/photo_upload_screen.dart';
import '../screens/processing_screen.dart';
import '../screens/purchase_screen.dart';
import '../screens/save_success_screen.dart';

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    await firestoreService.initializeDevice();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/': (context) => MainScreen(),
        '/upload': (context) => PhotoUploadScreen(),
        '/processing': (context) => ProcessingScreen(),
        '/results': (context) => ResultsScreen(),
        '/purchase': (context) => PurchaseScreen(),
        '/save-success': (context) => SaveSuccessScreen(),
      },
      initialRoute: '/',
    );
  }
}