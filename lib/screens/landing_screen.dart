import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'auth/widget_tree.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Interactive state
  final bool _isExpanded = false;
  int _selectedFeature = -1;
  int _selectedGuideStep = -1;

  // Theme-aware color palette for feature icons
  static Map<IconData, Color> getFeatureIconColors(
      bool isDarkMode, Color primaryColor) {
    if (isDarkMode) {
      // Dark mode: Brighter, more saturated colors for better visibility
      return {
        Icons.timeline: const Color(0xFF42A5F5), // Bright blue
        Icons.sync_alt: const Color(0xFF66BB6A), // Bright green
        Icons.auto_graph: const Color(0xFFFFB74D), // Bright orange
        Icons.people_alt_outlined: const Color(0xFFBA68C8), // Bright purple
        Icons.inventory_2: const Color(0xFF42A5F5), // Bright blue
        Icons.inventory: const Color(0xFF42A5F5), // Bright blue
        Icons.bar_chart: const Color(0xFF42A5F5), // Bright blue
        Icons.notifications: const Color(0xFFFFB74D), // Bright orange
        Icons.security: const Color(0xFFBA68C8), // Bright purple
        Icons.login: const Color(0xFF42A5F5), // Bright blue
        Icons.analytics: const Color(0xFF42A5F5), // Bright blue
        Icons.group_add: const Color(0xFF42A5F5), // Bright blue
        Icons.trending_up: const Color(0xFF66BB6A), // Bright green
        Icons.speed: const Color(0xFFFFB74D), // Bright orange
        Icons.group: const Color(0xFFBA68C8), // Bright purple
      };
    } else {
      // Light mode: Professional colors with good contrast
      return {
        Icons.timeline: const Color(0xFF1976D2), // Professional blue
        Icons.sync_alt: const Color(0xFF388E3C), // Professional green
        Icons.auto_graph: const Color(0xFFF57C00), // Professional orange
        Icons.people_alt_outlined:
            const Color(0xFF7B1FA2), // Professional purple
        Icons.inventory_2: const Color(0xFF1976D2), // Professional blue
        Icons.inventory: const Color(0xFF1976D2), // Professional blue
        Icons.bar_chart: const Color(0xFF1976D2), // Professional blue
        Icons.notifications: const Color(0xFFF57C00), // Professional orange
        Icons.security: const Color(0xFF7B1FA2), // Professional purple
        Icons.login: const Color(0xFF1976D2), // Professional blue
        Icons.analytics: const Color(0xFF1976D2), // Professional blue
        Icons.group_add: const Color(0xFF1976D2), // Professional blue
        Icons.trending_up: const Color(0xFF388E3C), // Professional green
        Icons.speed: const Color(0xFFF57C00), // Professional orange
        Icons.group: const Color(0xFF7B1FA2), // Professional purple
      };
    }
  }

  @override
  void initState() {
    super.initState();

    // Fade animation for overall content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Scale animation for logo
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // Start animations with delays for smooth, professional loading
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Responsive breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isMediumScreen = screenWidth < 600;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          // Dark theme: Pure dark gradient for better dark mode experience
                          const Color(0xFF121212), // Dark grey
                          const Color(0xFF1e1e1e), // Slightly lighter dark grey
                          const Color(0xFF0f0f0f), // Very dark grey
                        ]
                      : [
                          // Light theme: Neutral gradient for better readability
                          Colors.grey[50]!,
                          Colors.grey[25] ?? Colors.white,
                          Colors.white,
                          Colors.white,
                        ],
                  stops: isDarkMode
                      ? const [0.0, 0.5, 1.0] // 3 stops for 3 colors
                      : const [0.0, 0.33, 0.67, 1.0], // 4 stops for 4 colors
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // Animated Logo Section
                            AnimatedBuilder(
                              animation: _scaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: _buildHeroSection(context, isDarkMode,
                                      isSmallScreen, isMediumScreen),
                                );
                              },
                            ),

                            const SizedBox(height: 40),

                            // App Overview Section
                            _buildAppOverview(context, isDarkMode,
                                isSmallScreen, isMediumScreen),

                            const SizedBox(height: 40),

                            // Interactive Features Section
                            _buildFeaturesSection(context, isDarkMode),

                            const SizedBox(height: 40),

                            // Quick Start Guide
                            _buildQuickGuideSection(context, isDarkMode),

                            const SizedBox(height: 40),

                            // Stats Section
                            _buildStatsSection(context, isDarkMode),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                    _buildGetStartedButton(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDarkMode,
      bool isSmallScreen, bool isMediumScreen) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Animated Logo with Glow Effect
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withValues(alpha: 0.2),
                theme.primaryColor.withValues(alpha: 0.1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: isDarkMode ? Colors.white : theme.primaryColor,
          ),
        ),

        const SizedBox(height: 24),

        // App Title with Gradient Text
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isDarkMode
                ? [Colors.white, Colors.white70]
                : [Colors.black87, Colors.black],
          ).createShader(bounds),
          child: Text(
            'StockSense',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontFamilyFallback: ['Roboto', 'sans-serif'],
              fontSize: isSmallScreen ? 32 : (isMediumScreen ? 36 : 42),
              fontWeight: FontWeight.bold,
              color: Colors.white, // Required for ShaderMask
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Subtitle
        Text(
          'Smart Inventory Management,\nSimplified.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontFamilyFallback: ['Roboto', 'sans-serif'],
            fontSize: isSmallScreen ? 14 : (isMediumScreen ? 16 : 18),
            fontWeight: FontWeight.w400,
            color: isDarkMode ? Colors.white70 : Colors.black87,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 16),

        // Tagline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            'AI-Powered • Real-Time • Secure',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontFamilyFallback: ['Roboto', 'sans-serif'],
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppOverview(BuildContext context, bool isDarkMode,
      bool isSmallScreen, bool isMediumScreen) {
    final theme = Theme.of(context);

    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 600),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Text(
              'What is StockSense?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontFamilyFallback: ['Roboto', 'sans-serif'],
                fontSize: isSmallScreen ? 20 : (isMediumScreen ? 22 : 24),
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[200]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 32,
                    color: isDarkMode ? Colors.amber[400] : theme.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'StockSense is a comprehensive inventory management solution designed for modern businesses. Using advanced AI algorithms and real-time analytics, it helps you maintain optimal stock levels, predict future needs, and streamline your operations.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontFamilyFallback: ['Roboto', 'sans-serif'],
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 600),
          childAnimationBuilder: (widget) => SlideAnimation(
            horizontalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Text(
              'Powerful Features',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontFamilyFallback: ['Roboto', 'sans-serif'],
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            _buildInteractiveFeature(
              context,
              icon: Icons.timeline,
              title: 'Real-time Tracking',
              subtitle: 'Monitor your inventory levels and values instantly.',
              details:
                  'Get live updates on stock levels, values, and movements across all your locations.',
              isDarkMode: isDarkMode,
            ),
            _buildInteractiveFeature(
              context,
              icon: Icons.sync_alt,
              title: 'Stock Movements',
              subtitle:
                  'Log every stock addition, removal, or transfer with ease.',
              details:
                  'Track all inventory changes with detailed audit trails and automated logging.',
              isDarkMode: isDarkMode,
            ),
            _buildInteractiveFeature(
              context,
              icon: Icons.auto_graph,
              title: 'AI-Powered Predictions',
              subtitle: 'Forecast future stock needs to prevent shortages.',
              details:
                  'Machine learning algorithms predict demand patterns and alert you before stock runs out.',
              isDarkMode: isDarkMode,
            ),
            _buildInteractiveFeature(
              context,
              icon: Icons.people_alt_outlined,
              title: 'User Role Management',
              subtitle: 'Assign roles and permissions for secure team access.',
              details:
                  'Multi-user support with customizable permissions and secure access controls.',
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String details,
    required bool isDarkMode,
  }) {
    final theme = Theme.of(context);
    final iconColor =
        getFeatureIconColors(isDarkMode, theme.primaryColor)[icon] ??
            theme.primaryColor;
    final isSelected = _selectedFeature == icon.hashCode;

    return AnimationLimiter(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFeature = isSelected ? -1 : icon.hashCode;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? iconColor.withValues(alpha: 0.1)
                : (isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? iconColor.withValues(alpha: 0.3)
                  : (isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[200]!),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          iconColor.withValues(alpha: isSelected ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: isSelected ? 28 : 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white60 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: isSelected ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: isDarkMode ? Colors.white60 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isSelected ? null : 0,
                child: isSelected
                    ? Column(
                        children: [
                          const SizedBox(height: 16),
                          Divider(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey[300],
                            height: 1,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            details,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickGuideSection(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 600),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 30.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Text(
              'Quick Start Guide',
              style: GoogleFonts.poppins(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Get up and running in minutes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDarkMode ? Colors.white60 : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            _buildGuideStep(
              context,
              step: 1,
              icon: Icons.login,
              title: 'Sign Up / Sign In',
              description:
                  'Create your account or log in to access your dashboard.',
              isDarkMode: isDarkMode,
            ),
            _buildGuideStep(
              context,
              step: 2,
              icon: Icons.inventory,
              title: 'Add Your First Item',
              description:
                  'Start by adding your inventory items with details and categories.',
              isDarkMode: isDarkMode,
            ),
            _buildGuideStep(
              context,
              step: 3,
              icon: Icons.analytics,
              title: 'Monitor & Predict',
              description:
                  'Let AI analyze your patterns and provide smart predictions.',
              isDarkMode: isDarkMode,
            ),
            _buildGuideStep(
              context,
              step: 4,
              icon: Icons.group_add,
              title: 'Invite Your Team',
              description:
                  'Add team members and assign appropriate roles and permissions.',
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(
    BuildContext context, {
    required int step,
    required IconData icon,
    required String title,
    required String description,
    required bool isDarkMode,
  }) {
    final theme = Theme.of(context);
    final iconColor =
        getFeatureIconColors(isDarkMode, theme.primaryColor)[icon] ??
            theme.primaryColor;
    final isSelected = _selectedGuideStep == step;

    return AnimationLimiter(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGuideStep = isSelected ? -1 : step;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? iconColor.withValues(alpha: 0.1)
                : (isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? iconColor.withValues(alpha: 0.3)
                  : (isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[200]!),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          iconColor.withValues(alpha: isSelected ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: GoogleFonts.poppins(
                          fontSize: isSelected ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        child: Text(step.toString()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white60 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: isSelected ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: isDarkMode ? Colors.white60 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isSelected ? null : 0,
                child: isSelected
                    ? Column(
                        children: [
                          const SizedBox(height: 16),
                          Divider(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey[300],
                            height: 1,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailedGuideStep(step, isDarkMode),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedGuideStep(int step, bool isDarkMode) {
    final details = _getGuideStepDetails(step);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 20,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 8),
            Text(
              'What you\'ll do:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...details.map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      detail,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: isDarkMode ? Colors.white60 : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getGuideStepTip(step),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _getGuideStepDetails(int step) {
    switch (step) {
      case 1:
        return [
          'Create a new account with your email and password',
          'Or sign in if you already have an account',
          'Verify your email for security (optional)',
          'Set up your basic profile information'
        ];
      case 2:
        return [
          'Navigate to the inventory section',
          'Tap "Add Item" to create your first product',
          'Fill in item details: name, description, category',
          'Set quantity, price, and reorder levels',
          'Upload product images if available'
        ];
      case 3:
        return [
          'View your dashboard for real-time insights',
          'Check stock predictions and alerts',
          'Monitor inventory value and trends',
          'Review stock movement history',
          'Set up notifications for low stock alerts'
        ];
      case 4:
        return [
          'Go to user management in your profile',
          'Invite team members via email',
          'Assign appropriate roles (Admin/Staff)',
          'Set permissions for different access levels',
          'Manage user accounts and access rights'
        ];
      default:
        return [];
    }
  }

  String _getGuideStepTip(int step) {
    switch (step) {
      case 1:
        return 'Pro tip: Use a strong password and enable two-factor authentication for better security.';
      case 2:
        return 'Pro tip: Start with your most important or fast-moving items to see immediate benefits.';
      case 3:
        return 'Pro tip: Set up email notifications for critical stock alerts to stay on top of inventory.';
      case 4:
        return 'Pro tip: Assign Admin roles sparingly and Staff roles for daily operations.';
      default:
        return '';
    }
  }

  Widget _buildStatsSection(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 600),
          childAnimationBuilder: (widget) => ScaleAnimation(
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Text(
              'Why Choose StockSense?',
              style: GoogleFonts.poppins(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.trending_up,
                    value: '99.9%',
                    label: 'Uptime',
                    color: Colors.transparent, // Not used anymore
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.security,
                    value: '256-bit',
                    label: 'Encryption',
                    color: Colors.transparent, // Not used anymore
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.speed,
                    value: '< 1s',
                    label: 'Response Time',
                    color: Colors.transparent, // Not used anymore
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.group,
                    value: 'Team',
                    label: 'Access',
                    color: Colors.transparent, // Not used anymore
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDarkMode,
  }) {
    // Get theme-aware color for the stat icon
    final theme = Theme.of(context);
    final statIconColor =
        getStatIconColor(icon, isDarkMode, theme.primaryColor);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: statIconColor,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDarkMode ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Get theme-aware colors for stat icons
  static Color getStatIconColor(
      IconData icon, bool isDarkMode, Color primaryColor) {
    if (isDarkMode) {
      // Dark mode: Bright, vibrant colors for visibility
      switch (icon) {
        case Icons.trending_up:
          return const Color(0xFF66BB6A); // Bright green
        case Icons.security:
          return const Color(0xFF42A5F5); // Bright blue
        case Icons.speed:
          return const Color(0xFFFFB74D); // Bright orange
        case Icons.group:
          return const Color(0xFFBA68C8); // Bright purple
        default:
          return primaryColor;
      }
    } else {
      // Light mode: Professional colors with good contrast
      switch (icon) {
        case Icons.trending_up:
          return const Color(0xFF388E3C); // Professional green
        case Icons.security:
          return const Color(0xFF1976D2); // Professional blue
        case Icons.speed:
          return const Color(0xFFF57C00); // Professional orange
        case Icons.group:
          return const Color(0xFF7B1FA2); // Professional purple
        default:
          return primaryColor;
      }
    }
  }

  Widget _buildGetStartedButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnimationLimiter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        width: double.infinity,
        child: Column(
          children: [
            // Get Started Button
            AnimationConfiguration.staggeredList(
              position: 0,
              duration: const Duration(milliseconds: 800),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const WidgetTree(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOutCubic;

                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));
                              var slideAnimation = animation.drive(tween);

                              return SlideTransition(
                                position: slideAnimation,
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 600),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Skip Button for returning users
            AnimationConfiguration.staggeredList(
              position: 1,
              duration: const Duration(milliseconds: 800),
              child: SlideAnimation(
                verticalOffset: 30.0,
                child: FadeInAnimation(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const WidgetTree(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, 0.3);
                            const end = Offset.zero;
                            const curve = Curves.easeOut;

                            var tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));
                            var slideAnimation = animation.drive(tween);

                            return SlideTransition(
                              position: slideAnimation,
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 400),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      foregroundColor:
                          isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                    child: Text(
                      'Skip - Already have an account',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
