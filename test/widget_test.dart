// // This is a basic Flutter widget test for the Inventory Management System.
// //
// // To perform an interaction with a widget in your test, use the WidgetTester
// // utility in the flutter_test package. For example, you can send tap and scroll
// // gestures. You can also use WidgetTester to find child widgets in the widget
// // tree, read text, and verify that the values of widget properties are correct.

// import 'package:flutter_test/flutter_test.dart';

// import 'package:inventory_management_system/models/inventory_item.dart';
// import 'package:inventory_management_system/models/user_model.dart';
// import 'package:inventory_management_system/models/stock_movement.dart';
// import 'package:inventory_management_system/models/stock_prediction.dart';

// void main() {
//   group('Model Tests', () {
//     test('InventoryItem model creation', () {
//       final item = InventoryItem(
//         id: '3',
//         name: 'Out of Stock Item',
//         description: 'Test Description',
//         category: 'Test Category',
//         quantity: 0,
//         unitPrice: 35.99,
//         supplier: 'Test Supplier',
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         reorderLevel: 5,
//       );

//       expect(item.name, 'Out of Stock Item');
//       expect(item.quantity, 0);
//       expect(item.unitPrice, 35.99);
//       expect(item.reorderLevel, 5);
//     });

//     test('InventoryItem copyWith method', () {
//       final now = DateTime.now();
//       final item = InventoryItem(
//         id: '1',
//         name: 'Test Item',
//         description: 'Test Description',
//         category: 'Test Category',
//         quantity: 10,
//         unitPrice: 9.99,
//         supplier: 'Test Supplier',
//         createdAt: now,
//         updatedAt: now,
//         reorderLevel: 5,
//       );

//       final updatedItem = item.copyWith(
//         name: 'Updated Item',
//         quantity: 20,
//       );

//       expect(updatedItem.name, 'Updated Item');
//       expect(updatedItem.quantity, 20);
//       expect(updatedItem.unitPrice, 9.99); // Should remain unchanged
//       expect(updatedItem.id, '1'); // Should remain unchanged
//     });

//     test('InventoryItem toMap', () {
//       final now = DateTime.now();
//       final item = InventoryItem(
//         id: '1',
//         name: 'Test Item',
//         description: 'Test Description',
//         category: 'Test Category',
//         quantity: 10,
//         unitPrice: 9.99,
//         supplier: 'Test Supplier',
//         createdAt: now,
//         updatedAt: now,
//         reorderLevel: 5,
//       );

//       final map = item.toMap();
//       expect(map['name'], 'Test Item');
//       expect(map['quantity'], 10);
//       expect(map['unitPrice'], 9.99);
//       expect(map['category'], 'Test Category');
//       expect(map['supplier'], 'Test Supplier');
//       expect(map['reorderLevel'], 5);
//     });

//     test('User model role checks', () {
//       final adminUser = AppUser(
//         id: '1',
//         email: 'admin@test.com',
//         displayName: 'Admin User',
//         role: UserRole.admin,
//         createdAt: DateTime.now(),
//         lastLoginAt: DateTime.now(),
//         isActive: true,
//       );

//       final staffUser = AppUser(
//         id: '2',
//         email: 'staff@test.com',
//         displayName: 'Staff User',
//         role: UserRole.staff,
//         createdAt: DateTime.now(),
//         lastLoginAt: DateTime.now(),
//         isActive: true,
//       );

//       expect(adminUser.isAdmin, true);
//       expect(adminUser.isStaff, false);
//       expect(staffUser.isAdmin, false);
//       expect(staffUser.isStaff, true);
//     });

//     test('User model copyWith method', () {
//       final user = AppUser(
//         id: '1',
//         email: 'test@test.com',
//         displayName: 'Test User',
//         role: UserRole.staff,
//         createdAt: DateTime.now(),
//         lastLoginAt: DateTime.now(),
//         isActive: true,
//       );

//       final updatedUser = user.copyWith(
//         displayName: 'Updated User',
//         role: UserRole.admin,
//       );

