import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_register_page.dart';
import '../home_page.dart';
import '../../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in
          return FutureBuilder<UserModel?>(
            future: _getUserData(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Apply a professional page transition animation
              return PageTransition(
                type: PageTransitionType.professionalSlide,
                child: HomePage(currentUser: userSnapshot.data),
              );
            },
          );
        } else {
          // User is not logged in
          return const PageTransition(
            type: PageTransitionType.fade,
            child: LoginPage(),
          );
        }
      },
    );
  }

  // Helper method to get user data
  Future<UserModel?> _getUserData(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};

        // Convert directly to UserModel using the correct constructor parameters
        return UserModel(
          uid: doc.id,
          email: data['email'] ?? '',
          displayName: data['displayName'],
          isAdmin: data['role'] == 'admin',
          createdAt: data['createdAt']?.toDate(),
        );
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Helper method to parse user role
  UserRole _parseUserRole(String? roleStr) {
    if (roleStr == 'admin') {
      return UserRole.admin;
    }
    return UserRole.staff;
  }
}

// Custom page transition widget
class PageTransition extends StatelessWidget {
  final Widget child;
  final PageTransitionType type;
  final Curve curve;
  final Alignment alignment;
  final Duration duration;

  const PageTransition({
    super.key,
    required this.child,
    this.type = PageTransitionType.fade,
    this.curve = Curves.easeInOut,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        switch (type) {
          case PageTransitionType.fade:
            return Opacity(opacity: value, child: child);
          case PageTransitionType.scale:
            return Transform.scale(scale: value, child: child);
          case PageTransitionType.rotate:
            return Transform.rotate(
              angle: (1 - value) * 0.5,
              child: child,
            );
          case PageTransitionType.fadeWithScale:
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.6 + (0.4 * value),
                child: child,
              ),
            );
          case PageTransitionType.fadeWithScaleAndRotation:
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.7 + (0.3 * value),
                child: Transform.rotate(
                  angle: (1 - value) * 0.2,
                  child: child,
                ),
              ),
            );
          case PageTransitionType.professionalSlide:
            // Professional slide up with fade - smooth and elegant
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.95 + (0.05 * value),
                  child: child,
                ),
              ),
            );
        }
      },
      child: child,
    );
  }
}

enum PageTransitionType {
  fade,
  scale,
  rotate,
  fadeWithScale,
  fadeWithScaleAndRotation,
  professionalSlide,
}
