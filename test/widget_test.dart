import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventory_management_system/providers/theme_provider.dart';
import 'package:inventory_management_system/models/inventory_item.dart';

void main() {
  group('Theme Provider Tests', () {
    setUp(() {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('ThemeProvider initializes correctly',
        (WidgetTester tester) async {
      final themeProvider = ThemeProvider();

      // Test initial state
      expect(themeProvider.isDarkMode, false);
      expect(themeProvider.lightTheme, isNotNull);
      expect(themeProvider.darkTheme, isNotNull);
    });

    test('ThemeProvider can toggle theme', () async {
      final themeProvider = ThemeProvider();

      // Wait a bit for SharedPreferences initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Initial state should be light mode
      expect(themeProvider.isDarkMode, false);

      // Toggle to dark mode
      await themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, true);

      // Toggle back to light mode
      await themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, false);
    });
  });

  group('Inventory Item Tests', () {
    test('InventoryItem expiry date functionality works correctly', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 30));
      final pastDate = now.subtract(const Duration(days: 30));
      final farFutureDate = now.add(const Duration(days: 365));

      // Test perishable item expiring soon
      final expiringItem = InventoryItem(
        id: '1',
        name: 'Milk',
        description: 'Fresh milk',
        category: 'Dairy',
        quantity: 10,
        unitPrice: 2.50,
        supplier: 'Local Farm',
        createdAt: now,
        updatedAt: now,
        reorderLevel: 5,
        isPerishable: true,
        expiryDate: futureDate,
      );

      expect(expiringItem.isExpiringSoon(), true);
      expect(expiringItem.isExpired, false);
      expect(expiringItem.daysUntilExpiry, isNotNull);

      // Test expired item
      final expiredItem = expiringItem.copyWith(expiryDate: pastDate);
      expect(expiredItem.isExpired, true);
      expect(expiredItem.isExpiringSoon(), true);

      // Test non-perishable item
      final nonPerishableItem = InventoryItem(
        id: '2',
        name: 'Hammer',
        description: 'Tool',
        category: 'Hardware',
        quantity: 5,
        unitPrice: 15.00,
        supplier: 'Tool Store',
        createdAt: now,
        updatedAt: now,
        reorderLevel: 2,
        isPerishable: false,
      );

      expect(nonPerishableItem.isExpiringSoon(), false);
      expect(nonPerishableItem.isExpired, false);
      expect(nonPerishableItem.daysUntilExpiry, null);

      // Test item not expiring soon
      final notExpiringSoonItem =
          expiringItem.copyWith(expiryDate: farFutureDate);
      expect(notExpiringSoonItem.isExpiringSoon(), false);
      expect(notExpiringSoonItem.isExpired, false);
    });

    test('InventoryItem serialization works correctly', () {
      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: 30));

      final item = InventoryItem(
        id: '1',
        name: 'Test Item',
        description: 'Test Description',
        category: 'Test Category',
        quantity: 10,
        unitPrice: 5.99,
        supplier: 'Test Supplier',
        createdAt: now,
        updatedAt: now,
        reorderLevel: 5,
        isPerishable: true,
        expiryDate: expiryDate,
      );

      // Test toMap
      final map = item.toMap();
      expect(map['name'], 'Test Item');
      expect(map['isPerishable'], true);
      expect(map['expiryDate'], expiryDate.toIso8601String());

      // Test fromMap
      final reconstructedItem = InventoryItem.fromMap(map, '1');
      expect(reconstructedItem.name, item.name);
      expect(reconstructedItem.isPerishable, item.isPerishable);
      expect(reconstructedItem.expiryDate, item.expiryDate);
    });
  });
}
