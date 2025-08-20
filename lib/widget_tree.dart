import 'package:inventory_management_system/pages/login_register_page.dart';
import 'package:inventory_management_system/pages/home_page.dart';
import 'package:inventory_management_system/services/auth_service.dart';
import 'package:inventory_management_system/services/inventory_service.dart';
import 'package:inventory_management_system/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({Key? key}) : super(key: key);

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  void initState() {
    super.initState();
    // Initialize AuthService and check for admin user
    _initializeAppInBackground();
  }

  void _initializeAppInBackground() {
    // Run initialization in background without blocking the UI
    Future.microtask(() async {
      try {
        print('Starting app initialization...');

        // Test Firebase connection
        print('Testing Firebase connection...');
        await _testFirebaseConnection();

        // Initialize auth state listener
        print('Initializing auth state listener...');
        AuthService.initialize();

        // Initialize Firestore collections
        print('Initializing Firestore collections...');
        await InventoryService.initializeFirestore();

        // Check if admin user exists
        print('Checking for admin users...');
        await AuthService.ensureAdminUserExists();

        print('App initialization completed successfully');
      } catch (e) {
        print('Background initialization error: $e');
        // Continue anyway - user can still use the app
      }
    });
  }

  Future<void> _testFirebaseConnection() async {
    try {
      // Simple test to verify Firebase is working
      final testDoc =
          FirebaseFirestore.instance.collection('_test').doc('connection');
      await testDoc.set({'timestamp': FieldValue.serverTimestamp()});
      await testDoc.delete();
      print('Firebase connection test successful');
    } catch (e) {
      print('Firebase connection test failed: $e');
      throw Exception('Firebase connection failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService.authStateChanges,
      initialData: AuthService.currentUser,
      builder: (context, snapshot) {
        // Always show login page first if no user is authenticated
        // This ensures fast loading without waiting for database initialization
        if (snapshot.hasData && snapshot.data != null) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
