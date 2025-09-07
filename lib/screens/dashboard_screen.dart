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
  Map<String, dynamic>? dashboardStats;
  Map<String, int>? _categoryStats;
  bool _isLoadingCategory = true;
  bool isLoading = true;
  AppUser? currentUser;
  int _touchedStockIndex = -1;
  int _touchedCategoryIndex = -1;

  // late Future<void> _dashboardFuture;
  late Future<List<Map<String, dynamic>>> _monthlyDataFuture;
  late Future<Map<String, dynamic>> _dashboardStatsFuture;
  late Future<Map<String, dynamic>> _categoryStatsFuture;
  late Future<Map<String, int>> _expirySummaryFuture;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadDashboardData();
    _loadCategoryStats();
    // _dashboardFuture = _loadDashboardData();
    _expirySummaryFuture = ExpiryNotificationService.getExpirySummary();
    _dashboardStatsFuture = InventoryService.getDashboardStats();
    _monthlyDataFuture = InventoryService.getMonthlyMovementTrends();
    _categoryStatsFuture = InventoryService.getCategoryStats();
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

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Only load real data from Firebase
      final stats = await InventoryService.getDashboardStats();

      if (mounted) {
        setState(() {
          dashboardStats = stats;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load dashboard data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      isLoading = true;
    });
    // Re-run the same logic used in init to refresh the screen safely.
    await _loadDashboardData();
  }

  Future<void> _loadCategoryStats() async {
    final stats = await InventoryService.getCategoryStats();
    setState(() {
      _categoryStats = stats;
      _isLoadingCategory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey[50],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
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
        color: Colors.white.withOpacity(0.2),
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
            onBackgroundImageError: (exception, stackTrace) {
              debugPrint('Error loading user profile image: $exception');
            },
          );
        } catch (e) {
          debugPrint('Error decoding base64 profile image: $e');
        }
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
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('Error loading network profile image: $exception');
          },
        );
      }
    }

    // Fallback to initials
    return CircleAvatar(
      backgroundColor: user?.isActive == true
          ? (Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Theme.of(context).primaryColor.withValues(alpha: 0.1))
          : (Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1)),
      child: Text(
        user?.displayName.isNotEmpty == true
            ? user.displayName[0].toUpperCase()
            : 'U',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: user?.isActive == true
              ? (Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColor)
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600]),
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
    if (dashboardStats == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

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
              _formatLargeNumber(dashboardStats!['totalItems'].toDouble()),
              Icons.inventory_2,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Value',
              // Format as currency with proper formatting
              _formatCurrency(dashboardStats!['totalValue']),
              Icons.attach_money,
              Colors.green,
            ),
            _buildStatCard(
              'Low Stock',
              _formatLargeNumber(dashboardStats!['lowStockItems'].toDouble()),
              Icons.warning,
              Colors.orange,
            ),
            _buildStatCard(
              'Out of Stock',
              _formatLargeNumber(dashboardStats!['outOfStockItems'].toDouble()),
              Icons.error,
              Colors.red,
            ),
          ],
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
  ) {
    final trendData =
        _generateTrendData(_getCurrentValueForChart(title), 7, 0.8, 1.2);

    // Get the full formatted value for tooltip
    String fullValue = value;
    if (title == 'Total Value') {
      // Format as currency with proper formatting for tooltip
      final formatter = NumberFormat.currency(
        symbol: '\$',
        decimalDigits: 2,
      );
      fullValue = formatter.format(dashboardStats!['totalValue']);
    } else if (title == 'Total Items') {
      // Show integer value only for Total Items tooltip
      fullValue = (dashboardStats!['totalItems'] as int).toString();
    } else if (title == 'Low Stock') {
      fullValue = _getFullFormattedValue(dashboardStats!['lowStockItems']);
    } else if (title == 'Out of Stock') {
      fullValue = _getFullFormattedValue(dashboardStats!['outOfStockItems']);
    }

    return Tooltip(
      message: '$title: $fullValue',
      child: StatCard(
        title: title,
        value: value,
        icon: icon,
        color: color,
        trendData: trendData,
      ),
    );
  }

  Widget _buildMiniChart(String title, Color color) {
    // Generate trend data based on current stats to show realistic progression
    List<double> trendData;
    final currentValue = _getCurrentValueForChart(title);

    // Create a realistic trend leading to current value
    switch (title) {
      case 'Total Items':
        trendData = _generateTrendData(currentValue, 7, 0.8, 1.2);
        break;
      case 'Total Value':
        trendData = _generateTrendData(currentValue, 7, 0.7, 1.3);
        break;
      case 'Low Stock':
        trendData = _generateTrendData(currentValue, 7, 0.5, 2.0);
        break;
      case 'Out of Stock':
        trendData = _generateTrendData(currentValue, 7, 0.0, 3.0);
        break;
      default:
        trendData = _generateTrendData(currentValue, 7, 0.8, 1.2);
    }

    if (trendData.isEmpty || trendData.every((element) => element == 0)) {
      return Container(
        height: 30,
        alignment: Alignment.center,
        child: Text(
          'No trend data',
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
        ),
      );
    }

    return SizedBox(
      height: 30,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: trendData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value);
              }).toList(),
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.1),
              ),
            ),
          ],
          minY: trendData.reduce((a, b) => a < b ? a : b) * 0.8,
          maxY: trendData.reduce((a, b) => a > b ? a : b) * 1.2,
        ),
      ),
    );
  }

  double _getCurrentValueForChart(String title) {
    if (dashboardStats == null) return 0;

    switch (title) {
      case 'Total Items':
        return (dashboardStats!['totalItems'] ?? 0).toDouble();
      case 'Total Value':
        return (dashboardStats!['totalValue'] ?? 0).toDouble();
      case 'Low Stock':
        return (dashboardStats!['lowStockItems'] ?? 0).toDouble();
      case 'Out of Stock':
        return (dashboardStats!['outOfStockItems'] ?? 0).toDouble();
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio:
            1.1, // Slightly taller than square for better text fit
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
        FutureBuilder<Map<String, int>>(
          future: _expirySummaryFuture,
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
                        color: Colors.grey[600],
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
                          color: Colors.green.withOpacity(0.1),
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
                                color: Colors.grey[600],
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

  void _showExpiryItemsDialog(ExpiryPriority priority) {
    String title;
    Future<List<InventoryItem>> future;

    switch (priority) {
      case ExpiryPriority.expired:
        title = 'Expired Items';
        future = ExpiryNotificationService.getExpiredItems();
        break;
      case ExpiryPriority.high:
        title = 'Items Expiring Soon';
        future = ExpiryNotificationService.getItemsExpiringSoon();
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
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
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
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                );
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No items found',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                );
              }

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final daysUntilExpiry = item.daysUntilExpiry ?? 0;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getExpiryColor(daysUntilExpiry)
                          .withValues(alpha: 0.1),
                      child: Icon(
                        _getExpiryIcon(daysUntilExpiry),
                        color: _getExpiryColor(daysUntilExpiry),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      item.expiryDate != null
                          ? 'Expires: ${DateFormat('MMM dd, yyyy').format(item.expiryDate!)}'
                          : 'No expiry date',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    trailing: Text(
                      daysUntilExpiry < 0
                          ? '${daysUntilExpiry.abs()} days ago'
                          : '$daysUntilExpiry days',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _getExpiryColor(daysUntilExpiry),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
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
                        height: 200,
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
                    height: 250,
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
    if (dashboardStats == null) return const Center(child: Text('No data'));

    final totalItems = dashboardStats!['totalItems'] as int;
    final lowStockItems = dashboardStats!['lowStockItems'] as int;
    final outOfStockItems = dashboardStats!['outOfStockItems'] as int;
    final normalStock = (totalItems - lowStockItems - outOfStockItems).clamp(
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
  }

  // Widget _buildStockChart() {
  //   return FutureBuilder<Map<String, dynamic>>(
  //     future: _dashboardStatsFuture,
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return const Center(child: CircularProgressIndicator());
  //       }

  //       if (snapshot.hasError || !snapshot.hasData) {
  //         return const Center(child: Text('No data available'));
  //       }

  //       final dashboardStats = snapshot.data!;
  //       final totalItems = dashboardStats['totalItems'] ?? 0;
  //       final lowStock = dashboardStats['lowStockItems'] ?? 0;
  //       final outOfStock = dashboardStats['outOfStockItems'] ?? 0;
  //       final normalStock =
  //           (totalItems - lowStock - outOfStock).clamp(0, totalItems);

  //       if (totalItems == 0) {
  //         return const Center(child: Text('No inventory items'));
  //       }

  //       // Keep your existing PieChart implementation here exactly
  //       return PieChart(
  //         PieChartData(
  //           pieTouchData: PieTouchData(
  //             enabled: true,
  //             touchCallback: (event, response) {
  //               setState(() {
  //                 _touchedCategoryIndex =
  //                     response?.touchedSection?.touchedSectionIndex ?? -1;
  //               });
  //             },
  //           ),
  //           sections: [
  //             // your existing sections code...
  //           ],
  //           centerSpaceRadius: 40,
  //           sectionsSpace: 2,
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildChartLegend() {
    if (dashboardStats == null) return const SizedBox();

    final totalItems = dashboardStats!['totalItems'] as int;
    final lowStockItems = dashboardStats!['lowStockItems'] as int;
    final outOfStockItems = dashboardStats!['outOfStockItems'] as int;
    final normalStock = (totalItems - lowStockItems - outOfStockItems).clamp(
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
    if (dashboardStats == null) return const SizedBox();

    final totalItems = dashboardStats!['totalItems'] as int;
    final lowStockItems = dashboardStats!['lowStockItems'] as int;
    final outOfStockItems = dashboardStats!['outOfStockItems'] as int;
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
  }

  Widget _buildMonthlyTrendsChart() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _monthlyDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading trends',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          );
        }

        final monthlyData = snapshot.data ?? [];

        if (monthlyData.isEmpty) {
          return Center(
            child: Text(
              'No movement data available',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green[400]!
                        : Theme.of(context).primaryColor,
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

  String _getCategoryTooltipText(
      int index, Map<String, int> categoryStats, int totalItems) {
    if (index < 0 || index >= categoryStats.length) return '';

    final entries = categoryStats.entries.toList();
    final entry = entries[index];
    final percentage = ((entry.value / totalItems) * 100).toStringAsFixed(1);

    return '${entry.key}\n${entry.value} items ($percentage%)\nCategory distribution breakdown';
  }

  // Widget _buildCategoryChart() {
  //   if (_isLoadingCategory) {
  //     return const Center(child: CircularProgressIndicator());
  //   }

  //   if (_categoryStats == null || _categoryStats!.isEmpty) {
  //     return const Center(child: Text('No category data available'));
  //   }

  //   final colors = [
  //     Colors.blue,
  //     Colors.green,
  //     Colors.orange,
  //     Colors.purple,
  //     Colors.red,
  //     Colors.teal,
  //     Colors.indigo,
  //     Colors.pink,
  //   ];
  //   final totalItems =
  //       _categoryStats!.values.fold<int>(0, (sum, count) => sum + count);

  //   return LayoutBuilder(
  //     builder: (context, constraints) {
  //       final isSmallScreen = constraints.maxWidth < 500;

  //       return Column(
  //         children: [
  //           // Pie Chart with interactive tooltips
  //           SizedBox(
  //             height: 400,
  //             child: Stack(
  //               children: [
  //                 PieChart(
  //                   PieChartData(
  //                     pieTouchData: PieTouchData(
  //                       enabled: true,
  //                       touchCallback: (FlTouchEvent event, pieTouchResponse) {
  //                         setState(() {
  //                           if (!event.isInterestedForInteractions ||
  //                               pieTouchResponse == null ||
  //                               pieTouchResponse.touchedSection == null) {
  //                             _touchedCategoryIndex = -1;
  //                             return;
  //                           }
  //                           _touchedCategoryIndex = pieTouchResponse
  //                               .touchedSection!.touchedSectionIndex;
  //                         });
  //                       },
  //                     ),
  //                     sections: _categoryStats!.entries.map((entry) {
  //                       final index =
  //                           _categoryStats!.keys.toList().indexOf(entry.key);
  //                       final percentage =
  //                           ((entry.value / totalItems) * 100).toInt();
  //                       final isTouched = _touchedCategoryIndex == index;

  //                       return PieChartSectionData(
  //                         color: colors[index % colors.length],
  //                         value: entry.value.toDouble(),
  //                         title: isTouched
  //                             ? '${entry.value} items\n$percentage%'
  //                             : (percentage > 5 ? '$percentage%' : ''),
  //                         titleStyle: TextStyle(
  //                           fontSize: isTouched ? 10 : 12,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.white,
  //                         ),
  //                         radius: isTouched ? 90 : 80,
  //                         showTitle: entry.value > 0,
  //                       );
  //                     }).toList(),
  //                     centerSpaceRadius: 40,
  //                     sectionsSpace: 2,
  //                   ),
  //                 ),
  //                 // Tooltip overlay for category chart
  //                 if (_touchedCategoryIndex != -1)
  //                   Positioned.fill(
  //                     child: Container(
  //                       color: Colors.transparent,
  //                       child: Center(
  //                         child: Container(
  //                           padding: const EdgeInsets.all(8),
  //                           decoration: BoxDecoration(
  //                             color: Theme.of(context).brightness ==
  //                                     Brightness.dark
  //                                 ? Colors.grey[800]!.withValues(alpha: 0.9)
  //                                 : Colors.white.withValues(alpha: 0.9),
  //                             borderRadius: BorderRadius.circular(8),
  //                             boxShadow: [
  //                               BoxShadow(
  //                                 color: Colors.black.withValues(alpha: 0.2),
  //                                 blurRadius: 4,
  //                                 offset: const Offset(0, 2),
  //                               ),
  //                             ],
  //                           ),
  //                           child: Text(
  //                             _getCategoryTooltipText(_touchedCategoryIndex,
  //                                 _categoryStats!, totalItems),
  //                             style: GoogleFonts.poppins(
  //                               fontSize: 12,
  //                               fontWeight: FontWeight.w500,
  //                               color: Theme.of(context).brightness ==
  //                                       Brightness.dark
  //                                   ? Colors.white
  //                                   : Colors.grey[800],
  //                             ),
  //                             textAlign: TextAlign.center,
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ),
  //           const SizedBox(height: 20),
  //           // Legends below the chart - improved responsive layout
  //           Container(
  //             constraints: BoxConstraints(
  //               maxHeight: isSmallScreen
  //                   ? 200
  //                   : 150, // Limit height to prevent overflow
  //             ),
  //             child: SingleChildScrollView(
  //               child: Wrap(
  //                 spacing: isSmallScreen ? 12 : 16,
  //                 runSpacing: isSmallScreen ? 6 : 8,
  //                 alignment: WrapAlignment.center,
  //                 children: _categoryStats!.entries.map((entry) {
  //                   final index =
  //                       _categoryStats!.keys.toList().indexOf(entry.key);
  //                   final percentage =
  //                       ((entry.value / totalItems) * 100).toStringAsFixed(1);

  //                   return Tooltip(
  //                     message:
  //                         '${entry.key}: ${entry.value} items ($percentage%)',
  //                     child: Container(
  //                       constraints: BoxConstraints(
  //                         maxWidth: isSmallScreen
  //                             ? 120
  //                             : 150, // Limit width per legend item
  //                       ),
  //                       child: Row(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           Container(
  //                             width: 12,
  //                             height: 12,
  //                             decoration: BoxDecoration(
  //                               color: colors[index % colors.length],
  //                               borderRadius: BorderRadius.circular(2),
  //                             ),
  //                           ),
  //                           const SizedBox(width: 8),
  //                           Flexible(
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               mainAxisSize: MainAxisSize.min,
  //                               children: [
  //                                 Text(
  //                                   entry.key,
  //                                   style: GoogleFonts.poppins(
  //                                     fontSize: isSmallScreen ? 11 : 12,
  //                                     fontWeight: FontWeight.w500,
  //                                     color: Theme.of(context).brightness ==
  //                                             Brightness.dark
  //                                         ? Colors.white70
  //                                         : Colors.grey[700],
  //                                   ),
  //                                   overflow: TextOverflow.ellipsis,
  //                                   maxLines: 1,
  //                                   softWrap: false,
  //                                 ),
  //                                 Text(
  //                                   '${entry.value} items',
  //                                   style: GoogleFonts.poppins(
  //                                     fontSize: isSmallScreen ? 11 : 12,
  //                                     fontWeight: FontWeight.bold,
  //                                     color: Theme.of(context).brightness ==
  //                                             Brightness.dark
  //                                         ? Colors.white
  //                                         : Colors.grey[800],
  //                                   ),
  //                                   overflow: TextOverflow.ellipsis,
  //                                   maxLines: 1,
  //                                   softWrap: false,
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   );
  //                 }).toList(),
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // Widget _buildCategoryPieChart() {
  //   if (_isLoadingCategory) {
  //     return const Center(child: CircularProgressIndicator());
  //   }

  //   if (_categoryStats == null || _categoryStats!.isEmpty) {
  //     return const Center(child: Text('No category data available'));
  //   }

  //   final colors = [
  //     Colors.blue,
  //     Colors.green,
  //     Colors.orange,
  //     Colors.purple,
  //     Colors.red,
  //     Colors.teal,
  //     Colors.indigo,
  //     Colors.pink,
  //   ];

  //   final totalItems =
  //       _categoryStats!.values.fold<int>(0, (sum, count) => sum + count);

  //   return PieChart(
  //     PieChartData(
  //       pieTouchData: PieTouchData(
  //         enabled: true,
  //         touchCallback: (FlTouchEvent event, pieTouchResponse) {
  //           // Update the index WITHOUT calling setState to prevent dashboard refresh
  //           setState(() {
  //             if (!event.isInterestedForInteractions ||
  //                 pieTouchResponse == null ||
  //                 pieTouchResponse.touchedSection == null) {
  //               _touchedCategoryIndex = -1;
  //             } else {
  //               _touchedCategoryIndex =
  //                   pieTouchResponse.touchedSection!.touchedSectionIndex;
  //             }
  //           });
  //         },
  //         // touchCallback: (FlTouchEvent event, response) {
  //         //   if (!event.isInterestedForInteractions ||
  //         //       response == null ||
  //         //       response.touchedSection == null) {
  //         //     return;
  //         //   }
  //         //   setState(() {
  //         //     _touchedCategoryIndex =
  //         //         response.touchedSection!.touchedSectionIndex;
  //         //   });
  //         // },
  //       ),
  //       sections: _categoryStats!.entries.map((entry) {
  //         final index = _categoryStats!.keys.toList().indexOf(entry.key);
  //         final percentage = ((entry.value / totalItems) * 100).toInt();
  //         final isTouched = _touchedCategoryIndex == index;

  //         return PieChartSectionData(
  //           color: colors[index % colors.length],
  //           value: entry.value.toDouble(),
  //           title: isTouched
  //               ? '${entry.value}\n$percentage%'
  //               : (percentage > 5 ? '$percentage%' : ''),
  //           titleStyle: TextStyle(
  //             fontSize: isTouched ? 10 : 12,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.white,
  //           ),
  //           radius: isTouched ? 90 : 80,
  //           showTitle: entry.value > 0,
  //         );
  //       }).toList(),
  //       centerSpaceRadius: 40,
  //       sectionsSpace: 2,
  //     ),
  //   );
  // }

  Widget _buildCategoryPieChart() {
    if (_isLoadingCategory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categoryStats == null || _categoryStats!.isEmpty) {
      return const Center(child: Text('No category data available'));
    }

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
        _categoryStats!.values.fold<int>(0, (sum, count) => sum + count);

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
        sections: _categoryStats!.entries.map((entry) {
          final index = _categoryStats!.keys.toList().indexOf(entry.key);
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
  }

  // Widget _buildCategoryLegend() {
  //   return FutureBuilder<Map<String, int>>(
  //     future: InventoryService.getCategoryStats(),
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return const Center(child: CircularProgressIndicator());
  //       }

  //       if (snapshot.hasError || snapshot.data == null) {
  //         return const SizedBox();
  //       }

  //       final categoryData = snapshot.data!;
  //       if (categoryData.isEmpty) return const SizedBox();

  //       // Generate colors for categories
  //       final colors = _generateCategoryColors(categoryData.keys.length);
  //       final sortedEntries = categoryData.entries.toList()
  //         ..sort(
  //             (a, b) => b.value.compareTo(a.value)); // Sort by count descending

  //       return SingleChildScrollView(
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: sortedEntries.asMap().entries.map((mapEntry) {
  //             final index = mapEntry.key;
  //             final entry = mapEntry.value;
  //             final originalIndex =
  //                 categoryData.keys.toList().indexOf(entry.key);

  //             return Padding(
  //               padding: const EdgeInsets.only(bottom: 8.0),
  //               child: Tooltip(
  //                 message:
  //                     '${entry.key}: ${_getFullFormattedValue(entry.value)} items',
  //                 child: _buildCategoryLegendItem(entry.key, entry.value,
  //                     colors[originalIndex % colors.length]),
  //               ),
  //             );
  //           }).toList(),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildCategoryLegendGrid() {
    if (_isLoadingCategory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categoryStats == null || _categoryStats!.isEmpty) {
      return const SizedBox();
    }

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

    final sortedEntries = _categoryStats!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: sortedEntries.asMap().entries.map((mapEntry) {
          final entry = mapEntry.value;
          final originalIndex =
              _categoryStats!.keys.toList().indexOf(entry.key);

          return Container(
            constraints:
                const BoxConstraints(maxWidth: 140), // Prevent overflow
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[originalIndex % colors.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        '${entry.value}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
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
            ),
          );
        }).toList(),
      ),
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

  void _showNotImplementedDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text(
          '$feature functionality will be available in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
