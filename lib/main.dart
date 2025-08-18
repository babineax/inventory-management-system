import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:inventory_management_system/firebase_options.dart';
import 'package:inventory_management_system/widget_tree.dart';
import 'package:inventory_management_system/screens/inventory_form_screen.dart';
import 'package:inventory_management_system/screens/inventory_list_screen.dart';
import 'package:inventory_management_system/screens/stock_movements_screen.dart';
import 'package:inventory_management_system/screens/predictions_screen.dart';
import 'package:inventory_management_system/screens/profile_screen.dart';

// Conditional imports for SQLite
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// import 'package:auth_firebase/firebase_options.dart';
// import 'pages/signup/signup.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite for different platforms
  if (kIsWeb) {
    // Initialize web SQLite with better error handling
    try {
      databaseFactory = databaseFactoryFfiWeb;
      print('Web SQLite initialized successfully');
    } catch (e) {
      print('Web SQLite initialization failed: $e');
      // Continue without SQLite for web - app will handle gracefully
      // The app will show appropriate error messages if database operations fail
    }
  } else {
    // For non-web platforms, try to initialize desktop SQLite
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print('Desktop SQLite initialized successfully');
    } catch (e) {
      // If desktop SQLite fails, fall back to default (mobile) implementation
      // This will work for iOS/Android
      print('Desktop SQLite initialization failed, using default: $e');
    }
  }

  // Firebase initialization commented out for SQLite-only mode
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform
  // );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const WidgetTree(),
      routes: {
        '/add_item': (context) => const InventoryFormScreen(),
        '/inventory': (context) => const InventoryListScreen(),
        '/movements': (context) => const StockMovementsScreen(),
        '/predictions': (context) => const PredictionsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
