import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'landing_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Icon animation controller
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Icon zoom-in animation (medium to large)
    _iconScaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.elasticOut,
      ),
    );

    // Icon fade-in animation
    _iconOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Text fade-in animation
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    // Text slide-up animation
    _textSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    // Start animations
    _iconController.forward();

    // Start text animation after icon animation begins
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _textController.forward();
      }
    });

    // Navigate to the next screen with professional transition
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LandingScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              // Professional slide and fade transition
              const begin = Offset(0.0, 0.3);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var slideAnimation = Tween(begin: begin, end: end).animate(
                CurvedAnimation(parent: animation, curve: curve),
              );

              var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: curve),
              );

              return SlideTransition(
                position: slideAnimation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor,
              theme.primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon with zoom animation
              AnimatedBuilder(
                animation: _iconController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _iconScaleAnimation.value,
                    child: Opacity(
                      opacity: _iconOpacityAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/icons/app_icon6.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to default icon if image fails to load
                              return Icon(
                                Icons.inventory_2,
                                size: 60,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // App Name with slide and fade animation
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _textSlideAnimation.value),
                    child: Opacity(
                      opacity: _textOpacityAnimation.value,
                      child: Column(
                        children: [
                          Text(
                            'StockSense',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Smart Inventory Management',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.9),
                              letterSpacing: 0.5,
                            ),
                          ),
                          // const SizedBox(height: 4),
                          // Text(
                          //   'v3.2.1 (Build: 2025-11-29-22:00)',
                          //   style: GoogleFonts.poppins(
                          //     fontSize: 10,
                          //     fontWeight: FontWeight.w300,
                          //     color: Colors.white.withValues(alpha: 0.6),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 60),

              // Loading indicator
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textOpacityAnimation.value,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