//       expect(updatedUser.displayName, 'Updated User');
//       expect(updatedUser.role, UserRole.admin);
//       expect(updatedUser.email, 'test@test.com'); // Should remain unchanged
//     });

//     test('StockMovement model creation', () {
//       final movement = StockMovement(
//         id: '1',
//         itemId: 'item1',
//         itemName: 'Test Item',
//         type: MovementType.stockIn,
//         quantity: 5,
//         reason: 'Initial stock',
//         timestamp: DateTime.now(),
//         userId: 'user1',
//         userName: 'Test User',
//       );

//       expect(movement.itemName, 'Test Item');
//       expect(movement.type, MovementType.stockIn);
//       expect(movement.quantity, 5);
//       expect(movement.reason, 'Initial stock');
//     });

//     test('StockMovement toMap', () {
//       final now = DateTime.now();
//       final movement = StockMovement(
//         id: '1',
//         itemId: 'item1',
//         itemName: 'Test Item',
//         type: MovementType.stockOut,
//         quantity: 3,
//         reason: 'Sale',
//         timestamp: now,
//         userId: 'user1',
//         userName: 'Test User',
//       );

//       final map = movement.toMap();
//       expect(map['item_id'], 'item1');
//       expect(map['item_name'], 'Test Item');
//       expect(map['type'], 'stockOut');
//       expect(map['quantity'], 3);
//       expect(map['reason'], 'Sale');
//       expect(map['user_id'], 'user1');
//       expect(map['user_name'], 'Test User');
//     });

//     test('StockPrediction model creation', () {
//       final now = DateTime.now();
//       final prediction = StockPrediction(
//         itemId: 'item1',
//         itemName: 'Test Item',
//         currentQuantity: 10,
//         averageDailyUsage: 2.0,
//         daysLeft: 5,
//         predictedDepletionDate: now.add(const Duration(days: 5)),
//         needsRestock: true,
//         confidence: PredictionConfidence.high,
//         calculatedAt: now,
//       );

//       expect(prediction.itemName, 'Test Item');
//       expect(prediction.currentQuantity, 10);
//       expect(prediction.averageDailyUsage, 2.0);
//       expect(prediction.daysLeft, 5);
//       expect(prediction.needsRestock, true);
//       expect(prediction.confidence, PredictionConfidence.high);
//     });

//     test('StockPrediction daysLeftText', () {
//       final now = DateTime.now();

//       // Test out of stock
//       final outOfStock = StockPrediction(
//         itemId: 'item1',
//         itemName: 'Test Item',
//         currentQuantity: 0,
//         averageDailyUsage: 2.0,
//         daysLeft: 0,
//         predictedDepletionDate: now,
//         needsRestock: true,
//         confidence: PredictionConfidence.high,
//         calculatedAt: now,
//       );
//       expect(outOfStock.daysLeftText, 'Out of stock');

//       // Test 1 day left
//       final oneDay = StockPrediction(
//         itemId: 'item1',
//         itemName: 'Test Item',
//         currentQuantity: 2,
//         averageDailyUsage: 2.0,
//         daysLeft: 1,
//         predictedDepletionDate: now.add(const Duration(days: 1)),
//         needsRestock: true,
//         confidence: PredictionConfidence.high,
//         calculatedAt: now,
//       );
//       expect(oneDay.daysLeftText, '1 day left');

//       // Test multiple days
//       final multipleDays = StockPrediction(
//         itemId: 'item1',
//         itemName: 'Test Item',
//         currentQuantity: 10,
//         averageDailyUsage: 2.0,
//         daysLeft: 5,
//         predictedDepletionDate: now.add(const Duration(days: 5)),
//         needsRestock: false,
//         confidence: PredictionConfidence.high,
//         calculatedAt: now,
//       );
//       expect(multipleDays.daysLeftText, '5 days left');
//     });

//     test('StockPrediction confidenceText', () {
//       final now = DateTime.now();

