import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/inventory_service.dart';
import '../models/stock_prediction.dart';
import '../models/inventory_item.dart';
import '../widgets/loading_widget.dart';
import '../utils/date_utils.dart' as CustomDateUtils;

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  // Custom colors for filter icons
  static const Color _selectedFilterColor = Color(0xFF2196F3); // Blue
  static const Color _unselectedFilterColorLight = Color(0xFF757575); // Grey
  static const Color _unselectedFilterColorDark =
      Color(0xFFB0B0B0); // Light grey

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  // Filters
  String searchQuery = '';
  PredictionConfidence? selectedConfidence;
  bool showOnlyUrgent = false;
  bool showFilters = false;

  // Pagination
  int _currentPage = 1;
  final int _pageSize = 10; // Smaller page size for faster loading

  // Data
  List<StockPrediction> _allPredictions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Load real data
    _loadRealPredictions();
  }

  Future<void> _loadRealPredictions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load ALL inventory items from database using pagination
      final allItems = await _getAllInventoryItems();

      // Generate predictions for all items concurrently to reduce wait time
      final predictions = await Future.wait(
        allItems.map((item) async {
          // First, try to get existing prediction from database
          final existingPrediction =
              await InventoryService.getItemPrediction(item.id);

          if (existingPrediction != null) {
            // Use existing prediction if available and recent (within 24 hours)
            final isRecent = DateTime.now()
                    .difference(existingPrediction.calculatedAt)
                    .inHours <
                24;
            if (isRecent) {
              return existingPrediction;
            }
          }

          // Calculate new prediction based on actual historical data
          return InventoryService.calculatePredictionForItem(item);
        }),
        eagerError: false,
      );

      // Sort by days left (most urgent first)
      predictions.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

      if (mounted) {
        setState(() {
          _allPredictions = predictions;
          _isLoading = false;
          _resetPagination();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _resetPagination();
        });
      }
    }
  }

  // Helper method to get ALL inventory items using pagination
  Future<List<InventoryItem>> _getAllInventoryItems() async {
    final allItems = <InventoryItem>[];
    DocumentSnapshot? lastDoc;
    const batchSize = 100; // Process in batches to avoid memory issues

    while (true) {
      final batch = await InventoryService.getInventoryItems(
        limit: batchSize,
        lastDoc: lastDoc,
      );

      if (batch.isEmpty) break;

      allItems.addAll(batch);
      lastDoc = batch.last.snapshot;

      // Safety check to prevent infinite loops (though unlikely)
      if (batch.length < batchSize) break;
    }

    return allItems;
  }

  void _prevPage() {
    setState(() {
      if (_currentPage > 1) {
        _currentPage--;
      }
    });
  }

  void _nextPage(int totalPages) {
    setState(() {
      if (_currentPage < totalPages) {
        _currentPage++;
      }
    });
  }

  void _resetPagination() {
    _currentPage = 1;
  }

  void _clearFilters() {
    setState(() {
      selectedConfidence = null;
      showOnlyUrgent = false;
      searchQuery = '';
      _resetPagination();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allPredictions.where((prediction) {
      if (searchQuery.isNotEmpty &&
          !prediction.itemName.toLowerCase().contains(searchQuery)) {
        return false;
      }
      if (selectedConfidence != null &&
          prediction.confidence != selectedConfidence) {
        return false;
      }
      if (showOnlyUrgent && prediction.daysLeft > 7) {
        return false;
      }
      return true;
    }).toList();

    final totalPages = (filtered.length / _pageSize).ceil();
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize > filtered.length
        ? filtered.length
        : startIndex + _pageSize;
    final displayedPredictions = filtered.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey[50],
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _error != null
                    ? _buildErrorWidget(_error!)
                    : displayedPredictions.isEmpty
                        ? _buildEmptyWidget()
                        : _buildList(displayedPredictions),
          ),
          if (filtered.isNotEmpty)
            _buildPaginationControls(filtered, totalPages),
        ],
      ),
      floatingActionButton: Tooltip(
        message: 'Prediction Status Guide',
        textStyle: GoogleFonts.poppins(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
          fontSize: 14,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[600]!
                : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showStatusInterpretationDialog,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2196F3) // Bright blue in dark mode
              : const Color(0xFF1976D2), // Deep blue in light mode
          foregroundColor: Colors.white,
          elevation: 8,
          child: const Icon(Icons.help_outline, size: 28),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).cardColor
          : Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search items by name...',
                    hintStyle: GoogleFonts.poppins(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white60
                          : Colors.grey[600],
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white60
                          : Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[600]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[600]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                  ),
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[800],
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                      _resetPagination();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  setState(() {
                    showFilters = !showFilters;
                  });
                },
                icon: Icon(
                  showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color: showFilters
                      ? PredictionsScreen._selectedFilterColor
                      : (Theme.of(context).brightness == Brightness.dark
                          ? PredictionsScreen._unselectedFilterColorDark
                          : PredictionsScreen._unselectedFilterColorLight),
                ),
              ),
            ],
          ),
          if (showFilters) ...[
            const SizedBox(height: 16),
            _buildAdvancedFilters(),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Column(
      children: [
        Row(
          children: [
            Text('Confidence:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[800],
                )),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text('All',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.grey[800],
                        )),
                    selected: selectedConfidence == null,
                    onSelected: (selected) {
                      setState(() {
                        selectedConfidence = null;
                        _resetPagination();
                      });
                    },
                  ),
                  ...PredictionConfidence.values.map((confidence) {
                    return FilterChip(
                      label: Text(_getConfidenceLabel(confidence),
                          style: GoogleFonts.poppins(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.grey[800],
                          )),
                      selected: selectedConfidence == confidence,
                      onSelected: (selected) {
                        setState(() {
                          selectedConfidence = selected ? confidence : null;
                          _resetPagination();
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('Show only urgent items (≤7 days):',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[800],
                )),
            const Spacer(),
            Switch(
              value: showOnlyUrgent,
              onChanged: (value) {
                setState(() {
                  showOnlyUrgent = value;
                  _resetPagination();
                });
              },
            ),
          ],
        ),
        if (selectedConfidence != null || showOnlyUrgent) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildList(List<StockPrediction> displayedPredictions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth > 1400 ? 3 : 2,
              childAspectRatio: 1.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: displayedPredictions.length,
            itemBuilder: (context, index) => _buildPredictionCard(
                displayedPredictions[index],
                isCompact: true),
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: displayedPredictions.length,
            itemBuilder: (context, index) =>
                _buildPredictionCard(displayedPredictions[index]),
          );
        }
      },
    );
  }

  Widget _buildPaginationControls(
      List<StockPrediction> filtered, int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _currentPage > 1 ? _prevPage : null,
            child: const Text('Prev'),
          ),
          const SizedBox(width: 12),
          Text('Page $_currentPage of $totalPages'),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed:
                _currentPage < totalPages ? () => _nextPage(totalPages) : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text('Error loading predictions',
              style: GoogleFonts.poppins(fontSize: 18)),
          const SizedBox(height: 8),
          Text(error, style: GoogleFonts.poppins(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRealPredictions,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty ||
                    selectedConfidence != null ||
                    showOnlyUrgent
                ? 'No predictions match your filters'
                : 'No stock predictions available',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Predictions will appear here as your inventory data grows',
            style: GoogleFonts.poppins(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Card building logic
  Widget _buildPredictionCard(StockPrediction prediction,
      {bool isCompact = false}) {
    Color urgencyColor;
    IconData urgencyIcon;
    String urgencyText;

    if (prediction.daysLeft <= 0) {
      urgencyColor = Colors.red;
      urgencyIcon = Icons.error;
      urgencyText = 'OUT OF STOCK';
    } else if (prediction.daysLeft <= 3) {
      urgencyColor = Colors.red;
      urgencyIcon = Icons.warning;
      urgencyText = 'CRITICAL';
    } else if (prediction.daysLeft <= 7) {
      urgencyColor = Colors.orange;
      urgencyIcon = Icons.warning_amber;
      urgencyText = 'URGENT';
    } else if (prediction.daysLeft <= 14) {
      urgencyColor = Colors.yellow[700]!;
      urgencyIcon = Icons.schedule;
      urgencyText = 'MODERATE';
    } else {
      urgencyColor = Colors.green;
      urgencyIcon = Icons.check_circle;
      urgencyText = 'GOOD';
    }

    Color confidenceColor;
    switch (prediction.confidence) {
      case PredictionConfidence.high:
        confidenceColor = Colors.green;
        break;
      case PredictionConfidence.medium:
        confidenceColor = Colors.orange;
        break;
      case PredictionConfidence.low:
        confidenceColor = Colors.red;
        break;
    }

    // Calculate progress based on current quantity vs reorder level and usage pattern
    double stockPercent;
    if (prediction.currentQuantity <= 0) {
      stockPercent = 0.0;
    } else if (prediction.daysLeft <= 0) {
      stockPercent = 0.0;
    } else if (prediction.daysLeft <= 3) {
      stockPercent = 0.1; // Critical level
    } else if (prediction.daysLeft <= 7) {
      stockPercent = 0.3; // Urgent level
    } else if (prediction.daysLeft <= 14) {
      stockPercent = 0.6; // Moderate level
    } else if (prediction.daysLeft <= 30) {
      stockPercent = 0.8; // Good level
    } else {
      stockPercent = 1.0; // Excellent level
    }

    final daysLabel = prediction.currentQuantity <= 0
        ? 'Out of stock'
        : CustomDateUtils.DateUtils.formatDaysDifference(prediction.daysLeft);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prediction.itemName,
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[800])),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: urgencyColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(urgencyText,
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: urgencyColor)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: confidenceColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(
                                _getConfidenceLabel(prediction.confidence),
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: confidenceColor)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(urgencyIcon, color: urgencyColor, size: 20),
                        const SizedBox(width: 4),
                        Text(daysLabel,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: urgencyColor)),
                      ],
                    ),
                    Text('${prediction.currentQuantity} units',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white60
                                    : Colors.grey[600])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: stockPercent,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(urgencyColor),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  String _getConfidenceLabel(PredictionConfidence confidence) {
    switch (confidence) {
      case PredictionConfidence.high:
        return 'High';
      case PredictionConfidence.medium:
        return 'Medium';
      case PredictionConfidence.low:
        return 'Low';
    }
  }

  void _showStatusInterpretationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2196F3)
                        .withValues(alpha: 0.15) // Blue tint in dark mode
                    : const Color(0xFF1976D2)
                        .withValues(alpha: 0.1), // Blue tint in light mode
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.help_outline,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2196F3) // Bright blue in dark mode
                    : const Color(0xFF1976D2), // Deep blue in light mode
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Prediction Status Guide',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[800],
                ),
                softWrap: true,
                // overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock prediction statuses help you understand the urgency of restocking needs:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatusExplanation(
                  'CRITICAL',
                  '≤ 3 days',
                  Colors.red,
                  Icons.error,
                  'Immediate action required! Stock will run out within 3 days. Place urgent orders now.',
                ),
                const SizedBox(height: 12),
                _buildStatusExplanation(
                  'URGENT',
                  '4-7 days',
                  Colors.orange,
                  Icons.warning,
                  'High priority restocking needed. Stock will run out within a week. Order soon.',
                ),
                const SizedBox(height: 12),
                _buildStatusExplanation(
                  'MODERATE',
                  '8-14 days',
                  Colors.yellow[700]!,
                  Icons.schedule,
                  'Medium priority. Stock will last 1-2 weeks. Plan restocking accordingly.',
                ),
                const SizedBox(height: 12),
                _buildStatusExplanation(
                  'GOOD',
                  '15+ days',
                  Colors.green,
                  Icons.check_circle,
                  'Stock levels are healthy. No immediate restocking needed.',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Confidence Levels',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• High: Based on consistent usage patterns\n'
                        '• Medium: Some variation in usage data\n'
                        '• Low: Limited or inconsistent data available',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusExplanation(
    String status,
    String timeframe,
    Color color,
    IconData icon,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeframe,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
