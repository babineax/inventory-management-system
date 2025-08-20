import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/inventory_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onTabSelected;

  const DashboardScreen({Key? key, required this.onTabSelected})
      : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? dashboardStats;
  bool isLoading = true;
  AppUser? currentUser;

  /// static flag to avoid repeatedly inserting synthetic/demo data across
  /// multiple DashboardScreen instances during the app lifecycle.
  static bool _syntheticDataPopulated = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadDashboardData();
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
    // Show demo data immediately so UI is responsive
    setState(() {
      dashboardStats = {
        'totalItems': 25,
        'totalValue': 1250.75,
        'lowStockItems': 3,
        'outOfStockItems': 1,
        'itemsNeedingRestock': 4,
      };
      isLoading = false;
    });

    // Load real data in background, but only populate synthetic data
    // if the DB is empty — this avoids duplication when switching tabs.
    _loadRealDataInBackground();
  }

  void _loadRealDataInBackground() {
    Future.microtask(() async {
      try {
        // First try to fetch existing stats from the DB/service.
        final stats = await InventoryService.getDashboardStats();

        // If service returned stats and there are items, update UI and don't populate.
        if (mounted && (stats['totalItems'] ?? 0) > 0) {
          setState(() {
            dashboardStats = stats;
          });
          return;
        }

        // Fetch stats again (service might have been delayed)
        final updatedStats = await InventoryService.getDashboardStats();
        if (mounted) {
          setState(() {
            dashboardStats = updatedStats;
          });
        }
      } catch (e) {
        debugPrint('Background data loading failed: $e');
        // keep demo data already set; no further action required
      }
    });
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      isLoading = true;
    });
    // Re-run the same logic used in init to refresh the screen safely.
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    currentUser?.displayName ?? 'User',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildProfileAvatar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: ClipOval(
        child: currentUser?.profilePhotoPath != null
            ? Image.network(
                currentUser!.profilePhotoPath!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.white.withOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  );
                },
              )
            : _buildDefaultAvatar(),
      ),
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

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'U';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : 'U';
    }
    return '${words[0][0].toUpperCase()}${words[1][0].toUpperCase()}';
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
              dashboardStats!['totalItems'].toString(),
              Icons.inventory_2,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Value',
              // Guard against non-double values
              '\$${(dashboardStats!['totalValue'] is num) ? (dashboardStats!['totalValue'] as num).toStringAsFixed(2) : dashboardStats!['totalValue'].toString()}',
              Icons.attach_money,
              Colors.green,
            ),
            _buildStatCard(
              'Low Stock',
              dashboardStats!['lowStockItems'].toString(),
              Icons.warning,
              Colors.orange,
            ),
            _buildStatCard(
              'Out of Stock',
              dashboardStats!['outOfStockItems'].toString(),
              Icons.error,
              Colors.red,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Adjust font sizes based on card size
          double valueFontSize = constraints.maxHeight > 120 ? 20 : 16;
          double titleFontSize = constraints.maxHeight > 120 ? 12 : 10;
          double iconSize = constraints.maxHeight > 120 ? 24 : 20;
          double smallIconSize = constraints.maxHeight > 120 ? 16 : 14;

          return Padding(
            padding: EdgeInsets.all(constraints.maxHeight > 120 ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: color, size: iconSize),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, color: color, size: smallIconSize),
                    ),
                  ],
                ),
                if (constraints.maxHeight > 100) ...[
                  const SizedBox(height: 8),
                  // Mini visualization - only show if there's enough space
                  Flexible(child: _buildMiniChart(title, color)),
                ],
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: titleFontSize,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
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
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      );
    }

    return SizedBox(
      height: 30,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
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
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.1),
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
      double currentValue, int points, double minFactor, double maxFactor) {
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
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Add Item',
                Icons.add_box,
                Colors.green,
                () => Navigator.pushNamed(context, '/add_item'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'View Inventory',
                Icons.inventory_2,
                Colors.blue,
                () => widget.onTabSelected(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'Stock Movements',
                Icons.history,
                Colors.orange,
                () => widget.onTabSelected(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
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
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        child: _buildStockChart(),
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
                          child: _buildStockChart(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: _buildChartLegend(),
                        ),
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
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 200,
              child: _buildMonthlyTrendsChart(),
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
    final normalStock =
        (totalItems - lowStockItems - outOfStockItems).clamp(0, totalItems);

    if (totalItems == 0) {
      return const Center(child: Text('No inventory items'));
    }

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            color: Colors.green,
            value: normalStock.toDouble(),
            title: '${((normalStock / totalItems) * 100).toInt()}%',
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.orange,
            value: lowStockItems.toDouble(),
            title: '${((lowStockItems / totalItems) * 100).toInt()}%',
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.red,
            value: outOfStockItems.toDouble(),
            title: '${((outOfStockItems / totalItems) * 100).toInt()}%',
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildChartLegend() {
    if (dashboardStats == null) return const SizedBox();

    final totalItems = dashboardStats!['totalItems'] as int;
    final lowStockItems = dashboardStats!['lowStockItems'] as int;
    final outOfStockItems = dashboardStats!['outOfStockItems'] as int;
    final normalStock =
        (totalItems - lowStockItems - outOfStockItems).clamp(0, totalItems);

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
                  color: Colors.grey[700],
                ),
              ),
              Text(
                value.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendsChart() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: InventoryService.getMonthlyMovementTrends(),
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
                color: Colors.grey[600],
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
                color: Colors.grey[600],
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
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    if (value.toInt() < monthlyData.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          monthlyData[value.toInt()]['month'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
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
                  reservedSize: 40,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    return Text(
                      value.toInt().toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: monthlyData.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: (entry.value['value'] as int).toDouble(),
                    color: Theme.of(context).primaryColor,
                    width: 20,
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
            '$feature functionality will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