//       final highConfidence = StockPrediction(
//         itemId: 'item1',
//         itemName: 'Test Item',
//         currentQuantity: 10,
//         averageDailyUsage: 2.0,
//         daysLeft: 5,
//         predictedDepletionDate: now.add(const Duration(days: 5)),
//         needsRestock: false,
//         confidence: PredictionConfidence.high,
//         calculatedAt: now,
//       );
//       expect(highConfidence.confidenceText, 'High confidence');

//       final mediumConfidence = highConfidence.copyWith(
//         confidence: PredictionConfidence.medium,
//       );
//       expect(mediumConfidence.confidenceText, 'Medium confidence');

//       final lowConfidence = highConfidence.copyWith(
//         confidence: PredictionConfidence.low,
//       );
//       expect(lowConfidence.confidenceText, 'Low confidence');
//     });

//     test('StockPrediction usageText', () {
//       final now = DateTime.now();

//       // Test daily usage > 1
//       final dailyUsage = StockPrediction(
//         itemId: 'item1',
//         itemName: 'Test Item',
//         currentQuantity: 10,
//         averageDailyUsage: 2.5,
//         daysLeft: 4,
//         predictedDepletionDate: now.add(const Duration(days: 4)),
//         needsRestock: false,
//         confidence: PredictionConfidence.high,
//         calculatedAt: now,
//       );
//       expect(dailyUsage.usageText, '2.5 per day');

//       // Test weekly usage < 1 per day
//       final weeklyUsage = StockPrediction(
//         itemId: 'item1',
//         itemName: 'Test Item',
//         currentQuantity: 10,
//         averageDailyUsage: 0.5,
//         daysLeft: 20,
//         predictedDepletionDate: now.add(const Duration(days: 20)),
//         needsRestock: false,
//         confidence: PredictionConfidence.high,
//         calculatedAt: now,
//       );
//       expect(weeklyUsage.usageText, '3.5 per week');
//     });
//   });

//   group('Enum Tests', () {
//     test('MovementType enum', () {
//       expect(MovementType.stockIn.toString(), 'MovementType.stockIn');
//       expect(MovementType.stockOut.toString(), 'MovementType.stockOut');
//       expect(MovementType.adjustment.toString(), 'MovementType.adjustment');
//     });

//     test('UserRole enum', () {
//       expect(UserRole.admin.toString(), 'UserRole.admin');
//       expect(UserRole.staff.toString(), 'UserRole.staff');
//     });

//     test('PredictionConfidence enum', () {
//       expect(PredictionConfidence.high.toString(), 'PredictionConfidence.high');
//       expect(PredictionConfidence.medium.toString(),
//           'PredictionConfidence.medium');
//       expect(PredictionConfidence.low.toString(), 'PredictionConfidence.low');
//     });
//   });
// }

// This is a basic Flutter widget test for the Inventory Management System.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_management_system/models/inventory_item.dart';
import 'package:inventory_management_system/models/user_model.dart';
import 'package:inventory_management_system/models/stock_movement.dart';
import 'package:inventory_management_system/models/stock_prediction.dart';

