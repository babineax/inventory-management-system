import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pdfw;
import 'dart:convert';
import '../services/inventory_service.dart';
import '../services/auth_service.dart';
import '../models/inventory_item.dart';
import '../models/stock_movement.dart';

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:community_charts_flutter/community_charts_flutter.dart'
    as charts;
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

class SystemReportsScreen extends StatefulWidget {
  const SystemReportsScreen({super.key});

  @override
  State<SystemReportsScreen> createState() => _SystemReportsScreenState();
}

class _SystemReportsScreenState extends State<SystemReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;

  // Touch state for pie charts
  int _touchedStockIndex = -1;
  int _touchedCategoryIndex = -1;

  // Pagination state
  int _itemsPage = 0;
  int _usersPage = 0;
  int _movementsPage = 0;
  final int _itemsPerPage = 15;

  final ScrollController _itemsScrollController = ScrollController();
  final ScrollController _usersScrollController = ScrollController();
  final ScrollController _movementsScrollController = ScrollController();

  // Keys for capturing on-screen charts as images
  final GlobalKey _categoryChartKey = GlobalKey();
  final GlobalKey _monthlyTrendsChartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReportData();

    // Setup scroll listeners for pagination
    _itemsScrollController.addListener(_onItemsScroll);
    _usersScrollController.addListener(_onUsersScroll);
    _movementsScrollController.addListener(_onMovementsScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemsScrollController.dispose();
    _usersScrollController.dispose();
    _movementsScrollController.dispose();
    super.dispose();
  }

  void _onItemsScroll() {
    if (_itemsScrollController.position.pixels ==
        _itemsScrollController.position.maxScrollExtent) {
      setState(() {
        _itemsPage++;
      });
    }
  }

  void _onUsersScroll() {
    if (_usersScrollController.position.pixels ==
        _usersScrollController.position.maxScrollExtent) {
      setState(() {
        _usersPage++;
      });
    }
  }

  void _onMovementsScroll() {
    if (_movementsScrollController.position.pixels ==
        _movementsScrollController.position.maxScrollExtent) {
      setState(() {
        _movementsPage++;
      });
    }
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dashboardStats = await InventoryService.getDashboardStats();
      final categoryStats = await InventoryService.getCategoryStats();
      final monthlyTrends = await InventoryService.getMonthlyMovementTrends();
      final allUsers = await AuthService.getAllUsers();
      final allItems = await InventoryService.getInventoryItems();
      final stockMovements =
          await InventoryService.getStockMovements(limit: 1000);

      final now = DateTime.now();

      // Helper: calculate revenue for a list of movements
      double calculateRevenue(List movements, List<InventoryItem> items) {
        double revenue = 0.0;

        for (var m in movements) {
          // Match movement with item to get unit price
          final item = items.firstWhere(
            (i) => i.id == m.itemId || i.name == m.itemName,
            orElse: () => InventoryItem(
              id: '',
              name: m.itemName ?? 'Unknown Item',
              description: '',
              category: '',
              quantity: 0,
              unitPrice: 0.0,
              supplier: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              reorderLevel: 0,
            ),
          );

          // Count only stockOut movements as sales
          if (m.type == MovementType.stockOut) {
            revenue += (m.quantity * item.unitPrice);
          }
        }

        return revenue;
      }

      // Daily movements
      final dailyMovements = stockMovements.where((m) =>
          m.timestamp.year == now.year &&
          m.timestamp.month == now.month &&
          m.timestamp.day == now.day);

      final dailySales =
          dailyMovements.where((m) => m.type == MovementType.stockOut).length;
      final dailyRevenue = calculateRevenue(dailyMovements.toList(), allItems);

      // Monthly movements
      final monthlyMovements = stockMovements.where((m) =>
          m.timestamp.year == now.year && m.timestamp.month == now.month);

      final monthlySales =
          monthlyMovements.where((m) => m.type == MovementType.stockOut).length;
      final monthlyRevenue =
          calculateRevenue(monthlyMovements.toList(), allItems);

      // Yearly movements
      final yearlyMovements =
          stockMovements.where((m) => m.timestamp.year == now.year);

      final yearlySales =
          yearlyMovements.where((m) => m.type == MovementType.stockOut).length;
      final yearlyRevenue =
          calculateRevenue(yearlyMovements.toList(), allItems);

      setState(() {
        _reportData = {
          'dashboardStats': dashboardStats,
          'categoryStats': categoryStats,
          'monthlyTrends': monthlyTrends,
          'users': allUsers,
          'items': allItems,
          'movements': stockMovements,
          'generatedAt': now,

          // ✅ New analyses
          'revenueDaily': {
            'sales': dailySales,
            'revenue': dailyRevenue,
          },
          'revenueMonthly': {
            'sales': monthlySales,
            'revenue': monthlyRevenue,
          },
          'revenueYearly': {
            'sales': yearlySales,
            'revenue': yearlyRevenue,
          },
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading report data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'System Reports',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            onPressed: _loadReportData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                // case 'download':
                //   _downloadReport(context, _reportData);
                //   break;
                // case 'share_email':
                //   _shareViaEmail(context, _reportData); // now calls PDF share
                //   break;
                // case 'share_whatsapp':
                //   _shareViaWhatsApp(
                //       context, _reportData); // now calls PDF share
                //   break;
                case 'download':
                  saveReportPdfFromState(
                    context: context,
                    reportData: _reportData!,
                    categoryChartKey: _categoryChartKey,
                    monthlyTrendsKey: _monthlyTrendsChartKey,
                    themeColor: Theme.of(context).primaryColor,
                  );
                  break;

                case 'share_email':
                case 'share_whatsapp':
                  shareReportPdfFromState(
                    context: context,
                    reportData: _reportData!,
                    categoryChartKey: _categoryChartKey,
                    monthlyTrendsKey: _monthlyTrendsChartKey,
                    themeColor: Theme.of(context).primaryColor,
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Download Report'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share_email',
                child: ListTile(
                  leading: Icon(Icons.email),
                  title: Text('Share via Email'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share_whatsapp',
                child: ListTile(
                  leading: Icon(Icons.message),
                  title: Text('Share via WhatsApp'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            icon: const Icon(Icons.share),
            tooltip: 'Share Report',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Items'),
            Tab(text: 'Users'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildInventoryTab(),
                _buildUsersTab(),
                _buildActivityTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_reportData == null) {
      return const Center(child: Text('No data available'));
    }

    final stats = _reportData!['dashboardStats'] as Map<String, dynamic>;
    final generatedAt = _reportData!['generatedAt'] as DateTime;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Overview Report',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generated on ${DateFormat('MMMM d, yyyy • h:mm a').format(generatedAt)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white60
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive grid for metric cards - Increased height
              int crossAxisCount = 2;
              double childAspectRatio =
                  1.1; // Increased from 1.4 to give more height

              if (constraints.maxWidth > 900) {
                crossAxisCount = 4;
                childAspectRatio = 0.9; // Increased from 1.2
              } else if (constraints.maxWidth > 600) {
                crossAxisCount = 3;
                childAspectRatio = 1.0; // Increased from 1.3
              }

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildMetricCard(
                    'Total Items',
                    (stats['totalItems'] ?? 0).toString(),
                    Icons.inventory_2,
                    Colors.blue,
                  ),
                  _buildMetricCard(
                    'Total Value',
                    '\$${NumberFormat('#,##0.00').format((stats['totalValue'] ?? 0).toDouble())}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                  _buildMetricCard(
                    'Low Stock Items',
                    (stats['lowStockItems'] ?? 0).toString(),
                    Icons.warning,
                    Colors.orange,
                  ),
                  _buildMetricCard(
                    'Out of Stock',
                    (stats['outOfStockItems'] ?? 0).toString(),
                    Icons.error,
                    Colors.red,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 340, // Increased height to fit content properly
                    child: Column(
                      children: [
                        // Pie chart
                        // Expanded(
                        //   flex: 3,
                        //   child: Padding(
                        //     padding: const EdgeInsets.only(
                        //         bottom: 20), // spacing after chart
                        //     child: _buildCategoryChart(),

                        //   ),
                        // ),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: RepaintBoundary(
                              key: _categoryChartKey, // For chart export
                              child: _buildCategoryChart(),
                            ),
                          ),
                        ),

                        // Legend
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 12), // spacing before legend
                            child: _buildCategoryLegend(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    if (_reportData == null) {
      return const Center(child: Text('No data available'));
    }

    final items = _reportData!['items'] as List<InventoryItem>;

    if (items.isEmpty) {
      return const Center(child: Text('No items available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Items by Category Card (same structure as Overview tab)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 340, // Same height as Overview
                    child: Column(
                      children: [
                        // Pie Chart
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _buildCategoryChart(),
                          ),
                        ),

                        // Legend
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildCategoryLegend(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Top Items by Value Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Top Items by Value',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${items.length} items',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white60
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280, // fixed height to avoid overflow
                    child: _buildItemsList(items),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_reportData == null) {
      return const Center(child: Text('No data available'));
    }

    final users = _reportData!['users'] as List;
    final activeUsers = users.where((u) => u.isActive).length;
    final adminUsers =
        users.where((u) => u.role.toString().contains('admin')).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 2;
              double childAspectRatio = 1.1; // Increased height

              if (constraints.maxWidth > 900) {
                crossAxisCount = 4;
                childAspectRatio = 0.9; // Increased height
              } else if (constraints.maxWidth > 600) {
                crossAxisCount = 3;
                childAspectRatio = 1.0; // Increased height
              }

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildMetricCard(
                    'Total Users',
                    users.length.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                  _buildMetricCard(
                    'Active Users',
                    activeUsers.toString(),
                    Icons.person,
                    Colors.green,
                  ),
                  _buildMetricCard(
                    'Admin Users',
                    adminUsers.toString(),
                    Icons.admin_panel_settings,
                    Colors.purple,
                  ),
                  _buildMetricCard(
                    'Staff Users',
                    (users.length - adminUsers).toString(),
                    Icons.work,
                    Colors.orange,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Details',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: _buildUsersList(users),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    if (_reportData == null) {
      return const Center(child: Text('No data available'));
    }

    final movements = _reportData!['movements'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 2;
              double childAspectRatio = 1.1; // Increased height

              if (constraints.maxWidth > 900) {
                crossAxisCount = 4;
                childAspectRatio = 0.9; // Increased height
              } else if (constraints.maxWidth > 600) {
                crossAxisCount = 3;
                childAspectRatio = 1.0; // Increased height
              }

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildMetricCard(
                    'Movements',
                    movements.length.toString(),
                    Icons.compare_arrows,
                    Colors.blue,
                  ),
                  _buildMetricCard(
                    'Monthly Avg',
                    movements.isEmpty
                        ? '0.0'
                        : (movements.length / 12).toStringAsFixed(1),
                    Icons.trending_up,
                    Colors.green,
                  ),
                  _buildMetricCard(
                    'Stock In',
                    movements
                        .where((m) => m.type == 'stockIn')
                        .length
                        .toString(),
                    Icons.add_circle,
                    Colors.teal,
                  ),
                  _buildMetricCard(
                    'Stock Out',
                    movements
                        .where((m) => m.type == 'stockOut')
                        .length
                        .toString(),
                    Icons.remove_circle,
                    Colors.orange,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Activity Trends',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // SizedBox(
                  //   height: 220,
                  //   child: _buildMonthlyTrendsChart(),
                  // ),
                  SizedBox(
                    height: 220,
                    child: RepaintBoundary(
                      key: _monthlyTrendsChartKey,
                      child: _buildMonthlyTrendsChart(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Stock Movements',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: _buildStockMovementsList(movements),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Improved sizing with more height for content
          double iconSize = constraints.maxWidth * 0.18;
          double valueSize = constraints.maxWidth * 0.14;
          double titleSize = constraints.maxWidth * 0.09;

          iconSize = iconSize.clamp(28.0, 44.0);
          valueSize = valueSize.clamp(18.0, 30.0);
          titleSize = titleSize.clamp(12.0, 18.0);

          return Container(
            padding: EdgeInsets.all(constraints.maxWidth * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: color,
                ),
                SizedBox(height: constraints.maxHeight * 0.08),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: valueSize,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.08),
                Flexible(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
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

  Widget _buildStockDistributionChart() {
    if (_reportData == null) return const Center(child: Text('No data'));

    final stats = _reportData!['dashboardStats'] as Map<String, dynamic>;
    final totalItems = stats['totalItems'] as int;
    final lowStockItems = stats['lowStockItems'] as int;
    final outOfStockItems = stats['outOfStockItems'] as int;
    final normalStock =
        (totalItems - lowStockItems - outOfStockItems).clamp(0, totalItems);

    if (totalItems == 0) {
      return const Center(child: Text('No inventory items'));
    }

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          enabled: true,
          touchCallback: (event, pieTouchResponse) {
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
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: Colors.green,
            value: normalStock.toDouble(),
            title: _touchedStockIndex == 0
                ? '$normalStock\n${((normalStock / totalItems) * 100).toInt()}%'
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
                ? '$lowStockItems\n${((lowStockItems / totalItems) * 100).toInt()}%'
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
                ? '$outOfStockItems\n${((outOfStockItems / totalItems) * 100).toInt()}%'
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
      ),
    );
  }

  Widget _buildStockDistributionLegend() {
    if (_reportData == null) return const SizedBox();

    final stats = _reportData!['dashboardStats'] as Map<String, dynamic>;
    final totalItems = stats['totalItems'] as int;
    final lowStockItems = stats['lowStockItems'] as int;
    final outOfStockItems = stats['outOfStockItems'] as int;
    final normalStock =
        (totalItems - lowStockItems - outOfStockItems).clamp(0, totalItems);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (normalStock > 0)
            _buildLegendItem(
              'Normal Stock',
              '$normalStock items (${((normalStock / totalItems) * 100).toInt()}%)',
              Colors.green,
            ),
          if (lowStockItems > 0) const SizedBox(width: 16),
          if (lowStockItems > 0)
            _buildLegendItem(
              'Low Stock',
              '$lowStockItems items (${((lowStockItems / totalItems) * 100).toInt()}%)',
              Colors.orange,
            ),
          if (outOfStockItems > 0) const SizedBox(width: 16),
          if (outOfStockItems > 0)
            _buildLegendItem(
              'Out of Stock',
              '$outOfStockItems items (${((outOfStockItems / totalItems) * 100).toInt()}%)',
              Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    if (_reportData == null) return const Center(child: Text('No data'));

    final categoryStats = _reportData!['categoryStats'] as Map<String, dynamic>;
    if (categoryStats.isEmpty) {
      return const Center(child: Text('No category data'));
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple
    ];
    int colorIndex = 0;

    final total = categoryStats.values
        .fold(0, (sum, value) => sum + (value as num).toInt());

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
          final percentage =
              total > 0 ? ((entry.value as num) / total * 100).toInt() : 0;
          colorIndex++;

          return PieChartSectionData(
            color: color,
            value: (entry.value as num).toDouble(),
            title: isTouched ? '${entry.key}\n$percentage%' : '$percentage%',
            titleStyle: TextStyle(
              fontSize: isTouched ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            radius: isTouched ? 90 : 80,
            showTitle: true,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryLegend() {
    if (_reportData == null) return const SizedBox();

    final categoryStats = _reportData!['categoryStats'] as Map<String, dynamic>;
    if (categoryStats.isEmpty) return const SizedBox();

    final total = categoryStats.values
        .fold(0, (sum, value) => sum + (value as num).toInt());

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple
    ];
    int colorIndex = 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: categoryStats.entries.map((entry) {
          final color = colors[colorIndex % colors.length];
          final percentage =
              total > 0 ? ((entry.value as num) / total * 100).toInt() : 0;
          colorIndex++;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildLegendItem(
              entry.key,
              '${entry.value} items ($percentage%)',
              color,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendItem(String title, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildItemsList(List<InventoryItem> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No items available'));
    }

    // Sort items by value (unitPrice * quantity) in descending order
    final sortedItems = List<InventoryItem>.from(items);
    sortedItems.sort((a, b) =>
        (b.unitPrice * b.quantity).compareTo(a.unitPrice * a.quantity));

    // Apply pagination
    final visibleItems =
        sortedItems.take((_itemsPage + 1) * _itemsPerPage).toList();

    return ListView.builder(
      controller: _itemsScrollController,
      itemCount: visibleItems.length +
          (visibleItems.length < sortedItems.length ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == visibleItems.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final item = visibleItems[index];
        final value = item.unitPrice * item.quantity;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: _buildItemAvatar(item),
            title: Text(
              item.name,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500, fontSize: 13),
              // overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.category, style: GoogleFonts.poppins(fontSize: 12)),
                Text(
                    'Qty: ${item.quantity} • \$${item.unitPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontSize: 10)),
              ],
            ),
            trailing: Text(
              '\$${NumberFormat('#,##0.00').format(value)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            // isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildItemAvatar(InventoryItem item) {
    return GestureDetector(
      onTap: () => _showImagePreview(context, item.imageUrl, item.name),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[300],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildItemImage(item),
        ),
      ),
    );
  }

  Widget _buildItemImage(InventoryItem item) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      // Handle base64 data URLs
      if (item.imageUrl!.startsWith('data:image')) {
        try {
          final base64String = item.imageUrl!.split(',')[1];
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading base64 item image: $error');
              return _buildItemPlaceholder();
            },
          );
        } catch (e) {
          debugPrint('Error decoding base64 item image: $e');
          return _buildItemPlaceholder();
        }
      } else {
        // Handle network URLs
        return Image.network(
          item.imageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading network item image: $error');
            return _buildItemPlaceholder();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            );
          },
        );
      }
    }

    return _buildItemPlaceholder();
  }

  Widget _buildItemPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[700]
            : Colors.grey[200],
      ),
      child: Icon(
        Icons.inventory_2,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white60
            : Colors.blue,
        size: 24,
      ),
    );
  }

  Widget _buildUsersList(List users) {
    if (users.isEmpty) {
      return const Center(child: Text('No users available'));
    }

    // Apply pagination
    final visibleUsers = users.take((_usersPage + 1) * _itemsPerPage).toList();

    return ListView.builder(
      controller: _usersScrollController,
      itemCount:
          visibleUsers.length + (visibleUsers.length < users.length ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == visibleUsers.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = visibleUsers[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: _buildUserAvatar(user),
            title: Text(
              user.displayName ?? user.email ?? 'Unknown User',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(user.email ?? 'No email'),
                Text(
                    'Role: ${user.role?.toString().replaceAll('UserRole.', '') ?? 'User'}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user.isActive ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.isActive ? 'Active' : 'Inactive',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
            // isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar(dynamic user) {
    // Handle different user object types and property names
    String displayName = 'User';

    // Get display name
    try {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        displayName = user.displayName;
      } else if (user.email != null && user.email!.isNotEmpty) {
        displayName = user.email;
      }
    } catch (e) {
      debugPrint('Error accessing user display info: $e');
    }

    return GestureDetector(
      onTap: () {
        String? imageUrl;
        try {
          if (user.profilePhotoPath != null &&
              user.profilePhotoPath!.isNotEmpty) {
            imageUrl = user.profilePhotoPath;
          }
        } catch (e) {
          debugPrint('Error accessing profilePhotoPath: $e');
        }
        _showImagePreview(context, imageUrl, displayName);
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[300],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildUserImage(user),
        ),
      ),
    );
  }

  Widget _buildUserImage(dynamic user) {
    if (user?.profilePhotoPath != null && user!.profilePhotoPath!.isNotEmpty) {
      // Handle base64 data URLs
      if (user.profilePhotoPath!.startsWith('data:image')) {
        try {
          final base64String = user.profilePhotoPath!.split(',')[1];
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading base64 user image: $error');
              return _buildUserPlaceholder();
            },
          );
        } catch (e) {
          debugPrint('Error decoding base64 user image: $e');
          return _buildUserPlaceholder();
        }
      } else {
        // Handle network URLs
        return Image.network(
          user.profilePhotoPath!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading network user image: $error');
            return _buildUserPlaceholder();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            );
          },
        );
      }
    }

    return _buildUserPlaceholder();
  }

  Widget _buildUserPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[700]
            : Colors.grey[200],
      ),
      child: Icon(
        Icons.person,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white60
            : Colors.purple,
        size: 24,
      ),
    );
  }

  Widget _buildStockMovementsList(List movements) {
    if (movements.isEmpty) {
      return const Center(child: Text('No stock movements available'));
    }

    // Sort movements by date (most recent first)
    final sortedMovements = List.from(movements);
    sortedMovements.sort((a, b) => (b.timestamp?.compareTo(a.timestamp) ?? 0));

    // Apply pagination
    final visibleMovements =
        sortedMovements.take((_movementsPage + 1) * _itemsPerPage).toList();

    // Get items list for image lookup
    final items = _reportData?['items'] as List<InventoryItem>? ?? [];

    return ListView.builder(
      controller: _movementsScrollController,
      itemCount: visibleMovements.length +
          (visibleMovements.length < sortedMovements.length ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == visibleMovements.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final movement = visibleMovements[index];
        final isStockIn = movement.type == MovementType.stockIn;

        // Try to find the corresponding item for the image
        InventoryItem? correspondingItem;
        if (movement.itemId != null) {
          correspondingItem = items.firstWhere(
            (item) => item.id == movement.itemId,
            orElse: () => items.firstWhere(
              (item) => item.name == movement.itemName,
              orElse: () => InventoryItem(
                id: '',
                name: movement.itemName ?? 'Unknown Item',
                description: '',
                category: '',
                quantity: 0,
                unitPrice: 0.0,
                supplier: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                reorderLevel: 0,
              ),
            ),
          );
        } else if (movement.itemName != null) {
          try {
            correspondingItem = items.firstWhere(
              (item) => item.name == movement.itemName,
            );
          } catch (e) {
            // Item not found, create a placeholder
            correspondingItem = InventoryItem(
              id: '',
              name: movement.itemName ?? 'Unknown Item',
              description: '',
              category: '',
              quantity: 0,
              unitPrice: 0.0,
              supplier: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              reorderLevel: 0,
            );
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: _buildStockMovementAvatar(movement, correspondingItem),
            title: Text(
              movement.itemName ?? 'Unknown Item',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500, fontSize: 13),
              // overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isStockIn ? '+' : '-'}${movement.quantity} units',
                  style: const TextStyle(fontSize: 12),
                ),
                if (movement.timestamp != null)
                  Text(
                      DateFormat('MMM d, yyyy • h:mm a')
                          .format(movement.timestamp!),
                      style: const TextStyle(fontSize: 10)),
              ],
            ),
            trailing: Text(
              movement.type.toString().split('.').last.toUpperCase(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: isStockIn ? Colors.green : Colors.red,
                fontSize: 9,
              ),
            ),
            // isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildMonthlyTrendsChart() {
    if (_reportData == null) return const Center(child: Text('No data'));

    final monthlyTrendsData = _reportData!['monthlyTrends'];
    if (monthlyTrendsData == null) {
      return const Center(child: Text('No trend data available'));
    }

    List<Map<String, dynamic>> monthlyData = [];

    // Handle different data formats and convert to List format expected by dashboard logic
    if (monthlyTrendsData is List) {
      monthlyData = List<Map<String, dynamic>>.from(monthlyTrendsData);
    } else if (monthlyTrendsData is Map<String, dynamic>) {
      // Convert Map to List format
      monthlyData = monthlyTrendsData.entries.map((entry) {
        return {
          'month': entry.key,
          'value':
              entry.value is int ? entry.value : (entry.value as num).toInt(),
          'stockIn': 0, // Default values since Map format may not have these
          'stockOut': 0,
        };
      }).toList();
    }

    if (monthlyData.isEmpty) {
      return const Center(
        child: Text(
          'No movement data available',
          style: TextStyle(fontSize: 12, color: Colors.grey),
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
                final stockIn = data['stockIn'] as int? ?? 0;
                final stockOut = data['stockOut'] as int? ?? 0;

                return BarTooltipItem(
                  '$month\n'
                  'Total: $value\n'
                  'Stock In: $stockIn\n'
                  'Stock Out: $stockOut',
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
                          color: Theme.of(context).brightness == Brightness.dark
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
              interval: chartMaxY > 100 ? (chartMaxY / 5).ceilToDouble() : null,
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
  }

  // Future<void> _downloadReport(
  //     BuildContext context, Map<String, dynamic>? reportData) async {
  //   if (reportData == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('No report data available')),
  //     );
  //     return;
  //   }

  //   try {
  //     final stats = reportData['dashboardStats'] as Map<String, dynamic>;
  //     final generatedAt = reportData['generatedAt'] as DateTime;

  //     final pdf = pdfw.Document();

  //     // Capture chart images
  //     final categoryChartBytes = await _captureChartAsImage(_categoryChartKey);
  //     final monthlyTrendsChartBytes =
  //         await _captureChartAsImage(_monthlyTrendsChartKey);

  //     pdf.addPage(
  //       pdfw.MultiPage(
  //         pageFormat: PdfPageFormat.a4,
  //         margin: const pdfw.EdgeInsets.all(24),
  //         build: (pdfw.Context context) {
  //           return [
  //             // Header
  //             pdfw.Text(
  //               "Inventory System Report",
  //               style: pdfw.TextStyle(
  //                   fontSize: 22, fontWeight: pdfw.FontWeight.bold),
  //             ),
  //             pdfw.Text(
  //               "Generated on ${DateFormat('MMMM d, yyyy • h:mm a').format(generatedAt)}",
  //               style: const pdfw.TextStyle(
  //                   fontSize: 12, color: PdfColors.grey700),
  //             ),
  //             pdfw.SizedBox(height: 20),

  //             // Key Metrics
  //             pdfw.Text("📈 Key Metrics",
  //                 style: pdfw.TextStyle(
  //                     fontSize: 16, fontWeight: pdfw.FontWeight.bold)),
  //             pdfw.SizedBox(height: 8),
  //             pdfw.TableHelper.fromTextArray(
  //               headers: ["Metric", "Value"],
  //               data: [
  //                 ["Total Items", (stats['totalItems'] ?? 0).toString()],
  //                 [
  //                   "Total Value",
  //                   "\$${NumberFormat('#,##0.00').format((stats['totalValue'] ?? 0).toDouble())}"
  //                 ],
  //                 ["Low Stock Items", (stats['lowStockItems'] ?? 0).toString()],
  //                 ["Out of Stock", (stats['outOfStockItems'] ?? 0).toString()],
  //               ],
  //             ),
  //             pdfw.SizedBox(height: 20),

  //             // Category Chart
  //             if (categoryChartBytes != null) ...[
  //               pdfw.Text("📊 Items by Category",
  //                   style: pdfw.TextStyle(
  //                       fontSize: 16, fontWeight: pdfw.FontWeight.bold)),
  //               pdfw.SizedBox(height: 8),
  //               pdfw.Image(pdfw.MemoryImage(categoryChartBytes), height: 200),
  //               pdfw.SizedBox(height: 20),
  //             ],

  //             // Monthly Trends
  //             if (monthlyTrendsChartBytes != null) ...[
  //               pdfw.Text("📉 Monthly Trends",
  //                   style: pdfw.TextStyle(
  //                       fontSize: 16, fontWeight: pdfw.FontWeight.bold)),
  //               pdfw.SizedBox(height: 8),
  //               pdfw.Image(pdfw.MemoryImage(monthlyTrendsChartBytes),
  //                   height: 200),
  //               pdfw.SizedBox(height: 20),
  //             ],

  //             pdfw.Text("📱 Generated by Inventory Management System",
  //                 style: const pdfw.TextStyle(fontSize: 10)),
  //           ];
  //         },
  //       ),
  //     );

  //     // Save with file picker
  //     final output = await FilePicker.platform.saveFile(
  //       dialogTitle: 'Save Report As',
  //       fileName:
  //           'system-report-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
  //       type: FileType.custom,
  //       allowedExtensions: ['pdf'],
  //     );

  //     if (output != null) {
  //       final file = File(output);
  //       await file.writeAsBytes(await pdf.save());

  //       if (context.mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Report saved to $output')),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error generating report: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  /// Helper: Get top category
  String _getTopCategory(Map<String, dynamic> categoryStats) {
    if (categoryStats.isEmpty) return "N/A";
    final sorted = categoryStats.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    return sorted.first.key;
  }

// --- Use the same category data ---
  Future<Uint8List?> _generateCategoryChartImage(
      Map<String, int> categoryStats) async {
    final series = [
      charts.Series<MapEntry<String, int>, String>(
        id: 'Categories',
        domainFn: (entry, _) => entry.key,
        measureFn: (entry, _) => entry.value,
        data: categoryStats.entries.toList(),
        labelAccessorFn: (entry, _) => '${entry.key}: ${entry.value}',
      )
    ];

    final chart = charts.PieChart<String>(
      series,
      animate: false,
      defaultRenderer: charts.ArcRendererConfig(
        arcRendererDecorators: [charts.ArcLabelDecorator()],
      ),
    );

    return _captureChartAsImage(_categoryChartKey);
  }

// --- Use the same monthly trends data ---
  Future<Uint8List?> _generateMonthlyTrendChartImage(
      List<Map<String, dynamic>> monthlyTrends) async {
    final series = [
      charts.Series<Map<String, dynamic>, String>(
        id: 'Monthly Trends',
        domainFn: (row, _) => row['month'] as String,
        measureFn: (row, _) => row['value'] as int,
        data: monthlyTrends,
      )
    ];

    final chart = charts.BarChart(series, animate: false);
    return _captureChartAsImage(_categoryChartKey);
  }

  Future<Uint8List?> _generateStockTrendChartImage() async {
    // Dummy example — replace with your real trend data
    final data = [
      {'day': 'Mon', 'value': 20},
      {'day': 'Tue', 'value': 40},
      {'day': 'Wed', 'value': 35},
      {'day': 'Thu', 'value': 50},
    ];

    final series = [
      charts.Series<Map<String, Object>, String>(
        id: 'Stock Trends',
        domainFn: (row, _) => row['day'] as String,
        measureFn: (row, _) => row['value'] as int,
        data: data,
      )
    ];

    final chart = charts.BarChart(series, animate: false);
    return _captureChartAsImage(_categoryChartKey);
  }

  final GlobalKey _chartKey = GlobalKey();

  Future<Uint8List?> _captureChartAsImage(GlobalKey key) async {
    try {
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return null;

      final image = await renderObject.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Chart capture error: $e');
      return null;
    }
  }

  /// Helper: convert Flutter Color -> PdfColor with optional opacity
  PdfColor _pdfFromFlutterColor(Color c, {double opacity = 1.0}) {
    final clamped = opacity.clamp(0.0, 1.0);
    final a = (clamped * 255).round() & 0xFF;
    final r = (c.r * 255).round() & 0xFF;
    final g = (c.g * 255).round() & 0xFF;
    final b = (c.b * 255).round() & 0xFF;
    final argb = (a << 24) | (r << 16) | (g << 8) | b;
    return PdfColor.fromInt(argb);
  }

  /// Create a lighter tint of a Flutter color (mix with white)
  PdfColor _pdfTint(Color base, double t) {
    int mix(double channel) =>
        (channel * 255 + ((255 - channel * 255) * t)).round().clamp(0, 255);
    final r = mix(base.r);
    final g = mix(base.g);
    final b = mix(base.b);
    return PdfColor.fromInt(0xFF000000 | (r << 16) | (g << 8) | b);
  }

  // Generate full PDF report with charts and data
  Future<Uint8List> _generatePdfReport(
    Map<String, dynamic> reportData,
    Uint8List? categoryChartBytes,
    Uint8List? monthlyTrendsChartBytes,
    Color themeColor,
  ) async {
    final pdf = pdfw.Document();
    final generatedAt = reportData['generatedAt'] as DateTime;

    final dashboardStats = reportData['dashboardStats'] as Map<String, dynamic>;
    // final categoryStats = reportData['categoryStats'] as List<dynamic>;
    final categoryStats = (reportData['categoryStats'] as Map<String, int>)
        .entries
        .map((e) => {
              'category': e.key,
              'count': e.value,
              'value': 0, // if you don’t have value, keep 0
            })
        .toList();

    final items = reportData['items'] as List<InventoryItem>;
    final users = reportData['users'] as List<dynamic>;
    final movements = reportData['movements'] as List<StockMovement>;

    final daily = reportData['revenueDaily'] as Map<String, dynamic>;
    final monthly = reportData['revenueMonthly'] as Map<String, dynamic>;
    final yearly = reportData['revenueYearly'] as Map<String, dynamic>;

    PdfColor pdfFromFlutterColor(Color c, {double opacity = 1.0}) {
      final clamped = opacity.clamp(0.0, 1.0);
      final a = (clamped * 255).round() & 0xFF;
      final r = (c.r * 255.0).round() & 0xFF;
      final g = (c.g * 255.0).round() & 0xFF;
      final b = (c.b * 255.0).round() & 0xFF;
      final argb = (a << 24) | (r << 16) | (g << 8) | b;
      return PdfColor.fromInt(argb);
    }

    pdfw.Widget buildKpiCard(String label, String value, PdfColor color) {
      return pdfw.Container(
        padding: const pdfw.EdgeInsets.all(10),
        decoration: pdfw.BoxDecoration(
          borderRadius: const pdfw.BorderRadius.all(pdfw.Radius.circular(8)),
          color: color,
        ),
        child: pdfw.Column(
          crossAxisAlignment: pdfw.CrossAxisAlignment.start,
          children: [
            pdfw.Text(value,
                style: pdfw.TextStyle(
                  fontSize: 16,
                  fontWeight: pdfw.FontWeight.bold,
                  color: PdfColors.white,
                )),
            pdfw.SizedBox(height: 4),
            pdfw.Text(label,
                style: pdfw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.white,
                )),
          ],
        ),
      );
    }

    pdf.addPage(
      pdfw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pdfw.EdgeInsets.all(24),
        build: (context) {
          return [
            // Header
            pdfw.Row(
              mainAxisAlignment: pdfw.MainAxisAlignment.spaceBetween,
              children: [
                pdfw.Text(
                  "📊 Inventory System Report",
                  style: pdfw.TextStyle(
                    fontSize: 22,
                    fontWeight: pdfw.FontWeight.bold,
                    color: pdfFromFlutterColor(themeColor),
                  ),
                ),
                pdfw.Text(
                  DateFormat('MMMM d, yyyy • h:mm a').format(generatedAt),
                  style: pdfw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pdfw.SizedBox(height: 20),

            // KPI Section
            pdfw.Text("Key Performance Indicators",
                style: pdfw.TextStyle(
                  fontSize: 16,
                  fontWeight: pdfw.FontWeight.bold,
                )),
            pdfw.SizedBox(height: 10),

            pdfw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                buildKpiCard(
                    "Total Items",
                    "${dashboardStats['totalItems'] ?? 0}",
                    pdfFromFlutterColor(themeColor)),
                buildKpiCard(
                    "Total Value",
                    "\$${NumberFormat('#,##0.00').format((dashboardStats['totalValue'] ?? 0).toDouble())}",
                    PdfColors.blue),
                buildKpiCard(
                    "Low Stock",
                    "${dashboardStats['lowStockItems'] ?? 0}",
                    PdfColors.orange),
                buildKpiCard("Out of Stock",
                    "${dashboardStats['outOfStockItems'] ?? 0}", PdfColors.red),
              ],
            ),
            pdfw.SizedBox(height: 20),

            // Revenue Section
            pdfw.Text("Revenue & Sales Analysis",
                style: pdfw.TextStyle(
                  fontSize: 16,
                  fontWeight: pdfw.FontWeight.bold,
                )),
            pdfw.SizedBox(height: 10),
            pdfw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                buildKpiCard(
                    "Daily Sales",
                    "${daily['sales']} sales\n\$${NumberFormat('#,##0.00').format(daily['revenue'])}",
                    PdfColors.green),
                buildKpiCard(
                    "Monthly Sales",
                    "${monthly['sales']} sales\n\$${NumberFormat('#,##0.00').format(monthly['revenue'])}",
                    PdfColors.purple),
                buildKpiCard(
                    "Yearly Sales",
                    "${yearly['sales']} sales\n\$${NumberFormat('#,##0.00').format(yearly['revenue'])}",
                    PdfColors.teal),
              ],
            ),
            pdfw.SizedBox(height: 20),

            // Charts
            if (categoryChartBytes != null) ...[
              pdfw.Text("Items by Category",
                  style: pdfw.TextStyle(
                      fontSize: 14, fontWeight: pdfw.FontWeight.bold)),
              pdfw.SizedBox(height: 8),
              pdfw.Image(pdfw.MemoryImage(categoryChartBytes), height: 200),
              pdfw.SizedBox(height: 20),
            ],
            if (monthlyTrendsChartBytes != null) ...[
              pdfw.Text("Monthly Trends",
                  style: pdfw.TextStyle(
                      fontSize: 14, fontWeight: pdfw.FontWeight.bold)),
              pdfw.SizedBox(height: 8),
              pdfw.Image(pdfw.MemoryImage(monthlyTrendsChartBytes),
                  height: 200),
              pdfw.SizedBox(height: 20),
            ],

            // Category Table
            pdfw.Text("Category Breakdown",
                style: pdfw.TextStyle(
                    fontSize: 14, fontWeight: pdfw.FontWeight.bold)),
            pdfw.SizedBox(height: 8),
            pdfw.TableHelper.fromTextArray(
              headers: ["Category", "Items", "Value"],
              data: [
                for (var cat in categoryStats)
                  [
                    cat['category'] ?? 'Unknown',
                    cat['count'].toString(),
                    "\$${NumberFormat('#,##0.00').format((cat['value'] is num ? cat['value'] : 0))}",
                  ]
              ],
            ),

            pdfw.SizedBox(height: 20),

            // Stock Movements Table
            pdfw.Text("Stock Movements",
                style: pdfw.TextStyle(
                    fontSize: 14, fontWeight: pdfw.FontWeight.bold)),
            pdfw.SizedBox(height: 8),
            pdfw.TableHelper.fromTextArray(
              headers: ["Item", "Type", "Quantity", "Date"],
              data: [
                for (var m in movements)
                  [
                    m.itemName ?? "Unknown Item",
                    m.type.toString().split('.').last, // STOCKIN or STOCKOUT
                    m.quantity.toString(),
                    DateFormat('yyyy-MM-dd HH:mm')
                        .format(m.timestamp), // fallback if null
                  ]
              ],
            ),

            pdfw.SizedBox(height: 30),
            pdfw.Divider(),

            pdfw.Center(
              child: pdfw.Text("Generated by Inventory Management System",
                  style: pdfw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Future<Uint8List> _generatePdfReport({
  //   required Map<String, dynamic> reportData,
  //   required Color themeColor,
  //   Uint8List? logoBytes,
  //   Uint8List? categoryChartBytes,
  //   Uint8List? monthlyTrendsChartBytes,
  // }) async {
  //   final stats = reportData['dashboardStats'] as Map<String, dynamic>;
  //   final categoryStats =
  //       (reportData['categoryStats'] as Map<String, dynamic>?) ?? {};
  //   final generatedAt =
  //       reportData['generatedAt'] as DateTime? ?? DateTime.now();

  //   final pdf = pdfw.Document();

  //   final brand = _pdfFromFlutterColor(themeColor);
  //   final brandLight =
  //       _pdfTint(themeColor, 0.85); // very light background stripe
  //   final brandMid = _pdfTint(themeColor, 0.6);

  //   pdf.addPage(
  //     pdfw.MultiPage(
  //       pageFormat: PdfPageFormat.a4,
  //       margin: const pdfw.EdgeInsets.symmetric(horizontal: 28, vertical: 36),
  //       header: (context) => pdfw.Container(
  //         padding: const pdfw.EdgeInsets.only(bottom: 10),
  //         child: pdfw.Row(
  //           crossAxisAlignment: pdfw.CrossAxisAlignment.center,
  //           mainAxisAlignment: pdfw.MainAxisAlignment.spaceBetween,
  //           children: [
  //             pdfw.Row(
  //               crossAxisAlignment: pdfw.CrossAxisAlignment.center,
  //               children: [
  //                 if (logoBytes != null)
  //                   pdfw.Container(
  //                     width: 36,
  //                     height: 36,
  //                     decoration: pdfw.BoxDecoration(
  //                       borderRadius: pdfw.BorderRadius.circular(8),
  //                       color: brandLight,
  //                     ),
  //                     child: pdfw.Center(
  //                       child: pdfw.Image(pdfw.MemoryImage(logoBytes),
  //                           width: 28, height: 28, fit: pdfw.BoxFit.contain),
  //                     ),
  //                   )
  //                 else
  //                   pdfw.Container(
  //                     width: 36,
  //                     height: 36,
  //                     decoration: pdfw.BoxDecoration(
  //                       color: brand,
  //                       borderRadius: pdfw.BorderRadius.circular(8),
  //                     ),
  //                   ),
  //                 pdfw.SizedBox(width: 12),
  //                 pdfw.Column(
  //                   crossAxisAlignment: pdfw.CrossAxisAlignment.start,
  //                   children: [
  //                     pdfw.Text('Inventory System Report',
  //                         style: pdfw.TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: pdfw.FontWeight.bold,
  //                           color: brand,
  //                         )),
  //                     pdfw.Text(
  //                         DateFormat('MMMM d, yyyy • h:mm a')
  //                             .format(generatedAt),
  //                         style: pdfw.TextStyle(
  //                             fontSize: 9, color: PdfColors.grey700)),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //             pdfw.Container(
  //               padding: const pdfw.EdgeInsets.symmetric(
  //                   horizontal: 10, vertical: 4),
  //               decoration: pdfw.BoxDecoration(
  //                 color: brandLight,
  //                 borderRadius: pdfw.BorderRadius.circular(6),
  //               ),
  //               child: pdfw.Text(
  //                 'Confidential',
  //                 style: pdfw.TextStyle(fontSize: 9, color: brand),
  //               ),
  //             )
  //           ],
  //         ),
  //       ),
  //       footer: (context) => pdfw.Container(
  //         margin: const pdfw.EdgeInsets.only(top: 10),
  //         child: pdfw.Row(
  //           mainAxisAlignment: pdfw.MainAxisAlignment.spaceBetween,
  //           children: [
  //             pdfw.Text('Generated by Inventory Management System',
  //                 style: pdfw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
  //             pdfw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
  //                 style: pdfw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
  //           ],
  //         ),
  //       ),
  //       build: (context) => [
  //         // Colored band
  //         pdfw.Container(
  //           decoration: pdfw.BoxDecoration(
  //             color: brandLight,
  //             borderRadius: pdfw.BorderRadius.circular(8),
  //           ),
  //           padding: const pdfw.EdgeInsets.all(12),
  //           child: pdfw.Row(
  //             mainAxisAlignment: pdfw.MainAxisAlignment.spaceBetween,
  //             children: [
  //               pdfw.Text('Executive Summary',
  //                   style: pdfw.TextStyle(
  //                     fontSize: 12,
  //                     fontWeight: pdfw.FontWeight.bold,
  //                     color: brand,
  //                   )),
  //               pdfw.Text(
  //                   'As of ${DateFormat('yyyy-MM-dd').format(generatedAt)}',
  //                   style:
  //                       pdfw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
  //             ],
  //           ),
  //         ),
  //         pdfw.SizedBox(height: 14),

  //         // Key Metrics
  //         pdfw.Text('Key Metrics',
  //             style: pdfw.TextStyle(
  //                 fontSize: 14,
  //                 fontWeight: pdfw.FontWeight.bold,
  //                 color: brand)),
  //         pdfw.SizedBox(height: 8),
  //         pdfw.TableHelper.fromTextArray(
  //           headerDecoration: pdfw.BoxDecoration(color: brand),
  //           headerStyle: pdfw.TextStyle(
  //               color: PdfColors.white, fontWeight: pdfw.FontWeight.bold),
  //           cellStyle: const pdfw.TextStyle(fontSize: 10),
  //           cellAlignments: {
  //             0: pdfw.Alignment.centerLeft,
  //             1: pdfw.Alignment.centerRight
  //           },
  //           headers: ['Metric', 'Value'],
  //           data: [
  //             ['Total Items', (stats['totalItems'] ?? 0).toString()],
  //             [
  //               'Total Value',
  //               '\$${NumberFormat('#,##0.00').format((stats['totalValue'] ?? 0).toDouble())}'
  //             ],
  //             ['Low Stock Items', (stats['lowStockItems'] ?? 0).toString()],
  //             ['Out of Stock', (stats['outOfStockItems'] ?? 0).toString()],
  //           ],
  //         ),
  //         pdfw.SizedBox(height: 16),

  //         // Charts block
  //         pdfw.Text('Visuals',
  //             style: pdfw.TextStyle(
  //                 fontSize: 14,
  //                 fontWeight: pdfw.FontWeight.bold,
  //                 color: brand)),
  //         pdfw.SizedBox(height: 8),
  //         pdfw.Wrap(
  //           spacing: 12,
  //           runSpacing: 12,
  //           children: [
  //             if (categoryChartBytes != null)
  //               pdfw.Container(
  //                 width: PdfPageFormat.a4.availableWidth / 2 - 12,
  //                 padding: const pdfw.EdgeInsets.all(8),
  //                 decoration: pdfw.BoxDecoration(
  //                   border: pdfw.Border.all(color: brandMid, width: 0.6),
  //                   borderRadius: pdfw.BorderRadius.circular(8),
  //                 ),
  //                 child: pdfw.Column(
  //                   crossAxisAlignment: pdfw.CrossAxisAlignment.start,
  //                   children: [
  //                     pdfw.Text('Items by Category',
  //                         style: pdfw.TextStyle(
  //                             fontSize: 11, fontWeight: pdfw.FontWeight.bold)),
  //                     pdfw.SizedBox(height: 6),
  //                     pdfw.Image(pdfw.MemoryImage(categoryChartBytes),
  //                         height: 180, fit: pdfw.BoxFit.contain),
  //                   ],
  //                 ),
  //               ),
  //             if (monthlyTrendsChartBytes != null)
  //               pdfw.Container(
  //                 width: PdfPageFormat.a4.availableWidth / 2 - 12,
  //                 padding: const pdfw.EdgeInsets.all(8),
  //                 decoration: pdfw.BoxDecoration(
  //                   border: pdfw.Border.all(color: brandMid, width: 0.6),
  //                   borderRadius: pdfw.BorderRadius.circular(8),
  //                 ),
  //                 child: pdfw.Column(
  //                   crossAxisAlignment: pdfw.CrossAxisAlignment.start,
  //                   children: [
  //                     pdfw.Text('Monthly Activity Trends',
  //                         style: pdfw.TextStyle(
  //                             fontSize: 11, fontWeight: pdfw.FontWeight.bold)),
  //                     pdfw.SizedBox(height: 6),
  //                     pdfw.Image(pdfw.MemoryImage(monthlyTrendsChartBytes),
  //                         height: 180, fit: pdfw.BoxFit.contain),
  //                   ],
  //                 ),
  //               ),
  //           ],
  //         ),
  //         pdfw.SizedBox(height: 16),

  //         // Category table
  //         if (categoryStats.isNotEmpty) ...[
  //           pdfw.Text('Category Breakdown',
  //               style: pdfw.TextStyle(
  //                   fontSize: 14,
  //                   fontWeight: pdfw.FontWeight.bold,
  //                   color: brand)),
  //           pdfw.SizedBox(height: 8),
  //           pdfw.TableHelper.fromTextArray(
  //             headerDecoration: pdfw.BoxDecoration(color: brand),
  //             headerStyle: pdfw.TextStyle(
  //                 color: PdfColors.white, fontWeight: pdfw.FontWeight.bold),
  //             cellStyle: const pdfw.TextStyle(fontSize: 10),
  //             headers: ['Category', 'Count'],
  //             data: categoryStats.entries
  //                 .map((e) => [e.key, e.value.toString()])
  //                 .toList(),
  //           ),
  //           pdfw.SizedBox(height: 16),
  //         ],

  //         // Insights bullets
  //         pdfw.Text('Insights & Actions',
  //             style: pdfw.TextStyle(
  //                 fontSize: 14,
  //                 fontWeight: pdfw.FontWeight.bold,
  //                 color: brand)),
  //         pdfw.SizedBox(height: 8),
  //         pdfw.Bullet(
  //           text:
  //               'Low stock items (${stats['lowStockItems'] ?? 0}) should be reviewed for replenishment.',
  //           style: const pdfw.TextStyle(fontSize: 10),
  //         ),
  //         pdfw.Bullet(
  //           text:
  //               'Out-of-stock items (${stats['outOfStockItems'] ?? 0}) require immediate restock to prevent stockouts.',
  //           style: const pdfw.TextStyle(fontSize: 10),
  //         ),
  //         if (categoryStats.isNotEmpty)
  //           pdfw.Bullet(
  //             text:
  //                 'Highest category: ${_getTopCategory(categoryStats)} — monitor usage closely.',
  //             style: const pdfw.TextStyle(fontSize: 10),
  //           ),
  //       ],
  //     ),
  //   );

  //   return pdf.save();
  // }

  // String _getTopCategory(Map<String, dynamic> categoryStats) {
  //   if (categoryStats.isEmpty) return 'N/A';
  //   final sorted = categoryStats.entries.toList()
  //     ..sort((a, b) => (b.value as num).compareTo(a.value as num));
  //   return sorted.first.key;
  // }

  // /// Generate full PDF report
  // Future<Uint8List> _generatePdfReport(
  //   Map<String, dynamic> reportData,
  //   Uint8List? categoryChartBytes,
  //   Uint8List? monthlyTrendsChartBytes,
  // ) async {
  //   final stats = reportData['dashboardStats'] as Map<String, dynamic>;
  //   final categoryStats = reportData['categoryStats'] as Map<String, dynamic>;
  //   final generatedAt = reportData['generatedAt'] as DateTime;

  //   final pdf = pdfw.Document();

  //   pdf.addPage(
  //     pdfw.MultiPage(
  //       pageFormat: PdfPageFormat.a4,
  //       margin: const pdfw.EdgeInsets.all(24),
  //       build: (pdfw.Context context) {
  //         return [
  //           // Header
  //           pdfw.Text("Inventory System Report",
  //               style: pdfw.TextStyle(
  //                   fontSize: 22, fontWeight: pdfw.FontWeight.bold)),
  //           pdfw.Text(
  //             "Generated on ${DateFormat('MMMM d, yyyy • h:mm a').format(generatedAt)}",
  //             style:
  //                 const pdfw.TextStyle(fontSize: 12, color: PdfColors.grey700),
  //           ),
  //           pdfw.SizedBox(height: 20),

  //           // Key Metrics
  //           pdfw.Text("📈 Key Metrics",
  //               style: pdfw.TextStyle(
  //                   fontSize: 16, fontWeight: pdfw.FontWeight.bold)),
  //           pdfw.SizedBox(height: 8),
  //           pdfw.TableHelper.fromTextArray(
  //             headers: ["Metric", "Value"],
  //             data: [
  //               ["Total Items", (stats['totalItems'] ?? 0).toString()],
  //               [
  //                 "Total Value",
  //                 "\$${NumberFormat('#,##0.00').format((stats['totalValue'] ?? 0).toDouble())}"
  //               ],
  //               ["Low Stock Items", (stats['lowStockItems'] ?? 0).toString()],
  //               ["Out of Stock", (stats['outOfStockItems'] ?? 0).toString()],
  //             ],
  //           ),
  //           pdfw.SizedBox(height: 20),

  //           // Category Chart
  //           if (categoryChartBytes != null) ...[
  //             pdfw.Text("📊 Items by Category",
  //                 style: pdfw.TextStyle(
  //                     fontSize: 16, fontWeight: pdfw.FontWeight.bold)),
  //             pdfw.SizedBox(height: 8),
  //             pdfw.Image(pdfw.MemoryImage(categoryChartBytes), height: 200),
  //             pdfw.SizedBox(height: 20),
  //           ],

  //           // Monthly Trends Chart
  //           if (monthlyTrendsChartBytes != null) ...[
  //             pdfw.Text("📉 Monthly Trends",
  //                 style: pdfw.TextStyle(
  //                     fontSize: 16, fontWeight: pdfw.FontWeight.bold)),
  //             pdfw.SizedBox(height: 8),
  //             pdfw.Image(pdfw.MemoryImage(monthlyTrendsChartBytes),
  //                 height: 200),
  //             pdfw.SizedBox(height: 20),
  //           ],

  //           // Items by Category Table
  //           if (categoryStats.isNotEmpty) ...[
  //             pdfw.Text("📂 Category Breakdown",
  //                 style: pdfw.TextStyle(
  //                     fontSize: 16, fontWeight: pdfw.FontWeight.bold)),
  //             pdfw.SizedBox(height: 8),
  //             pdfw.TableHelper.fromTextArray(
  //               headers: ["Category", "Count"],
  //               data: categoryStats.entries
  //                   .map((e) => [e.key, e.value.toString()])
  //                   .toList(),
  //             ),
  //             pdfw.SizedBox(height: 20),
  //           ],

  //           // Footer
  //           pdfw.Text("📱 Generated by Inventory Management System",
  //               style: const pdfw.TextStyle(fontSize: 10)),
  //         ];
  //       },
  //     ),
  //   );

  //   return pdf.save();
  // }

  /// Save PDF to user-selected location
  // Future<void> _downloadReport(
  //     BuildContext context, Map<String, dynamic>? reportData) async {
  //   if (reportData == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('No report data available')),
  //     );
  //     return;
  //   }

  //   try {
  //     final categoryChartBytes = await _captureChartAsImage(_categoryChartKey);
  //     final monthlyTrendsChartBytes =
  //         await _captureChartAsImage(_monthlyTrendsChartKey);

  //     final pdfBytes = await _generatePdfReport(
  //         reportData, categoryChartBytes, monthlyTrendsChartBytes);

  //     await FileSaver.instance.saveFile(
  //       name:
  //           'system-report-${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
  //       bytes: pdfBytes,
  //       ext: 'pdf',
  //       mimeType: MimeType.pdf,
  //     );

  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Report saved successfully')),
  //       );
  //     }
  //   } catch (e) {
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error generating report: $e')),
  //       );
  //     }
  //   }
  // }

  // /// Share report via email or WhatsApp (PDF attachment)
  // Future<void> _shareReport(
  //     BuildContext context, Map<String, dynamic>? reportData) async {
  //   if (reportData == null) return;

  //   try {
  //     final categoryChartBytes = await _captureChartAsImage(_categoryChartKey);
  //     final monthlyTrendsChartBytes =
  //         await _captureChartAsImage(_monthlyTrendsChartKey);

  //     final pdfBytes = await _generatePdfReport(
  //         reportData, categoryChartBytes, monthlyTrendsChartBytes);

  //     // Save temporarily
  //     final dir = await getTemporaryDirectory();
  //     final filePath =
  //         '${dir.path}/system-report-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
  //     final file = File(filePath);
  //     await file.writeAsBytes(pdfBytes);

  //     await Share.shareXFiles(
  //       [XFile(filePath)],
  //       subject: "Inventory System Report",
  //       text: "Please find the attached report.",
  //     );
  //   } catch (e) {
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error sharing report: $e')),
  //       );
  //     }
  //   }
  // }

  // /// Share Report via Email
  // Future<void> _shareViaEmail(
  //     BuildContext context, Map<String, dynamic>? reportData) async {
  //   if (reportData == null) return;

  //   try {
  //     final categoryChartBytes = await _captureChartAsImage(_categoryChartKey);
  //     final monthlyTrendsChartBytes =
  //         await _captureChartAsImage(_monthlyTrendsChartKey);

  //     final pdfBytes = await _generatePdfReport(
  //         reportData, categoryChartBytes, monthlyTrendsChartBytes);

  //     final dir = await getTemporaryDirectory();
  //     final filePath =
  //         '${dir.path}/system-report-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
  //     final file = File(filePath);
  //     await file.writeAsBytes(pdfBytes);

  //     await Share.shareXFiles(
  //       [XFile(filePath)],
  //       subject: "Inventory System Report",
  //       text: "Please find the attached Inventory System Report.",
  //     );
  //   } catch (e) {
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error sharing via Email: $e')),
  //       );
  //     }
  //   }
  // }

  // /// Share Report via WhatsApp
  // Future<void> _shareViaWhatsApp(
  //     BuildContext context, Map<String, dynamic>? reportData) async {
  //   if (reportData == null) return;

  //   try {
  //     final categoryChartBytes = await _captureChartAsImage(_categoryChartKey);
  //     final monthlyTrendsChartBytes =
  //         await _captureChartAsImage(_monthlyTrendsChartKey);

  //     final pdfBytes = await _generatePdfReport(
  //         reportData, categoryChartBytes, monthlyTrendsChartBytes);

  //     final dir = await getTemporaryDirectory();
  //     final filePath =
  //         '${dir.path}/system-report-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
  //     final file = File(filePath);
  //     await file.writeAsBytes(pdfBytes);

  //     await Share.shareXFiles(
  //       [XFile(filePath)],
  //       subject: "Inventory System Report",
  //       text: "📊 Inventory System Report attached as PDF",
  //     );
  //   } catch (e) {
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error sharing via WhatsApp: $e')),
  //       );
  //     }
  //   }
  // }

  Future<void> _shareViaEmail(
          BuildContext context, Map<String, dynamic>? data) =>
      _shareReport(context, data);

  Future<void> _shareViaWhatsApp(
          BuildContext context, Map<String, dynamic>? data) =>
      _shareReport(context, data);

  /// Download report with file save dialog
  Future<void> _downloadReport(
      BuildContext context, Map<String, dynamic>? reportData) async {
    if (reportData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No report data available')),
      );
      return;
    }

    try {
      final categoryChartBytes = await _captureChartAsImage(_categoryChartKey);
      final monthlyTrendsChartBytes =
          await _captureChartAsImage(_monthlyTrendsChartKey);

      // Generate PDF
      final pdfBytes = await _generatePdfReport(
        reportData,
        categoryChartBytes,
        monthlyTrendsChartBytes,
        Theme.of(context).primaryColor,
      );

      // Let user pick save location
      await FileSaver.instance.saveAs(
        name:
            'system-report-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
        ext: 'pdf',
        bytes: pdfBytes,
        mimeType: MimeType.pdf,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Share report (email/WhatsApp) as PDF attachment
  Future<void> _shareReport(
      BuildContext context, Map<String, dynamic>? reportData) async {
    if (reportData == null) return;

    try {
      final categoryChartBytes = await _captureChartAsImage(_categoryChartKey);
      final monthlyTrendsChartBytes =
          await _captureChartAsImage(_monthlyTrendsChartKey);

      // Generate PDF
      final pdfBytes = await _generatePdfReport(
        reportData,
        categoryChartBytes,
        monthlyTrendsChartBytes,
        Theme.of(context).primaryColor,
      );

      // Save temporarily
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/system-report-${DateFormat('yyyy-MM-dd-HHmmss').format(DateTime.now())}.pdf';
      final file = File(path);
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Inventory System Report',
        text: 'Please find the attached report.',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Capture a widget wrapped in RepaintBoundary (by its GlobalKey) as PNG bytes.
  /// Use key: _categoryChartKey or _monthlyTrendsChartKey (defined in your State)
  Future<Uint8List?> captureRepaintBoundaryImage(GlobalKey key) async {
    try {
      if (key.currentContext == null) return null;
      final renderObject = key.currentContext!.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        return null;
      }

      final boundary = renderObject;

      // Wait a tick for paints/layouts if needed
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e, st) {
      debugPrint('captureRepaintBoundaryImage error: $e\n$st');
      return null;
    }
  }

  /// Convert Flutter color (int) to PdfColor
  PdfColor _pdfColorFromInt(int colorInt) {
    final a = (colorInt >> 24) & 0xFF;
    final r = (colorInt >> 16) & 0xFF;
    final g = (colorInt >> 8) & 0xFF;
    final b = colorInt & 0xFF;
    // PdfColor uses 0..1
    return PdfColor.fromInt(colorInt);
  }

  /// Draw a small fallback bar chart in the PDF when we couldn't capture the UI chart.
  /// monthlyData: List<Map<String, dynamic>> with keys 'month' and 'value'
  pdfw.Widget _pdfFallbackBarChart(List<Map<String, dynamic>> monthlyData,
      {double height = 120}) {
    if (monthlyData.isEmpty) {
      return pdfw.Container(
        height: height,
        alignment: pdfw.Alignment.center,
        child: pdfw.Text('No monthly trend data',
            style: pdfw.TextStyle(fontSize: 10, color: PdfColors.grey)),
      );
    }

    final values = monthlyData.map((m) {
      final val = m['value'];
      if (val is int) return val.toDouble();
      if (val is double) return val;
      if (val is num) return val.toDouble();
      return 0.0;
    }).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final bars = <pdfw.Widget>[];
    for (var i = 0; i < monthlyData.length; i++) {
      final label = monthlyData[i]['month']?.toString() ?? '';
      final v = values[i];
      final heightRatio = maxVal == 0.0 ? 0.0 : (v / maxVal);
      bars.add(
        pdfw.Column(
          mainAxisAlignment: pdfw.MainAxisAlignment.end,
          children: [
            pdfw.Container(
              width: 12,
              height: height * 0.7 * heightRatio + 2,
              decoration: pdfw.BoxDecoration(
                color: PdfColors.blue300,
                borderRadius:
                    const pdfw.BorderRadius.all(pdfw.Radius.circular(3)),
              ),
            ),
            pdfw.SizedBox(height: 6),
            pdfw.Container(
              width: 28,
              child: pdfw.Text(label,
                  textAlign: pdfw.TextAlign.center,
                  style: const pdfw.TextStyle(fontSize: 8)),
            )
          ],
        ),
      );
    }

    return pdfw.Container(
      height: height,
      child: pdfw.Row(
        crossAxisAlignment: pdfw.CrossAxisAlignment.end,
        mainAxisAlignment: pdfw.MainAxisAlignment.spaceEvenly,
        children: bars,
      ),
    );
  }

  /// Draw a small fallback pie legend (percent list) when the pie chart didn't capture
  pdfw.Widget _pdfFallbackPieLegend(Map<String, dynamic> categoryStats) {
    if (categoryStats.isEmpty) {
      return pdfw.Container(
          child: pdfw.Text('No category data',
              style: const pdfw.TextStyle(fontSize: 10)));
    }

    final total = categoryStats.values.fold<num>(0, (s, v) => s + (v as num));
    final colors = [
      PdfColors.blue,
      PdfColors.green,
      PdfColors.orange,
      PdfColors.red,
      PdfColors.purple
    ];

    final rows = <pdfw.Widget>[];
    int idx = 0;
    for (final e in categoryStats.entries) {
      final percent =
          (total == 0) ? 0 : (((e.value as num) / total) * 100).round();
      final color = colors[idx % colors.length];
      rows.add(
        pdfw.Row(
          children: [
            pdfw.Container(
                width: 10,
                height: 10,
                decoration: pdfw.BoxDecoration(
                    color: color, shape: pdfw.BoxShape.rectangle)),
            pdfw.SizedBox(width: 6),
            pdfw.Expanded(
                child: pdfw.Text(e.key,
                    style: const pdfw.TextStyle(fontSize: 10))),
            pdfw.Text('${e.value} ($percent%)',
                style: const pdfw.TextStyle(fontSize: 10)),
          ],
        ),
      );
      rows.add(pdfw.SizedBox(height: 6));
      idx++;
    }

    return pdfw.Column(children: rows);
  }

  /// Build the full PDF bytes. This is the core function — it constructs a professional-looking multi-page PDF.
  Future<Uint8List> buildFullReportPdf({
    required Map<String, dynamic> reportData,
    required Uint8List? categoryChartImageBytes,
    required Uint8List? monthlyTrendsImageBytes,
    Color?
        themeColor, // optional Flutter color (use Theme.of(context).primaryColor in caller)
    Uint8List? logoBytes, // optional organization logo bytes (PNG)
  }) async {
    final stats = (reportData['dashboardStats'] as Map<String, dynamic>?) ?? {};
    final categoryStats =
        (reportData['categoryStats'] as Map<String, dynamic>?) ?? {};
    final items = (reportData['items'] as List<dynamic>?) ?? [];
    final movements = (reportData['movements'] as List<dynamic>?) ?? [];
    final monthlyTrends = (reportData['monthlyTrends'] as List<dynamic>?) ?? [];
    final generatedAt =
        reportData['generatedAt'] as DateTime? ?? DateTime.now();
    final orgName =
        reportData['organization'] as String? ?? 'Your Organization';
    final orgContact = reportData['organizationContact'] as String? ?? '';

    PdfColor pdfColorFromFlutter(Color color) {
      return PdfColor.fromInt(color.toARGB32());
    }

    // Resolve theme color for PDF
    // final pdfThemeColor = themeColor != null
    //     ? PdfColor.fromInt(themeColor.toARGB32())
    //     : PdfColors.teal; // fallback

    final pdfThemeColor =
        themeColor != null ? pdfColorFromFlutter(themeColor) : PdfColors.teal;

    final pdf = pdfw.Document();

    // Helper to render the metric card in the PDF
    pdfw.Widget metricCard(String label, String value, {PdfColor? accent}) {
      final accentColor = accent ?? pdfThemeColor;
      return pdfw.Container(
        padding: const pdfw.EdgeInsets.all(10),
        decoration: pdfw.BoxDecoration(
          borderRadius: const pdfw.BorderRadius.all(pdfw.Radius.circular(8)),
          // color: _pdfFromFlutterColor(accentColor, opacity: 0.08), // fixed
          color: accentColor, // fixed
          border: pdfw.Border.all(
            // color: _pdfFromFlutterColor(accentColor, opacity: 0.18), // fixed
            color: accentColor, // fixed
          ),
        ),
        child: pdfw.Column(
          crossAxisAlignment: pdfw.CrossAxisAlignment.start,
          children: [
            pdfw.Text(
              value,
              style: pdfw.TextStyle(
                fontSize: 16,
                fontWeight: pdfw.FontWeight.bold,
                // color: _pdfFromFlutterColor(accentColor), // fixed
                color: accentColor, // fixed
              ),
            ),
            pdfw.SizedBox(height: 6),
            pdfw.Text(
              label,
              style: const pdfw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      );
    }

    // Convert monthlyTrends to standard list of {month, value}
    List<Map<String, dynamic>> monthlyList = [];
    try {
      for (final e in monthlyTrends) {
        if (e is Map<String, dynamic>) {
          monthlyList.add(e);
        } else if (e is Map) monthlyList.add(Map<String, dynamic>.from(e));
      }
    } catch (_) {}

    pdf.addPage(
      pdfw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pdfw.EdgeInsets.all(28),
        header: (pdfw.Context ctx) {
          return pdfw.Row(
            mainAxisAlignment: pdfw.MainAxisAlignment.spaceBetween,
            children: [
              // optional logo
              if (logoBytes != null)
                pdfw.Container(
                  width: 80,
                  height: 40,
                  child: pdfw.Image(pdfw.MemoryImage(logoBytes)),
                )
              else
                pdfw.Container(
                  padding: const pdfw.EdgeInsets.symmetric(
                      vertical: 6, horizontal: 10),
                  decoration: pdfw.BoxDecoration(
                    color: pdfThemeColor,
                    borderRadius:
                        const pdfw.BorderRadius.all(pdfw.Radius.circular(6)),
                  ),
                  child: pdfw.Text(orgName,
                      style: pdfw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                          fontWeight: pdfw.FontWeight.bold)),
                ),
              pdfw.Column(
                crossAxisAlignment: pdfw.CrossAxisAlignment.end,
                children: [
                  pdfw.Text(
                      DateFormat('MMMM d, yyyy • h:mm a').format(generatedAt),
                      style: const pdfw.TextStyle(
                          fontSize: 9, color: PdfColors.grey600)),
                  if (orgContact.isNotEmpty)
                    pdfw.Text(orgContact,
                        style: const pdfw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
        footer: (pdfw.Context ctx) {
          return pdfw.Container(
            alignment: pdfw.Alignment.centerRight,
            child: pdfw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style:
                    const pdfw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          );
        },
        build: (pdfw.Context context) {
          final children = <pdfw.Widget>[];

          // Title
          children.add(
            pdfw.Row(
              mainAxisAlignment: pdfw.MainAxisAlignment.spaceBetween,
              children: [
                pdfw.Text('System Inventory Report',
                    style: pdfw.TextStyle(
                        fontSize: 20, fontWeight: pdfw.FontWeight.bold)),
                pdfw.Container(
                  padding: const pdfw.EdgeInsets.symmetric(
                      vertical: 6, horizontal: 10),
                  decoration: pdfw.BoxDecoration(
                    borderRadius:
                        const pdfw.BorderRadius.all(pdfw.Radius.circular(6)),
                    color: pdfThemeColor,
                  ),
                  child: pdfw.Text('CONFIDENTIAL',
                      style: const pdfw.TextStyle(
                          fontSize: 9, color: PdfColors.white)),
                )
              ],
            ),
          );
          children.add(pdfw.SizedBox(height: 12));
          children.add(pdfw.Text(
              'Generated on ${DateFormat('MMMM d, yyyy • h:mm a').format(generatedAt)}',
              style: const pdfw.TextStyle(
                  fontSize: 10, color: PdfColors.grey700)));
          children.add(pdfw.SizedBox(height: 18));

          // Metric cards: render a 2x2 grid
          final totalItems = (stats['totalItems'] ?? 0).toString();
          final totalValue =
              '\$${NumberFormat('#,##0.00').format(((stats['totalValue'] ?? 0) as num).toDouble())}';
          final lowStock = (stats['lowStockItems'] ?? 0).toString();
          final outOfStock = (stats['outOfStockItems'] ?? 0).toString();

          children.add(
            pdfw.Row(
              mainAxisAlignment: pdfw.MainAxisAlignment.spaceBetween,
              children: [
                pdfw.Expanded(
                    child: metricCard('Total Items', totalItems,
                        accent: pdfThemeColor)),
                pdfw.SizedBox(width: 12),
                pdfw.Expanded(
                    child: metricCard('Total Value', totalValue,
                        accent: PdfColors.green600)),
                pdfw.SizedBox(width: 12),
                pdfw.Expanded(
                    child: metricCard('Low Stock Items', lowStock,
                        accent: PdfColors.orange)),
              ],
            ),
          );
          children.add(pdfw.SizedBox(height: 12));
          children.add(
            pdfw.Row(
              children: [
                pdfw.Expanded(
                    child: metricCard('Out of Stock', outOfStock,
                        accent: PdfColors.red)),
                // leave empty space on right for balance
                pdfw.SizedBox(width: 12),
                pdfw.Expanded(child: pdfw.Container()),
                pdfw.SizedBox(width: 12),
                pdfw.Expanded(child: pdfw.Container()),
              ],
            ),
          );

          children.add(pdfw.SizedBox(height: 20));

          // Two-column: left = category chart + table, right = monthly trend + insights
          children.add(
            pdfw.Row(
              crossAxisAlignment: pdfw.CrossAxisAlignment.start,
              children: [
                // Left column
                pdfw.Expanded(
                  flex: 2,
                  child: pdfw.Column(
                    crossAxisAlignment: pdfw.CrossAxisAlignment.start,
                    children: [
                      // Category chart
                      pdfw.Text('Items by Category',
                          style: pdfw.TextStyle(
                              fontSize: 14, fontWeight: pdfw.FontWeight.bold)),
                      pdfw.SizedBox(height: 8),
                      if (categoryChartImageBytes != null)
                        pdfw.Container(
                            height: 180,
                            child: pdfw.Image(
                                pdfw.MemoryImage(categoryChartImageBytes)))
                      else
                        // fallback legend + small graphic
                        pdfw.Container(
                          padding: const pdfw.EdgeInsets.all(8),
                          height: 180,
                          decoration: pdfw.BoxDecoration(
                            border: pdfw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pdfw.BorderRadius.all(
                                pdfw.Radius.circular(6)),
                          ),
                          child: pdfw.Row(
                            children: [
                              pdfw.Expanded(
                                  child: _pdfFallbackBarChart(monthlyList,
                                      height: 140)),
                              pdfw.SizedBox(width: 8),
                              pdfw.Expanded(
                                  child: _pdfFallbackPieLegend(categoryStats)),
                            ],
                          ),
                        ),

                      pdfw.SizedBox(height: 12),

                      // Category table (compact)
                      if (categoryStats.isNotEmpty)
                        pdfw.Column(
                          crossAxisAlignment: pdfw.CrossAxisAlignment.start,
                          children: [
                            pdfw.Text('Category Breakdown',
                                style: pdfw.TextStyle(
                                    fontWeight: pdfw.FontWeight.bold)),
                            pdfw.SizedBox(height: 8),
                            pdfw.TableHelper.fromTextArray(
                              headers: ['Category', 'Count'],
                              data: categoryStats.entries
                                  .map((e) => [e.key, e.value.toString()])
                                  .toList(),
                              headerStyle: pdfw.TextStyle(
                                  fontWeight: pdfw.FontWeight.bold,
                                  color: PdfColors.white),
                              headerDecoration: const pdfw.BoxDecoration(
                                  color: PdfColors.blueGrey800),
                              cellHeight: 22,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                pdfw.SizedBox(width: 12),

                // Right column
                pdfw.Expanded(
                  flex: 2,
                  child: pdfw.Column(
                    crossAxisAlignment: pdfw.CrossAxisAlignment.start,
                    children: [
                      // Monthly trends
                      pdfw.Text('Monthly Activity Trends',
                          style: pdfw.TextStyle(
                              fontSize: 14, fontWeight: pdfw.FontWeight.bold)),
                      pdfw.SizedBox(height: 8),
                      if (monthlyTrendsImageBytes != null)
                        pdfw.Container(
                            height: 180,
                            child: pdfw.Image(
                                pdfw.MemoryImage(monthlyTrendsImageBytes)))
                      else
                        pdfw.Container(
                          padding: const pdfw.EdgeInsets.all(8),
                          height: 180,
                          decoration: pdfw.BoxDecoration(
                            border: pdfw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pdfw.BorderRadius.all(
                                pdfw.Radius.circular(6)),
                          ),
                          child: _pdfFallbackBarChart(monthlyList, height: 150),
                        ),

                      pdfw.SizedBox(height: 12),

                      // Insights
                      pdfw.Text('Top Insights',
                          style: pdfw.TextStyle(
                              fontSize: 12, fontWeight: pdfw.FontWeight.bold)),
                      pdfw.SizedBox(height: 8),
                      pdfw.Bullet(
                          text:
                              'Low stock items (${stats['lowStockItems'] ?? 0}) require attention.'),
                      pdfw.Bullet(
                          text:
                              'Out-of-stock items (${stats['outOfStockItems'] ?? 0}) should be restocked immediately.'),
                      pdfw.Bullet(
                          text:
                              'Top category: ${_getTopCategoryName(categoryStats)}'),
                      pdfw.SizedBox(height: 12),

                      // Top items by value
                      pdfw.Text('Top Items by Value',
                          style: pdfw.TextStyle(
                              fontSize: 12, fontWeight: pdfw.FontWeight.bold)),
                      pdfw.SizedBox(height: 8),
                      if (items.isNotEmpty)
                        pdfw.TableHelper.fromTextArray(
                          headers: ['Item', 'Qty', 'Unit Price', 'Value'],
                          data: _buildTopItemsTable(items),
                          headerStyle: pdfw.TextStyle(
                              fontWeight: pdfw.FontWeight.bold,
                              color: PdfColors.white),
                          headerDecoration: const pdfw.BoxDecoration(
                              color: PdfColors.blueGrey800),
                          cellHeight: 20,
                        )
                      else
                        pdfw.Text('No items data available',
                            style: const pdfw.TextStyle(color: PdfColors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          );

          // Optionally add recent movements table below on second page if needed
          if (movements.isNotEmpty) {
            children.add(pdfw.SizedBox(height: 18));
            children.add(pdfw.Text('Recent Stock Movements',
                style: pdfw.TextStyle(
                    fontSize: 14, fontWeight: pdfw.FontWeight.bold)));
            children.add(pdfw.SizedBox(height: 8));

            final movementRows = <List<dynamic>>[];
            for (final m in movements.take(20)) {
              final name = (m.itemName ?? m.name ?? 'Unknown').toString();
              final qty = (m.quantity ?? 0).toString();
              final type = (m.type ?? 'N/A').toString();
              final time = (m.timestamp is DateTime)
                  ? DateFormat('yyyy-MM-dd • h:mm a')
                      .format(m.timestamp as DateTime)
                  : (m.timestamp?.toString() ?? '');
              movementRows.add([name, qty, type, time]);
            }

            // for (final m in movements.take(20)) {
            //   final name = m.itemName ?? m.name ?? 'Unknown';
            //   final qty = m.quantity?.toString() ?? '0';
            //   final type = m.type ?? 'N/A';
            //   final time = (m.timestamp is DateTime)
            //       ? DateFormat('yyyy-MM-dd • h:mm a').format(m.timestamp!)
            //       : '';
            //   movementRows.add([name, qty, type, time]);
            // }

            children.add(
              pdfw.TableHelper.fromTextArray(
                headers: ['Item', 'Qty', 'Type', 'Timestamp'],
                data: movementRows,
                headerStyle: pdfw.TextStyle(
                    fontWeight: pdfw.FontWeight.bold, color: PdfColors.white),
                headerDecoration:
                    const pdfw.BoxDecoration(color: PdfColors.blueGrey800),
                cellHeight: 20,
              ),
            );
          }

          return children;
        },
      ),
    );

    return pdf.save();
  }

  /// Helper: sort and produce rows for top items table
  List<List<dynamic>> _buildTopItemsTable(List<dynamic> items) {
    try {
      final itemList = items.map((i) {
        if (i is Map<String, dynamic>) return i;
        // If InventoryItem objects exist, attempt to access by property names
        // but keep safe:
        return {
          'name': i?.name?.toString() ?? i?.toString() ?? 'Item',
          'quantity': i?.quantity ?? 0,
          'unitPrice': i?.unitPrice ?? 0.0,
        };
      }).toList();

      itemList.sort((a, b) {
        final va =
            ((a['quantity'] ?? 0) as num) * ((a['unitPrice'] ?? 0.0) as num);
        final vb =
            ((b['quantity'] ?? 0) as num) * ((b['unitPrice'] ?? 0.0) as num);
        return vb.compareTo(va);
      });

      final rows = <List<dynamic>>[];
      for (final it in itemList.take(10)) {
        final name = it['name'] ?? 'Item';
        final qty = (it['quantity'] ?? 0).toString();
        final unitPrice = (it['unitPrice'] ?? 0.0) as num;
        final value = (unitPrice * (it['quantity'] ?? 0));
        rows.add([
          name,
          qty,
          '\$${(unitPrice).toStringAsFixed(2)}',
          '\$${(value).toStringAsFixed(2)}'
        ]);
      }
      return rows;
    } catch (e) {
      return [];
    }
  }

  /// Helper to pick top category name
  String _getTopCategoryName(Map<String, dynamic> stats) {
    try {
      if (stats.isEmpty) return 'N/A';
      final list = stats.entries.toList();
      list.sort((a, b) => (b.value as num).compareTo(a.value as num));
      return list.first.key;
    } catch (e) {
      return 'N/A';
    }
  }

  /// ----------------------------
  /// Methods to wire into your State
  /// ----------------------------

  /// Download (save) PDF — captures charts, builds PDF, and lets user save
  // Future<void> saveReportPdfFromState({
  //   required BuildContext context,
  //   required Map<String, dynamic> reportData,
  //   required GlobalKey categoryChartKey,
  //   required GlobalKey monthlyTrendsKey,
  //   Color? themeColor,
  //   Uint8List? logoBytes,
  // }) async {
  //   try {
  //     final categoryChart = await captureRepaintBoundaryImage(categoryChartKey);
  //     final monthlyChart = await captureRepaintBoundaryImage(monthlyTrendsKey);

  //     final bytes = await buildFullReportPdf(
  //       reportData: reportData,
  //       categoryChartImageBytes: categoryChart,
  //       monthlyTrendsImageBytes: monthlyChart,
  //       themeColor: themeColor,
  //       logoBytes: logoBytes,
  //     );

  //     // Use FileSaver to let user pick save location cross-platform
  //     await FileSaver.instance.saveFile(
  //       name:
  //           'system-report-${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
  //       bytes: bytes,
  //       ext: 'pdf',
  //       mimeType: MimeType.pdf,
  //     );

  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Report saved successfully')));
  //     }
  //   } catch (e) {
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context)
  //           .showSnackBar(SnackBar(content: Text('Error saving report: $e')));
  //     }
  //   }
  // }

  Future<void> saveReportPdfFromState({
    required BuildContext context,
    required Map<String, dynamic> reportData,
    required GlobalKey categoryChartKey,
    required GlobalKey monthlyTrendsKey,
    required Color themeColor,
    Uint8List? logoBytes, // not used currently but kept for future extension
  }) async {
    try {
      // Capture chart images
      final categoryChartBytes = await _captureChartAsImage(categoryChartKey);
      final monthlyTrendsChartBytes =
          await _captureChartAsImage(monthlyTrendsKey);

      // Generate PDF (positional arguments, no named params)
      final pdfBytes = await _generatePdfReport(reportData, categoryChartBytes,
          monthlyTrendsChartBytes, Theme.of(context).primaryColor);

      // Save with Save Dialog (lets user pick location)
      await FileSaver.instance.saveAs(
        name:
            'system-report-${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
        bytes: pdfBytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report saved successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving report: $e')),
        );
      }
    }
  }

  /// Share the PDF as an attachment (email, WhatsApp, etc.)
  Future<void> shareReportPdfFromState({
    required BuildContext context,
    required Map<String, dynamic> reportData,
    required GlobalKey categoryChartKey,
    required GlobalKey monthlyTrendsKey,
    Color? themeColor,
    Uint8List? logoBytes,
  }) async {
    try {
      final categoryChart = await captureRepaintBoundaryImage(categoryChartKey);
      final monthlyChart = await captureRepaintBoundaryImage(monthlyTrendsKey);

      final bytes = await buildFullReportPdf(
        reportData: reportData,
        categoryChartImageBytes: categoryChart,
        monthlyTrendsImageBytes: monthlyChart,
        themeColor: themeColor,
        logoBytes: logoBytes,
      );

      final tmpDir = await getTemporaryDirectory();
      final tmpPath =
          '${tmpDir.path}/system-report-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
      final tmpFile = File(tmpPath);
      await tmpFile.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(tmpPath)],
          subject: 'Inventory System Report',
          text: 'Please find attached the system inventory report (PDF).');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error sharing report: $e')));
      }
    }
  }

  void _showImagePreview(BuildContext context, String? imageUrl, String title) {
    if (imageUrl == null || imageUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                    color: Colors.black87,
                    child: Center(
                      child: InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: _buildPreviewImage(imageUrl),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewImage(String imageUrl) {
    // Handle base64 data URLs
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load base64 image',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            );
          },
        );
      } catch (e) {
        debugPrint('Error decoding base64 preview image: $e');
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.white54,
              ),
              SizedBox(height: 16),
              Text(
                'Invalid base64 image format',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        );
      }
    } else {
      // Handle network URLs
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading image...',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading network preview image: $error');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white54,
                ),
                SizedBox(height: 16),
                Text(
                  'Failed to load network image',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildStockMovementAvatar(dynamic movement, InventoryItem? item) {
    final isStockIn = movement.type == MovementType.stockIn;

    // Fallback to the stock in/out icon
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isStockIn ? Colors.green[100] : Colors.red[100],
      ),
      child: Icon(
        isStockIn ? Icons.add_circle : Icons.remove_circle,
        color: isStockIn ? Colors.green : Colors.red,
      ),
    );
  }
}
