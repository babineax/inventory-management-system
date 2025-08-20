// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// import 'package:animations/animations.dart';
// import '../services/inventory_service.dart';
// import '../services/auth_service.dart';
// import '../models/inventory_item.dart';
// import '../models/user_model.dart';
// import '../models/stock_prediction.dart';
// import 'inventory_form_screen.dart';

// // Custom animated modal function
// Future<T?> showModal<T>({
//   required BuildContext context,
//   required Widget Function(BuildContext) builder,
// }) {
//   return showGeneralDialog<T>(
//     context: context,
//     barrierDismissible: true,
//     barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
//     barrierColor: Colors.black54,
//     transitionDuration: const Duration(milliseconds: 300),
//     pageBuilder: (context, animation, secondaryAnimation) {
//       return builder(context);
//     },
//     transitionBuilder: (context, animation, secondaryAnimation, child) {
//       return SlideTransition(
//         position: Tween<Offset>(
//           begin: const Offset(0, 0.3),
//           end: Offset.zero,
//         ).animate(CurvedAnimation(
//           parent: animation,
//           curve: Curves.easeOutCubic,
//         )),
//         child: FadeTransition(
//           opacity: CurvedAnimation(
//             parent: animation,
//             curve: Curves.easeOut,
//           ),
//           child: ScaleTransition(
//             scale: Tween<double>(
//               begin: 0.95,
//               end: 1.0,
//             ).animate(CurvedAnimation(
//               parent: animation,
//               curve: Curves.easeOutCubic,
//             )),
//             child: child,
//           ),
//         ),
//       );
//     },
//   );
// }

// // Custom animated text field widget
// class AnimatedTextField extends StatefulWidget {
//   final TextEditingController controller;
//   final InputDecoration decoration;
//   final TextInputType? keyboardType;
//   final int? maxLines;

//   const AnimatedTextField({
//     Key? key,
//     required this.controller,
//     required this.decoration,
//     this.keyboardType,
//     this.maxLines,
//   }) : super(key: key);

//   @override
//   State<AnimatedTextField> createState() => _AnimatedTextFieldState();
// }

