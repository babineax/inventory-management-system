import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/inventory_service.dart';
import '../models/stock_prediction.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

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
  int currentPage = 1;
  final int pageSize = 20;

  // Data
  List<StockPrediction> _allPredictions = [];
  List<StockPrediction> _displayedPredictions = [];
  bool _isLoading = true;
  bool _usingDemoData = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPredictionsWithFallback();
  }

  Future<void> _fetchPredictionsWithFallback() async {
    // Show demo data immediately
    setState(() {
      _allPredictions = _generateDemoData();
      _updateDisplayedPredictions();
      _isLoading = true;
      _usingDemoData = true;
    });

    try {
      final predictions = await InventoryService.getStockPredictions();
      setState(() {
        _allPredictions = predictions;
        _usingDemoData = false;
        _error = null;
        _updateDisplayedPredictions();
      });
    } catch (e) {
      print('Error fetching stock predictions: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateDisplayedPredictions() {
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
    }).toList()
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

    final startIndex = (currentPage - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    _displayedPredictions = filtered.sublist(
        startIndex, endIndex > filtered.length ? filtered.length : endIndex);
  }

  void _nextPage() {
    setState(() {
      currentPage++;
      _updateDisplayedPredictions();
    });
  }

  void _prevPage() {
    setState(() {
      if (currentPage > 1) currentPage--;
      _updateDisplayedPredictions();
    });
  }

  void _clearFilters() {
    setState(() {
      selectedConfidence = null;
      showOnlyUrgent = false;
      searchQuery = '';
      currentPage = 1;
      _updateDisplayedPredictions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey[50],
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          Expanded(
            child: _isLoading && _usingDemoData
                ? _buildList()
                : _error != null
                    ? _buildErrorWidget(_error!)
                    : _displayedPredictions.isEmpty
                        ? _buildEmptyWidget()
                        : _buildList(),
          ),
          if (_displayedPredictions.isNotEmpty) _buildPaginationControls(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showStatusInterpretationDialog,
        tooltip: 'Prediction Status Guide',
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.help_outline),
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
                      currentPage = 1;
                      _updateDisplayedPredictions();
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
                      ? Theme.of(context).primaryColor
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white60
                          : Colors.grey[600]),
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
                        currentPage = 1;
                        _updateDisplayedPredictions();
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
                          currentPage = 1;
                          _updateDisplayedPredictions();
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
                  currentPage = 1;
                  _updateDisplayedPredictions();
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

  Widget _buildList() {
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
            itemCount: _displayedPredictions.length,
            itemBuilder: (context, index) => _buildPredictionCard(
                _displayedPredictions[index],
                isCompact: true),
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _displayedPredictions.length,
            itemBuilder: (context, index) =>
                _buildPredictionCard(_displayedPredictions[index]),
          );
        }
      },
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_allPredictions
                .where((p) =>
                    (searchQuery.isEmpty ||
                        p.itemName.toLowerCase().contains(searchQuery)) &&
                    (selectedConfidence == null ||
                        p.confidence == selectedConfidence) &&
                    (!showOnlyUrgent || p.daysLeft <= 7))
                .length /
            pageSize)
        .ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: currentPage > 1 ? _prevPage : null,
            child: const Text('Prev'),
          ),
          const SizedBox(width: 12),
          Text('Page $currentPage of $totalPages'),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: currentPage < totalPages ? _nextPage : null,
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
            onPressed: _fetchPredictionsWithFallback,
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
                                color: urgencyColor.withOpacity(0.1),
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
                                color: confidenceColor.withOpacity(0.1),
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
                        Text('${prediction.daysLeft} days',
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

  // Generate 35–40 demo predictions
  List<StockPrediction> _generateDemoData() {
    final List<StockPrediction> list = [];
    final now = DateTime.now();
    for (int i = 1; i <= 100; i++) {
      final daysLeft = (i % 30) + 1;
      final confidence = PredictionConfidence.values[i % 3];
      list.add(StockPrediction(
        itemId: i.toString(),
        itemName: 'Demo Item ${i + 1}',
        currentQuantity: 10 + (i * 2),
        averageDailyUsage: 1.0 + (i % 5),
        daysLeft: daysLeft,
        predictedDepletionDate: now.add(Duration(days: daysLeft)),
        needsRestock: daysLeft <= 7,
        confidence: confidence,
        calculatedAt: now.subtract(Duration(hours: i % 24)),
      ));
    }
    return list;
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
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.help_outline,
                color: Theme.of(context).primaryColor,
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
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
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
