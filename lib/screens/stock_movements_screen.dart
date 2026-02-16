import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/stock_movement.dart';
import '../services/inventory_service.dart';

class StockMovementsScreen extends StatefulWidget {
  const StockMovementsScreen({super.key});

  // Custom colors for filter icons
  static const Color _selectedFilterColor = Color(0xFF4CAF50); // Green
  static const Color _unselectedFilterColorLight = Color(0xFF757575); // Grey
  static const Color _unselectedFilterColorDark =
      Color(0xFFB0B0B0); // Light grey

  @override
  State<StockMovementsScreen> createState() => _StockMovementsScreenState();
}

class _StockMovementsScreenState extends State<StockMovementsScreen> {
  // Filters / UI state
  String searchQuery = '';
  MovementType? selectedType;
  DateTime? startDate;
  DateTime? endDate;
  bool showFilters = false;

  // Data
  List<StockMovement> _allMovements = [];
  bool _loadingRemote = false;
  Object? _loadError;

  // Pagination
  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();

    // Load remote data
    _loadingRemote = true;
    _loadRemoteMovements();
  }

  Future<void> _loadRemoteMovements() async {
    setState(() {
      _loadingRemote = true;
      _loadError = null;
    });

    try {
      final items = await InventoryService.getStockMovements(
        limit: 1000,
      ).timeout(const Duration(seconds: 6));

      final itemsSafe = items ?? <StockMovement>[];

      if (mounted) {
        setState(() {
          _allMovements = itemsSafe;
          _loadingRemote = false;
        });
      }
    } on TimeoutException catch (e) {
      if (mounted) {
        setState(() {
          _loadingRemote = false;
          _loadError = e;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRemote = false;
          _loadError = e;
        });
      }
    }
  }

  void _prevPage() {
    setState(() {
      if (_currentPage > 1) _currentPage--;
    });
  }

  void _nextPage(int totalPages) {
    setState(() {
      if (_currentPage < totalPages) _currentPage++;
    });
  }

  void _resetPagination() {
    _currentPage = 1;
  }

  List<StockMovement> _filterMovements(List<StockMovement> movements) {
    final q = searchQuery.trim().toLowerCase();

    return movements.where((movement) {
      final itemName = movement.itemName ?? '';
      final reason = movement.reason ?? '';
      final ts = movement.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);

      if (q.isNotEmpty) {
        final matchesItem = itemName.toLowerCase().contains(q);
        final matchesReason = reason.toLowerCase().contains(q);
        if (!matchesItem && !matchesReason) return false;
      }

      if (selectedType != null) {
        if (movement.type != selectedType) {
          return false;
        }
      }

      if (startDate != null && ts.isBefore(startDate!)) return false;
      if (endDate != null &&
          ts.isAfter(endDate!.add(const Duration(days: 1)))) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterMovements(_allMovements);

    final totalPages = (filtered.length / _pageSize).ceil();
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = math.min(startIndex + _pageSize, filtered.length);
    final visibleMovements = filtered.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey[50],
      body: Column(
        children: [
          // Search & Filter
          Container(
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
                          hintText: 'Search by item name or reason...',
                          prefixIcon: Icon(
                            Icons.search,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white60
                                    : Colors.grey[600],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[600]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[600]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
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
                      onPressed: () =>
                          setState(() => showFilters = !showFilters),
                      icon: Icon(
                        showFilters ? Icons.filter_list_off : Icons.filter_list,
                        color: showFilters
                            ? StockMovementsScreen._selectedFilterColor
                            : (Theme.of(context).brightness == Brightness.dark
                                ? StockMovementsScreen
                                    ._unselectedFilterColorDark
                                : StockMovementsScreen
                                    ._unselectedFilterColorLight),
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
          ),

          // Movements List
          Expanded(
            child: visibleMovements.isEmpty
                ? Center(
                    child: _loadingRemote
                        ? const CircularProgressIndicator()
                        : Text(
                            'No movements found',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: visibleMovements.length,
                    itemBuilder: (context, index) {
                      final movement = visibleMovements[index];
                      return _buildMovementCard(movement);
                    },
                  ),
          ),

          // Pagination Controls
          if (filtered.isNotEmpty)
            Padding(
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
                    onPressed: _currentPage < totalPages
                        ? () => _nextPage(totalPages)
                        : null,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Column(
      children: [
        // Movement Type Filter
        Row(
          children: [
            Text(
              'Type:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.grey[800],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: selectedType == null,
                    onSelected: (selected) => setState(() {
                      selectedType = null;
                      _resetPagination();
                    }),
                  ),
                  ...MovementType.values.map(
                    (type) => FilterChip(
                      label: Text(type.name),
                      selected: selectedType == type,
                      onSelected: (selected) => setState(() {
                        selectedType = selected ? type : null;
                        _resetPagination();
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Date Range Filter
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectStartDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[600]!
                          : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white60
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        startDate != null
                            ? 'From: ${DateFormat('MMM d').format(startDate!)}'
                            : 'Start Date',
                        style: GoogleFonts.poppins(
                          color: startDate != null
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[800])
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white60
                                  : Colors.grey[500]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _selectEndDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[600]!
                          : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white60
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        endDate != null
                            ? 'To: ${DateFormat('MMM d').format(endDate!)}'
                            : 'End Date',
                        style: GoogleFonts.poppins(
                          color: endDate != null
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[800])
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white60
                                  : Colors.grey[500]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (selectedType != null || startDate != null || endDate != null) ...[
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

  Widget _buildMovementCard(StockMovement movement) {
    final type = movement.type ?? MovementType.adjustment;
    final itemName = movement.itemName ?? 'Unknown item';
    final reason = movement.reason ?? '';
    final quantity = movement.quantity ?? 0;
    final userName = movement.userName ?? 'Unknown';
    final timestamp = movement.timestamp ?? DateTime.now();

    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (type) {
      case MovementType.stockIn:
        typeColor = Colors.green;
        typeIcon = Icons.add_circle;
        typeLabel = 'Stock In';
        break;
      case MovementType.stockOut:
        typeColor = Colors.red;
        typeIcon = Icons.remove_circle;
        typeLabel = 'Stock Out';
        break;
      case MovementType.adjustment:
      default:
        typeColor = Colors.blue;
        typeIcon = Icons.edit;
        typeLabel = 'Adjustment';
        break;
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          typeLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: typeColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${type == MovementType.stockOut ? '-' : '+'}$quantity',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              ],
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, yyyy • h:mm a').format(timestamp),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'by $userName',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: endDate ?? DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
        _resetPagination();
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate:
          startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
        _resetPagination();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      selectedType = null;
      startDate = null;
      endDate = null;
      _resetPagination();
    });
  }
}