// class _AnimatedTextFieldState extends State<AnimatedTextField>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   late Animation<Color?> _colorAnimation;
//   bool _isFocused = false;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 200),
//       vsync: this,
//     );
//     _scaleAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.02,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));
//     _colorAnimation = ColorTween(
//       begin: Colors.grey[300],
//       end: Theme.of(context).primaryColor,
//     ).animate(_animationController);
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _animationController,
//       builder: (context, child) {
//         return Transform.scale(
//           scale: _scaleAnimation.value,
//           child: Focus(
//             onFocusChange: (hasFocus) {
//               setState(() {
//                 _isFocused = hasFocus;
//               });
//               if (hasFocus) {
//                 _animationController.forward();
//               } else {
//                 _animationController.reverse();
//               }
//             },
//             child: TextField(
//               controller: widget.controller,
//               decoration: widget.decoration.copyWith(
//                 enabledBorder: widget.decoration.enabledBorder ??
//                     OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(
//                         color: _colorAnimation.value ?? Colors.grey[300]!,
//                       ),
//                     ),
//               ),
//               keyboardType: widget.keyboardType,
//               maxLines: widget.maxLines,
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class InventoryListScreen extends StatefulWidget {
//   const InventoryListScreen({Key? key}) : super(key: key);

//   @override
//   State<InventoryListScreen> createState() => _InventoryListScreenState();
// }

// late Future<List<InventoryItem>> _itemsFuture;

// class _InventoryListScreenState extends State<InventoryListScreen> {
//   String searchQuery = '';
//   String selectedCategory = 'All';
//   List<String> categories = ['All'];
//   AppUser? currentUser;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _itemsFuture = _getInventoryItemsWithFallback();
//     _loadData();
//   }

//   void _refreshItems() {
//     setState(() {
//       _itemsFuture = _getInventoryItemsWithFallback();
//     });
//   }

//   Future<void> _loadData() async {
//     try {
//       final cats = await InventoryService.getCategories();
//       setState(() {
//         currentUser = AuthService.currentUser;
//         categories = ['All', ...cats];
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<List<InventoryItem>> _getInventoryItemsWithFallback() async {
//     try {
//       // FIX: ensure the Future completes by adding a timeout and catching errors.
//       return await InventoryService.getInventoryItems()
//           .timeout(const Duration(seconds: 5));
//     } catch (e) {
//       debugPrint('Error loading inventory items: $e');
//       // Return demo data if database fails or times out
//       return [
//         InventoryItem(
//           id: '1',
//           name: 'Wireless Mouse',
//           description: 'High-quality wireless mouse for professional use',
//           category: 'Electronics',
//           quantity: 15,
//           unitPrice: 25.99,
//           supplier: 'TechCorp',
//           createdAt: DateTime.now().subtract(const Duration(days: 10)),
//           updatedAt: DateTime.now(),
//           reorderLevel: 10,
//         ),
//         InventoryItem(
//           id: '2',
//           name: 'A4 Paper Ream',
//           description: 'Premium quality A4 paper for office use',
//           category: 'Office Supplies',
//           quantity: 5,
//           unitPrice: 8.99,
//           supplier: 'PaperCo',
//           createdAt: DateTime.now().subtract(const Duration(days: 5)),
//           updatedAt: DateTime.now(),
//           reorderLevel: 10,
//         ),
//         InventoryItem(
//           id: '3',
//           name: 'Coffee Beans',
//           description: 'Premium coffee beans (1kg)',
//           category: 'Food & Beverages',
//           quantity: 0,
//           unitPrice: 24.99,
//           supplier: 'BrewMaster',
//           createdAt: DateTime.now().subtract(const Duration(days: 15)),
//           updatedAt: DateTime.now(),
//           reorderLevel: 5,
//         ),
//       ];
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: Column(
//         children: [
//           // Search and Filter Section
//           Container(
//             padding: const EdgeInsets.all(16),
//             color: Colors.white,
//             child: Column(
//               children: [
//                 // Search Bar
//                 TextField(
//                   decoration: InputDecoration(
//                     hintText: 'Search items by name or description...',
//                     prefixIcon: const Icon(Icons.search),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(color: Colors.grey[300]!),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(color: Colors.grey[300]!),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide:
//                           BorderSide(color: Theme.of(context).primaryColor),
//                     ),
//                     filled: true,
//                     fillColor: Colors.grey[50],
//                   ),
//                   onChanged: (value) {
//                     setState(() {
//                       searchQuery = value.toLowerCase();
//                     });
//                   },
//                 ),
//                 const SizedBox(height: 12),

//                 // Category Filter
//                 if (categories.length > 1)
//                   SizedBox(
//                     height: 40,
//                     child: ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: categories.length,
//                       itemBuilder: (context, index) {
//                         final category = categories[index];
//                         final isSelected = selectedCategory == category;
//                         return Padding(
//                           padding: const EdgeInsets.only(right: 8),
//                           child: FilterChip(
//                             label: Text(category),
//                             selected: isSelected,
//                             onSelected: (selected) {
//                               setState(() {
//                                 selectedCategory = category;
//                               });
//                             },
//                             backgroundColor: Colors.grey[200],
//                             selectedColor:
//                                 Theme.of(context).primaryColor.withOpacity(0.2),
//                             labelStyle: TextStyle(
//                               color: isSelected
//                                   ? Theme.of(context).primaryColor
//                                   : Colors.grey[700],
//                               fontWeight: isSelected
//                                   ? FontWeight.w600
//                                   : FontWeight.normal,
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           // Inventory List
//           Expanded(
//             child: FutureBuilder<List<InventoryItem>>(
//               // future: _getInventoryItemsWithFallback(),
//               future: _itemsFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.hasError) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.error_outline,
//                             size: 64, color: Colors.red[400]),
//                         const SizedBox(height: 16),
//                         Text('Error loading inventory',
//                             style: GoogleFonts.poppins(fontSize: 18)),
//                         const SizedBox(height: 8),
//                         Text(snapshot.error.toString(),
//                             style:
//                                 GoogleFonts.poppins(color: Colors.grey[600])),
//                       ],
//                     ),
//                   );
//                 }

//                 final items = snapshot.data ?? [];
//                 final filteredItems = items.where((item) {
//                   final matchesSearch =
//                       item.name.toLowerCase().contains(searchQuery) ||
//                           item.description.toLowerCase().contains(searchQuery);
//                   final matchesCategory = selectedCategory == 'All' ||
//                       item.category == selectedCategory;
//                   return matchesSearch && matchesCategory;
//                 }).toList();

//                 if (filteredItems.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.inventory_2_outlined,
//                             size: 64, color: Colors.grey[400]),
//                         const SizedBox(height: 16),
//                         Text(
//                           searchQuery.isNotEmpty || selectedCategory != 'All'
//                               ? 'No items match your search'
//                               : 'No inventory items found',
//                           style: GoogleFonts.poppins(
//                               fontSize: 18, color: Colors.grey[600]),
//                         ),
//                         if (currentUser?.isAdmin == true) ...[
//                           const SizedBox(height: 8),
//                           Text(
//                             'Add your first inventory item to get started',
//                             style: GoogleFonts.poppins(color: Colors.grey[500]),
//                           ),
//                         ],
//                       ],
//                     ),
//                   );
//                 }

//                 return AnimationLimiter(
//                   child: ListView.builder(
//                     padding: const EdgeInsets.all(16),
//                     itemCount: filteredItems.length,
//                     itemBuilder: (context, index) {
//                       final item = filteredItems[index];
//                       return AnimationConfiguration.staggeredList(
//                         position: index,
//                         duration: const Duration(milliseconds: 375),
//                         child: SlideAnimation(
//                           verticalOffset: 50.0,
//                           child: FadeInAnimation(
//                             child: _buildInventoryCard(item),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: currentUser?.isAdmin == true
//           ? AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               child: FloatingActionButton.extended(
//                 onPressed: () => _showAddEditItemDialog(),
//                 icon: const Icon(Icons.add),
//                 label: Text(
//                   'Add Item',
//                   style: GoogleFonts.poppins(
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 backgroundColor: Theme.of(context).primaryColor,
//                 foregroundColor: Colors.white,
//                 elevation: 8,
//                 heroTag: "add_item_fab",
//               ),
//             )
//           : null,
//     );
//   }

//   Widget _buildInventoryCard(InventoryItem item) {
//     final isLowStock = item.quantity <= item.reorderLevel;
//     final isOutOfStock = item.quantity == 0;

//     Color statusColor = Colors.green;
//     String statusText = 'In Stock';
//     IconData statusIcon = Icons.check_circle;

//     if (isOutOfStock) {
//       statusColor = Colors.red;
//       statusText = 'Out of Stock';
//       statusIcon = Icons.error;
//     } else if (isLowStock) {
//       statusColor = Colors.orange;
//       statusText = 'Low Stock';
//       statusIcon = Icons.warning;
//     }

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: InkWell(
//         onTap: () => _showItemDetailsDialog(item),
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header Row
//               Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           item.name,
//                           style: GoogleFonts.poppins(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.grey[800],
//                           ),
//                         ),
//                         if (item.category.isNotEmpty) ...[
//                           const SizedBox(height: 4),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 8, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: Theme.of(context)
//                                   .primaryColor
//                                   .withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               item.category,
//                               style: GoogleFonts.poppins(
//                                 fontSize: 10,
//                                 color: Theme.of(context).primaryColor,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                   // Stock Prediction
//                   FutureBuilder<StockPrediction?>(
//                     future: InventoryService.getItemPrediction(item.id),
//                     builder: (context, predictionSnapshot) {
//                       if (predictionSnapshot.hasData &&
//                           predictionSnapshot.data != null) {
//                         final prediction = predictionSnapshot.data!;
//                         if (prediction.needsRestock &&
//                             prediction.daysLeft <= 30) {
//                           return Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 8, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: prediction.daysLeft <= 7
//                                   ? Colors.red[100]
//                                   : Colors.orange[100],
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Column(
//                               children: [
//                                 Icon(
//                                   Icons.schedule,
//                                   size: 16,
//                                   color: prediction.daysLeft <= 7
//                                       ? Colors.red[700]
//                                       : Colors.orange[700],
//                                 ),
//                                 Text(
//                                   prediction.daysLeftText,
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 9,
//                                     color: prediction.daysLeft <= 7
//                                         ? Colors.red[700]
//                                         : Colors.orange[700],
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }
//                       }
//                       return const SizedBox();
//                     },
//                   ),
//                   const SizedBox(width: 8),
//                   // Actions Menu
//                   if (currentUser?.isAdmin == true)
//                     PopupMenuButton<String>(
//                       onSelected: (value) => _handleItemAction(value, item),
//                       itemBuilder: (context) => [
//                         const PopupMenuItem(value: 'edit', child: Text('Edit')),
//                         const PopupMenuItem(
//                             value: 'adjust', child: Text('Adjust Stock')),
//                         const PopupMenuItem(
//                             value: 'delete', child: Text('Delete')),
//                       ],
//                       child: Icon(Icons.more_vert, color: Colors.grey[600]),
//                     ),
//                 ],
//               ),

//               const SizedBox(height: 12),

//               // Description
//               if (item.description.isNotEmpty) ...[
//                 Text(
//                   item.description,
//                   style: GoogleFonts.poppins(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 12),
//               ],

//               // Details Row
//               Row(
//                 children: [
//                   // Quantity
//                   Expanded(
//                     child: Row(
//                       children: [
//                         Icon(statusIcon, color: statusColor, size: 16),
//                         const SizedBox(width: 4),
//                         Text(
//                           '${item.quantity} units',
//                           style: GoogleFonts.poppins(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                             color: statusColor,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   // Price
//                   Text(
//                     '\$${item.unitPrice.toStringAsFixed(2)}',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey[800],
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 8),

//               // Status and Supplier
//               Row(
//                 children: [
//                   Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       statusText,
//                       style: GoogleFonts.poppins(
//                         fontSize: 10,
//                         color: statusColor,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                   const Spacer(),
//                   if (item.supplier.isNotEmpty)
//                     Text(
//                       'Supplier: ${item.supplier}',
//                       style: GoogleFonts.poppins(
//                         fontSize: 10,
//                         color: Colors.grey[500],
//                       ),
//                     ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _handleItemAction(String action, InventoryItem item) {
//     switch (action) {
//       case 'edit':
//         _showAddEditItemDialog(item: item);
//         break;
//       case 'adjust':
//         _showAdjustStockDialog(item);
//         break;
//       case 'delete':
//         _showDeleteConfirmation(item);
//         break;
//     }
//   }

//   void _showAddEditItemDialog({InventoryItem? item}) async {
//     final result = await Navigator.of(context).push<bool>(
//       PageRouteBuilder(
//         pageBuilder: (context, animation, secondaryAnimation) =>
//             InventoryFormScreen(
//           item: item,
//           isEditing: item != null,
//         ),
//         transitionsBuilder: (context, animation, secondaryAnimation, child) {
//           const begin = Offset(1.0, 0.0);
//           const end = Offset.zero;
//           const curve = Curves.easeInOutCubic;

//           var tween = Tween(begin: begin, end: end).chain(
//             CurveTween(curve: curve),
//           );

//           return SlideTransition(
//             position: animation.drive(tween),
//             child: FadeTransition(
//               opacity: animation,
//               child: child,
//             ),
//           );
//         },
//         transitionDuration: const Duration(milliseconds: 400),
//       ),
//     );

//     // Refresh the list if an item was added/updated
//     if (result == true) {
//       setState(() {
//         // This will trigger a rebuild and refresh the data
//       });
//       _loadData(); // Refresh categories as well
//       _refreshItems(); // Refresh the inventory items
//     }
//   }

//   void _saveItem(
//     InventoryItem? existingItem,
//     String name,
//     String description,
//     String category,
//     String quantity,
//     String price,
//     String supplier,
//     String reorderLevel,
//   ) async {
//     if (name.trim().isEmpty ||
//         quantity.trim().isEmpty ||
//         price.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill in all required fields')),
//       );
//       return;
//     }

//     try {
//       final parsedQuantity = int.parse(quantity);
//       final parsedPrice = double.parse(price);
//       final parsedReorderLevel =
//           int.parse(reorderLevel.isEmpty ? '10' : reorderLevel);

//       final newItem = InventoryItem(
//         id: existingItem?.id ?? '',
//         name: name.trim(),
//         description: description.trim(),
//         category: category.trim(),
//         quantity: parsedQuantity,
//         unitPrice: parsedPrice,
//         supplier: supplier.trim(),
//         createdAt: existingItem?.createdAt ?? DateTime.now(),
//         updatedAt: DateTime.now(),
//         reorderLevel: parsedReorderLevel,
//       );

//       if (existingItem != null) {
//         await InventoryService.updateInventoryItem(newItem);
//       } else {
//         await InventoryService.addInventoryItem(newItem);
//       }

//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content: Text(
//                 'Item ${existingItem != null ? 'updated' : 'added'} successfully')),
//       );

//       // Refresh categories
//       _loadData();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error saving item: $e')),
//       );
//     }
//   }

//   void _showAdjustStockDialog(InventoryItem item) {
//     final quantityController =
//         TextEditingController(text: item.quantity.toString());
//     final reasonController = TextEditingController();

//     showModal(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Theme.of(context).primaryColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(
//                 Icons.tune,
//                 color: Theme.of(context).primaryColor,
//                 size: 20,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Adjust Stock',
//                     style: GoogleFonts.poppins(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   Text(
//                     item.name,
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                       fontWeight: FontWeight.w400,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.blue[50],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Current quantity: ${item.quantity} units',
//                     style: GoogleFonts.poppins(
//                       color: Colors.blue[700],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
//             AnimatedTextField(
//               controller: quantityController,
//               decoration: InputDecoration(
//                 labelText: 'New Quantity',
//                 prefixIcon: const Icon(Icons.inventory),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: Theme.of(context).primaryColor),
//                 ),
//               ),
//               keyboardType: TextInputType.number,
//             ),
//             const SizedBox(height: 12),
//             AnimatedTextField(
//               controller: reasonController,
//               decoration: InputDecoration(
//                 labelText: 'Reason for adjustment',
//                 prefixIcon: const Icon(Icons.note_add),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: Theme.of(context).primaryColor),
//                 ),
//               ),
//               maxLines: 2,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             style: TextButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             ),
//             child: Text(
//               'Cancel',
//               style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () => _adjustStock(
//                 item, quantityController.text, reasonController.text),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Theme.of(context).primaryColor,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: Text(
//               'Adjust Stock',
//               style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _adjustStock(
//       InventoryItem item, String newQuantityStr, String reason) async {
//     if (newQuantityStr.trim().isEmpty || reason.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill in all fields')),
//       );
//       return;
//     }

//     try {
//       final newQuantity = int.parse(newQuantityStr);
//       await InventoryService.adjustStock(item.id, newQuantity, reason);
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Stock adjusted successfully')),
//       );
//       _refreshItems(); // Refresh the inventory items list
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error adjusting stock: $e')),
//       );
//     }
//   }

//   void _showDeleteConfirmation(InventoryItem item) {
//     showModal(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.red[50],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(
//                 Icons.delete_outline,
//                 color: Colors.red[600],
//                 size: 24,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Text(
//               'Delete Item',
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.red[700],
//               ),
//             ),
//           ],
//         ),
//         content: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.red[50],
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.red[200]!),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 Icons.warning_amber_rounded,
//                 color: Colors.red[600],
//                 size: 48,
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'Are you sure you want to delete "${item.name}"?',
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.red[800],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'This action cannot be undone and will permanently remove all associated data.',
//                 style: GoogleFonts.poppins(
//                   fontSize: 12,
//                   color: Colors.red[600],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             style: TextButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             ),
//             child: Text(
//               'Cancel',
//               style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () => _deleteItem(item),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red[600],
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: Text(
//               'Delete',
//               style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _deleteItem(InventoryItem item) async {
//     try {
//       await InventoryService.deleteInventoryItem(item.id);
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Item deleted successfully')),
//       );
//       _refreshItems(); // Refresh the inventory items list
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error deleting item: $e')),
//       );
//     }
//   }

//   void _showItemDetailsDialog(InventoryItem item) {
//     final isLowStock = item.quantity <= item.reorderLevel;
//     final isOutOfStock = item.quantity == 0;

//     Color statusColor = Colors.green;
//     String statusText = 'In Stock';
//     IconData statusIcon = Icons.check_circle;

//     if (isOutOfStock) {
//       statusColor = Colors.red;
//       statusText = 'Out of Stock';
//       statusIcon = Icons.error;
//     } else if (isLowStock) {
//       statusColor = Colors.orange;
//       statusText = 'Low Stock';
//       statusIcon = Icons.warning;
//     }

//     showModal(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Theme.of(context).primaryColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(
//                 Icons.inventory_2,
//                 color: Theme.of(context).primaryColor,
//                 size: 24,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     item.name,
//                     style: GoogleFonts.poppins(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   if (item.category.isNotEmpty)
//                     Container(
//                       margin: const EdgeInsets.only(top: 4),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 8, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: Theme.of(context).primaryColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         item.category,
//                         style: GoogleFonts.poppins(
//                           fontSize: 10,
//                           color: Theme.of(context).primaryColor,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Status Card
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: statusColor.withOpacity(0.3)),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(statusIcon, color: statusColor, size: 24),
//                     const SizedBox(width: 12),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           statusText,
//                           style: GoogleFonts.poppins(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: statusColor,
//                           ),
//                         ),
//                         Text(
//                           '${item.quantity} units available',
//                           style: GoogleFonts.poppins(
//                             fontSize: 12,
//                             color: statusColor,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // Description
//               if (item.description.isNotEmpty) ...[
//                 _buildDetailRow(
//                   icon: Icons.description,
//                   label: 'Description',
//                   value: item.description,
//                 ),
//                 const SizedBox(height: 12),
//               ],

//               // Details Grid
//               _buildDetailRow(
//                 icon: Icons.attach_money,
//                 label: 'Unit Price',
//                 value: '\$${item.unitPrice.toStringAsFixed(2)}',
//               ),
//               const SizedBox(height: 12),

//               _buildDetailRow(
//                 icon: Icons.business,
//                 label: 'Supplier',
//                 value: item.supplier.isEmpty ? 'Not specified' : item.supplier,
//               ),
//               const SizedBox(height: 12),

//               _buildDetailRow(
//                 icon: Icons.low_priority,
//                 label: 'Reorder Level',
//                 value: '${item.reorderLevel} units',
//               ),
//               const SizedBox(height: 12),

//               _buildDetailRow(
//                 icon: Icons.calendar_today,
//                 label: 'Created',
//                 value: DateFormat('MMM d, yyyy').format(item.createdAt),
//               ),
//               const SizedBox(height: 12),

//               _buildDetailRow(
//                 icon: Icons.update,
//                 label: 'Last Updated',
//                 value: DateFormat('MMM d, yyyy').format(item.updatedAt),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           if (currentUser?.isAdmin == true) ...[
//             TextButton.icon(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _showAddEditItemDialog(item: item);
//               },
//               icon: const Icon(Icons.edit),
//               label: Text(
//                 'Edit',
//                 style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//               ),
//             ),
//             TextButton.icon(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _showAdjustStockDialog(item);
//               },
//               icon: const Icon(Icons.tune),
//               label: Text(
//                 'Adjust Stock',
//                 style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//               ),
//             ),
//           ],
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Theme.of(context).primaryColor,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: Text(
//               'Close',
//               style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow({
//     required IconData icon,
//     required String label,
//     required String value,
//   }) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           padding: const EdgeInsets.all(6),
//           decoration: BoxDecoration(
//             color: Colors.grey[100],
//             borderRadius: BorderRadius.circular(6),
//           ),
//           child: Icon(icon, size: 16, color: Colors.grey[600]),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: GoogleFonts.poppins(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               Text(
//                 value,
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.grey[800],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// ignore_for_file: use_build_context_synchronously, unnecessary_const

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/inventory_service.dart';
import '../services/auth_service.dart';
import '../models/inventory_item.dart';
import '../models/user_model.dart';
import '../models/stock_prediction.dart';
import 'inventory_form_screen.dart';

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
    Key? key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.decoration = const InputDecoration(),
    this.maxLines = 1,
  }) : super(key: key);

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
  const InventoryListScreen({Key? key}) : super(key: key);

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
  List<String> categories = ['All'];
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
    _scrollController.addListener(_onScroll);
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
    final newCats = ['All', ...loadedCats];
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

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialLoading = true;
    });

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
      debugPrint('Error loading categories: $e');
      _setupTabController(_defaultCategories);
    }

    // Load items (cached)
    try {
      final items = await _getInventoryItemsWithFallback();
      setState(() {
        _allItems.clear();
        _allItems.addAll(items);
        currentUser = AuthService.currentUser;
        _isInitialLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading initial inventory items: $e');
      // Even if error occurred, _getInventoryItemsWithFallback already returns demo data
      setState(() {
        currentUser = AuthService.currentUser;
        _isInitialLoading = false;
      });
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

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Slight delay to show the loading spinner (simulate load)
    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      // increase items limit by one page
      _itemsLimit += _pageSize;
      _isLoadingMore = false;
    });
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
      // Keep the simple call and ensure it times out so it never blocks UI forever
      // We call without offset/limit here (client-side pagination), but keep signature for compatibility.
      final items = await InventoryService.getInventoryItems()
          .timeout(const Duration(seconds: 5));
      return items;
    } catch (e) {
      debugPrint('Error loading inventory items: $e');
      // Return demo data if database fails or times out
      return [
        InventoryItem(
          id: '1',
          name: 'Wireless Mouse',
          description:
              'High-quality wireless mouse for professional use, designed for long hours of productivity with smooth navigation and ergonomic comfort.',
          category: 'Electronics',
          quantity: 15,
          unitPrice: 25.99,
          supplier: 'TechCorp',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now(),
          reorderLevel: 10,
        ),
        InventoryItem(
          id: '2',
          name: 'A4 Paper Ream',
          description:
              'Premium quality A4 paper for office use, suitable for printing, copying, and everyday documentation needs.',
          category: 'Office Supplies',
          quantity: 5,
          unitPrice: 8.99,
          supplier: 'PaperCo',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now(),
          reorderLevel: 10,
        ),
        InventoryItem(
          id: '3',
          name: 'Coffee Beans',
          description:
              'Premium coffee beans (1kg) roasted to perfection, offering a strong aroma and bold flavor ideal for both espresso and filter coffee lovers.',
          category: 'Food & Beverages',
          quantity: 0,
          unitPrice: 24.99,
          supplier: 'BrewMaster',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now(),
          reorderLevel: 5,
        ),
        InventoryItem(
          id: '4',
          name: 'Ergonomic Chair',
          description:
              'Comfortable ergonomic chair with adjustable height, lumbar support, and breathable mesh for improved posture and long sitting sessions.',
          category: 'Furniture',
          quantity: 7,
          unitPrice: 189.50,
          supplier: 'FurniWorld',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now(),
          reorderLevel: 3,
        ),
        InventoryItem(
          id: '5',
          name: 'USB-C Charger',
          description:
              'Fast-charging USB-C charger compatible with multiple devices, offering 65W power delivery for laptops, tablets, and smartphones.',
          category: 'Electronics',
          quantity: 20,
          unitPrice: 29.99,
          supplier: 'ChargePro',
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
          updatedAt: DateTime.now(),
          reorderLevel: 10,
        ),
        InventoryItem(
          id: '6',
          name: 'Water Bottle',
          description:
              'Reusable stainless steel water bottle with insulation, keeps beverages hot for 12 hours and cold for 24 hours, eco-friendly design.',
          category: 'Household',
          quantity: 50,
          unitPrice: 15.99,
          supplier: 'EcoLife',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
          reorderLevel: 20,
        ),
        InventoryItem(
          id: '7',
          name: 'Laptop Stand',
          description:
              'Aluminum adjustable laptop stand that improves airflow and reduces neck strain, suitable for laptops of up to 17 inches.',
          category: 'Electronics',
          quantity: 10,
          unitPrice: 45.00,
          supplier: 'DeskMate',
          createdAt: DateTime.now().subtract(const Duration(days: 6)),
          updatedAt: DateTime.now(),
          reorderLevel: 5,
        ),
        InventoryItem(
          id: '8',
          name: 'Printer Ink Cartridge',
          description:
              'High-yield black ink cartridge designed for smooth and crisp printing, compatible with popular office printer models.',
          category: 'Office Supplies',
          quantity: 25,
          unitPrice: 39.99,
          supplier: 'PrintPlus',
          createdAt: DateTime.now().subtract(const Duration(days: 18)),
          updatedAt: DateTime.now(),
          reorderLevel: 15,
        ),
        InventoryItem(
          id: '9',
          name: 'Notebook',
          description:
              'Hardcover notebook with 200 ruled pages, perfect for note-taking, journaling, and office meetings.',
          category: 'Office Supplies',
          quantity: 60,
          unitPrice: 4.99,
          supplier: 'StationeryHub',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now(),
          reorderLevel: 30,
        ),
        InventoryItem(
          id: '10',
          name: 'LED Desk Lamp',
          description:
              'Energy-efficient LED desk lamp with adjustable brightness levels and a flexible neck, ideal for study and workspaces.',
          category: 'Electronics',
          quantity: 12,
          unitPrice: 34.75,
          supplier: 'BrightLite',
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
          updatedAt: DateTime.now(),
          reorderLevel: 5,
        ),
        InventoryItem(
          id: '11',
          name: 'Bluetooth Headphones',
          description:
              'Wireless over-ear Bluetooth headphones with noise cancellation and 20 hours of battery life, designed for immersive listening.',
          category: 'Electronics',
          quantity: 8,
          unitPrice: 79.99,
          supplier: 'SoundMax',
          createdAt: DateTime.now().subtract(const Duration(days: 9)),
          updatedAt: DateTime.now(),
          reorderLevel: 5,
        ),
        InventoryItem(
          id: '12',
          name: 'Office Desk',
          description:
              'Spacious office desk with drawers and cable management, built with durable wood for a professional look and feel.',
          category: 'Furniture',
          quantity: 3,
          unitPrice: 250.00,
          supplier: 'WorkSpace Furnishings',
          createdAt: DateTime.now().subtract(const Duration(days: 40)),
          updatedAt: DateTime.now(),
          reorderLevel: 2,
        ),
        InventoryItem(
          id: '13',
          name: 'Smartphone',
          description:
              'Latest model smartphone with 128GB storage, high-resolution camera, and 5G connectivity for blazing fast internet speeds.',
          category: 'Electronics',
          quantity: 6,
          unitPrice: 699.99,
          supplier: 'MobileTech',
          createdAt: DateTime.now().subtract(const Duration(days: 12)),
          updatedAt: DateTime.now(),
          reorderLevel: 3,
        ),
        InventoryItem(
          id: '14',
          name: 'Hand Sanitizer',
          description:
              'Portable hand sanitizer gel with aloe vera, kills 99.9% of germs while keeping skin moisturized and refreshed.',
          category: 'Health & Safety',
          quantity: 100,
          unitPrice: 3.49,
          supplier: 'SafeHands',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now(),
          reorderLevel: 50,
        ),
        InventoryItem(
          id: '15',
          name: 'Whiteboard Markers',
          description:
              'Set of 12 whiteboard markers in assorted colors, long-lasting ink and easy to erase without staining.',
          category: 'Office Supplies',
          quantity: 40,
          unitPrice: 12.99,
          supplier: 'MarkerWorld',
          createdAt: DateTime.now().subtract(const Duration(days: 22)),
          updatedAt: DateTime.now(),
          reorderLevel: 20,
        ),
        InventoryItem(
          id: '16',
          name: 'Stapler',
          description:
              'Durable stapler with a sleek design, capable of stapling up to 50 sheets at once, includes starter pack of staples.',
          category: 'Office Supplies',
          quantity: 18,
          unitPrice: 9.50,
          supplier: 'StationeryPro',
          createdAt: DateTime.now().subtract(const Duration(days: 11)),
          updatedAt: DateTime.now(),
          reorderLevel: 10,
        ),
        InventoryItem(
          id: '17',
          name: 'Smartwatch',
          description:
              'Feature-packed smartwatch with fitness tracking, heart rate monitoring, and customizable watch faces.',
          category: 'Electronics',
          quantity: 9,
          unitPrice: 199.99,
          supplier: 'WristTech',
          createdAt: DateTime.now().subtract(const Duration(days: 19)),
          updatedAt: DateTime.now(),
          reorderLevel: 4,
        ),
        InventoryItem(
          id: '18',
          name: 'Projector',
          description:
              'High-definition projector suitable for classrooms and offices, supports HDMI and wireless screen mirroring.',
          category: 'Electronics',
          quantity: 4,
          unitPrice: 450.00,
          supplier: 'VisionPro',
          createdAt: DateTime.now().subtract(const Duration(days: 13)),
          updatedAt: DateTime.now(),
          reorderLevel: 2,
        ),
        InventoryItem(
          id: '19',
          name: 'Desk Organizer',
          description:
              'Multi-compartment desk organizer for pens, notepads, and other small supplies, keeps your workspace neat and tidy.',
          category: 'Office Supplies',
          quantity: 35,
          unitPrice: 14.99,
          supplier: 'NeatSpace',
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
          updatedAt: DateTime.now(),
          reorderLevel: 15,
        ),
        InventoryItem(
          id: '20',
          name: 'External Hard Drive',
          description:
              'Portable external hard drive with 2TB storage, USB 3.0 interface for fast data transfer and secure backup.',
          category: 'Electronics',
          quantity: 14,
          unitPrice: 99.99,
          supplier: 'DataStore',
          createdAt: DateTime.now().subtract(const Duration(days: 16)),
          updatedAt: DateTime.now(),
          reorderLevel: 5,
        ),
        InventoryItem(
          id: '21',
          name: 'Printer Paper',
          description:
              'Standard white printer paper, 500 sheets per ream, smooth surface for professional print results.',
          category: 'Office Supplies',
          quantity: 80,
          unitPrice: 7.99,
          supplier: 'PaperPro',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          updatedAt: DateTime.now(),
          reorderLevel: 40,
        ),
        InventoryItem(
          id: '22',
          name: 'Router',
          description:
              'High-speed wireless router with dual-band connectivity and parental control features.',
          category: 'Electronics',
          quantity: 11,
          unitPrice: 129.99,
          supplier: 'NetLink',
          createdAt: DateTime.now().subtract(const Duration(days: 21)),
          updatedAt: DateTime.now(),
          reorderLevel: 5,
        ),
        InventoryItem(
          id: '23',
          name: 'Backpack',
          description:
              'Durable laptop backpack with multiple compartments, water-resistant material, and padded straps for comfort.',
          category: 'Accessories',
          quantity: 22,
          unitPrice: 54.99,
          supplier: 'CarryAll',
          createdAt: DateTime.now().subtract(const Duration(days: 9)),
          updatedAt: DateTime.now(),
          reorderLevel: 10,
        ),
        InventoryItem(
          id: '24',
          name: 'First Aid Kit',
          description:
              'Comprehensive first aid kit including bandages, antiseptic wipes, scissors, gloves, and more for workplace or home use.',
          category: 'Health & Safety',
          quantity: 12,
          unitPrice: 39.50,
          supplier: 'MediCare Supplies',
          createdAt: DateTime.now().subtract(const Duration(days: 28)),
          updatedAt: DateTime.now(),
          reorderLevel: 6,
        ),
        InventoryItem(
          id: '25',
          name: 'Paper Clips',
          description:
              'Pack of 100 paper clips, rust-resistant and smooth finish for holding documents securely.',
          category: 'Office Supplies',
          quantity: 120,
          unitPrice: 2.50,
          supplier: 'ClipMasters',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
          reorderLevel: 50,
        ),
        InventoryItem(
          id: '26',
          name: 'Surge Protector',
          description:
              '6-outlet surge protector with USB charging ports and safety switch, protects devices from power surges.',
          category: 'Electronics',
          quantity: 17,
          unitPrice: 27.99,
          supplier: 'SafePower',
          createdAt: DateTime.now().subtract(const Duration(days: 24)),
          updatedAt: DateTime.now(),
          reorderLevel: 8,
        ),
        InventoryItem(
          id: '27',
          name: 'CCTV Camera',
          description:
              'Indoor/outdoor CCTV camera with night vision and motion detection, offers real-time monitoring and cloud storage options.',
          category: 'Security',
          quantity: 6,
          unitPrice: 149.99,
          supplier: 'SecureVision',
          createdAt: DateTime.now().subtract(const Duration(days: 32)),
          updatedAt: DateTime.now(),
          reorderLevel: 3,
        ),
        InventoryItem(
          id: '28',
          name: 'Keyboard',
          description:
              'Mechanical keyboard with customizable RGB backlighting, tactile switches, and durable keycaps for gamers and professionals.',
          category: 'Electronics',
          quantity: 13,
          unitPrice: 89.99,
          supplier: 'KeyPro',
          createdAt: DateTime.now().subtract(const Duration(days: 17)),
          updatedAt: DateTime.now(),
          reorderLevel: 5,
        ),
        InventoryItem(
          id: '29',
          name: 'Office Chair Mat',
          description:
              'Durable PVC office chair mat designed to protect floors and allow smooth movement of chairs on carpet or hardwood.',
          category: 'Furniture',
          quantity: 9,
          unitPrice: 45.99,
          supplier: 'ProtectPro',
          createdAt: DateTime.now().subtract(const Duration(days: 27)),
          updatedAt: DateTime.now(),
          reorderLevel: 4,
        ),
        InventoryItem(
          id: '30',
          name: 'Smart LED Bulb',
          description:
              'Energy-efficient smart LED bulb with adjustable brightness and color, controllable via smartphone app or voice assistants.',
          category: 'Electronics',
          quantity: 25,
          unitPrice: 19.99,
          supplier: 'BrightHome',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now(),
          reorderLevel: 10,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText:
                        'Search items by name, description or category...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.primaryColor),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
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
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: theme.primaryColor,
                      unselectedLabelColor: Colors.grey[700],
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
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(c),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),

          // Inventory List
          Expanded(
            child: _isInitialLoading
                ? const Center(child: CircularProgressIndicator())
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

                    final visibleCount = filteredItems.length < _itemsLimit
                        ? filteredItems.length
                        : _itemsLimit;

                    final showLoadMoreFooter = _isLoadingMore;

                    if (filteredItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isNotEmpty ||
                                      selectedCategory != 'All'
                                  ? 'No items match your search'
                                  : 'No inventory items found',
                              style: GoogleFonts.poppins(
                                  fontSize: 18, color: Colors.grey[600]),
                            ),
                            if (currentUser?.isAdmin == true) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Add your first inventory item to get started',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey[500]),
                              ),
                            ],
                          ],
                        ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showItemDetailsDialog(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        if (item.category.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.category,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Stock Prediction
                  FutureBuilder<StockPrediction?>(
                    future: InventoryService.getItemPrediction(item.id),
                    builder: (context, predictionSnapshot) {
                      if (predictionSnapshot.hasData &&
                          predictionSnapshot.data != null) {
                        final prediction = predictionSnapshot.data!;
                        if (prediction.needsRestock &&
                            prediction.daysLeft <= 30) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: prediction.daysLeft <= 7
                                  ? Colors.red[100]
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: prediction.daysLeft <= 7
                                      ? Colors.red[700]
                                      : Colors.orange[700],
                                ),
                                Text(
                                  prediction.daysLeftText,
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: prediction.daysLeft <= 7
                                        ? Colors.red[700]
                                        : Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                      return const SizedBox();
                    },
                  ),
                  const SizedBox(width: 8),
                  // Actions Menu
                  if (currentUser?.isAdmin == true)
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleItemAction(value, item),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                            value: 'adjust', child: Text('Adjust Stock')),
                        const PopupMenuItem(
                            value: 'delete', child: Text('Delete')),
                      ],
                      child: Icon(Icons.more_vert, color: Colors.grey[600]),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              if (item.description.isNotEmpty) ...[
                Text(
                  item.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Details Row
              Row(
                children: [
                  // Quantity
                  Expanded(
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${item.quantity} units',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price
                  Text(
                    '\$${item.unitPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Status and Supplier
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (item.supplier.isNotEmpty)
                    Text(
                      'Supplier: ${item.supplier}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
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
            // Controllers live *inside* the dialog widget tree
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
                      color:
                          Theme.of(parentContext).primaryColor.withOpacity(0.1),
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
                        ),
                        Text(
                          item.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
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
                          Text(
                            'Current quantity: ${item.quantity} units',
                            style: GoogleFonts.poppins(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
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
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
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
        children: const [
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

  // void _showDeleteConfirmation(InventoryItem item) {
  //   showModal(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       title: Row(
  //         children: [
  //           Container(
  //             padding: const EdgeInsets.all(8),
  //             decoration: BoxDecoration(
  //               color: Colors.red[50],
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             child: Icon(
  //               Icons.delete_outline,
  //               color: Colors.red[600],
  //               size: 24,
  //             ),
  //           ),
  //           const SizedBox(width: 12),
  //           Text(
  //             'Delete Item',
  //             style: GoogleFonts.poppins(
  //               fontSize: 18,
  //               fontWeight: FontWeight.w600,
  //               color: Colors.red[700],
  //             ),
  //           ),
  //         ],
  //       ),
  //       content: Container(
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           color: Colors.red[50],
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(color: Colors.red[200]!),
  //         ),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Icon(
  //               Icons.warning_amber_rounded,
  //               color: Colors.red[600],
  //               size: 48,
  //             ),
  //             const SizedBox(height: 12),
  //             Text(
  //               'Are you sure you want to delete "${item.name}"?',
  //               style: GoogleFonts.poppins(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w500,
  //                 color: Colors.red[800],
  //               ),
  //               textAlign: TextAlign.center,
  //             ),
  //             const SizedBox(height: 8),
  //             Text(
  //               'This action cannot be undone and will permanently remove all associated data.',
  //               style: GoogleFonts.poppins(
  //                 fontSize: 12,
  //                 color: Colors.red[600],
  //               ),
  //               textAlign: TextAlign.center,
  //             ),
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           style: TextButton.styleFrom(
  //             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  //           ),
  //           child: Text(
  //             'Cancel',
  //             style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
  //           ),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => _deleteItem(item),
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: Colors.red[600],
  //             foregroundColor: Colors.white,
  //             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //           ),
  //           child: Text(
  //             'Delete',
  //             style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.inventory_2,
                color: Theme.of(context).primaryColor,
                size: 24,
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
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.category.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.category,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
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
                value: '\$${item.unitPrice.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),

              _buildDetailRow(
                icon: Icons.business,
                label: 'Supplier',
                value: item.supplier.isEmpty ? 'Not specified' : item.supplier,
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
        actions: [
          if (currentUser?.isAdmin == true) ...[
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showAddEditItemDialog(item: item);
              },
              icon: const Icon(Icons.edit),
              label: Text(
                'Edit',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showAdjustStockDialog(item);
              },
              icon: const Icon(Icons.tune),
              label: Text(
                'Adjust Stock',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: Colors.grey[600]),
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
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
