// Backward compatibility wrapper - use AuthService instead
import 'services/auth_service.dart';
// import 'package:firebase_auth/firebase_auth.dart';

class Auth {
  // User authentication is disabled for local SQLite testing.
  // You can implement local user logic here if needed.

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await AuthService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await AuthService.createUserWithEmailAndPassword(
      email: email,
      password: password,
      displayName: email.split('@').first,
    );
  }

  Future<void> signOut() async {
    await AuthService.signOut();
  }
}
