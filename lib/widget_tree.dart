import 'package:inventory_management_system/pages/login_register_page.dart';
import 'package:inventory_management_system/pages/home_page.dart';
import 'package:inventory_management_system/services/auth_service.dart';
import 'package:inventory_management_system/models/user_model.dart';
import 'package:flutter/material.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({Key? key}) : super(key: key);

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  void initState() {
    super.initState();
    // Initialize database in background without blocking UI
    _initializeAppInBackground();
  }

  void _initializeAppInBackground() {
    // Run initialization in background without blocking the UI
    Future.microtask(() async {
      try {
        await AuthService.ensureUserProfileExists();
      } catch (e) {
        print('Background initialization error: $e');
        // Continue anyway - user can still use the app
      }
    });
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
