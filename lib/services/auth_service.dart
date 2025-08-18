// Firebase imports commented out for SQLite-only mode
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import 'inventory_service.dart';

class AuthService {
  static AppUser? _currentUser;
  static const String _usersTable = 'users';
  static final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();

  // In-memory storage for demo purposes
  static final Map<String, String> _userPasswords = {};

  // Simple local authentication for testing
  static AppUser? get currentUser => _currentUser;

  static Stream<AppUser?> get authStateChanges => _authStateController.stream;

  static Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Check if user exists and password matches
    if (_userPasswords.containsKey(email)) {
      if (_userPasswords[email] != password) {
        throw Exception('Invalid password');
      }
    } else {
      // For demo - with any password
      if (email != 'admin@inventory.com') {
        throw Exception('User not found');
      }
      // Store the password for future logins
      _userPasswords[email] = password;
    }

    final tempUser = AppUser(
      id: '1',
      email: email,
      displayName: email == 'admin@inventory.com' ? 'Administrator' : 'User',
      role: email == 'admin@inventory.com' ? UserRole.admin : UserRole.staff,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isActive: true,
    );

    _currentUser = tempUser;

    // Notify listeners of auth state change
    _authStateController.add(_currentUser);

    // Try to save to database in background (don't wait for it)
    _saveUserToDatabase(tempUser);

    return _currentUser!;
  }

  static void _saveUserToDatabase(AppUser user) async {
    try {
      final db = await InventoryService.database;
      await db.insert(_usersTable, user.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('Background database save failed: $e');
      // Continue anyway - user is already logged in
    }
  }

  static Future<AppUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    UserRole role = UserRole.staff,
  }) async {
    // Check if user already exists
    if (_userPasswords.containsKey(email)) {
      throw Exception('User already exists');
    }

    // Store the password
    _userPasswords[email] = password;

    final tempUser = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      displayName: displayName,
      role: role,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isActive: true,
    );

    _currentUser = tempUser;

    // Notify listeners of auth state change
    _authStateController.add(_currentUser);

    // Try to save to database in background (don't wait for it)
    _saveUserToDatabase(tempUser);

    return _currentUser!;
  }

  static Future<void> signOut() async {
    _currentUser = null;
    // Notify listeners of auth state change
    _authStateController.add(null);
  }

  static Future<void> ensureUserProfileExists() async {
    try {
      // Create a default admin user if no users exist
      final db = await InventoryService.database;
      final maps = await db.query(_usersTable);

      if (maps.isEmpty) {
        await createUserWithEmailAndPassword(
          email: 'admin@inventory.com',
          password: 'admin123',
          displayName: 'Administrator',
          role: UserRole.admin,
        );
      }
    } catch (e) {
      print('Error ensuring user profile exists: $e');
      // Continue without creating user - app will handle gracefully
    }
  }

  // Firebase Auth methods (commented out for reference)
  /*
  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    UserRole role = UserRole.staff,
  }) async {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Create user profile in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(credential.user!.uid)
        .set({
      'email': email,
      'displayName': displayName,
      'role': role.toString().split('.').last,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
    
    return credential;
  }
  */
}
