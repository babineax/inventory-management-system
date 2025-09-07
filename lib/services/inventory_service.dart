import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/inventory_item.dart';
import '../models/stock_movement.dart';
import '../models/stock_prediction.dart';
import '../exceptions/inventory_exceptions.dart';
import 'notification_service.dart';
import 'auth_service.dart';

class InventoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection names
  static const String _inventoryCollection = 'inventory_items';
  static const String _movementsCollection = 'stock_movements';
  static const String _predictionsCollection = 'stock_predictions';
  static const String _categoriesCollection = 'categories';

  // Initialize collections with proper indexes (run once)
  static Future<void> initializeFirestore() async {
    try {
      // Create default categories if they don't exist
      await _initializeCategories();
      print('Firestore collections initialized successfully');
    } catch (e) {
      print('Error initializing Firestore: $e');
      throw InventoryException('Failed to initialize Firestore: $e');
    }
  }

  // Initialize default categories
  static Future<void> _initializeCategories() async {
    try {
      final categoriesSnapshot =
          await _firestore.collection(_categoriesCollection).limit(1).get();

      if (categoriesSnapshot.docs.isEmpty) {
        final defaultCategories = getPredefinedCategories();
        defaultCategories.removeLast(); // Remove "Other"

        final batch = _firestore.batch();
        for (final category in defaultCategories) {
          final docRef = _firestore.collection(_categoriesCollection).doc();
          batch.set(docRef, {'name': category});
        }
        await batch.commit();
        print('Default categories created');
      }
    } catch (e) {
      print('Error initializing categories: $e');
      throw CategoryException('Failed to initialize categories: $e');
    }
  }

  // Inventory Items CRUD
  // static Future<List<InventoryItem>> getInventoryItems({
  //   int offset = 0,
  //   int limit = 20,
  //   String? searchQuery,
  //   String? category,
  // }) async {
  //   try {
  //     // Log current user for debugging
  //     final currentUser = _auth.currentUser;
  //     print(
  //         'Getting inventory items for user: ${currentUser?.uid} (${currentUser?.email})');

  //     Query query = _firestore.collection(_inventoryCollection);

  //     // Apply category filter
  //     if (category != null && category.isNotEmpty && category != 'All') {
  //       query = query.where('category', isEqualTo: category);
  //     }

  //     // Apply search filter (Firestore doesn't support full-text search natively)
  //     // For production, consider using Algolia or similar for better search
  //     if (searchQuery != null && searchQuery.trim().isNotEmpty) {
  //       // Simple prefix search on name field
  //       final searchLower = searchQuery.toLowerCase();
  //       query = query
  //           .where('name', isGreaterThanOrEqualTo: searchLower)
  //           .where('name', isLessThanOrEqualTo: '$searchLower\uf8ff');
  //     }

  //     // Apply pagination
  //     query = query.orderBy('name').limit(limit);
  //     if (offset > 0) {
  //       // For proper pagination, you'd need to use startAfter with document snapshots
  //       // This is a simplified version
  //       final skipQuery = _firestore
  //           .collection(_inventoryCollection)
  //           .orderBy('name')
  //           .limit(offset);
  //       final skipSnapshot = await skipQuery.get();
  //       if (skipSnapshot.docs.isNotEmpty) {
  //         query = query.startAfterDocument(skipSnapshot.docs.last);
  //       }
  //     }

  //     final snapshot = await query.get();
  //     final items = snapshot.docs
  //         .map((doc) =>
  //             InventoryItem.fromMap(doc.data() as Map<String, dynamic>, doc.id))
  //         .toList();

  //     print('Retrieved ${items.length} inventory items');
  //     return items;
  //   } catch (e) {
  //     print('Error getting inventory items: $e');
  //     throw InventoryException('Failed to get inventory items: $e');
  //   }
  // }

  static Future<List<InventoryItem>> getInventoryItems({
    int limit = 20,
    DocumentSnapshot? lastDoc,
    String? searchQuery,
    String? category,
  }) async {
    try {
      Query query = _firestore.collection(_inventoryCollection);

      // Category filter
      if (category != null && category.isNotEmpty && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      // Search filter (basic prefix search on "name")
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        query = query
            .where('name', isGreaterThanOrEqualTo: searchLower)
            .where('name', isLessThanOrEqualTo: '$searchLower\uf8ff');
      }

      // Order and limit
      query = query.orderBy('name').limit(limit);

      // Cursor-based pagination
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => InventoryItem.fromDoc(doc)).toList();
    } catch (e) {
      print('Error getting inventory items: $e');
      throw InventoryException('Failed to get inventory items: $e');
    }
  }

  static Future<String> addInventoryItem(InventoryItem item) async {
    try {
      final docRef =
          await _firestore.collection(_inventoryCollection).add(item.toMap());

      // Log initial stock movement
      await _logStockMovement(StockMovement(
        id: '',
        itemId: docRef.id,
        itemName: item.name,
        type: MovementType.stockIn,
        quantity: item.quantity,
        reason: 'Initial stock',
        timestamp: DateTime.now(),
        userId: _auth.currentUser?.uid ?? '',
        userName: _auth.currentUser?.displayName ?? 'Unknown',
      ));

      // Check if item needs immediate stock alert
      if (item.quantity <= item.reorderLevel) {
        await _triggerStockAlert(item);
      }

      // Check if item is expiring soon
      if (item.isPerishable && item.expiryDate != null) {
        final daysUntilExpiry =
            item.expiryDate!.difference(DateTime.now()).inDays;
        if (daysUntilExpiry <= 7) {
          await _triggerExpiryAlert(item, daysUntilExpiry);
        }
      }

      return docRef.id;
    } catch (e) {
      print('Error adding inventory item: $e');
      throw InventoryItemCreationException('Failed to add inventory item: $e');
    }
  }

  static Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      await _firestore
          .collection(_inventoryCollection)
          .doc(item.id)
          .update(item.toMap());

      // Check if item needs stock alert after update
      if (item.quantity <= item.reorderLevel) {
        await _triggerStockAlert(item);
      }

      // Check if item is expiring soon after update
      if (item.isPerishable && item.expiryDate != null) {
        final daysUntilExpiry =
            item.expiryDate!.difference(DateTime.now()).inDays;
        if (daysUntilExpiry <= 7) {
          await _triggerExpiryAlert(item, daysUntilExpiry);
        }
      }
    } catch (e) {
      print('Error updating inventory item: $e');
      throw InventoryItemUpdateException('Failed to update inventory item: $e');
    }
  }

  static Future<void> deleteInventoryItem(String itemId) async {
    try {
      // Delete the item
      await _firestore.collection(_inventoryCollection).doc(itemId).delete();

      // Delete related movements
      await _deleteItemMovements(itemId);

      // Delete prediction
      await _deletePrediction(itemId);
    } catch (e) {
      print('Error deleting inventory item: $e');
      throw InventoryItemDeletionException(
          'Failed to delete inventory item: $e');
    }
  }

  static Future<void> adjustStock(
      String itemId, int newQuantity, String reason) async {
    try {
      final itemDoc =
          await _firestore.collection(_inventoryCollection).doc(itemId).get();
      if (!itemDoc.exists) throw InventoryItemNotFoundException(itemId);

      final currentItem = InventoryItem.fromDoc(itemDoc);
      final difference = newQuantity - currentItem.quantity;

      // Update quantity
      await _firestore.collection(_inventoryCollection).doc(itemId).update({
        'quantity': newQuantity,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Log movement if there's a difference
      if (difference != 0) {
        await _logStockMovement(StockMovement(
          id: '',
          itemId: itemId,
          itemName: currentItem.name,
          type: difference > 0 ? MovementType.stockIn : MovementType.stockOut,
          quantity: difference.abs(),
          reason: reason,
          timestamp: DateTime.now(),
          userId: _auth.currentUser?.uid ?? '',
          userName: _auth.currentUser?.displayName ?? 'Unknown',
        ));
      }

      // Check if item needs stock alert after adjustment
      if (newQuantity <= currentItem.reorderLevel) {
        final updatedItem = currentItem.copyWith(quantity: newQuantity);
        await _triggerStockAlert(updatedItem);
      }

      // Recalculate prediction and check for prediction alerts
      await _recalculatePrediction(itemId);
      await _checkAndSendPredictionAlert(itemId);
    } catch (e) {
      print('Error adjusting stock: $e');
      throw StockAdjustmentException('Failed to adjust stock: $e');
    }
  }

  // Stock Movements
  static Future<List<StockMovement>> getStockMovements({
    String? itemId,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection(_movementsCollection);

      if (itemId != null) {
        query = query.where('itemId', isEqualTo: itemId);
      }

      query = query.orderBy('timestamp', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) =>
              StockMovement.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting stock movements: $e');
      throw InventoryException('Failed to get stock movements: $e');
    }
  }

  // Get monthly stock movement trends for dashboard
  static Future<List<Map<String, dynamic>>> getMonthlyMovementTrends({
    int monthsBack = 6,
  }) async {
    try {
      final startDate =
          DateTime.now().subtract(Duration(days: monthsBack * 30));

      final snapshot = await _firestore
          .collection(_movementsCollection)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(startDate))
          .orderBy('timestamp')
          .get();

      final movements = snapshot.docs
          .map((doc) => StockMovement.fromMap(doc.data(), doc.id))
          .toList();

      // Group movements by month
      final monthlyData = <String, Map<String, int>>{};

      for (final movement in movements) {
        final monthKey =
            '${movement.timestamp.year}-${movement.timestamp.month.toString().padLeft(2, '0')}';
        final monthName = _getMonthName(movement.timestamp.month);

        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = {
            'stockIn': 0,
            'stockOut': 0,
            'total': 0,
          };
        }

        if (movement.type == MovementType.stockIn) {
          monthlyData[monthKey]!['stockIn'] =
              monthlyData[monthKey]!['stockIn']! + movement.quantity;
        } else if (movement.type == MovementType.stockOut) {
          monthlyData[monthKey]!['stockOut'] =
              monthlyData[monthKey]!['stockOut']! + movement.quantity;
        }

        monthlyData[monthKey]!['total'] =
            monthlyData[monthKey]!['total']! + movement.quantity;
      }

      // Convert to list and sort by date
      final sortedData = monthlyData.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      // Return the last 6 months of data
      return sortedData.take(monthsBack).map((entry) {
        final monthKey = entry.key;
        final year = int.parse(monthKey.split('-')[0]);
        final month = int.parse(monthKey.split('-')[1]);
        final monthName = _getMonthName(month);

        return {
          'month': monthName,
          'value': entry.value['total'],
          'stockIn': entry.value['stockIn'],
          'stockOut': entry.value['stockOut'],
        };
      }).toList();
    } catch (e) {
      print('Error getting monthly movement trends: $e');
      throw InventoryException('Failed to get monthly movement trends: $e');
    }
  }

  static String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  static Future<void> _logStockMovement(StockMovement movement) async {
    try {
      await _firestore.collection(_movementsCollection).add(movement.toMap());
    } catch (e) {
      print('Error logging stock movement: $e');
      throw StockMovementException('Failed to log stock movement: $e');
    }
  }

  // Stock Predictions
  static Future<List<StockPrediction>> getStockPredictions() async {
    try {
      // Get all inventory items first
      final itemsSnapshot =
          await _firestore.collection(_inventoryCollection).get();
      final items =
          itemsSnapshot.docs.map((doc) => InventoryItem.fromDoc(doc)).toList();

      // Generate predictions for all items
      final predictions = <StockPrediction>[];

      for (final item in items) {
        // Check if item needs restock (low stock or expiring soon)
        final isLowStock = item.quantity <= item.reorderLevel;
        final isOutOfStock = item.quantity == 0;

        // Calculate days left based on current stock and reorder level
        int daysLeft;
        if (isOutOfStock) {
          daysLeft = 0;
        } else if (isLowStock) {
          // If low stock, estimate based on remaining quantity
          daysLeft =
              (item.quantity / (item.reorderLevel * 0.1)).ceil().clamp(1, 7);
        } else {
          // Estimate based on stock level
          final stockRatio = item.quantity / item.reorderLevel;
          if (stockRatio > 3) {
            daysLeft = 30 + (stockRatio * 5).toInt();
          } else if (stockRatio > 2) {
            daysLeft = 14 + (stockRatio * 3).toInt();
          } else {
            daysLeft = 7 + (stockRatio * 2).toInt();
          }
        }

        // Check for expiry date if item is perishable
        if (item.isPerishable && item.expiryDate != null) {
          final daysUntilExpiry =
              item.expiryDate!.difference(DateTime.now()).inDays;
          if (daysUntilExpiry < daysLeft) {
            daysLeft = daysUntilExpiry.clamp(0, daysLeft);
          }
        }

        final needsRestock = isLowStock || isOutOfStock || daysLeft <= 7;

        // Determine confidence based on data availability
        PredictionConfidence confidence;
        if (item.isPerishable && item.expiryDate != null) {
          confidence = PredictionConfidence.high;
        } else if (isLowStock || isOutOfStock) {
          confidence = PredictionConfidence.medium;
        } else {
          confidence = PredictionConfidence.low;
        }

        predictions.add(StockPrediction(
          itemId: item.id,
          itemName: item.name,
          currentQuantity: item.quantity,
          averageDailyUsage: item.reorderLevel * 0.1, // Estimated usage
          daysLeft: daysLeft,
          predictedDepletionDate: DateTime.now().add(Duration(days: daysLeft)),
          needsRestock: needsRestock,
          confidence: confidence,
          calculatedAt: DateTime.now(),
        ));
      }

      // Sort by days left (most urgent first)
      predictions.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

      return predictions;
    } catch (e) {
      print('Error getting stock predictions: $e');
      throw InventoryException('Failed to get stock predictions: $e');
    }
  }

  static Future<StockPrediction?> getItemPrediction(String itemId) async {
    try {
      final snapshot = await _firestore
          .collection(_predictionsCollection)
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return StockPrediction.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error getting item prediction: $e');
      // For this method, we'll return null as it's already expected to possibly return null
      return null;
    }
  }

  static Future<void> _recalculatePrediction(String itemId) async {
    try {
      // Get item details
      final itemDoc =
          await _firestore.collection(_inventoryCollection).doc(itemId).get();
      if (!itemDoc.exists) return;

      final item = InventoryItem.fromDoc(itemDoc);

      // Get movements from last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final movementsSnapshot = await _firestore
          .collection(_movementsCollection)
          .where('itemId', isEqualTo: itemId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('timestamp', descending: true)
          .get();

      if (movementsSnapshot.docs.isEmpty) {
        await _savePrediction(StockPrediction(
          itemId: itemId,
          itemName: item.name,
          currentQuantity: item.quantity,
          averageDailyUsage: 0,
          daysLeft: item.quantity > 0 ? 999 : 0,
          predictedDepletionDate: DateTime.now().add(const Duration(days: 999)),
          needsRestock: item.quantity <= item.reorderLevel,
          confidence: PredictionConfidence.low,
          calculatedAt: DateTime.now(),
        ));
        return;
      }

      // Calculate daily usage
      double totalUsage = 0;
      int usageDays = 0;
      final movements = movementsSnapshot.docs
          .map((doc) => StockMovement.fromMap(doc.data(), doc.id))
          .toList();

      final dailyUsage = <String, int>{};
      for (final movement in movements) {
        if (movement.type == MovementType.stockOut) {
          final dateKey = movement.timestamp.toIso8601String().substring(0, 10);
          dailyUsage[dateKey] = (dailyUsage[dateKey] ?? 0) + movement.quantity;
        }
      }

      if (dailyUsage.isNotEmpty) {
        final totalUsageInt = dailyUsage.values.reduce((a, b) => a + b);
        totalUsage = totalUsageInt.toDouble();
        usageDays = dailyUsage.length;
      }

      final averageDailyUsage = usageDays > 0 ? totalUsage / usageDays : 0.0;
      final daysLeft = averageDailyUsage > 0
          ? (item.quantity.toDouble() / averageDailyUsage).ceil()
          : 999;
      final predictedDate = DateTime.now().add(Duration(days: daysLeft));

      PredictionConfidence confidence;
      if (usageDays >= 14) {
        confidence = PredictionConfidence.high;
      } else if (usageDays >= 7) {
        confidence = PredictionConfidence.medium;
      } else {
        confidence = PredictionConfidence.low;
      }

      await _savePrediction(StockPrediction(
        itemId: itemId,
        itemName: item.name,
        currentQuantity: item.quantity,
        averageDailyUsage: averageDailyUsage,
        daysLeft: daysLeft,
        predictedDepletionDate: predictedDate,
        needsRestock: item.quantity <= item.reorderLevel || daysLeft <= 7,
        confidence: confidence,
        calculatedAt: DateTime.now(),
      ));
    } catch (e) {
      print('Error calculating prediction for item $itemId: $e');
      throw PredictionCalculationException(
          'Error calculating prediction for item $itemId: $e');
    }
  }

  static Future<void> _savePrediction(StockPrediction prediction) async {
    try {
      // Check if prediction exists
      final existingSnapshot = await _firestore
          .collection(_predictionsCollection)
          .where('itemId', isEqualTo: prediction.itemId)
          .limit(1)
          .get();

      if (existingSnapshot.docs.isNotEmpty) {
        // Update existing prediction
        await _firestore
            .collection(_predictionsCollection)
            .doc(existingSnapshot.docs.first.id)
            .update(prediction.toMap());
      } else {
        // Create new prediction
        await _firestore
            .collection(_predictionsCollection)
            .add(prediction.toMap());
      }
    } catch (e) {
      print('Error saving prediction: $e');
      throw PredictionCalculationException('Failed to save prediction: $e');
    }
  }

  // Helper methods
  static Future<void> _deleteItemMovements(String itemId) async {
    try {
      final snapshot = await _firestore
          .collection(_movementsCollection)
          .where('itemId', isEqualTo: itemId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting item movements: $e');
      throw InventoryItemDeletionException(
          'Failed to delete item movements: $e');
    }
  }

  static Future<void> _deletePrediction(String itemId) async {
    try {
      final snapshot = await _firestore
          .collection(_predictionsCollection)
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await _firestore
            .collection(_predictionsCollection)
            .doc(snapshot.docs.first.id)
            .delete();
      }
    } catch (e) {
      print('Error deleting prediction: $e');
      throw InventoryItemDeletionException('Failed to delete prediction: $e');
    }
  }

  // Dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final itemsSnapshot =
          await _firestore.collection(_inventoryCollection).get();
      final items =
          itemsSnapshot.docs.map((doc) => InventoryItem.fromDoc(doc)).toList();

      final totalItems = items.length;
      final totalValue = items.fold<double>(
          0, (sum, item) => sum + (item.quantity * item.unitPrice));
      final lowStockItems =
          items.where((item) => item.quantity <= item.reorderLevel).length;
      final outOfStockItems = items.where((item) => item.quantity == 0).length;

      final predictionsSnapshot = await _firestore
          .collection(_predictionsCollection)
          .where('needsRestock', isEqualTo: true)
          .get();

      return {
        'totalItems': totalItems,
        'totalValue': totalValue,
        'lowStockItems': lowStockItems,
        'outOfStockItems': outOfStockItems,
        'itemsNeedingRestock': predictionsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      throw DashboardStatsException('Failed to get dashboard stats: $e');
    }
  }

  // Get category statistics for dashboard
  static Future<Map<String, int>> getCategoryStats() async {
    try {
      final itemsSnapshot =
          await _firestore.collection(_inventoryCollection).get();

      final items =
          itemsSnapshot.docs.map((doc) => InventoryItem.fromDoc(doc)).toList();

      final categoryStats = <String, int>{};

      for (final item in items) {
        final category = item.category.isNotEmpty ? item.category : 'Other';
        categoryStats[category] =
            (categoryStats[category] ?? 0) + item.quantity;
      }

      return categoryStats;
    } catch (e) {
      print('Error getting category stats: $e');
      throw InventoryException('Failed to get category stats: $e');
    }
  }

  // Categories
  static Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection(_categoriesCollection)
          .orderBy('name')
          .get();

      if (snapshot.docs.isEmpty) {
        // Initialize default categories
        await _initializeCategories();
        return getPredefinedCategories();
      }

      return snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
    } catch (e) {
      print('Error getting categories: $e');
      throw CategoryException('Failed to get categories: $e');
    }
  }

  // Predefined categories with "Other" option
  static List<String> getPredefinedCategories() {
    return [
      'Electronics',
      'Office Supplies',
      'Food & Beverages',
      'Clothing & Apparel',
      'Tools & Equipment',
      'Medical Supplies',
      'Automotive',
      'Books & Media',
      'Furniture',
      'Cleaning Supplies',
      'Sports & Recreation',
      'Beauty & Personal Care',
      'Other'
    ];
  }

  // Reorder level options
  static List<int> getReorderLevelOptions() {
    return [5, 10, 15, 20, 25, 30, 50, 75, 100];
  }

  // Email alert functionality (simulated for now)
  static Future<void> checkLowStockAndSendAlerts() async {
    try {
      final items = await getInventoryItems();
      final lowStockItems = items
          .where((item) =>
              item.quantity <= item.reorderLevel || item.quantity == 0)
          .toList();

      if (lowStockItems.isNotEmpty) {
        await _sendLowStockAlert(lowStockItems);
      }
    } catch (e) {
      print('Error checking low stock: $e');
      throw InventoryException('Failed to check low stock: $e');
    }
  }

  static Future<void> _sendLowStockAlert(
      List<InventoryItem> lowStockItems) async {
    // In a real app, this would send actual emails
    // For now, this implementation just logs the alert
    print('🚨 LOW STOCK ALERT 🚨');
    print('The following items need restocking:');
    for (final item in lowStockItems) {
      if (item.quantity == 0) {
        print('❌ OUT OF STOCK: ${item.name}');
      } else {
        print(
            '⚠️  LOW STOCK: ${item.name} (${item.quantity} remaining, reorder at ${item.reorderLevel})');
      }
    }
    print('Please restock these items as soon as possible.');

    // Send notifications to all active users
    try {
      final users = await AuthService.getAllUsers();
      for (final user in users) {
        if (user.isActive && user.stockAlertsEnabled) {
          for (final item in lowStockItems) {
            await NotificationService.sendStockAlert(user: user, item: item);
          }
        }
      }
    } catch (e) {
      print('Error sending stock alert notifications: $e');
    }
  }

  // Trigger stock alert for a specific item
  static Future<void> _triggerStockAlert(InventoryItem item) async {
    try {
      final users = await AuthService.getAllUsers();
      for (final user in users) {
        if (user.isActive && user.stockAlertsEnabled) {
          await NotificationService.sendStockAlert(user: user, item: item);
        }
      }
    } catch (e) {
      print('Error triggering stock alert: $e');
    }
  }

  // Trigger expiry alert for a specific item
  static Future<void> _triggerExpiryAlert(
      InventoryItem item, int daysUntilExpiry) async {
    try {
      final users = await AuthService.getAllUsers();
      for (final user in users) {
        if (user.isActive && user.expiryAlertsEnabled) {
          await NotificationService.sendExpiryAlert(
            user: user,
            item: item,
            daysUntilExpiry: daysUntilExpiry,
          );
        }
      }
    } catch (e) {
      print('Error triggering expiry alert: $e');
    }
  }

  // Check and send prediction alert for a specific item
  static Future<void> _checkAndSendPredictionAlert(String itemId) async {
    try {
      final prediction = await getItemPrediction(itemId);
      if (prediction != null && prediction.needsRestock) {
        final users = await AuthService.getAllUsers();
        for (final user in users) {
          if (user.isActive && user.predictionAlertsEnabled) {
            await NotificationService.sendPredictionAlert(
              user: user,
              itemName: prediction.itemName,
              predictionType: 'Stock Depletion',
              predictionMessage:
                  'This item is predicted to run out in ${prediction.daysLeft} days',
              predictionData: {
                'Current Quantity': '${prediction.currentQuantity} units',
                'Daily Usage':
                    '${prediction.averageDailyUsage.toStringAsFixed(1)} units/day',
                'Days Remaining': '${prediction.daysLeft} days',
                'Predicted Depletion': prediction.predictedDepletionDate
                    .toString()
                    .substring(0, 10),
                'Confidence': prediction.confidence
                    .toString()
                    .split('.')
                    .last
                    .toUpperCase(),
              },
            );
          }
        }
      }
    } catch (e) {
      print('Error checking prediction alert: $e');
    }
  }

  // Add this method to your InventoryService class
  static Future<dynamic> getUserData(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        // Assuming you have a UserModel class that can parse from Firestore
        // This is a placeholder - you'll need to implement this based on your UserModel structure
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      throw InventoryException('Failed to get user data: $e');
    }
  }
}
