import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();

  static AppUser? _currentUser;

  // Get current user
  static AppUser? get currentUser => _currentUser;

  // Auth state changes stream
  static Stream<AppUser?> get authStateChanges => _authStateController.stream;

  // Initialize auth state listener
  static void initialize() {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        // User is signed in, get user profile from Firestore
        try {
          final userDoc =
              await _firestore.collection('users').doc(firebaseUser.uid).get();

          if (userDoc.exists) {
            _currentUser = AppUser.fromMap(userDoc.data()!, firebaseUser.uid);
          } else {
            // Create user profile if it doesn't exist
            _currentUser = await _createUserProfile(firebaseUser);
          }
        } catch (e) {
          print('Error getting user profile: $e');
          _currentUser = null;
        }
      } else {
        // User is signed out
        _currentUser = null;
      }

      // Notify listeners
      _authStateController.add(_currentUser);
    });
  }

  // Sign in with email and password
  static Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Sign in failed');
      }

      // Update last login time
      await _firestore.collection('users').doc(credential.user!.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      // Get user profile
      final userDoc =
          await _firestore.collection('users').doc(credential.user!.uid).get();

      if (userDoc.exists) {
        _currentUser = AppUser.fromMap(userDoc.data()!, credential.user!.uid);
        return _currentUser!;
      } else {
        // Create user profile if it doesn't exist
        _currentUser = await _createUserProfile(credential.user!);
        return _currentUser!;
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found for that email.');
        case 'wrong-password':
          throw Exception('Wrong password provided.');
        case 'invalid-email':
          throw Exception('Invalid email address.');
        case 'user-disabled':
          throw Exception('User account has been disabled.');
        default:
          throw Exception('Sign in failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Create user with email and password
  static Future<AppUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    UserRole? role,
  }) async {
    try {
      print('Starting user creation for: $email');

      // Check if this is the first user (should be admin regardless of role parameter)
      UserRole userRole = role ?? UserRole.staff;
      try {
        final allUsersQuery =
            await _firestore.collection('users').limit(1).get();

        if (allUsersQuery.docs.isEmpty) {
          userRole = UserRole.admin;
          print('No existing users found. Creating first user as admin.');
        } else {
          print(
              'Existing users found. Creating user with role: ${userRole.toString()}');
        }
      } catch (firestoreError) {
        print('Error checking existing users: $firestoreError');
        // If we can't check, assume it's the first user
        userRole = UserRole.admin;
        print(
            'Assuming first user due to Firestore check error. Creating as admin.');
      }

      print('Creating Firebase Auth user...');
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Firebase Auth returned null user');
      }

      print(
          'Firebase Auth user created successfully. UID: ${credential.user!.uid}');

      // Update display name
      print('Updating display name...');
      await credential.user!.updateDisplayName(displayName);

      // Create user profile in Firestore
      print('Creating user profile in Firestore...');
      final userData = {
        'email': email,
        'displayName': displayName,
        'role': userRole.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userData);

      print('User profile created in Firestore successfully');

      // Create AppUser object
      _currentUser = AppUser(
        id: credential.user!.uid,
        email: email,
        displayName: displayName,
        role: userRole,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
      );

      print('User creation completed successfully');
      return _currentUser!;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'weak-password':
          throw Exception('The password provided is too weak.');
        case 'email-already-in-use':
          throw Exception('The account already exists for that email.');
        case 'invalid-email':
          throw Exception('Invalid email address.');
        case 'network-request-failed':
          throw Exception(
              'Network error. Please check your internet connection.');
        case 'too-many-requests':
          throw Exception('Too many requests. Please try again later.');
        default:
          throw Exception('Account creation failed: ${e.message}');
      }
    } catch (e) {
      print('General error during user creation: $e');
      throw Exception('Account creation failed: $e');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      _authStateController.add(null);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Create user profile in Firestore
  static Future<AppUser> _createUserProfile(User firebaseUser) async {
    final userData = {
      'email': firebaseUser.email ?? '',
      'displayName': firebaseUser.displayName ??
          firebaseUser.email?.split('@')[0] ??
          'User',
      'role': 'staff', // Default role
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'isActive': true,
    };

    await _firestore.collection('users').doc(firebaseUser.uid).set(userData);

    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ??
          firebaseUser.email?.split('@')[0] ??
          'User',
      role: UserRole.staff,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isActive: true,
    );
  }

  // Ensure admin user exists (for production setup)
  static Future<void> ensureAdminUserExists() async {
    try {
      // Check if any users exist at all
      final allUsersQuery = await _firestore.collection('users').limit(1).get();

      if (allUsersQuery.docs.isEmpty) {
        print('No users found. First user will be created as admin.');
        return;
      }

      // Check if any admin users exist
      final adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (adminQuery.docs.isEmpty) {
        print(
            'No admin user found. Please create an admin user through the app.');
      }
    } catch (e) {
      print('Error checking for admin user: $e');
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found for that email.');
        case 'invalid-email':
          throw Exception('Invalid email address.');
        default:
          throw Exception('Password reset failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    String? displayName,
    String? profilePhotoPath,
  }) async {
    try {
      if (_currentUser == null) {
        throw Exception('No user signed in');
      }

      final updates = <String, dynamic>{};

      if (displayName != null) {
        updates['displayName'] = displayName;
        await _auth.currentUser?.updateDisplayName(displayName);
      }

      if (profilePhotoPath != null) {
        updates['profilePhotoPath'] = profilePhotoPath;
      }

      if (updates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(_currentUser!.id)
            .update(updates);

        // Update local user object
        _currentUser = _currentUser!.copyWith(
          displayName: displayName ?? _currentUser!.displayName,
          profilePhotoPath: profilePhotoPath ?? _currentUser!.profilePhotoPath,
        );

        _authStateController.add(_currentUser);
      }
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  // Dispose resources
  static void dispose() {
    _authStateController.close();
  }
}
