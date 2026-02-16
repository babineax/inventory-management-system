import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/inventory_item.dart';
import '../services/expiry_notification_service.dart';
import '../services/auth_service.dart';
import '../widgets/loading_widget.dart';
import '../screens/auth/widget_tree.dart';
import '../utils/date_utils.dart' as CustomDateUtils;

class ExpiryAlertsScreen extends StatefulWidget {
  const ExpiryAlertsScreen({super.key});

  @override
  State<ExpiryAlertsScreen> createState() => _ExpiryAlertsScreenState();
}

class _ExpiryAlertsScreenState extends State<ExpiryAlertsScreen> {
  bool _isLoading = true;
  bool _isAuthenticating = true;
  List<InventoryItem> _expiringItems = [];
  List<InventoryItem> _expiredItems = [];
  List<InventoryItem> _immediateAttentionItems = [];
  String _filter = 'all'; // all, immediate, expiring, expired

  Timer? _authTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _initializeAuthentication();
  }

  @override
  void dispose() {
    _authTimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeAuthentication() async {
    // Set a timeout for authentication check
    bool timeoutReached = false;

    // Create a timer for timeout
    _authTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isAuthenticating) {
        timeoutReached = true;
        setState(() {
          _isAuthenticating = false;
        });

        // Show error and redirect
        _showAuthError();
      }
    });

    // Wait for Firebase Auth to initialize
    await Future.delayed(const Duration(milliseconds: 100));

    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted || timeoutReached) return;

      setState(() {
        _isAuthenticating = false;
      });

      if (user == null) {
        // User not authenticated, redirect to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const WidgetTree(),
          ),
        );
      } else {
        // User is authenticated, load data
        _loadExpiryData();
      }
    });
  }

  void _showAuthError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Authentication check timed out. Please restart the app.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkAuthenticationAndLoadData() async {
    // Check authentication first
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      // User not authenticated, redirect to login
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const WidgetTree(),
          ),
        );
      }
      return;
    }

    // User is authenticated, load data
    await _loadExpiryData();
  }

  Future<void> _loadExpiryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check authentication state
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final appUser = AuthService.currentUser;

      // Load expiring items (within 180 days)
      final expiringItems = await ExpiryNotificationService.getExpiringItems();

      // Load expired items
      final expiredItems = await ExpiryNotificationService.getExpiredItems();

      // Load items needing immediate attention (food items ≤6 months)
      final immediateAttentionItems =
          await ExpiryNotificationService.getItemsNeedingImmediateAttention();

      if (mounted) {
        setState(() {
          _expiringItems = expiringItems;
          _expiredItems = expiredItems;
          _immediateAttentionItems = immediateAttentionItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show more detailed error for debugging
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load expiry data: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadExpiryData();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final clampedTextScaler =
        mediaQuery.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedTextScaler),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Expiry Alerts',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _isAuthenticating
            ? const LoadingWidget()
            : _isLoading
                ? const LoadingWidget()
                : (FirebaseAuth.instance.currentUser == null)
                    ? _buildAuthRequiredState()
                    : (_expiringItems.isEmpty &&
                            _expiredItems.isEmpty &&
                            _immediateAttentionItems.isEmpty)
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _refreshData,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  _buildFilterChips(),
                                  const SizedBox(height: 16),
                                  _buildSummaryCards(),
                                  const SizedBox(height: 20),
                                  if (_filter == 'all' ||
                                      _filter == 'immediate')
                                    _buildImmediateAttentionSection(),
                                  if (_filter == 'all' || _filter == 'expiring')
                                    _buildExpiringItemsSection(),
                                  if (_filter == 'all' || _filter == 'expired')
                                    _buildExpiredItemsSection(),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
      ),
    );
  }

  Widget _buildAuthRequiredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.login,
            size: 64,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white38
                : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Authentication Required',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please log in to view expiry alerts',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white38
                  : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white38
                : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No expiry alerts found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All your items are up to date!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white38
                  : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: Text(
                'All',
                style: GoogleFonts.poppins(
                  color: _filter == 'all'
                      ? Colors.white
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[700]),
                ),
              ),
              selected: _filter == 'all',
              selectedColor: Theme.of(context).primaryColor,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
              onSelected: (selected) {
                setState(() {
                  _filter = selected ? 'all' : 'all';
                });
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(
                'Urgent',
                style: GoogleFonts.poppins(
                  color: _filter == 'immediate'
                      ? Colors.white
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[700]),
                ),
              ),
              selected: _filter == 'immediate',
              selectedColor: Colors.deepOrange,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
              onSelected: (selected) {
                setState(() {
                  _filter = selected ? 'immediate' : 'all';
                });
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(
                'Expiring Soon',
                style: GoogleFonts.poppins(
                  color: _filter == 'expiring'
                      ? Colors.white
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[700]),
                ),
              ),
              selected: _filter == 'expiring',
              selectedColor: Theme.of(context).primaryColor,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
              onSelected: (selected) {
                setState(() {
                  _filter = selected ? 'expiring' : 'all';
                });
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(
                'Expired',
                style: GoogleFonts.poppins(
                  color: _filter == 'expired'
                      ? Colors.white
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[700]),
                ),
              ),
              selected: _filter == 'expired',
              selectedColor: Colors.red,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
              onSelected: (selected) {
                setState(() {
                  _filter = selected ? 'expired' : 'all';
                });
              },
            ),
            const SizedBox(width: 16), // Extra space at the end
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Expiring items card
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.warning,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                        size: isSmallScreen ? 19 : 23,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _expiringItems.length.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 19 : 23,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expiring Soon',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white60
                            : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 16),

          // Expired items card
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.error,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.red,
                        size: isSmallScreen ? 19 : 23,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _expiredItems.length.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 19 : 23,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expired',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white60
                            : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiringItemsSection() {
    if (_expiringItems.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort items by priority: critical (≤7 days) first, then urgent (8-30 days), then moderate (>30 days)
    final sortedItems = List<InventoryItem>.from(_expiringItems)
      ..sort((a, b) {
        // First, handle null expiry dates
        if (a.expiryDate == null && b.expiryDate == null) return 0;
        if (a.expiryDate == null) return 1;
        if (b.expiryDate == null) return -1;

        final daysA = a.expiryDate!.difference(DateTime.now()).inDays;
        final daysB = b.expiryDate!.difference(DateTime.now()).inDays;

        // Define priority levels
        int getPriority(int days) {
          if (days <= 7) return 0; // Critical
          if (days <= 30) return 1; // Urgent
          return 2; // Moderate
        }

        final priorityA = getPriority(daysA);
        final priorityB = getPriority(daysB);

        // Sort by priority first, then by expiry date
        if (priorityA != priorityB) {
          return priorityA.compareTo(priorityB);
        }

        // Same priority, sort by expiry date (closest first)
        return daysA.compareTo(daysB);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Expiring Soon',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: sortedItems
              .map((item) => _buildExpiryItemCard(item, isExpired: false))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildExpiredItemsSection() {
    if (_expiredItems.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort items by how long ago they expired: most recently expired first
    final sortedItems = List<InventoryItem>.from(_expiredItems)
      ..sort((a, b) {
        // First, handle null expiry dates
        if (a.expiryDate == null && b.expiryDate == null) return 0;
        if (a.expiryDate == null) return 1;
        if (b.expiryDate == null) return -1;

        final daysExpiredA = DateTime.now().difference(a.expiryDate!).inDays;
        final daysExpiredB = DateTime.now().difference(b.expiryDate!).inDays;

        // Sort by how recently expired (most recent first)
        // Items expired today (0 days) come first, then 1 day ago, etc.
        return daysExpiredA.compareTo(daysExpiredB);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Expired Items',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: sortedItems
              .map((item) => _buildExpiryItemCard(item, isExpired: true))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildExpiryItemCard(InventoryItem item,
      {required bool isExpired, bool isUrgent = false}) {
    final daysUntilExpiry = item.daysUntilExpiry ?? 0;
    final statusMessage =
        CustomDateUtils.DateUtils.formatExpiryStatus(daysUntilExpiry);

    Color cardColor;
    String statusText;

    if (daysUntilExpiry < 0 || isExpired) {
      cardColor = Colors.red;
      statusText = 'EXPIRED';
    } else if (isUrgent) {
      cardColor = Colors.deepOrange;
      final isFoodItem = item.category.toLowerCase().contains('food') ||
          item.category.toLowerCase().contains('beverage');
      statusText = 'URGENT ATTENTION';
      if (!isFoodItem) {
        statusText += ' - URGENT!';
      }
    } else {
      if (daysUntilExpiry <= 7) {
        cardColor = Colors.red;
        statusText = 'EXPIRES SOON';
      } else if (daysUntilExpiry <= 30) {
        cardColor = Colors.orange;
        statusText = 'EXPIRES THIS MONTH';
      } else {
        cardColor = Colors.green;
        statusText = 'EXPIRES LATER';
      }
    }

    final expiryColor = _getExpiryColor(daysUntilExpiry);
    final expiryIcon = _getExpiryIcon(daysUntilExpiry);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with image and basic info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with status overlay
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? _buildExpiryItemImage(item)
                          : Icon(
                              Icons.inventory_2,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white60
                                  : Colors.grey[500],
                              size: 24,
                            ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: expiryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Theme.of(context).cardColor, width: 2),
                        ),
                        child: Icon(
                          expiryIcon,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Item name and category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.grey[900],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.category,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Quantity
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item.quantity}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status and expiry information row
            Row(
              children: [
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cardColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        expiryIcon,
                        color: cardColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: cardColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Expiry date information
                if (item.expiryDate != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy').format(item.expiryDate!),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.grey[800],
                        ),
                      ),
                      Text(
                        statusMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: _getExpiryColor(daysUntilExpiry),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'No expiry date',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white60
                          : Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),

            // Additional expiry details for urgent items
            if (isUrgent && item.expiryDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cardColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: cardColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        daysUntilExpiry < 0
                            ? 'Expired ${daysUntilExpiry.abs()} days ago'
                            : 'Expires in ${daysUntilExpiry.abs()} days',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: cardColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryItemImage(InventoryItem item) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      // Handle base64 data URLs
      if (item.imageUrl!.startsWith('data:image')) {
        try {
          final base64String = item.imageUrl!.split(',')[1];
          final bytes = base64Decode(base64String);
          return GestureDetector(
            onTap: () => _showImagePreview(context, item.imageUrl!, item.name),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.inventory_2,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : Colors.grey[600],
                  );
                },
              ),
            ),
          );
        } catch (e) {
          return Icon(
            Icons.inventory_2,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white60
                : Colors.grey[600],
          );
        }
      } else {
        // Handle network URLs
        return GestureDetector(
          onTap: () => _showImagePreview(context, item.imageUrl!, item.name),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              item.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.inventory_2,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : Colors.grey[600],
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    }

    return Icon(
      Icons.inventory_2,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white60
          : Colors.grey[600],
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl, String title) {
    if (imageUrl.isEmpty) return;

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

  Widget _buildImmediateAttentionSection() {
    if (_immediateAttentionItems.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort items by priority: expired first, then by food items, then by expiry date
    final sortedItems = List<InventoryItem>.from(_immediateAttentionItems)
      ..sort((a, b) {
        // First, handle null expiry dates
        if (a.expiryDate == null && b.expiryDate == null) return 0;
        if (a.expiryDate == null) return 1;
        if (b.expiryDate == null) return -1;

        final daysA = a.expiryDate!.difference(DateTime.now()).inDays;
        final daysB = b.expiryDate!.difference(DateTime.now()).inDays;

        // Priority 1: Expired items (negative days) come first
        final isExpiredA = daysA < 0;
        final isExpiredB = daysB < 0;
        if (isExpiredA != isExpiredB) {
          return isExpiredA ? -1 : 1; // Expired items first
        }

        // Priority 2: Food items come before non-food items
        final isFoodA = _isFoodItem(a.category);
        final isFoodB = _isFoodItem(b.category);
        if (isFoodA != isFoodB) {
          return isFoodA ? -1 : 1; // Food items first
        }

        // Priority 3: Sort by expiry date (closest first)
        return daysA.compareTo(daysB);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.priority_high,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.deepOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Needs Immediate Attention',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Food items and products expiring within 6 months',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: sortedItems
              .map((item) =>
                  _buildExpiryItemCard(item, isExpired: false, isUrgent: true))
              .toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Widget _buildItemCard(InventoryItem item) {
  //   final daysUntilExpiry = item.daysUntilExpiry ?? 0;
  //   final expiryColor = _getExpiryColor(daysUntilExpiry);
  //   final expiryIcon = _getExpiryIcon(daysUntilExpiry);

  //   return Card(
  //     elevation: 2,
  //     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(12),
  //       child: Row(
  //         children: [
  //           // Image with expiry icon overlay
  //           Stack(
  //             alignment: Alignment.bottomRight,
  //             children: [
  //               ClipRRect(
  //                 borderRadius: BorderRadius.circular(8),
  //                 child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
  //                     ? Image.network(
  //                         item.imageUrl!,
  //                         width: 70,
  //                         height: 70,
  //                         fit: BoxFit.cover,
  //                         errorBuilder: (context, error, stackTrace) =>
  //                             Container(
  //                           width: 70,
  //                           height: 70,
  //                           color: Colors.grey[200],
  //                           child: const Icon(Icons.image_not_supported,
  //                               color: Colors.grey),
  //                         ),
  //                       )
  //                     : Container(
  //                         width: 70,
  //                         height: 70,
  //                         color: Colors.grey[200],
  //                         child:
  //                             const Icon(Icons.inventory_2, color: Colors.grey),
  //                       ),
  //               ),
  //               Container(
  //                 padding: const EdgeInsets.all(4),
  //                 decoration: BoxDecoration(
  //                   color: expiryColor,
  //                   shape: BoxShape.circle,
  //                   border: Border.all(
  //                       color: Theme.of(context).cardColor, width: 2),
  //                 ),
  //                 child: Icon(
  //                   expiryIcon,
  //                   color: Colors.white,
  //                   size: 14,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(width: 16),

  //           // Item details
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   item.name,
  //                   style: GoogleFonts.poppins(
  //                     fontSize: 15,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                   maxLines: 2,
  //                   overflow: TextOverflow.ellipsis,
  //                 ),
  //                 const SizedBox(height: 4),
  //                 Text(
  //                   item.expiryDate != null
  //                       ? 'Expires: ${DateFormat('MMM dd, yyyy').format(item.expiryDate!)}'
  //                       : 'No expiry date',
  //                   style: GoogleFonts.poppins(
  //                     fontSize: 12,
  //                     color: Theme.of(context).brightness == Brightness.dark
  //                         ? Colors.white70
  //                         : Colors.grey[600],
  //                   ),
  //                 ),
  //                 const SizedBox(height: 6),
  //                 Container(
  //                   padding:
  //                       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                   decoration: BoxDecoration(
  //                     color: expiryColor.withValues(alpha: 0.1),
  //                     borderRadius: BorderRadius.circular(20),
  //                   ),
  //                   child: Text(
  //                     daysUntilExpiry < 0
  //                         ? 'Expired ${daysUntilExpiry.abs()} days ago'
  //                         : 'Expires in $daysUntilExpiry days',
  //                     style: GoogleFonts.poppins(
  //                       fontSize: 11,
  //                       color: expiryColor,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Color _getExpiryColor(int daysUntilExpiry) {
    if (daysUntilExpiry < 0) {
      return Colors.red;
    } else if (daysUntilExpiry <= 7) {
      return Colors.red;
    } else if (daysUntilExpiry <= 30) {
      return Colors.orange;
    } else {
      return Theme.of(context).primaryColor;
    }
  }

  IconData _getExpiryIcon(int daysUntilExpiry) {
    if (daysUntilExpiry < 0) {
      return Icons.error;
    } else if (daysUntilExpiry <= 7) {
      return Icons.warning;
    } else if (daysUntilExpiry <= 30) {
      return Icons.warning;
    } else {
      return Icons.check_circle;
    }
  }

  bool _isFoodItem(String category) {
    final foodCategories = [
      'food',
      'beverages',
      'food & beverages',
      'snacks',
      'dairy',
      'meat',
      'vegetables',
      'fruits',
      'canned food',
      'frozen food',
      'bakery',
      'grocery',
      'perishables',
    ];

    return foodCategories.any(
        (foodCat) => category.toLowerCase().contains(foodCat.toLowerCase()));
  }
}
