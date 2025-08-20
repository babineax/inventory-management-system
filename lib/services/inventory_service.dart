import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/inventory_item.dart';
import '../models/stock_movement.dart';
import '../models/stock_prediction.dart';

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
    }
  }

  // Inventory Items CRUD
  static Future<List<InventoryItem>> getInventoryItems({
    int offset = 0,
    int limit = 20,
    String? searchQuery,
    String? category,
  }) async {
    try {
      Query query = _firestore.collection(_inventoryCollection);

      // Apply category filter
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      // Apply search filter (Firestore doesn't support full-text search natively)
      // For production, consider using Algolia or similar for better search
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        // Simple prefix search on name field
        final searchLower = searchQuery.toLowerCase();
        query = query
            .where('name', isGreaterThanOrEqualTo: searchLower)
            .where('name', isLessThanOrEqualTo: '$searchLower\uf8ff');
      }

      // Apply pagination
      query = query.orderBy('name').limit(limit);
      if (offset > 0) {
        // For proper pagination, you'd need to use startAfter with document snapshots
        // This is a simplified version
        final skipQuery = _firestore
            .collection(_inventoryCollection)
            .orderBy('name')
            .limit(offset);
        final skipSnapshot = await skipQuery.get();
        if (skipSnapshot.docs.isNotEmpty) {
          query = query.startAfterDocument(skipSnapshot.docs.last);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) =>
              InventoryItem.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting inventory items: $e');
      return [];
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

      return docRef.id;
    } catch (e) {
      print('Error adding inventory item: $e');
      throw Exception('Failed to add inventory item: $e');
    }
  }

  static Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      await _firestore
          .collection(_inventoryCollection)
          .doc(item.id)
          .update(item.toMap());
    } catch (e) {
      print('Error updating inventory item: $e');
      throw Exception('Failed to update inventory item: $e');
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
      throw Exception('Failed to delete inventory item: $e');
    }
  }

  static Future<void> adjustStock(
      String itemId, int newQuantity, String reason) async {
    try {
      final itemDoc =
          await _firestore.collection(_inventoryCollection).doc(itemId).get();
      if (!itemDoc.exists) throw Exception('Item not found');

      final currentItem = InventoryItem.fromMap(itemDoc.data()!, itemId);
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

      // Recalculate prediction
      await _recalculatePrediction(itemId);
    } catch (e) {
      print('Error adjusting stock: $e');
      throw Exception('Failed to adjust stock: $e');
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
      return [];
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
      return [];
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
    }
  }

  // Stock Predictions
  static Future<List<StockPrediction>> getStockPredictions() async {
    try {
      final snapshot = await _firestore
          .collection(_predictionsCollection)
          .where('needsRestock', isEqualTo: true)
          .orderBy('daysLeft')
          .get();

      return snapshot.docs
          .map((doc) => StockPrediction.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting stock predictions: $e');
      return [];
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
      return null;
    }
  }

  static Future<void> _recalculatePrediction(String itemId) async {
    try {
      // Get item details
      final itemDoc =
          await _firestore.collection(_inventoryCollection).doc(itemId).get();
      if (!itemDoc.exists) return;

      final item = InventoryItem.fromMap(itemDoc.data()!, itemId);

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
    }
  }

  // Dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final itemsSnapshot =
          await _firestore.collection(_inventoryCollection).get();
      final items = itemsSnapshot.docs
          .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
          .toList();

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
      return {
        'totalItems': 0,
        'totalValue': 0.0,
        'lowStockItems': 0,
        'outOfStockItems': 0,
        'itemsNeedingRestock': 0,
      };
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
      return getPredefinedCategories();
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

    // TODO: Implement actual email sending using a service.
    // Example implementation:
    // await EmailService.sendLowStockAlert(lowStockItems);
  }
}
