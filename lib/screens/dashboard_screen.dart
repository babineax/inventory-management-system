import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/inventory_service.dart';
import '../services/auth_service.dart';
import '../services/expiry_notification_service.dart';
import '../models/user_model.dart';
import '../models/inventory_item.dart';
import '../providers/theme_provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../widgets/stat_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/expiry_alert_card.dart';
import '../widgets/welcome_card.dart';
import '../services/notification_service.dart';
import '../utils/date_utils.dart' as CustomDateUtils;
import 'inventory_form_screen.dart';
import 'qr_scanner_screen.dart';
import 'expiry_alerts_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onTabSelected;

  const DashboardScreen({super.key, required this.onTabSelected});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AppUser? currentUser;
  int _touchedStockIndex = -1;
  int _touchedCategoryIndex = -1;

  // late Future<void> _dashboardFuture;
  late Stream<List<Map<String, dynamic>>> _monthlyDataStream;
  late Stream<Map<String, dynamic>> _dashboardStatsStream;
  late Stream<Map<String, int>> _categoryStatsStream;
  late Stream<Map<String, int>> _expirySummaryStream;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    // _dashboardFuture = _loadDashboardData();
    _expirySummaryStream = ExpiryNotificationService.getExpirySummaryStream();
    _dashboardStatsStream = InventoryService.getDashboardStatsStream();
    _monthlyDataStream = InventoryService.getMonthlyMovementTrendsStream();
    _categoryStatsStream = InventoryService.getCategoryStatsStream();
  }

  void _loadCurrentUser() {
    // Get current user from AuthService
    currentUser = AuthService.currentUser;

    // Listen to auth state changes
    AuthService.authStateChanges.listen((user) {
      if (mounted) {
        setState(() {
          currentUser = user;
        });
      }
    });
  }

  Future<void> _refreshDashboard() async {
    // Since we're using streams, we don't need to manually refresh
    // The streams will automatically update when data changes
    // This method is kept for the RefreshIndicator compatibility
    setState(() {
      // Force a rebuild to refresh streams if needed
    });
  }

  // Test Gmail connection
  Future<void> _testGmailConnection() async {
    try {
      final result = await NotificationService.testGmailConnection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            duration: const Duration(seconds: 5),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Send test notification
  Future<void> _sendTestNotification() async {
    try {
      final result = await NotificationService.testNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email: ${result['emailSent'] ? 'Sent' : 'Failed'}, '
                // 'SMS: ${result['smsSent'] ? 'Sent' : 'Failed'}'
                ),
            duration: const Duration(seconds: 5),
            backgroundColor: (result['emailSent'] || result['smsSent'])
                ? Colors.green
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test notification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeCard(),
              const SizedBox(height: 20),

              // Statistics Cards
              _buildStatisticsGrid(),
              const SizedBox(height: 20),

              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 20),

              // Test Email Section (temporary for testing)
              // _buildTestSection(),
              // const SizedBox(height: 20),

              // Expiry Notifications
              _buildExpiryNotifications(),
              const SizedBox(height: 20),

              // Recent Activity or Chart
              _buildActivitySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final greeting = _getGreeting();
    return WelcomeCard(
      greeting: greeting,
      userName: _getFirstName(currentUser?.displayName.split(',')[0] ?? 'User'),
      themeToggleButton: _buildThemeToggleButton(),
      profileAvatar: _buildUserAvatar(currentUser),
    );
  }

  Widget _buildDefaultAvatar() {
    final initials = _getInitials(currentUser?.displayName ?? 'User');
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(dynamic user) {
    if (user?.profilePhotoPath != null && user!.profilePhotoPath!.isNotEmpty) {
      // Handle base64 data URLs
      if (user.profilePhotoPath!.startsWith('data:image')) {
        try {
          final base64String = user.profilePhotoPath!.split(',')[1];
          final bytes = base64Decode(base64String);
          return CircleAvatar(
            backgroundColor: user.isActive
                ? (Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                    : Theme.of(context).primaryColor.withValues(alpha: 0.1))
                : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.1)),
            backgroundImage: MemoryImage(bytes),
            onBackgroundImageError: (exception, stackTrace) {},
          );
        } catch (e) {}
      } else {
        // Handle network URLs
        return CircleAvatar(
          backgroundColor: user.isActive
              ? (Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                  : Theme.of(context).primaryColor.withValues(alpha: 0.1))
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1)),
          backgroundImage: NetworkImage(user.profilePhotoPath!),
          onBackgroundImageError: (exception, stackTrace) {},
        );
      }
    }

    // Fallback to initials
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CircleAvatar(
      // Use the same soft white tint as the theme toggle for consistency
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      child: Text(
        user?.displayName.isNotEmpty == true
            ? user.displayName[0].toUpperCase()
            : 'U',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: user?.isActive == true
              ? (isDark ? Colors.white : Theme.of(context).primaryColor)
              : (isDark ? Colors.white70 : Colors.grey[700]),
        ),
      ),
    );
  }

  String _getFirstName(String name) {
    if (name.isEmpty) return 'User';

    final nameParts = name.split(' ');
    return nameParts[0];
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'U';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : 'U';
    }
    return '${words[0][0].toUpperCase()}${words[1][0].toUpperCase()}';
  }

  Widget _buildThemeToggleButton() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            onPressed: () {
              themeProvider.toggleTheme();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    themeProvider.isDarkMode
                        ? 'Switched to dark theme'
                        : 'Switched to light theme',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                key: ValueKey(themeProvider.isDarkMode),
                color: Colors.white,
                size: 20,
              ),
            ),
            tooltip: themeProvider.isDarkMode
                ? 'Switch to light theme'
                : 'Switch to dark theme',
          ),
        );
      },
    );
  }

  /// Responsive statistics grid.
  /// Ensures at least 2 columns on small screens (prevents vertical-only stacking).
  Widget _buildStatisticsGrid() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _dashboardStatsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No data available')),
          );
        }

        final dashboardStats = snapshot.data!;

        return LayoutBuilder(
          builder: (context, constraints) {
            // Minimum 2 columns on small devices, grow to 4 on wide screens
            int crossAxisCount;
            double childAspectRatio;

            if (constraints.maxWidth < 400) {
              crossAxisCount = 2;
              childAspectRatio = 1.2;
            } else if (constraints.maxWidth < 600) {
              crossAxisCount = 2;
              childAspectRatio = 1.3;
            } else if (constraints.maxWidth < 900) {
              crossAxisCount = 3;
              childAspectRatio = 1.4;
            } else {
              crossAxisCount = 4;
              childAspectRatio = 1.2;
            }

            // Single GridView with all four stat cards. This prevents odd double-grid layout and
            // ensures responsive columns across breakpoints.
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
              children: [
                _buildStatCard(
                  'Total Items',
                  _formatLargeNumber(dashboardStats['totalItems'].toDouble()),
                  Icons.inventory_2,
                  Colors.blue,
                  dashboardStats,
                ),
                _buildStatCard(
                  'Total Value',
                  // Format as currency with proper formatting
                  _formatCurrency(dashboardStats['totalValue']),
                  Icons.attach_money,
                  Colors.green,
                  dashboardStats,
                ),
                _buildStatCard(
                  'Low Stock',
                  _formatLargeNumber(
                      dashboardStats['lowStockItems'].toDouble()),
                  Icons.warning,
                  Colors.orange,
                  dashboardStats,
                ),
                _buildStatCard(
                  'Out of Stock',
                  _formatLargeNumber(
                      dashboardStats['outOfStockItems'].toDouble()),
                  Icons.error,
                  Colors.red,
                  dashboardStats,
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatCurrency(dynamic value) {
    // Handle null or non-numeric values
    if (value == null) return '\$0.00';

    // Convert to double if possible
    double numericValue;
    if (value is num) {
      numericValue = value.toDouble();
    } else {
      try {
        numericValue = double.parse(value.toString());
      } catch (_) {
        return '\$0.00';
      }
    }

    return _formatLargeNumber(numericValue, isCurrency: true);
  }

  String _formatLargeNumber(double value, {bool isCurrency = false}) {
    final prefix = isCurrency ? '\$' : '';

    if (value >= 1000000000) {
      // Billions
      final billions = value / 1000000000;
      if (billions >= 100) {
        return '$prefix${billions.toInt()}B+';
      } else if (billions >= 10) {
        return '$prefix${billions.toStringAsFixed(0)}B+';
      } else {
        return '$prefix${billions.toStringAsFixed(1)}B+';
      }
    } else if (value >= 1000000) {
      // Millions
      final millions = value / 1000000;
      if (millions >= 100) {
        return '$prefix${millions.toInt()}M+';
      } else if (millions >= 10) {
        return '$prefix${millions.toStringAsFixed(0)}M+';
      } else {
        return '$prefix${millions.toStringAsFixed(1)}M+';
      }
    } else if (value >= 1000) {
      // Thousands
      final thousands = value / 1000;
      if (thousands >= 100) {
        return '$prefix${thousands.toInt()}K+';
      } else if (thousands >= 10) {
        return '$prefix${thousands.toStringAsFixed(0)}K+';
      } else {
        return '$prefix${thousands.toStringAsFixed(1)}K+';
      }
    } else {
      // Less than 1000 - show full number
      if (isCurrency) {
        final formatter = NumberFormat.currency(
          symbol: '\$',
          decimalDigits: 2,
        );
        return formatter.format(value);
      } else {
        return value.toInt().toString();
      }
    }
  }

  String _getFullFormattedValue(dynamic value, {bool isCurrency = false}) {
    // Handle null or non-numeric values
    if (value == null) return isCurrency ? '\$0.00' : '0';

    // Convert to double if possible
    double numericValue;
    if (value is num) {
      numericValue = value.toDouble();
    } else {
      try {
        numericValue = double.parse(value.toString());
      } catch (_) {
        return isCurrency ? '\$0.00' : '0';
      }
    }

    if (isCurrency) {
      final formatter = NumberFormat.currency(
        symbol: '\$',
        decimalDigits: 2,
      );
      return formatter.format(numericValue);
    } else {
      final formatter = NumberFormat('#,###');
      return formatter.format(numericValue.toInt());
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Map<String, dynamic> dashboardStats,
  ) {
    final trendData = _generateTrendData(
        _getCurrentValueForChart(title, dashboardStats), 7, 0.8, 1.2);

    // Get the full formatted value for tooltip
    String fullValue = value;
    if (title == 'Total Value') {
      // Format as currency with proper formatting for tooltip
      final formatter = NumberFormat.currency(
        symbol: '\$',
        decimalDigits: 2,
      );
      fullValue = formatter.format(dashboardStats['totalValue']);
    } else if (title == 'Total Items') {
      // Show integer value only for Total Items tooltip
      fullValue = (dashboardStats['totalItems'] as int).toString();
    } else if (title == 'Low Stock') {
      fullValue = _getFullFormattedValue(dashboardStats['lowStockItems']);
    } else if (title == 'Out of Stock') {
      fullValue = _getFullFormattedValue(dashboardStats['outOfStockItems']);
    }

    // Make tooltip more responsive - shorter on small screens
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final tooltipMessage = isSmallScreen ? fullValue : '$title: $fullValue';

    return Tooltip(
      message: tooltipMessage,
      child: StatCard(
        title: title,
        value: value,
        icon: icon,
        color: color,
        trendData: trendData,
      ),
    );
  }

  double _getCurrentValueForChart(
      String title, Map<String, dynamic> dashboardStats) {
    switch (title) {
      case 'Total Items':
        return (dashboardStats['totalItems'] ?? 0).toDouble();
      case 'Total Value':
        return (dashboardStats['totalValue'] ?? 0).toDouble();
      case 'Low Stock':
        return (dashboardStats['lowStockItems'] ?? 0).toDouble();
      case 'Out of Stock':
        return (dashboardStats['outOfStockItems'] ?? 0).toDouble();
      default:
        return 0;
    }
  }

  List<double> _generateTrendData(
    double currentValue,
    int points,
    double minFactor,
    double maxFactor,
  ) {
    if (currentValue == 0) {
      return List.filled(points, 0);
    }

    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    final trend = <double>[];

    for (int i = 0; i < points; i++) {
      final factor =
          minFactor + (maxFactor - minFactor) * ((i + random) % 100) / 100.0;
      final value = currentValue * factor;
      trend.add(value);
    }

    // Ensure the last value matches current value
    trend[points - 1] = currentValue;

    return trend;
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        // // Debug button to add test perishable items
        // if (currentUser?.isAdmin == true) ...[
        //   Card(
        //     elevation: 2,
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(12),
        //     ),
        //     child: InkWell(
        //       onTap: _addTestPerishableItems,
        //       borderRadius: BorderRadius.circular(12),
        //       child: Padding(
        //         padding: const EdgeInsets.all(12),
        //         child: Row(
        //           children: [
        //             Container(
        //               padding: const EdgeInsets.all(8),
        //               decoration: BoxDecoration(
        //                 color: Colors.orange.withValues(alpha: 0.1),
        //                 borderRadius: BorderRadius.circular(8),
        //               ),
        //               child: const Icon(
        //                 Icons.add_circle,
        //                 color: Colors.orange,
        //                 size: 20,
        //               ),
        //             ),
        //             const SizedBox(width: 12),
        //             Expanded(
        //               child: Text(
        //                 'Add Test Perishable Items (Debug)',
        //                 style: GoogleFonts.poppins(
        //                   fontSize: 14,
        //                   fontWeight: FontWeight.w500,
        //                   color: Theme.of(context).brightness == Brightness.dark
        //                       ? Colors.white70
        //                       : Colors.grey[700],
        //                 ),
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ),
        //   ),
        // const SizedBox(height: 12),
        // ],
        LayoutBuilder(
          builder: (context, constraints) {
            // Create list of all quick actions
            List<Widget> quickActions = [];

            // Always include basic actions
            quickActions.addAll([
              _buildQuickActionButton(
                'View Inventory',
                Icons.inventory_2,
                Colors.blue,
                () => widget.onTabSelected(1),
              ),
              _buildQuickActionButton(
                'Stock Movements',
                Icons.history,
                Colors.orange,
                () => widget.onTabSelected(2),
              ),
            ]);

            // Add admin-only actions
            if (currentUser?.isAdmin == true) {
              quickActions.insertAll(0, [
                _buildQuickActionButton(
                  'Add Item',
                  Icons.add_box,
                  Colors.green,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const InventoryFormScreen(
                          isEditing: false,
                          item: null,
                        ),
                      ),
                    );
                  },
                ),
              ]);

              quickActions.add(
                _buildQuickActionButton(
                  'Scan QR/Bar Code',
                  Icons.qr_code_scanner,
                  Colors.purple,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const QRScannerScreen(),
                      ),
                    );
                  },
                ),
              );
            }

            // Determine layout based on screen size
            if (constraints.maxWidth < 400) {
              // Small screens: 2 cards per row
              return _buildResponsiveGrid(quickActions, 2);
            } else if (constraints.maxWidth < 600) {
              // Medium screens: 2-3 cards per row depending on admin status
              return _buildResponsiveGrid(quickActions,
                  quickActions.length > 3 ? 2 : quickActions.length);
            } else {
              // Large screens: All cards in one row if possible, otherwise wrap
              return _buildResponsiveGrid(quickActions,
                  quickActions.length > 4 ? 3 : quickActions.length);
            }
          },
        ),
      ],
    );
  }

  Widget _buildResponsiveGrid(List<Widget> actions, int crossAxisCount) {
    // Make cards rectangular (taller than wide) for better appearance
    double childAspectRatio;
    if (crossAxisCount >= 3) {
      childAspectRatio = 1.4; // Large screens - taller rectangles
    } else {
      childAspectRatio = 1.2; // Small/medium screens - taller rectangles
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) => actions[index],
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return QuickActionButton(
      title: title,
      icon: icon,
      color: color,
      onTap: onTap,
    );
  }

  // Widget _buildTestSection() {
  //   // Only show test section for admin users
  //   if (currentUser?.isAdmin != true) return const SizedBox.shrink();

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'Email Testing (Admin Only)',
  //         style: GoogleFonts.poppins(
  //           fontSize: 18,
  //           fontWeight: FontWeight.w600,
  //           color: Theme.of(context).brightness == Brightness.dark
  //               ? Colors.white
  //               : Colors.grey[800],
  //         ),
  //       ),
  //       const SizedBox(height: 12),
  //       Row(
  //         children: [
  //           Expanded(
  //             child: ElevatedButton.icon(
  //               onPressed: _testGmailConnection,
  //               icon: const Icon(Icons.email),
  //               label: const Text('Test Gmail Connection'),
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.blue,
  //                 foregroundColor: Colors.white,
  //                 padding: const EdgeInsets.symmetric(vertical: 12),
  //               ),
  //             ),
  //           ),
  //           const SizedBox(width: 12),
  //           Expanded(
  //             child: ElevatedButton.icon(
  //               onPressed: _sendTestNotification,
  //               icon: const Icon(Icons.send),
  //               label: const Text('Send Test Email'),
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.green,
  //                 foregroundColor: Colors.white,
  //                 padding: const EdgeInsets.symmetric(vertical: 12),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Widget _buildExpiryNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Expiry Alerts',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.grey[800],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // Navigate to full expiry list
                _navigateToExpiryAlertsScreen();
              },
              icon: const Icon(Icons.visibility, size: 16),
              label: Text(
                'View All',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<Map<String, int>>(
          stream: _expirySummaryStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Error loading expiry data',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white60
                            : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }

            final expirySummary = snapshot.data ?? {};
            final expired = expirySummary['expired'] ?? 0;
            final expiringSoon = expirySummary['expiringSoon'] ?? 0;
            final expiringWithin6Months =
                expirySummary['expiringWithin6Months'] ?? 0;
            final immediateAttention = expirySummary['immediateAttention'] ?? 0;

            if (expired == 0 &&
                expiringSoon == 0 &&
                expiringWithin6Months == 0 &&
                immediateAttention == 0) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Good!',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'No items are expiring soon',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white60
                                    : Colors.grey[600],
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

            return Column(
              children: [
                if (immediateAttention > 0)
                  _buildExpiryAlertCard(
                    'Needs Immediate Attention',
                    immediateAttention,
                    'Food items & urgent expiries (≤6 months)',
                    Icons.priority_high,
                    Colors.deepOrange,
                    ExpiryPriority.medium,
                  ),
                if (immediateAttention > 0 && expired > 0)
                  const SizedBox(height: 12),
                if (expired > 0)
                  _buildExpiryAlertCard(
                    'Expired Items',
                    expired,
                    'Items have already expired',
                    Icons.error,
                    Colors.red,
                    ExpiryPriority.expired,
                  ),
                if ((immediateAttention > 0 || expired > 0) && expiringSoon > 0)
                  const SizedBox(height: 12),
                if (expiringSoon > 0)
                  _buildExpiryAlertCard(
                    'Expiring Soon',
                    expiringSoon,
                    'Items expire within 30 days',
                    Icons.warning,
                    Colors.orange,
                    ExpiryPriority.high,
                  ),
                if ((immediateAttention > 0 ||
                        expired > 0 ||
                        expiringSoon > 0) &&
                    expiringWithin6Months > 0)
                  const SizedBox(height: 12),
                if (expiringWithin6Months > 0)
                  _buildExpiryAlertCard(
                    'Expiring Within 6 Months',
                    expiringWithin6Months,
                    'Items expire within 6 months',
                    Icons.schedule,
                    Colors.blue,
                    ExpiryPriority.low,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildExpiryAlertCard(
    String title,
    int count,
    String subtitle,
    IconData icon,
    Color color,
    ExpiryPriority priority,
  ) {
    return ExpiryAlertCard(
      title: title,
      count: count,
      subtitle: subtitle,
      icon: icon,
      color: color,
      onTap: () => _showExpiryItemsDialog(priority),
    );
  }

  void _navigateToExpiryAlertsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ExpiryAlertsScreen(),
      ),
    );
  }

  // Future<void> _addTestPerishableItems() async {
  //   try {
  //     final now = DateTime.now();

  //     // Create test items with different expiry scenarios
  //     final testItems = [
  //       InventoryItem(
  //         id: '',
  //         name: 'Milk',
  //         description: 'Fresh dairy milk',
  //         category: 'Food & Beverages',
  //         quantity: 10,
  //         unitPrice: 2.50,
  //         supplier: 'Local Dairy',
  //         createdAt: now,
  //         updatedAt: now,
  //         reorderLevel: 5,
  //         isPerishable: true,
  //         expiryDate: now.add(const Duration(days: 5)), // Expires in 5 days
  //       ),
  //       InventoryItem(
  //         id: '',
  //         name: 'Bread',
  //         description: 'Whole grain bread',
  //         category: 'Food & Beverages',
  //         quantity: 15,
  //         unitPrice: 3.00,
  //         supplier: 'Bakery Co',
  //         createdAt: now,
  //         updatedAt: now,
  //         reorderLevel: 8,
  //         isPerishable: true,
  //         expiryDate: now.subtract(const Duration(days: 2)), // Already expired
  //       ),
  //       InventoryItem(
  //         id: '',
  //         name: 'Cheese',
  //         description: 'Aged cheddar cheese',
  //         category: 'Food & Beverages',
  //         quantity: 8,
  //         unitPrice: 8.50,
  //         supplier: 'Cheese Factory',
  //         createdAt: now,
  //         updatedAt: now,
  //         reorderLevel: 3,
  //         isPerishable: true,
  //         expiryDate: now.add(const Duration(days: 25)), // Expires in 25 days
  //       ),
  //       InventoryItem(
  //         id: '',
  //         name: 'Yogurt',
  //         description: 'Greek yogurt',
  //         category: 'Food & Beverages',
  //         quantity: 12,
  //         unitPrice: 1.75,
  //         supplier: 'Dairy Farms',
  //         createdAt: now,
  //         updatedAt: now,
  //         reorderLevel: 6,
  //         isPerishable: true,
  //         expiryDate: now.add(const Duration(days: 90)), // Expires in 90 days
  //       ),
  //     ];

  //     for (final item in testItems) {
  //       await InventoryService.addInventoryItem(item);
  //     }

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Added 4 test perishable items for expiry testing'),
  //           backgroundColor: Colors.green,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error adding test items: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  void _showExpiryItemsDialog(ExpiryPriority priority) {
    String title;
    Future<List<InventoryItem>> future;

    final mediaQuery = MediaQuery.of(context);
    final clampedTextScaler =
        mediaQuery.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2);
    final dialogMaxHeight = mediaQuery.size.height * 0.7;
    final dialogMaxWidth = mediaQuery.size.width * 0.95;

    switch (priority) {
      case ExpiryPriority.expired:
        title = 'Expired Items';
        future = ExpiryNotificationService.getExpiredItems();
        break;
      case ExpiryPriority.high:
        title = 'Items Expiring Soon';
        future = ExpiryNotificationService.getItemsExpiringSoon();
        break;
      case ExpiryPriority.medium:
        title = 'Needs Immediate Attention';
        future = ExpiryNotificationService.getItemsNeedingImmediateAttention();
        break;
      case ExpiryPriority.low:
        title = 'Items Expiring Within 6 Months';
        future = ExpiryNotificationService.getItemsExpiringWithin6Months();
        break;
      default:
        title = 'Expiring Items';
        future = ExpiryNotificationService.getItemsExpiringSoon();
    }

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedTextScaler),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogMaxWidth,
                maxHeight: dialogMaxHeight,
                minHeight: 200,
              ),
              child: FutureBuilder<List<InventoryItem>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading items',
                        style: GoogleFonts.poppins(
                          color:
                              isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    );
                  }

                  final items = snapshot.data ?? [];

                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'No items found',
                        style: GoogleFonts.poppins(
                          color:
                              isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    );
                  }

                  return Scrollbar(
                    radius: const Radius.circular(12),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final daysUntilExpiry = item.daysUntilExpiry ?? 0;
                        final statusColor = _getExpiryColor(daysUntilExpiry);
                        final statusText = CustomDateUtils.DateUtils
                            .formatExpiryStatus(daysUntilExpiry);

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getExpiryIcon(daysUntilExpiry),
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.grey.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.expiryDate != null
                                        ? 'Expires: ${DateFormat('MMM dd, yyyy').format(item.expiryDate!)}'
                                        : 'No expiry date',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: dialogMaxWidth * 0.35,
                              ),
                              child: Text(
                                statusText,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getExpiryColor(int daysUntilExpiry) {
    if (daysUntilExpiry < 0) {
      return Colors.red;
    } else if (daysUntilExpiry <= 7) {
      return Colors.red;
    } else if (daysUntilExpiry <= 30) {
      return Colors.orange;
    } else if (daysUntilExpiry <= 90) {
      return Colors.yellow[700]!;
    } else {
      return Colors.blue;
    }
  }

  IconData _getExpiryIcon(int daysUntilExpiry) {
    if (daysUntilExpiry < 0) {
      return Icons.error;
    } else if (daysUntilExpiry <= 7) {
      return Icons.warning;
    } else if (daysUntilExpiry <= 30) {
      return Icons.warning_amber;
    } else {
      return Icons.schedule;
    }
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stock Overview Pie Chart
        Text(
          'Stock Overview',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // For small screens, stack chart and legend vertically
                if (constraints.maxWidth < 500) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 300,
                        child: Stack(
                          children: [
                            _buildStockChart(),
                            if (_touchedStockIndex >= 0)
                              _buildStockTooltip(_touchedStockIndex),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildChartLegend(),
                    ],
                  );
                } else {
                  // For larger screens, keep side-by-side layout
                  return SizedBox(
                    width: double.infinity,
                    height: 350,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Stack(
                            children: [
                              _buildStockChart(),
                              if (_touchedStockIndex >= 0)
                                _buildStockTooltip(_touchedStockIndex),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(flex: 1, child: _buildChartLegend()),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Monthly Trends Bar Chart
        Text(
          'Monthly Trends',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 200,
              child: _buildMonthlyTrendsChart(),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Items by Category Chart
        Text(
          'Items by Category',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // For small screens, stack chart and legend vertically
                if (constraints.maxWidth < 500) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 300,
                        child: Stack(
                          children: [
                            _buildCategoryPieChart(),
                            // if (_touchedCategoryIndex >= 0)
                            //   _buildCategoryTooltip(_touchedCategoryIndex),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryLegendGrid(),
                    ],
                  );
                } else {
                  // For larger screens, keep side-by-side layout
                  return SizedBox(
                    width: double.infinity,
                    height: 350,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Stack(
                            children: [
                              _buildCategoryPieChart(),
                              // if (_touchedCategoryIndex >= 0)
                              //   _buildCategoryTooltip(_touchedCategoryIndex),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(flex: 1, child: _buildCategoryLegendGrid()),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockChart() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _dashboardStatsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('No data'));
        }

        final dashboardStats = snapshot.data!;
        final totalItems = dashboardStats['totalItems'] as int;
        final lowStockItems = dashboardStats['lowStockItems'] as int;
        final outOfStockItems = dashboardStats['outOfStockItems'] as int;
        final normalStock =
            (totalItems - lowStockItems - outOfStockItems).clamp(
          0,
          totalItems,
        );

        if (totalItems == 0) {
          return const Center(child: Text('No inventory items'));
        }

        return PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              enabled: true,
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedStockIndex = -1;
                    return;
                  }
                  _touchedStockIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            sections: [
              PieChartSectionData(
                color: Colors.green,
                value: normalStock.toDouble(),
                title: _touchedStockIndex == 0
                    ? '$normalStock items\n(${((normalStock / totalItems) * 100).toInt()}%)'
                    : '${((normalStock / totalItems) * 100).toInt()}%',
                titleStyle: TextStyle(
                  fontSize: _touchedStockIndex == 0 ? 10 : 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                radius: _touchedStockIndex == 0 ? 90 : 80,
                showTitle: normalStock > 0,
              ),
              PieChartSectionData(
                color: Colors.orange,
                value: lowStockItems.toDouble(),
                title: _touchedStockIndex == 1
                    ? '$lowStockItems items\n(${((lowStockItems / totalItems) * 100).toInt()}%)'
                    : '${((lowStockItems / totalItems) * 100).toInt()}%',
                titleStyle: TextStyle(
                  fontSize: _touchedStockIndex == 1 ? 10 : 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                radius: _touchedStockIndex == 1 ? 90 : 80,
                showTitle: lowStockItems > 0,
              ),
              PieChartSectionData(
                color: Colors.red,
                value: outOfStockItems.toDouble(),
                title: _touchedStockIndex == 2
                    ? '$outOfStockItems items\n(${((outOfStockItems / totalItems) * 100).toInt()}%)'
                    : '${((outOfStockItems / totalItems) * 100).toInt()}%',
                titleStyle: TextStyle(
                  fontSize: _touchedStockIndex == 2 ? 10 : 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                radius: _touchedStockIndex == 2 ? 90 : 80,
                showTitle: outOfStockItems > 0,
              ),
            ],
            centerSpaceRadius: 40,
            sectionsSpace: 2,
          ),
        );
      },
    );
  }

  // }

  Widget _buildChartLegend() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _dashboardStatsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError ||
            !snapshot.hasData) {
          return const SizedBox();
        }

        final dashboardStats = snapshot.data!;
        final totalItems = dashboardStats['totalItems'] as int;
        final lowStockItems = dashboardStats['lowStockItems'] as int;
        final outOfStockItems = dashboardStats['outOfStockItems'] as int;
        final normalStock =
            (totalItems - lowStockItems - outOfStockItems).clamp(
          0,
          totalItems,
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendItem('Normal Stock', normalStock, Colors.green),
            const SizedBox(height: 8),
            _buildLegendItem('Low Stock', lowStockItems, Colors.orange),
            const SizedBox(height: 8),
            _buildLegendItem('Out of Stock', outOfStockItems, Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey[700],
                ),
              ),
              Text(
                value.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockTooltip(int index) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _dashboardStatsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError ||
            !snapshot.hasData) {
          return const SizedBox();
        }

        final dashboardStats = snapshot.data!;
        final totalItems = dashboardStats['totalItems'] as int;
        final lowStockItems = dashboardStats['lowStockItems'] as int;
        final outOfStockItems = dashboardStats['outOfStockItems'] as int;
        final normalStock =
            (totalItems - lowStockItems - outOfStockItems).clamp(0, totalItems);

        String tooltipText;
        switch (index) {
          case 0:
            final percentage =
                ((normalStock / totalItems) * 100).toStringAsFixed(1);
            tooltipText =
                'Normal Stock\n$normalStock items ($percentage%)\nItems with adequate stock levels';
            break;
          case 1:
            final percentage =
                ((lowStockItems / totalItems) * 100).toStringAsFixed(1);
            tooltipText =
                'Low Stock\n$lowStockItems items ($percentage%)\nItems requiring restocking soon';
            break;
          case 2:
            final percentage =
                ((outOfStockItems / totalItems) * 100).toStringAsFixed(1);
            tooltipText =
                'Out of Stock\n$outOfStockItems items ($percentage%)\nItems that need immediate attention';
            break;
          default:
            return const SizedBox();
        }

        return Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]!.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              tooltipText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyTrendsChart() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _monthlyDataStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading trends',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60
                    : Colors.grey[600],
              ),
            ),
          );
        }

        final monthlyData = snapshot.data ?? [];

        if (monthlyData.isEmpty) {
          return Center(
            child: Text(
              'No movement data available',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60
                    : Colors.grey[600],
              ),
            ),
          );
        }

        // Calculate max value for chart scaling
        final maxValue = monthlyData.isEmpty
            ? 35.0
            : monthlyData
                .map((data) => (data['value'] as int).toDouble())
                .reduce((a, b) => a > b ? a : b);
        final chartMaxY = (maxValue * 1.2).ceilToDouble();

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: chartMaxY > 0 ? chartMaxY : 35,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) =>
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]!
                        : Colors.white,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  if (groupIndex < monthlyData.length) {
                    final data = monthlyData[groupIndex];
                    final month = data['month'] as String;
                    final value = data['value'] as int;
                    final stockIn = data['stockIn'] as int;
                    final stockOut = data['stockOut'] as int;

                    return BarTooltipItem(
                      '$month\n'
                      'Total: ${_getFullFormattedValue(value)}\n'
                      'Stock In: ${_getFullFormattedValue(stockIn)}\n'
                      'Stock Out: ${_getFullFormattedValue(stockOut)}',
                      GoogleFonts.poppins(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, _) {
                    if (value.toInt() < monthlyData.length) {
                      final isRotated = monthlyData.length > 6;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: RotatedBox(
                          quarterTurns: isRotated ? 1 : 0,
                          child: Text(
                            monthlyData[value.toInt()]['month'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                            textAlign:
                                isRotated ? TextAlign.right : TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval:
                      chartMaxY > 100 ? (chartMaxY / 5).ceilToDouble() : null,
                  getTitlesWidget: (double value, _) {
                    return Text(
                      value >= 1000
                          ? '${(value / 1000).toStringAsFixed(1)}k'
                          : value.toInt().toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.grey[600],
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: monthlyData.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: (entry.value['value'] as int).toDouble(),
                    // color: Theme.of(context).brightness == Brightness.dark
                    //     ? Colors.green[400]!
                    //     : Theme.of(context).primaryColor,
                    color: Colors.green,
                    width: monthlyData.length > 8 ? 15 : 20,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCategoryPieChart() {
    return StreamBuilder<Map<String, int>>(
      stream: _categoryStatsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No category data available'));
        }

        final categoryStats = snapshot.data!;
        final colors = [
          Colors.blue,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.red,
          Colors.teal,
          Colors.indigo,
          Colors.pink,
        ];

        final totalItems =
            categoryStats.values.fold<int>(0, (sum, count) => sum + count);

        int colorIndex = 0;

        return PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              enabled: true,
              touchCallback: (event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedCategoryIndex = -1;
                    return;
                  }
                  _touchedCategoryIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            centerSpaceRadius: 40,
            sections: categoryStats.entries.map((entry) {
              final index = categoryStats.keys.toList().indexOf(entry.key);
              final isTouched = _touchedCategoryIndex == index;
              final color = colors[colorIndex % colors.length];
              colorIndex++;
              final percentage = ((entry.value / totalItems) * 100).toInt();

              return PieChartSectionData(
                color: color,
                value: entry.value.toDouble(),
                title: isTouched
                    ? '${entry.key}\n${entry.value} items\n$percentage%'
                    : (percentage > 5 ? '$percentage%' : ''),
                titleStyle: TextStyle(
                  fontSize: isTouched ? 10 : 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                radius: isTouched ? 90 : 80,
                showTitle: entry.value > 0,
              );
            }).toList(),
            sectionsSpace: 2,
          ),
        );
      },
    );
  }

  Widget _buildCategoryLegendGrid() {
    return StreamBuilder<Map<String, int>>(
      stream: _categoryStatsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        final categoryStats = snapshot.data!;
        final colors = [
          Colors.blue,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.red,
          Colors.teal,
          Colors.indigo,
          Colors.pink,
        ];

        final sortedEntries = categoryStats.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sortedEntries.asMap().entries.map((mapEntry) {
              final entry = mapEntry.value;
              final originalIndex =
                  categoryStats.keys.toList().indexOf(entry.key);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[originalIndex % colors.length],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.key,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            '${entry.value}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCategoryLegendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatLargeNumber(value.toDouble()),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Color> _generateCategoryColors(int count) {
    final baseColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
      Colors.deepOrange,
    ];

    if (count <= baseColors.length) {
      return baseColors.take(count).toList();
    }

    // Generate additional colors if needed
    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      if (i < baseColors.length) {
        colors.add(baseColors[i]);
      } else {
        // Generate variations of base colors
        final baseColor = baseColors[i % baseColors.length];
        final hsl = HSLColor.fromColor(baseColor);
        final variation = hsl
            .withLightness((hsl.lightness + (i / count * 0.3)).clamp(0.3, 0.8));
        colors.add(variation.toColor());
      }
    }
    return colors;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  // Widget _buildCategoryTooltip(int index) {
  //   return FutureBuilder<Map<String, int>>(
  //     future: InventoryService.getCategoryStats(),
  //     builder: (context, snapshot) {
  //       if (!snapshot.hasData || snapshot.data == null) return const SizedBox();

  //       final categoryData = snapshot.data!;
  //       if (index < 0 || index >= categoryData.length) return const SizedBox();

  //       final entries = categoryData.entries.toList();
  //       final entry = entries[index];
  //       final totalItems =
  //           categoryData.values.fold<int>(0, (sum, count) => sum + count);
  //       final percentage =
  //           ((entry.value / totalItems) * 100).toStringAsFixed(1);

  //       final tooltipText =
  //           '${entry.key}\n${entry.value} items ($percentage%)\nCategory distribution breakdown';

  //       return Positioned(
  //         top: 20,
  //         right: 20,
  //         child: Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: Theme.of(context).brightness == Brightness.dark
  //                 ? Colors.grey[800]!.withValues(alpha: 0.9)
  //                 : Colors.white.withValues(alpha: 0.9),
  //             borderRadius: BorderRadius.circular(8),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withValues(alpha: 0.2),
  //                 blurRadius: 8,
  //                 offset: const Offset(0, 4),
  //               ),
  //             ],
  //           ),
  //           child: Text(
  //             tooltipText,
  //             style: GoogleFonts.poppins(
  //               fontSize: 12,
  //               fontWeight: FontWeight.w500,
  //               color: Theme.of(context).brightness == Brightness.dark
  //                   ? Colors.white
  //                   : Colors.grey[800],
  //             ),
  //             textAlign: TextAlign.center,
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
}
