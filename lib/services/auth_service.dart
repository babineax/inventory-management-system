import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../exceptions/auth_exceptions.dart';
import 'notification_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream controller for auth state changes
  static final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();

  // Current user cache
  static AppUser? _currentUser;

  // Getter for current user
  static AppUser? get currentUser => _currentUser;

  // Stream of auth state changes
  static Stream<AppUser?> get authStateChanges => _authStateController.stream;

  // Initialize auth service
  static Future<void> init() async {
    // Listen to Firebase Auth state changes
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        _authStateController.add(null);
      } else {
        // Get user data from Firestore
        try {
          final userDoc =
              await _firestore.collection('users').doc(firebaseUser.uid).get();

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;

            _currentUser = AppUser(
              id: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              displayName:
                  userData['displayName'] ?? firebaseUser.displayName ?? 'User',
              profilePhotoPath: userData['profilePhotoPath'],
              role: _stringToUserRole(userData['role'] ?? 'staff'),
              createdAt: userData['createdAt'] != null
                  ? (userData['createdAt'] as Timestamp).toDate()
                  : DateTime.now(),
              lastLoginAt: userData['lastLoginAt'] != null
                  ? (userData['lastLoginAt'] as Timestamp).toDate()
                  : DateTime.now(),
              isActive: userData['isActive'] ?? true,
              phone: userData['phone'] ?? '',
              emailNotificationsEnabled:
                  userData['emailNotificationsEnabled'] ?? true,
              smsNotificationsEnabled:
                  userData['smsNotificationsEnabled'] ?? true,
              expiryAlertsEnabled: userData['expiryAlertsEnabled'] ?? true,
              stockAlertsEnabled: userData['stockAlertsEnabled'] ?? true,
              predictionAlertsEnabled:
                  userData['predictionAlertsEnabled'] ?? true,
            );
          } else {
            // Create new user document if it doesn't exist
            final newUser = AppUser(
              id: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              displayName: firebaseUser.displayName ?? 'User',
              profilePhotoPath: firebaseUser.photoURL,
              role: _stringToUserRole('user'),
              createdAt: DateTime.now(),
              lastLoginAt: DateTime.now(),
              isActive: true,
              phone: '',
            );

            await _firestore.collection('users').doc(firebaseUser.uid).set({
              'email': newUser.email,
              'displayName': newUser.displayName,
              'profilePhotoPath': newUser.profilePhotoPath,
              'role': newUser.role.toString().split('.').last,
              'createdAt': FieldValue.serverTimestamp(),
              'lastLoginAt': FieldValue.serverTimestamp(),
              'isActive': true,
              'phone': '',
              'emailNotificationsEnabled': true,
              'smsNotificationsEnabled': true,
              'expiryAlertsEnabled': true,
              'stockAlertsEnabled': true,
              'predictionAlertsEnabled': true,
            });

            _currentUser = newUser;
          }

          _authStateController.add(_currentUser);
        } catch (e) {
          // print('Error fetching user data: $e');
          _currentUser = null;
          _authStateController.add(null);
        }
      }
    });
  }

  // Sign in with email and password
  static Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
    UserRole? role,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Get user data from Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          // Get the user's actual role from database
          final actualUserRole = _stringToUserRole(userData['role'] ?? 'staff');

          // Check if user account is active
          final isActive = userData['isActive'] ?? true;
          if (!isActive) {
            // Sign out the user immediately
            await _auth.signOut();
            throw Exception(
                'Your account has been deactivated. Please contact an administrator.');
          }

          // If a role was selected during login, validate it matches the database role
          if (role != null && role != actualUserRole) {
            // Sign out the user immediately
            await _auth.signOut();
            throw Exception(
                'Invalid credentials. The selected role does not match your account permissions.');
          }

          // Update last login timestamp
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });

          _currentUser = AppUser(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            displayName: userData['displayName'] ??
                userCredential.user!.displayName ??
                'User',
            profilePhotoPath: userData['profilePhotoPath'],
            role: actualUserRole, // Use the actual role from database
            createdAt: userData['createdAt'] != null
                ? (userData['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            lastLoginAt: DateTime.now(),
            isActive: isActive,
            phone: userData['phone'] ?? '',
            emailNotificationsEnabled:
                userData['emailNotificationsEnabled'] ?? true,
            smsNotificationsEnabled:
                userData['smsNotificationsEnabled'] ?? true,
            expiryAlertsEnabled: userData['expiryAlertsEnabled'] ?? true,
            stockAlertsEnabled: userData['stockAlertsEnabled'] ?? true,
            predictionAlertsEnabled:
                userData['predictionAlertsEnabled'] ?? true,
          );

          _authStateController.add(_currentUser);
          return _currentUser;
        } else {
          // If user exists in Firebase Auth but not in Firestore, create a new document
          // For new users, use staff role by default (first user will be admin)
          final userRole = UserRole.staff;

          final newUser = AppUser(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            displayName: userCredential.user!.displayName ?? 'User',
            profilePhotoPath: userCredential.user!.photoURL,
            role: userRole,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            isActive: true,
            phone: '',
          );

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'email': newUser.email,
            'displayName': newUser.displayName,
            'profilePhotoPath': newUser.profilePhotoPath,
            'role': newUser.role.toString().split('.').last,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
            'isActive': true,
            'phone': '',
            'emailNotificationsEnabled': true,
            'smsNotificationsEnabled': true,
            'expiryAlertsEnabled': true,
            'stockAlertsEnabled': true,
            'predictionAlertsEnabled': true,
          });

          _currentUser = newUser;
          _authStateController.add(_currentUser);
          return _currentUser;
        }
      }

      return null;
    } catch (e) {
      print('Sign in error: $e');
      throw AuthException('Sign in failed: ${_getAuthErrorMessage(e)}');
    }
  }

  // Create user with email and password
  static Future<AppUser?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    UserRole? role,
  }) async {
    try {
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
        // If we can't check, assume it's not the first user
      }

      // Create user in Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(displayName);

        // Create user document in Firestore
        final newUser = AppUser(
          id: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          profilePhotoPath: null,
          role:
              userRole, // Use the determined userRole instead of role parameter
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isActive: true,
          phone: '',
        );

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'displayName': displayName,
          'profilePhotoPath': null,
          'role': userRole.toString().split('.').last,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'phone': '',
          'emailNotificationsEnabled': true,
          'smsNotificationsEnabled': true,
          'expiryAlertsEnabled': true,
          'stockAlertsEnabled': true,
          'predictionAlertsEnabled': true,
        });

        _currentUser = newUser;
        _authStateController.add(_currentUser);

        // Send welcome notification
        try {
          await NotificationService.sendWelcomeNotification(newUser);
        } catch (e) {
          print('Failed to send welcome notification: $e');
          // Don't fail user creation if notification fails
        }

        return _currentUser;
      }

      return null;
    } catch (e) {
      print('Registration error: $e');
      throw AuthException('Registration failed: ${_getAuthErrorMessage(e)}');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      _authStateController.add(null);
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Get current user from Firestore
  static Future<AppUser?> getCurrentUserFromFirestore() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      // Get user data from Firestore
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        _currentUser = AppUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName:
              userData['displayName'] ?? firebaseUser.displayName ?? 'User',
          profilePhotoPath: userData['profilePhotoPath'],
          role: _stringToUserRole(userData['role'] ?? 'staff'),
          createdAt: userData['createdAt'] != null
              ? (userData['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          lastLoginAt: userData['lastLoginAt'] != null
              ? (userData['lastLoginAt'] as Timestamp).toDate()
              : DateTime.now(),
          isActive: userData['isActive'] ?? true,
          phone: userData['phone'] ?? '',
          emailNotificationsEnabled:
              userData['emailNotificationsEnabled'] ?? true,
          smsNotificationsEnabled: userData['smsNotificationsEnabled'] ?? true,
          expiryAlertsEnabled: userData['expiryAlertsEnabled'] ?? true,
          stockAlertsEnabled: userData['stockAlertsEnabled'] ?? true,
          predictionAlertsEnabled: userData['predictionAlertsEnabled'] ?? true,
        );

        return _currentUser;
      } else {
        // Create user document if it doesn't exist
        final newUser = AppUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'User',
          profilePhotoPath: firebaseUser.photoURL,
          role: _stringToUserRole('user'),
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isActive: true,
          phone: '',
        );

        await _firestore.collection('users').doc(firebaseUser.uid).set({
          'email': newUser.email,
          'displayName': newUser.displayName,
          'profilePhotoPath': newUser.profilePhotoPath,
          'role': newUser.role.toString().split('.').last,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'phone': '',
          'emailNotificationsEnabled': true,
          'smsNotificationsEnabled': true,
          'expiryAlertsEnabled': true,
          'stockAlertsEnabled': true,
          'predictionAlertsEnabled': true,
        });

        _currentUser = newUser;
        return _currentUser;
      }
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    String? displayName,
    String? profilePhotoPath,
    String? phone,
    bool? emailNotificationsEnabled,
    bool? smsNotificationsEnabled,
    bool? expiryAlertsEnabled,
    bool? stockAlertsEnabled,
    bool? predictionAlertsEnabled,
  }) async {
    try {
      if (_currentUser == null) {
        throw UserNotAuthenticatedException();
      }

      final updates = <String, dynamic>{};

      if (displayName != null) {
        updates['displayName'] = displayName;
        await _auth.currentUser?.updateDisplayName(displayName);
      }

      // Handle profile photo path - including explicit null/empty to remove photo
      if (profilePhotoPath != null) {
        updates['profilePhotoPath'] =
            profilePhotoPath.isEmpty ? null : profilePhotoPath;
      }

      if (phone != null) {
        updates['phone'] = phone;
      }

      if (emailNotificationsEnabled != null) {
        updates['emailNotificationsEnabled'] = emailNotificationsEnabled;
      }

      if (smsNotificationsEnabled != null) {
        updates['smsNotificationsEnabled'] = smsNotificationsEnabled;
      }

      if (expiryAlertsEnabled != null) {
        updates['expiryAlertsEnabled'] = expiryAlertsEnabled;
      }

      if (stockAlertsEnabled != null) {
        updates['stockAlertsEnabled'] = stockAlertsEnabled;
      }

      if (predictionAlertsEnabled != null) {
        updates['predictionAlertsEnabled'] = predictionAlertsEnabled;
      }

      if (updates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(_currentUser!.id)
            .update(updates);

        // Update local user object - handle null profilePhotoPath correctly
        _currentUser = _currentUser!.copyWith(
          displayName: displayName ?? _currentUser!.displayName,
          profilePhotoPath: updates.containsKey('profilePhotoPath')
              ? profilePhotoPath
              : _currentUser!.profilePhotoPath,
          phone: phone ?? _currentUser!.phone,
          emailNotificationsEnabled: emailNotificationsEnabled ??
              _currentUser!.emailNotificationsEnabled,
          smsNotificationsEnabled:
              smsNotificationsEnabled ?? _currentUser!.smsNotificationsEnabled,
          expiryAlertsEnabled:
              expiryAlertsEnabled ?? _currentUser!.expiryAlertsEnabled,
          stockAlertsEnabled:
              stockAlertsEnabled ?? _currentUser!.stockAlertsEnabled,
          predictionAlertsEnabled:
              predictionAlertsEnabled ?? _currentUser!.predictionAlertsEnabled,
        );

        _authStateController.add(_currentUser);
      }
    } catch (e) {
      print('Profile update error: $e');
      throw UserProfileUpdateException('Profile update failed: $e');
    }
  }

  // Change user password
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw UserNotAuthenticatedException();
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } catch (e) {
      print('Password change error: $e');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            throw Exception('Current password is incorrect');
          case 'weak-password':
            throw Exception('New password is too weak');
          case 'requires-recent-login':
            throw Exception('Please sign in again to change your password');
          default:
            throw Exception('Failed to change password: ${e.message}');
        }
      }
      throw Exception('Failed to change password: $e');
    }
  }

  // Reset password via email
  static Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Password reset error: $e');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw Exception('No user found with this email address');
          case 'invalid-email':
            throw Exception('Invalid email address');
          case 'too-many-requests':
            throw Exception('Too many requests. Please try again later');
          default:
            throw Exception(
                'Failed to send password reset email: ${e.message}');
        }
      }
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Check if user is admin
  static bool isUserAdmin() {
    return _currentUser?.role == UserRole.admin;
  }

  // Promote a user to admin role
  static Future<bool> promoteUserToAdmin(String userId) async {
    try {
      // Update the user's role in Firestore
      await _firestore.collection('users').doc(userId).update({
        'role': 'admin',
      });

      // If the promoted user is the current user, update the local user object
      if (_currentUser != null && _currentUser!.id == userId) {
        _currentUser = _currentUser!.copyWith(role: UserRole.admin);
        _authStateController.add(_currentUser);
      }

      return true;
    } catch (e) {
      print('Error promoting user to admin: $e');
      throw UserPromotionException('Error promoting user to admin: $e');
    }
  }

  // Get all users (admin only)
  static Future<List<AppUser>> getAllUsers() async {
    try {
      if (!isUserAdmin()) {
        throw Exception('Only admins can access user list');
      }

      final usersSnapshot = await _firestore.collection('users').get();

      return usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return AppUser(
          id: doc.id,
          email: data['email'] ?? '',
          displayName: data['displayName'] ?? 'User',
          profilePhotoPath: data['profilePhotoPath'],
          role: _stringToUserRole(data['role'] ?? 'staff'),
          createdAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          lastLoginAt: data['lastLoginAt'] != null
              ? (data['lastLoginAt'] as Timestamp).toDate()
              : DateTime.now(),
          isActive: data['isActive'] ?? true,
          phone: data['phone'] ?? '',
          emailNotificationsEnabled: data['emailNotificationsEnabled'] ?? true,
          smsNotificationsEnabled: data['smsNotificationsEnabled'] ?? true,
          expiryAlertsEnabled: data['expiryAlertsEnabled'] ?? true,
          stockAlertsEnabled: data['stockAlertsEnabled'] ?? true,
          predictionAlertsEnabled: data['predictionAlertsEnabled'] ?? true,
        );
      }).toList();
    } catch (e) {
      print('Error getting all users: $e');
      throw Exception('Failed to get users: $e');
    }
  }

  // Create user by admin
  static Future<AppUser> createUserByAdmin({
    required String email,
    required String password,
    required String displayName,
    required String phone,
    required UserRole role,
  }) async {
    try {
      if (!isUserAdmin()) {
        throw Exception('Only admins can create users');
      }

      // Store current admin user info
      final adminUser = _auth.currentUser;
      final adminEmail = adminUser?.email;

      // Create user in Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(displayName);

        // Create user document in Firestore
        final newUser = AppUser(
          id: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          profilePhotoPath: null,
          role: role,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isActive: true,
          phone: phone,
          emailNotificationsEnabled: true,
          smsNotificationsEnabled: true,
          expiryAlertsEnabled: true,
          stockAlertsEnabled: true,
          predictionAlertsEnabled: true,
        );

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'displayName': displayName,
          'profilePhotoPath': null,
          'role': role.toString().split('.').last,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'phone': phone,
          'emailNotificationsEnabled': true,
          'smsNotificationsEnabled': true,
          'expiryAlertsEnabled': true,
          'stockAlertsEnabled': true,
          'predictionAlertsEnabled': true,
          'needsPasswordReset': true, // Flag for temporary password
        });

        // Sign out the newly created user immediately
        await _auth.signOut();

        // Restore admin session by getting from Firestore
        if (adminUser != null && adminEmail != null) {
          try {
            final adminDoc =
                await _firestore.collection('users').doc(adminUser.uid).get();
            if (adminDoc.exists) {
              final adminData = adminDoc.data() as Map<String, dynamic>;
              _currentUser = AppUser(
                id: adminUser.uid,
                email: adminData['email'] ?? '',
                displayName: adminData['displayName'] ?? 'Admin',
                profilePhotoPath: adminData['profilePhotoPath'],
                role: _stringToUserRole(adminData['role'] ?? 'admin'),
                createdAt: adminData['createdAt'] != null
                    ? (adminData['createdAt'] as Timestamp).toDate()
                    : DateTime.now(),
                lastLoginAt: adminData['lastLoginAt'] != null
                    ? (adminData['lastLoginAt'] as Timestamp).toDate()
                    : DateTime.now(),
                isActive: adminData['isActive'] ?? true,
                phone: adminData['phone'] ?? '',
                emailNotificationsEnabled:
                    adminData['emailNotificationsEnabled'] ?? true,
                smsNotificationsEnabled:
                    adminData['smsNotificationsEnabled'] ?? true,
                expiryAlertsEnabled: adminData['expiryAlertsEnabled'] ?? true,
                stockAlertsEnabled: adminData['stockAlertsEnabled'] ?? true,
                predictionAlertsEnabled:
                    adminData['predictionAlertsEnabled'] ?? true,
              );
              _authStateController.add(_currentUser);
            }
          } catch (restoreError) {
            print('Error restoring admin session: $restoreError');
          }
        }

        // Send password reset email to new user for them to set their own password
        try {
          await _auth.sendPasswordResetEmail(email: email);
          print('Password reset email sent to new user: $email');
        } catch (emailError) {
          print('Failed to send password reset email: $emailError');
          // Check if it's a configuration issue
          if (emailError.toString().contains('auth/invalid-continue-uri') ||
              emailError
                  .toString()
                  .contains('auth/unauthorized-continue-uri')) {
            print(
                'Email configuration error - this is expected in development');
          }
          // Don't fail user creation if email fails
        }

        return newUser;
      }

      throw Exception('Failed to create user');
    } catch (e) {
      print('Error creating user by admin: $e');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            throw Exception('A user with this email already exists');
          case 'weak-password':
            throw Exception(
                'Password is too weak. Please use at least 6 characters');
          case 'invalid-email':
            throw Exception('Invalid email address format');
          case 'operation-not-allowed':
            throw Exception('Email/password accounts are not enabled');
          default:
            throw Exception('Failed to create user: ${e.message}');
        }
      }
      throw Exception('Failed to create user: $e');
    }
  }

  // Update user by admin
  static Future<void> updateUserByAdmin({
    required String userId,
    required String displayName,
    required String phone,
    required UserRole role,
    required bool isActive,
  }) async {
    try {
      if (!isUserAdmin()) {
        throw Exception('Only admins can update users');
      }

      await _firestore.collection('users').doc(userId).update({
        'displayName': displayName,
        'phone': phone,
        'role': role.toString().split('.').last,
        'isActive': isActive,
      });

      // If the updated user is the current user, update the local user object
      if (_currentUser != null && _currentUser!.id == userId) {
        _currentUser = _currentUser!.copyWith(
          displayName: displayName,
          phone: phone,
          role: role,
          isActive: isActive,
        );
        _authStateController.add(_currentUser);
      }
    } catch (e) {
      print('Error updating user by admin: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  // Toggle user status (admin only)
  static Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      if (!isUserAdmin()) {
        throw Exception('Only admins can toggle user status');
      }

      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
      });

      // If the updated user is the current user, update the local user object
      if (_currentUser != null && _currentUser!.id == userId) {
        _currentUser = _currentUser!.copyWith(isActive: isActive);
        _authStateController.add(_currentUser);
      }
    } catch (e) {
      print('Error toggling user status: $e');
      throw Exception('Failed to toggle user status: $e');
    }
  }

  // Delete user (admin only)
  static Future<void> deleteUser(String userId) async {
    try {
      if (!isUserAdmin()) {
        throw Exception('Only admins can delete users');
      }

      // Delete user document from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Note: Deleting from Firebase Auth requires admin SDK
      // For now, we'll just deactivate the user in Firestore
      // In a production app, you'd need to use Firebase Admin SDK on the backend
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  // Helper method to get user-friendly error messages
  static String _getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'email-already-in-use':
          return 'The email address is already in use.';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        default:
          return error.message ?? 'An unknown error occurred.';
      }
    }
    return error.toString();
  }

  // Convert string role to UserRole enum
  static UserRole _stringToUserRole(String roleStr) {
    switch (roleStr.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'staff':
        return UserRole.staff;
      default:
        return UserRole.staff; // Default role
    }
  }

  // Dispose resources
  static void dispose() {
    _authStateController.close();
  }
}
