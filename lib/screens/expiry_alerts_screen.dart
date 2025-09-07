import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/inventory_item.dart';
import '../services/expiry_notification_service.dart';
import '../widgets/loading_widget.dart';

class ExpiryAlertsScreen extends StatefulWidget {
  const ExpiryAlertsScreen({super.key});

  @override
  State<ExpiryAlertsScreen> createState() => _ExpiryAlertsScreenState();
}

class _ExpiryAlertsScreenState extends State<ExpiryAlertsScreen> {
  bool _isLoading = true;
  List<InventoryItem> _expiringItems = [];
  List<InventoryItem> _expiredItems = [];
  List<InventoryItem> _immediateAttentionItems = [];
  String _filter = 'all'; // all, immediate, expiring, expired

  @override
  void initState() {
    super.initState();
    _loadExpiryData();
  }

  Future<void> _loadExpiryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
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
      debugPrint('Error loading expiry data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load expiry data: $e')),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadExpiryData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: _isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Filter chips
                    _buildFilterChips(),

                    const SizedBox(height: 16),

                    // Summary cards
                    _buildSummaryCards(),

                    const SizedBox(height: 20),

                    // Immediate attention section (food items ≤6 months)
                    if (_filter == 'all' || _filter == 'immediate')
                      _buildImmediateAttentionSection(),

                    // Expiring items section
                    if (_filter == 'all' || _filter == 'expiring')
                      _buildExpiringItemsSection(),

                    // Expired items section
                    if (_filter == 'all' || _filter == 'expired')
                      _buildExpiredItemsSection(),
                  ],
                ),
              ),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.warning,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _expiringItems.length.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expiring Soon',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white60
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Expired items card
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _expiredItems.length.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expired',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white60
                            : Colors.grey[600],
                      ),
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

    // Sort items by expiry date (closest first)
    final sortedItems = List<InventoryItem>.from(_expiringItems)
      ..sort((a, b) {
        if (a.expiryDate == null) return 1;
        if (b.expiryDate == null) return -1;
        return a.expiryDate!.compareTo(b.expiryDate!);
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedItems.length,
          itemBuilder: (context, index) {
            final item = sortedItems[index];
            return _buildExpiryItemCard(item, isExpired: false);
          },
        ),
      ],
    );
  }

  Widget _buildExpiredItemsSection() {
    if (_expiredItems.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort items by expiry date (most recently expired first)
    final sortedItems = List<InventoryItem>.from(_expiredItems)
      ..sort((a, b) {
        if (a.expiryDate == null) return 1;
        if (b.expiryDate == null) return -1;
        return b.expiryDate!.compareTo(a.expiryDate!);
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedItems.length,
          itemBuilder: (context, index) {
            final item = sortedItems[index];
            return _buildExpiryItemCard(item, isExpired: true);
          },
        ),
      ],
    );
  }

  Widget _buildExpiryItemCard(InventoryItem item,
      {required bool isExpired, bool isUrgent = false}) {
    final priority = ExpiryNotificationService.getExpiryPriority(item);
    final daysUntilExpiry = item.daysUntilExpiry ?? 0;

    Color cardColor;
    String statusText;

    if (isExpired) {
      cardColor = Colors.red;
      statusText = 'Expired ${daysUntilExpiry.abs()} days ago';
    } else if (isUrgent) {
      cardColor = Colors.deepOrange;
      final isFoodItem = item.category.toLowerCase().contains('food') ||
          item.category.toLowerCase().contains('beverage');
      statusText = isFoodItem
          ? 'Food item - Expires in $daysUntilExpiry days'
          : 'Expires in $daysUntilExpiry days - URGENT!';
    } else {
      if (daysUntilExpiry <= 7) {
        cardColor = Colors.red;
        statusText = 'Expires in $daysUntilExpiry days - URGENT!';
      } else if (daysUntilExpiry <= 30) {
        cardColor = Colors.orange;
        statusText = 'Expires in $daysUntilExpiry days';
      } else {
        cardColor = Theme.of(context).primaryColor;
        statusText = 'Expires in $daysUntilExpiry days';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Item image or icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.inventory_2,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),

            // Item details
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
                          : Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.category,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white60
                          : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: cardColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.quantity} units',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white60
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Expiry date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.expiryDate != null
                      ? DateFormat('MMM dd, yyyy').format(item.expiryDate!)
                      : 'No expiry date',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.expiryDate != null
                      ? DateFormat('h:mm a').format(item.expiryDate!)
                      : '',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImmediateAttentionSection() {
    if (_immediateAttentionItems.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort items by expiry date (closest first)
    final sortedItems = List<InventoryItem>.from(_immediateAttentionItems)
      ..sort((a, b) {
        if (a.expiryDate == null) return 1;
        if (b.expiryDate == null) return -1;
        return a.expiryDate!.compareTo(b.expiryDate!);
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
                color: Colors.deepOrange,
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedItems.length,
          itemBuilder: (context, index) {
            final item = sortedItems[index];
            return _buildExpiryItemCard(item, isExpired: false, isUrgent: true);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
