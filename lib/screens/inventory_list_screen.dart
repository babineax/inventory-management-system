import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/inventory_service.dart';
import '../services/auth_service.dart';
import '../models/inventory_item.dart';
import '../models/user_model.dart';
import '../widgets/inventory_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';
import 'inventory_form_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Custom animated modal function
Future<T?> showModal<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        ),
      );
    },
  );
}

// Custom animated text field widget
class AnimatedTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final InputDecoration decoration;
  final int maxLines;

  const AnimatedTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.decoration = const InputDecoration(),
    this.maxLines = 1,
  });

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize color animation based on the current theme
    _colorAnimation = ColorTween(
      begin: Colors.grey[300],
      end: Theme.of(context).primaryColor,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Focus(
            onFocusChange: (hasFocus) {
              if (hasFocus) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            },
            child: TextField(
              controller: widget.controller,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              maxLines: widget.maxLines,
              decoration: widget.decoration.copyWith(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _colorAnimation.value ?? Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

// Keep your cached Future as in your current implementation
late Future<List<InventoryItem>> _itemsFuture;

class _InventoryListScreenState extends State<InventoryListScreen>
    with TickerProviderStateMixin {
  // Search & filter
  String searchQuery = '';
  String selectedCategory = 'All';
  List<String> categories = [
    'All',
  ];
  AppUser? currentUser;

  // Loading states
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;

  // Tabs + pagination state
  TabController? _tabController;
  final int _pageSize = 20;
  int _itemsLimit = 20;

  // Scroll & cached items
  final ScrollController _scrollController = ScrollController();
  final List<InventoryItem> _allItems = [];

  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  // Default categories used if none in DB
  static const List<String> _defaultCategories = [
    'Electronics',
    'Office Supplies',
    'Food & Beverages',
    'Furniture',
    'Miscellaneous'
  ];

  @override
  void initState() {
    super.initState();

    // prepare initial cached future (kept for compatibility if other parts rely on it)
    _itemsFuture = _getInventoryItemsWithFallback();
    _itemsLimit = _pageSize;

    // basic TabController using current categories length (will be replaced in _setupTabController)
    _tabController = TabController(length: categories.length, vsync: this);
    _tabController!.addListener(_onTabChanged);

    // load categories + initial items
    _loadInitialData();

    // scroll listener for infinite scroll
    // _scrollController.addListener(_onScroll);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // if the user is close to the bottom and not already loading more, try to load more
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 120 &&
        !_isLoadingMore &&
        !_isInitialLoading) {
      // compute whether more filtered items exist
      final filteredLength = _filteredItemsCount();
      final visibleCount = min(filteredLength, _itemsLimit);
      if (filteredLength > visibleCount) {
        _loadMore();
      }
    }
  }

  void _onTabChanged() {
    if (_tabController == null || _tabController!.indexIsChanging) return;
    final idx = _tabController!.index;
    if (idx >= 0 && idx < categories.length) {
      setState(() {
        selectedCategory = categories[idx];
        _itemsLimit = _pageSize; // reset pagination on tab change
      });
      // scroll to top after switching tabs
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  void _setupTabController(List<String> loadedCats) {
    // Remove duplicates from loaded categories
    final uniqueCats = loadedCats.toSet().toList();
    final newCats = ['All', ...uniqueCats];
    final initialIndex = newCats.indexOf(selectedCategory);
    // Recreate controller with the new length and the correct selected index
    final newController = TabController(
      length: newCats.length,
      vsync: this,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
    );
    newController.addListener(_onTabChanged);

    // Swap controllers safely
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();

    setState(() {
      categories = newCats;
      _tabController = newController;
    });
  }

  // Future<void> _loadInitialData() async {
  //   setState(() {
  //     _isInitialLoading = true;
  //   });

  //   // Load categories (with default fallback)
  //   try {
  //     final cats = await InventoryService.getCategories()
  //         .timeout(const Duration(seconds: 5));
  //     if (cats.isEmpty) {
  //       _setupTabController(_defaultCategories);
  //     } else {
  //       _setupTabController(cats);
  //     }
  //   } catch (e) {
  //     // On error, fall back to defaults

  //     _setupTabController(_defaultCategories);
  //   }

  //   // Load items (cached)
  //   try {
  //     final items = await _getInventoryItemsWithFallback();
  //     setState(() {
  //       _allItems.clear();
  //       _allItems.addAll(items);
  //       currentUser = AuthService.currentUser;
  //       _isInitialLoading = false;
  //     });
  //   } catch (e) {

  //     // Even if error occurred, _getInventoryItemsWithFallback already returns demo data
  //     setState(() {
  //       currentUser = AuthService.currentUser;
  //       _isInitialLoading = false;
  //     });
  //   }
  // }

  Future<void> _loadInitialData() async {
    setState(() => _isInitialLoading = true);

    // Load categories (with default fallback)
    try {
      final cats = await InventoryService.getCategories()
          .timeout(const Duration(seconds: 5));
      if (cats.isEmpty) {
        _setupTabController(_defaultCategories);
      } else {
        _setupTabController(cats);
      }
    } catch (e) {
      // On error, fall back to defaults

      _setupTabController(_defaultCategories);
    }

    // Load items
    try {
      final items = await InventoryService.getInventoryItems(limit: _pageSize);
      setState(() {
        _allItems.clear();
        _allItems.addAll(items);

        _lastDocument = items.isNotEmpty ? items.last.snapshot : null;
        _hasMore = items.length == _pageSize;
        currentUser = AuthService.currentUser;
      });
    } finally {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  /// Refresh items (useful after add/edit/delete)
  void _refreshItems() {
    // reset pagination and reload items
    setState(() {
      _itemsLimit = _pageSize;
      _isLoadingMore = false;
    });
    _loadInitialData();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  // Future<void> _loadMore() async {
  //   if (_isLoadingMore) return;

  //   setState(() {
  //     _isLoadingMore = true;
  //   });

  //   // Slight delay to show the loading spinner (simulate load)
  //   await Future.delayed(const Duration(milliseconds: 400));

  //   setState(() {
  //     // increase items limit by one page
  //     _itemsLimit += _pageSize;
  //     _isLoadingMore = false;
  //   });
  // }
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final items = await InventoryService.getInventoryItems(
        limit: _pageSize,
        lastDoc: _lastDocument,
      );

      if (mounted) {
        setState(() {
          _allItems.addAll(items);
          _lastDocument =
              items.isNotEmpty ? items.last.snapshot : _lastDocument;
          _hasMore = items.length == _pageSize;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  /// Returns number of filtered items based on current search/category
  int _filteredItemsCount() {
    final q = searchQuery.trim().toLowerCase();
    return _allItems.where((item) {
      final matchesSearch = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q);
      final matchesCategory =
          selectedCategory == 'All' || item.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).length;
  }

  Future<List<InventoryItem>> _getInventoryItemsWithFallback() async {
    try {
      // Get items from Firebase
      final items = await InventoryService.getInventoryItems()
          .timeout(const Duration(seconds: 10));
      return items;
    } catch (e) {
      // Return empty list if database fails - no demo data
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey[50],
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).cardColor
                : Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText:
                        'Search items by name, category, or description...',
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
                      borderSide: BorderSide(color: theme.primaryColor),
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
                      _itemsLimit = _pageSize; // reset pagination on new search
                    });
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Category Tabs (with "All" default)
                if (_tabController != null && categories.isNotEmpty)
                  Container(
                    constraints:
                        const BoxConstraints(minHeight: 44, maxHeight: 60),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelColor: theme.primaryColor,
                        unselectedLabelColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.grey[700],
                        labelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        unselectedLabelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        tabs: categories
                            .map(
                              (c) => Tab(
                                child: Container(
                                  constraints: const BoxConstraints(
                                      minWidth: 60, maxWidth: 120),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      c,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Inventory List
          Expanded(
            child: _isInitialLoading
                ? const LoadingWidget()
                : Builder(builder: (context) {
                    // Compute filtered list (client-side)
                    final q = searchQuery.trim().toLowerCase();
                    final filteredItems = _allItems.where((item) {
                      final matchesSearch = q.isEmpty ||
                          item.name.toLowerCase().contains(q) ||
                          item.description.toLowerCase().contains(q) ||
                          item.category.toLowerCase().contains(q);
                      final matchesCategory = selectedCategory == 'All' ||
                          item.category == selectedCategory;
                      return matchesSearch && matchesCategory;
                    }).toList();

                    // final visibleCount = filteredItems.length < _itemsLimit
                    //     ? filteredItems.length
                    //     : _itemsLimit;

                    // final showLoadMoreFooter = _isLoadingMore;

                    final visibleCount = filteredItems.length;
                    final showLoadMoreFooter = _isLoadingMore;

                    if (filteredItems.isEmpty) {
                      return EmptyStateWidget(
                        title:
                            searchQuery.isNotEmpty || selectedCategory != 'All'
                                ? 'No items match your search'
                                : 'No inventory items found',
                        message: currentUser?.isAdmin == true
                            ? (searchQuery.isNotEmpty ||
                                    selectedCategory != 'All'
                                ? 'Try adjusting your search criteria'
                                : 'Add your first inventory item to get started')
                            : 'No items available at the moment',
                        showAddButton: currentUser?.isAdmin == true &&
                            searchQuery.isEmpty &&
                            selectedCategory == 'All',
                        onAddPressed: () => _showAddEditItemDialog(),
                      );
                    }

                    return AnimationLimiter(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: visibleCount + (showLoadMoreFooter ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < visibleCount) {
                            final item = filteredItems[index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _buildInventoryCard(item),
                                ),
                              ),
                            );
                          }

                          // Footer: Loading spinner when fetching more
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    );
                  }),
          ),
        ],
      ),
      floatingActionButton: currentUser?.isAdmin == true
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: FloatingActionButton.extended(
                onPressed: () => _showAddEditItemDialog(),
                icon: const Icon(Icons.add),
                label: Text(
                  'Add Item',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 8,
                heroTag: "add_item_fab",
              ),
            )
          : null,
    );
  }

  Widget _buildInventoryCard(InventoryItem item) {
    return InventoryCard(
      item: item,
      onTap: () => _showItemDetailsDialog(item),
      onActionSelected: _handleItemAction,
      isAdmin: currentUser?.isAdmin == true,
    );
  }

  void _handleItemAction(String action, InventoryItem item) {
    switch (action) {
      case 'edit':
        _showAddEditItemDialog(item: item);
        break;
      case 'adjust':
        _showAdjustStockDialog(item);
        break;
      case 'delete':
        _showDeleteConfirmation(item);
        break;
    }
  }

  void _showAddEditItemDialog({InventoryItem? item}) async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            InventoryFormScreen(
          item: item,
          isEditing: item != null,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

    // Refresh the list if an item was added/updated
    if (result == true) {
      _refreshItems(); // refresh categories & items
    }
  }

  void _saveItem(
    InventoryItem? existingItem,
    String name,
    String description,
    String category,
    String quantity,
    String price,
    String supplier,
    String reorderLevel,
  ) async {
    if (name.trim().isEmpty ||
        quantity.trim().isEmpty ||
        price.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      final parsedQuantity = int.parse(quantity);
      final parsedPrice = double.parse(price);
      final parsedReorderLevel =
          int.parse(reorderLevel.isEmpty ? '10' : reorderLevel);

      final newItem = InventoryItem(
        id: existingItem?.id ?? '',
        name: name.trim(),
        description: description.trim(),
        category: category.trim(),
        quantity: parsedQuantity,
        unitPrice: parsedPrice,
        supplier: supplier.trim(),
        createdAt: existingItem?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        reorderLevel: parsedReorderLevel,
      );

      if (existingItem != null) {
        await InventoryService.updateInventoryItem(newItem);
      } else {
        await InventoryService.addInventoryItem(newItem);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Item ${existingItem != null ? 'updated' : 'added'} successfully')),
      );

      // Refresh categories & items
      _refreshItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving item: $e')),
      );
    }
  }

  void _showAdjustStockDialog(InventoryItem item) {
    final BuildContext parentContext = context;

    showDialog(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final TextEditingController quantityController =
                TextEditingController(text: item.quantity.toString());
            final TextEditingController reasonController =
                TextEditingController();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(parentContext)
                          .primaryColor
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.tune,
                      color: Theme.of(parentContext).primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adjust Stock',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Current quantity: ${item.quantity} units',
                                style: GoogleFonts.poppins(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedTextField(
                        key: ValueKey('quantity_${item.id}'),
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'New Quantity',
                          prefixIcon: const Icon(Icons.inventory),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(parentContext).primaryColor,
                            ),
                          ),
                        ),
                        label: '',
                      ),
                      const SizedBox(height: 12),
                      AnimatedTextField(
                        key: ValueKey('reason_${item.id}'),
                        controller: reasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Reason for adjustment',
                          prefixIcon: const Icon(Icons.note_add),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(parentContext).primaryColor,
                            ),
                          ),
                        ),
                        label: '',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final qtyText = quantityController.text;
                    final reasonText = reasonController.text;

                    Navigator.of(dialogContext).pop();

                    await _adjustStock(
                        item, qtyText, reasonText, parentContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(parentContext).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Adjust Stock',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _adjustStock(
    InventoryItem item,
    String newQuantityStr,
    String reason,
    BuildContext parentContext,
  ) async {
    // Basic validation
    if (newQuantityStr.trim().isEmpty || reason.trim().isEmpty) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    int? newQuantity;
    try {
      newQuantity = int.parse(newQuantityStr.trim());
    } catch (_) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text('Quantity must be a valid integer')),
      );
      return;
    }

    if (newQuantity < 0) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text('Quantity cannot be negative')),
      );
      return;
    }

    // Optionally show a temporary loading indicator / SnackBar while performing the network/db call
    const loading = SnackBar(
      content: Row(
        children: [
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 12),
          Text('Adjusting stock...'),
        ],
      ),
      duration: Duration(seconds: 5),
    );
    ScaffoldMessenger.of(parentContext).showSnackBar(loading);

    try {
      // Call your service - adjustStock might throw on failure
      await InventoryService.adjustStock(item.id, newQuantity, reason);

      // Remove the loading SnackBar and show success
      ScaffoldMessenger.of(parentContext).hideCurrentSnackBar();
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text('Stock adjusted successfully')),
      );

      // Refresh the items view (your implementation)
      _refreshItems();
    } catch (e) {
      // Remove loading and show error
      ScaffoldMessenger.of(parentContext).hideCurrentSnackBar();
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(content: Text('Error adjusting stock: $e')),
      );
    }
  }

  void _showDeleteConfirmation(InventoryItem item) {
    final parentContext = context; // capture parent context

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Item',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red[600],
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete "${item.name}"?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone and will permanently remove all associated data.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.red[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteItem(item, parentContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(
      InventoryItem item, BuildContext parentContext) async {
    try {
      await InventoryService.deleteInventoryItem(item.id);
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(content: Text('${item.name} deleted successfully')),
      );
      _refreshItems(); // refresh inventory list
    } catch (e) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(content: Text('Error deleting item: $e')),
      );
    }
  }

  void _showItemDetailsDialog(InventoryItem item) {
    final isLowStock = item.quantity <= item.reorderLevel;
    final isOutOfStock = item.quantity == 0;

    Color statusColor = Colors.green;
    String statusText = 'In Stock';
    IconData statusIcon = Icons.check_circle;

    if (isOutOfStock) {
      statusColor = Colors.red;
      statusText = 'Out of Stock';
      statusIcon = Icons.error;
    } else if (isLowStock) {
      statusColor = Colors.orange;
      statusText = 'Low Stock';
      statusIcon = Icons.warning;
    }

    showModal(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header with image
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // Large Image Preview
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[600]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child:
                            item.imageUrl != null && item.imageUrl!.isNotEmpty
                                ? _buildItemDetailImage(item)
                                : _buildImagePlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title and Category
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.grey[800],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.category.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 24),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusText,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                                Text(
                                  '${item.quantity} units available',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      if (item.description.isNotEmpty) ...[
                        _buildDetailRow(
                          icon: Icons.description,
                          label: 'Description',
                          value: item.description,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Details Grid
                      _buildDetailRow(
                        icon: Icons.attach_money,
                        label: 'Unit Price',
                        // value: '\$${item.unitPrice.toStringAsFixed(2)}',
                        value:
                            '\$${NumberFormat('#,##0.00').format(item.unitPrice)}',
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        icon: Icons.business,
                        label: 'Supplier',
                        value: item.supplier.isEmpty
                            ? 'Not specified'
                            : item.supplier,
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        icon: Icons.low_priority,
                        label: 'Reorder Level',
                        value: '${item.reorderLevel} units',
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Created',
                        value: DateFormat('MMM d, yyyy').format(item.createdAt),
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        icon: Icons.update,
                        label: 'Last Updated',
                        value: DateFormat('MMM d, yyyy').format(item.updatedAt),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    if (currentUser?.isAdmin == true) ...[
                      // Admin action buttons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showAddEditItemDialog(item: item);
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: Text(
                                'Edit',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showAdjustStockDialog(item);
                              },
                              icon: const Icon(Icons.tune, size: 18),
                              label: Text(
                                'Adjust Stock',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Close button - always centered and full width
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 18),
                        label: Text(
                          'Close',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[700]
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2,
            size: 48,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white60
                : Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            'No Image',
            style: GoogleFonts.poppins(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetailImage(InventoryItem item) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      // Handle base64 data URLs
      if (item.imageUrl!.startsWith('data:image')) {
        try {
          final base64String = item.imageUrl!.split(',')[1];
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildImagePlaceholder();
            },
          );
        } catch (e) {
          return _buildImagePlaceholder();
        }
      } else {
        // Handle network URLs
        return Image.network(
          item.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder();
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

    return _buildImagePlaceholder();
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white60
                : Colors.grey[600],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