void main() {
  group('Model Tests', () {
    test('InventoryItem model creation', () {
      final item = InventoryItem(
        id: '3',
        name: 'Out of Stock Item',
        description: 'Test Description',
        category: 'Test Category',
        quantity: 0,
        unitPrice: 35.99,
        supplier: 'Test Supplier',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        reorderLevel: 5,
      );

      expect(item.name, 'Out of Stock Item');
      expect(item.quantity, 0);
      expect(item.unitPrice, 35.99);
      expect(item.reorderLevel, 5);
    });

    test('InventoryItem copyWith method', () {
      final now = DateTime.now();
      final item = InventoryItem(
        id: '1',
        name: 'Test Item',
        description: 'Test Description',
        category: 'Test Category',
        quantity: 10,
        unitPrice: 9.99,
        supplier: 'Test Supplier',
        createdAt: now,
        updatedAt: now,
        reorderLevel: 5,
      );

      final updatedItem = item.copyWith(
        name: 'Updated Item',
        quantity: 20,
      );

      expect(updatedItem.name, 'Updated Item');
      expect(updatedItem.quantity, 20);
      expect(updatedItem.unitPrice, 9.99); // Should remain unchanged
      expect(updatedItem.id, '1'); // Should remain unchanged
    });

    test('InventoryItem toMap', () {
      final now = DateTime.now();
      final item = InventoryItem(
        id: '1',
        name: 'Test Item',
        description: 'Test Description',
        category: 'Test Category',
        quantity: 10,
        unitPrice: 9.99,
        supplier: 'Test Supplier',
        createdAt: now,
        updatedAt: now,
        reorderLevel: 5,
      );

      final map = item.toMap();
      expect(map['name'], 'Test Item');
      expect(map['quantity'], 10);
      expect(map['unitPrice'], 9.99);
      expect(map['category'], 'Test Category');
      expect(map['supplier'], 'Test Supplier');
      expect(map['reorderLevel'], 5);
    });

    test('User model role checks', () {
      final adminUser = AppUser(
        id: '1',
        email: 'admin@test.com',
        displayName: 'Admin User',
        role: UserRole.admin,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
      );

      final staffUser = AppUser(
        id: '2',
        email: 'staff@test.com',
        displayName: 'Staff User',
        role: UserRole.staff,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
      );

      expect(adminUser.isAdmin, true);
      expect(adminUser.isStaff, false);
      expect(staffUser.isAdmin, false);
      expect(staffUser.isStaff, true);
    });

    test('User model copyWith method', () {
      final user = AppUser(
        id: '1',
        email: 'test@test.com',
        displayName: 'Test User',
        role: UserRole.staff,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
      );

      final updatedUser = user.copyWith(
        displayName: 'Updated User',
        role: UserRole.admin,
      );

      expect(updatedUser.displayName, 'Updated User');
      expect(updatedUser.role, UserRole.admin);
      expect(updatedUser.email, 'test@test.com'); // Should remain unchanged
    });

    test('StockMovement model creation', () {
      final movement = StockMovement(
        id: '1',
        itemId: 'item1',
        itemName: 'Test Item',
        type: MovementType.stockIn,
        quantity: 5,
        reason: 'Initial stock',
        timestamp: DateTime.now(),
        userId: 'user1',
        userName: 'Test User',
      );

      expect(movement.itemName, 'Test Item');
      expect(movement.type, MovementType.stockIn);
      expect(movement.quantity, 5);
      expect(movement.reason, 'Initial stock');
    });

    test('StockMovement toMap', () {
      final now = DateTime.now();
      final movement = StockMovement(
        id: '1',
        itemId: 'item1',
        itemName: 'Test Item',
        type: MovementType.stockOut,
        quantity: 3,
        reason: 'Sale',
        timestamp: now,
        userId: 'user1',
        userName: 'Test User',
      );

      final map = movement.toMap();
      expect(map['item_id'], 'item1');
      expect(map['item_name'], 'Test Item');
      expect(map['type'], 'stockOut');
      expect(map['quantity'], 3);
      expect(map['reason'], 'Sale');
      expect(map['user_id'], 'user1');
      expect(map['user_name'], 'Test User');
    });

    test('StockPrediction model creation', () {
      final now = DateTime.now();
      final prediction = StockPrediction(
        itemId: 'item1',
        itemName: 'Test Item',
        currentQuantity: 10,
        averageDailyUsage: 2.0,
        daysLeft: 5,
        predictedDepletionDate: now.add(const Duration(days: 5)),
        needsRestock: true,
        confidence: PredictionConfidence.high,
        calculatedAt: now,
      );

      expect(prediction.itemName, 'Test Item');
      expect(prediction.currentQuantity, 10);
      expect(prediction.averageDailyUsage, 2.0);
      expect(prediction.daysLeft, 5);
      expect(prediction.needsRestock, true);
      expect(prediction.confidence, PredictionConfidence.high);
    });

    test('StockPrediction daysLeftText', () {
      final now = DateTime.now();

      final outOfStock = StockPrediction(
        itemId: 'item1',
        itemName: 'Test Item',
        currentQuantity: 0,
        averageDailyUsage: 2.0,
        daysLeft: 0,
        predictedDepletionDate: now,
        needsRestock: true,
        confidence: PredictionConfidence.high,
        calculatedAt: now,
      );
      expect(outOfStock.daysLeftText, 'Out of stock');

      final oneDay = StockPrediction(
        itemId: 'item1',
        itemName: 'Test Item',
        currentQuantity: 2,
        averageDailyUsage: 2.0,
        daysLeft: 1,
        predictedDepletionDate: now.add(const Duration(days: 1)),
        needsRestock: true,
        confidence: PredictionConfidence.high,
        calculatedAt: now,
      );
      expect(oneDay.daysLeftText, '1 day left');

      final multipleDays = StockPrediction(
        itemId: 'item1',
        itemName: 'Test Item',
        currentQuantity: 10,
        averageDailyUsage: 2.0,
        daysLeft: 5,
        predictedDepletionDate: now.add(const Duration(days: 5)),
        needsRestock: false,
        confidence: PredictionConfidence.high,
        calculatedAt: now,
      );
      expect(multipleDays.daysLeftText, '5 days left');
    });

    test('StockPrediction confidenceText', () {
      final now = DateTime.now();

      final highConfidence = StockPrediction(
        itemId: 'item1',
        itemName: 'Test Item',
        currentQuantity: 10,
        averageDailyUsage: 2.0,
        daysLeft: 5,
        predictedDepletionDate: now.add(const Duration(days: 5)),
        needsRestock: false,
        confidence: PredictionConfidence.high,
        calculatedAt: now,
      );
      expect(highConfidence.confidenceText, 'High confidence');

      final mediumConfidence = highConfidence.copyWith(
        confidence: PredictionConfidence.medium,
      );
      expect(mediumConfidence.confidenceText, 'Medium confidence');

      final lowConfidence = highConfidence.copyWith(
        confidence: PredictionConfidence.low,
      );
      expect(lowConfidence.confidenceText, 'Low confidence');
    });

    test('StockPrediction usageText', () {
      final now = DateTime.now();

      final dailyUsage = StockPrediction(
        itemId: 'item1',
        itemName: 'Test Item',
        currentQuantity: 10,
        averageDailyUsage: 2.5,
        daysLeft: 4,
        predictedDepletionDate: now.add(const Duration(days: 4)),
        needsRestock: false,
        confidence: PredictionConfidence.high,
        calculatedAt: now,
      );
      expect(dailyUsage.usageText, '2.5 per day');

      final weeklyUsage = StockPrediction(
        itemId: 'item1',
        itemName: 'Test Item',
        currentQuantity: 10,
        averageDailyUsage: 0.5,
        daysLeft: 20,
        predictedDepletionDate: now.add(const Duration(days: 20)),
        needsRestock: false,
        confidence: PredictionConfidence.high,
        calculatedAt: now,
      );
      expect(weeklyUsage.usageText, '3.5 per week');
    });
  });

  group('Enum Tests', () {
    test('MovementType enum', () {
      expect(MovementType.stockIn.toString(), 'MovementType.stockIn');
      expect(MovementType.stockOut.toString(), 'MovementType.stockOut');
      expect(MovementType.adjustment.toString(), 'MovementType.adjustment');
    });

    test('UserRole enum', () {
      expect(UserRole.admin.toString(), 'UserRole.admin');
      expect(UserRole.staff.toString(), 'UserRole.staff');
    });

    test('PredictionConfidence enum', () {
      expect(PredictionConfidence.high.toString(), 'PredictionConfidence.high');
      expect(PredictionConfidence.medium.toString(),
          'PredictionConfidence.medium');
      expect(PredictionConfidence.low.toString(), 'PredictionConfidence.low');
    });
  });
}
