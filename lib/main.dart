import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:inventory_management_system/firebase_options.dart';
import 'package:inventory_management_system/widget_tree.dart';
import 'package:inventory_management_system/screens/inventory_form_screen.dart';
import 'package:inventory_management_system/screens/inventory_list_screen.dart';
import 'package:inventory_management_system/screens/stock_movements_screen.dart';
import 'package:inventory_management_system/screens/predictions_screen.dart';
import 'package:inventory_management_system/screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
