import 'package:sqflite/sqflite.dart';
import 'dart:math';
import '../models/inventory_item.dart';
import '../models/stock_movement.dart';
import '../models/stock_prediction.dart';

class InventoryService {
  // static final _firestore = FirebaseFirestore.instance;
  // static final _auth = FirebaseAuth.instance;
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    try {
      _db = await _initDb();
      // Always populate with synthetic data on first initialization
      await populateWithSyntheticData();
      return _db!;
    } catch (e) {
      print('Database initialization failed: $e');
      // Create a minimal in-memory database as fallback
      _db = await openDatabase(
        ':memory:',
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE inventory_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              description TEXT,
              category TEXT,
              quantity INTEGER DEFAULT 0,
              unitPrice REAL DEFAULT 0.0,
              supplier TEXT,
              createdAt TEXT,
              updatedAt TEXT,
              reorderLevel INTEGER DEFAULT 10,
              imageUrl TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE stock_movements (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              item_id TEXT NOT NULL,
              item_name TEXT,
              type TEXT NOT NULL,
              quantity INTEGER NOT NULL,
              reason TEXT,
              date TEXT NOT NULL,
              user_id TEXT,
              user_name TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE stock_predictions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              item_id TEXT NOT NULL UNIQUE,
              item_name TEXT,
              current_quantity INTEGER,
              average_daily_usage REAL,
              days_left INTEGER,
              predicted_depletion_date TEXT,
              needs_restock INTEGER DEFAULT 0,
              confidence TEXT,
              calculated_at TEXT
            )
          ''');
          await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            display_name TEXT NOT NULL,
            role TEXT NOT NULL,
            created_at TEXT NOT NULL,
            last_login_at TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            profile_photo_path TEXT
          )
          ''');
        },
      );
      await populateWithSyntheticData();
      return _db!;
    }
  }

  static Future<Database> _initDb() async {
    try {
      // Store database in project root directory for easy access
      const path = 'inventory.db';
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE inventory_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              description TEXT,
              category TEXT,
              quantity INTEGER DEFAULT 0,
              unitPrice REAL DEFAULT 0.0,
              supplier TEXT,
              createdAt TEXT,
              updatedAt TEXT,
              reorderLevel INTEGER DEFAULT 10,
              imageUrl TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE stock_movements (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              item_id TEXT NOT NULL,
              item_name TEXT,
              type TEXT NOT NULL,
              quantity INTEGER NOT NULL,
              reason TEXT,
              date TEXT NOT NULL,
              user_id TEXT,
              user_name TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE stock_predictions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              item_id TEXT NOT NULL UNIQUE,
              item_name TEXT,
              current_quantity INTEGER,
              average_daily_usage REAL,
              days_left INTEGER,
              predicted_depletion_date TEXT,
              needs_restock INTEGER DEFAULT 0,
              confidence TEXT,
              calculated_at TEXT
            )
          ''');
          await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            display_name TEXT NOT NULL,
            role TEXT NOT NULL,
            created_at TEXT NOT NULL,
            last_login_at TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            profile_photo_path TEXT
          )
          ''');
        },
      );
      return db;
    } catch (e) {
      print('Database initialization failed: $e');
      rethrow;
    }
  }

  static const String _inventoryTable = 'inventory_items';
  static const String _movementsTable = 'stock_movements';
  static const String _predictionsTable = 'stock_predictions';

  // Inventory Items CRUD
  // static Future<List<InventoryItem>> getInventoryItems(
  //     {required int offset,
  //     required int limit,
  //     required String searchQuery}) async {
  //   final db = await database;
  //   final maps = await db.query(_inventoryTable, orderBy: 'name');
  //   return maps
  //       .map((map) => InventoryItem.fromMap(map, map['id'].toString()))
  //       .toList();
  // }

  static Future<List<InventoryItem>> getInventoryItems({
    int offset = 0,
    int limit = 20,
    String? searchQuery,
    String? category,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClause = 'WHERE name LIKE ? OR category LIKE ?';
      whereArgs = ['%$searchQuery%', '%$searchQuery%'];
    }

    final result = await db.rawQuery('''
      SELECT * FROM inventory
      $whereClause
      ORDER BY name ASC
      LIMIT ? OFFSET ?
    ''', [...whereArgs, limit, offset]);

    return result
        .map((row) => InventoryItem.fromMap(row, row['id'].toString()))
        .toList();
  }

  static Future<int> addInventoryItem(InventoryItem item) async {
    final db = await database;
    final id = await db.insert(_inventoryTable, item.toMap());
    // Log initial stock movement
    await _logStockMovement(StockMovement(
      id: '',
      itemId: id.toString(),
      itemName: item.name,
      type: MovementType.stockIn,
      quantity: item.quantity,
      reason: 'Initial stock',
      timestamp: DateTime.now(),
      userId: '',
      userName: 'Local',
    ));
    return id;
  }

  static Future<void> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    await db.update(_inventoryTable, item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  static Future<void> deleteInventoryItem(String itemId) async {
    final db = await database;
    await db.delete(_inventoryTable, where: 'id = ?', whereArgs: [itemId]);
    await _deleteItemMovements(itemId);
    await _deletePrediction(itemId);
  }

  static Future<void> adjustStock(
      String itemId, int newQuantity, String reason) async {
    final db = await database;
    final maps =
        await db.query(_inventoryTable, where: 'id = ?', whereArgs: [itemId]);
    if (maps.isEmpty) throw Exception('Item not found');
    final currentItem = InventoryItem.fromMap(maps.first, itemId);
    final difference = newQuantity - currentItem.quantity;
    await db.update(_inventoryTable, {'quantity': newQuantity},
        where: 'id = ?', whereArgs: [itemId]);
    if (difference != 0) {
      await _logStockMovement(StockMovement(
        id: '',
        itemId: itemId,
        itemName: currentItem.name,
        type: difference > 0 ? MovementType.stockIn : MovementType.stockOut,
        quantity: difference.abs(),
        reason: reason,
        timestamp: DateTime.now(),
        userId: '',
        userName: 'Local',
      ));
    }
    await _recalculatePrediction(itemId);
  }

  // Stock Movements
  static Future<List<StockMovement>> getStockMovements(
      {String? itemId, int limit = 100}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (itemId != null) {
      maps = await db.query(_movementsTable,
          where: 'item_id = ?',
          whereArgs: [itemId],
          orderBy: 'date DESC',
          limit: limit);
    } else {
      maps =
          await db.query(_movementsTable, orderBy: 'date DESC', limit: limit);
    }
    return maps
        .map((map) => StockMovement.fromMap(map, map['id'].toString()))
        .toList();
  }

  static Future<void> _logStockMovement(StockMovement movement) async {
    final db = await database;
    await db.insert(_movementsTable, movement.toMap());
  }

  // Stock Predictions
  static Future<List<StockPrediction>> getStockPredictions() async {
    final db = await database;
    final maps = await db.query(_predictionsTable,
        where: 'needs_restock = ?', whereArgs: [1], orderBy: 'days_left');
    return maps.map((map) => StockPrediction.fromMap(map)).toList();
  }

  static Future<StockPrediction?> getItemPrediction(String itemId) async {
    final db = await database;
    final maps = await db
        .query(_predictionsTable, where: 'item_id = ?', whereArgs: [itemId]);
    if (maps.isEmpty) return null;
    return StockPrediction.fromMap(maps.first);
  }

  static Future<void> _recalculatePrediction(String itemId) async {
    try {
      final db = await database;
      final itemMaps =
          await db.query(_inventoryTable, where: 'id = ?', whereArgs: [itemId]);
      if (itemMaps.isEmpty) return;
      final item = InventoryItem.fromMap(itemMaps.first, itemId);
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final movementMaps = await db.query(
        _movementsTable,
        where: 'item_id = ? AND date > ?',
        whereArgs: [itemId, thirtyDaysAgo.toIso8601String()],
        orderBy: 'date DESC',
      );
      if (movementMaps.isEmpty) {
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
      double totalUsage = 0;
      int usageDays = 0;
      final movements = movementMaps
          .map((map) => StockMovement.fromMap(map, map['id'].toString()))
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
      // For production, log error to server instead of printing
      print('Error calculating prediction for item $itemId: $e');
    }
  }

  static Future<void> _savePrediction(StockPrediction prediction) async {
    final db = await database;
    final maps = await db.query(_predictionsTable,
        where: 'item_id = ?', whereArgs: [prediction.itemId]);
    if (maps.isEmpty) {
      await db.insert(_predictionsTable, prediction.toMap());
    } else {
      await db.update(_predictionsTable, prediction.toMap(),
          where: 'item_id = ?', whereArgs: [prediction.itemId]);
    }
  }

  // Helper methods
  static Future<void> _deleteItemMovements(String itemId) async {
    final db = await database;
    await db.delete(_movementsTable, where: 'item_id = ?', whereArgs: [itemId]);
  }

  static Future<void> _deletePrediction(String itemId) async {
    final db = await database;
    await db
        .delete(_predictionsTable, where: 'item_id = ?', whereArgs: [itemId]);
  }

  // Dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    final itemsMaps = await db.query(_inventoryTable);
    final items = itemsMaps
        .map((map) => InventoryItem.fromMap(map, map['id'].toString()))
        .toList();
    final totalItems = items.length;
    final totalValue = items.fold<double>(
        0, (sum, item) => sum + (item.quantity * item.unitPrice));
    final lowStockItems =
        items.where((item) => item.quantity <= item.reorderLevel).length;
    final outOfStockItems = items.where((item) => item.quantity == 0).length;
    final predictionsMaps = await db
        .query(_predictionsTable, where: 'needs_restock = ?', whereArgs: [1]);
    return {
      'totalItems': totalItems,
      'totalValue': totalValue,
      'lowStockItems': lowStockItems,
      'outOfStockItems': outOfStockItems,
      'itemsNeedingRestock': predictionsMaps.length,
    };
  }

  // Categories
  // static Future<List<String>> getCategories() async {
  //   final db = await database;
  //   final maps = await db.query(_inventoryTable, columns: ['category']);
  //   final categories = maps
  //       .map((map) => map['category'] as String? ?? '')
  //       .where((c) => c.isNotEmpty)
  //       .toSet()
  //       .toList();
  //   categories.sort();
  //   return categories;
  // }

  static Future<List<String>> getCategories() async {
    final db = await database;

    // Get categories
    final result = await db.query('categories', orderBy: 'name ASC');

    if (result.isEmpty) {
      // Default categories
      final defaults = [
        'Electronics',
        'Furniture',
        'Office Supplies',
        'Groceries',
        'Clothing'
      ];
      for (final cat in defaults) {
        await db.insert('categories', {'name': cat});
      }
      // Re-query after insert
      return defaults;
    }

    return result.map((row) => row['name'] as String).toList();
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

  // Synthetic data population for testing
  static Future<void> populateWithSyntheticData() async {
    try {
      final db = await database;

      // Check if data already exists
      final existingItems = await db.query(_inventoryTable, limit: 1);
      if (existingItems.isNotEmpty) {
        print(
            'Database already contains data. Skipping synthetic data population.');
        return;
      }

      print('Populating database with synthetic data...');

      final random = Random();
      final categories = getPredefinedCategories();
      categories.removeLast(); // Remove "Other" for synthetic data

      final sampleItems = [
        // Electronics
        {
          'name': 'Wireless Mouse',
          'category': 'Electronics',
          'supplier': 'TechCorp',
          'price': 25.99
        },
        {
          'name': 'USB-C Cable',
          'category': 'Electronics',
          'supplier': 'TechCorp',
          'price': 12.50
        },
        {
          'name': 'Bluetooth Headphones',
          'category': 'Electronics',
          'supplier': 'AudioMax',
          'price': 89.99
        },
        {
          'name': 'Laptop Stand',
          'category': 'Electronics',
          'supplier': 'ErgoTech',
          'price': 45.00
        },
        {
          'name': 'Power Bank',
          'category': 'Electronics',
          'supplier': 'PowerPlus',
          'price': 35.75
        },

        // Office Supplies
        {
          'name': 'A4 Paper Ream',
          'category': 'Office Supplies',
          'supplier': 'PaperCo',
          'price': 8.99
        },
        {
          'name': 'Blue Ink Pens (Pack of 10)',
          'category': 'Office Supplies',
          'supplier': 'WriteMate',
          'price': 5.50
        },
        {
          'name': 'Sticky Notes',
          'category': 'Office Supplies',
          'supplier': 'NotePad Inc',
          'price': 3.25
        },
        {
          'name': 'Stapler',
          'category': 'Office Supplies',
          'supplier': 'OfficeMax',
          'price': 15.99
        },
        {
          'name': 'File Folders (Pack of 25)',
          'category': 'Office Supplies',
          'supplier': 'OrganizePro',
          'price': 12.75
        },

        // Food & Beverages
        {
          'name': 'Coffee Beans (1kg)',
          'category': 'Food & Beverages',
          'supplier': 'BrewMaster',
          'price': 24.99
        },
        {
          'name': 'Green Tea Bags (100ct)',
          'category': 'Food & Beverages',
          'supplier': 'TeaTime',
          'price': 18.50
        },
        {
          'name': 'Bottled Water (24 pack)',
          'category': 'Food & Beverages',
          'supplier': 'PureWater',
          'price': 6.99
        },
        {
          'name': 'Energy Bars (12 pack)',
          'category': 'Food & Beverages',
          'supplier': 'HealthySnacks',
          'price': 19.99
        },

        // Tools & Equipment
        {
          'name': 'Screwdriver Set',
          'category': 'Tools & Equipment',
          'supplier': 'ToolMaster',
          'price': 29.99
        },
        {
          'name': 'Measuring Tape',
          'category': 'Tools & Equipment',
          'supplier': 'PrecisionTools',
          'price': 12.99
        },
        {
          'name': 'Safety Goggles',
          'category': 'Tools & Equipment',
          'supplier': 'SafetyFirst',
          'price': 8.75
        },
        {
          'name': 'Work Gloves (Pair)',
          'category': 'Tools & Equipment',
          'supplier': 'ProtectPro',
          'price': 6.50
        },

        // Medical Supplies
        {
          'name': 'First Aid Kit',
          'category': 'Medical Supplies',
          'supplier': 'MedSupply',
          'price': 45.99
        },
        {
          'name': 'Disposable Masks (50 pack)',
          'category': 'Medical Supplies',
          'supplier': 'HealthGuard',
          'price': 15.99
        },
        {
          'name': 'Hand Sanitizer (500ml)',
          'category': 'Medical Supplies',
          'supplier': 'CleanHands',
          'price': 7.99
        },

        // Cleaning Supplies
        {
          'name': 'All-Purpose Cleaner',
          'category': 'Cleaning Supplies',
          'supplier': 'CleanPro',
          'price': 4.99
        },
        {
          'name': 'Microfiber Cloths (10 pack)',
          'category': 'Cleaning Supplies',
          'supplier': 'WipeClean',
          'price': 12.99
        },
        {
          'name': 'Trash Bags (50 count)',
          'category': 'Cleaning Supplies',
          'supplier': 'WasteMgmt',
          'price': 8.50
        },
      ];

      for (int i = 0; i < sampleItems.length; i++) {
        final itemData = sampleItems[i];
        final quantity = random.nextInt(100) + 1; // 1-100
        final reorderLevel = [5, 10, 15, 20, 25][random.nextInt(5)];

        final item = InventoryItem(
          id: '',
          name: itemData['name'] as String,
          description: 'High-quality ${itemData['name']} for professional use',
          category: itemData['category'] as String,
          quantity: quantity,
          unitPrice: itemData['price'] as double,
          supplier: itemData['supplier'] as String,
          createdAt:
              DateTime.now().subtract(Duration(days: random.nextInt(30))),
          updatedAt: DateTime.now(),
          reorderLevel: reorderLevel,
        );

        final itemId = await addInventoryItem(item);

        // Add some random stock movements for realistic data
        final movementCount = random.nextInt(5) + 1;
        for (int j = 0; j < movementCount; j++) {
          final isStockOut = random.nextBool();
          final movementQuantity = random.nextInt(10) + 1;
          final daysAgo = random.nextInt(30);

          await _logStockMovement(StockMovement(
            id: '',
            itemId: itemId.toString(),
            itemName: item.name,
            type: isStockOut ? MovementType.stockOut : MovementType.stockIn,
            quantity: movementQuantity,
            reason: isStockOut
                ? ['Sale', 'Usage', 'Damaged', 'Return'][random.nextInt(4)]
                : [
                    'Purchase',
                    'Return',
                    'Adjustment',
                    'Transfer'
                  ][random.nextInt(4)],
            timestamp: DateTime.now().subtract(Duration(days: daysAgo)),
            userId: 'user_${random.nextInt(5) + 1}',
            userName: [
              'John Doe',
              'Jane Smith',
              'Mike Johnson',
              'Sarah Wilson',
              'Admin'
            ][random.nextInt(5)],
          ));
        }

        // Calculate predictions for each item
        await _recalculatePrediction(itemId.toString());
      }

      print(
          'Successfully populated database with ${sampleItems.length} items and their movement history');

      // Check for low stock items and send alerts
      await checkLowStockAndSendAlerts();
    } catch (e) {
      print('Error populating synthetic data: $e');
    }
  }
}
