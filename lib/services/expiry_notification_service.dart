import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item.dart';

class ExpiryNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all items that are expiring within the specified number of days
  static Future<List<InventoryItem>> getExpiringItems(
      {int daysThreshold = 180, int minDaysThreshold = 0}) async {
    try {
      final now = DateTime.now();
      final thresholdDate = now.add(Duration(days: daysThreshold));

      // Get all perishable items and filter in memory
      final querySnapshot = await _firestore
          .collection('inventory_items')
          .where('isPerishable', isEqualTo: true)
          .get();

      final expiringItems = querySnapshot.docs
          .map((doc) => InventoryItem.fromDoc(doc))
          .where((item) {
        if (item.expiryDate == null) return false;
        final daysUntilExpiry = item.expiryDate!.difference(now).inDays;
        return daysUntilExpiry > minDaysThreshold &&
            daysUntilExpiry <= daysThreshold;
      }).toList()
        ..sort((a, b) => a.expiryDate!
            .compareTo(b.expiryDate!)); // Sort by expiry date ascending

      return expiringItems;
    } catch (e) {
      return [];
    }
  }

  /// Get expired items
  static Future<List<InventoryItem>> getExpiredItems() async {
    try {
      final now = DateTime.now();

      // Get all perishable items and filter in memory to avoid Firestore query limitations
      final querySnapshot = await _firestore
          .collection('inventory_items')
          .where('isPerishable', isEqualTo: true)
          .get();

      final expiredItems = querySnapshot.docs
          .map((doc) => InventoryItem.fromDoc(doc))
          .where((item) {
        if (item.expiryDate == null) return false;
        final daysUntilExpiry = item.expiryDate!.difference(now).inDays;
        return daysUntilExpiry < 0;
      }).toList()
        ..sort((a, b) => b.expiryDate!
            .compareTo(a.expiryDate!)); // Sort by expiry date descending

      return expiredItems;
    } catch (e) {
      return [];
    }
  }

  /// Get items expiring soon (within 30 days)
  static Future<List<InventoryItem>> getItemsExpiringSoon() async {
    return getExpiringItems(daysThreshold: 30, minDaysThreshold: -1);
  }

  /// Get items expiring within 6 months
  static Future<List<InventoryItem>> getItemsExpiringWithin6Months() async {
    return getExpiringItems(daysThreshold: 180, minDaysThreshold: 30);
  }

  /// Get expiry summary for dashboard
  static Future<Map<String, int>> getExpirySummary() async {
    try {
      final expiredItems = await getExpiredItems();
      final expiringSoonItems = await getItemsExpiringSoon();
      final expiringWithin6MonthsItems = await getItemsExpiringWithin6Months();
      final immediateAttentionItems = await getItemsNeedingImmediateAttention();

      return {
        'expired': expiredItems.length,
        'expiringSoon': expiringSoonItems.length,
        'expiringWithin6Months': expiringWithin6MonthsItems.length,
        'immediateAttention': immediateAttentionItems.length,
      };
    } catch (e) {
      return {
        'expired': 0,
        'expiringSoon': 0,
        'expiringSoon': 0,
        'expiringWithin6Months': 0,
        'immediateAttention': 0,
      };
    }
  }

  /// Real-time expiry summary stream for dashboard
  static Stream<Map<String, int>> getExpirySummaryStream() {
    return _firestore
        .collection('inventory_items')
        .where('isPerishable', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        final items =
            snapshot.docs.map((doc) => InventoryItem.fromDoc(doc)).toList();

        final now = DateTime.now();
        final thirtyDaysFromNow = now.add(const Duration(days: 30));
        final sixMonthsFromNow = now.add(const Duration(days: 180));

        int expired = 0;
        int expiringSoon = 0;
        int expiringWithin6Months = 0;
        int immediateAttention = 0;

        for (final item in items) {
          if (item.expiryDate == null) continue;

          final daysUntilExpiry = item.expiryDate!.difference(now).inDays;
          final isFoodItem = _isFoodCategory(item.category);

          if (daysUntilExpiry < 0) {
            expired++;
          } else if (daysUntilExpiry <= 30) {
            expiringSoon++;
          } else if (daysUntilExpiry > 30 && daysUntilExpiry <= 180) {
            expiringWithin6Months++;
          }

          // Immediate attention: expired, expiring soon, or food items ≤6 months
          // Note: immediateAttention includes overlapping categories
          if (daysUntilExpiry < 0 ||
              daysUntilExpiry <= 30 ||
              (isFoodItem && daysUntilExpiry <= 180)) {
            immediateAttention++;
          }
        }

        return {
          'expired': expired,
          'expiringSoon': expiringSoon,
          'expiringWithin6Months': expiringWithin6Months,
          'immediateAttention': immediateAttention,
        };
      } catch (e) {
        return {
          'expired': 0,
          'expiringSoon': 0,
          'expiringWithin6Months': 0,
          'immediateAttention': 0,
        };
      }
    });
  }

  /// Get notification priority for an item
  static ExpiryPriority getExpiryPriority(InventoryItem item) {
    if (!item.isPerishable || item.expiryDate == null) {
      return ExpiryPriority.none;
    }

    final now = DateTime.now();
    final daysUntilExpiry = item.expiryDate!.difference(now).inDays;
    final isFoodItem = _isFoodCategory(item.category);

    if (daysUntilExpiry < 0) {
      return ExpiryPriority.expired;
    } else if (daysUntilExpiry <= 7) {
      return ExpiryPriority.critical;
    } else if (daysUntilExpiry <= 30) {
      return ExpiryPriority.high;
    } else if (daysUntilExpiry <= 90) {
      return ExpiryPriority.medium;
    } else if (daysUntilExpiry <= 180) {
      // For food items, 6 months or less should trigger immediate alerts
      return isFoodItem ? ExpiryPriority.medium : ExpiryPriority.low;
    } else if (daysUntilExpiry <= 365 && isFoodItem) {
      // Food items with 6-12 months expiry should still be monitored
      return ExpiryPriority.low;
    } else {
      return ExpiryPriority.none;
    }
  }

  /// Check if an item is in a food category
  static bool _isFoodCategory(String category) {
    final foodCategories = [
      'food',
      'beverages',
      'food & beverages',
      'snacks',
      'dairy',
      'meat',
      'vegetables',
      'fruits',
      'canned food',
      'frozen food',
      'bakery',
      'grocery',
      'perishables',
    ];

    return foodCategories.any(
        (foodCat) => category.toLowerCase().contains(foodCat.toLowerCase()));
  }

  /// Get items that need immediate attention (food items ≤6 months)
  static Future<List<InventoryItem>> getItemsNeedingImmediateAttention() async {
    try {
      final now = DateTime.now();

      // Get all perishable items and filter in memory
      final querySnapshot = await _firestore
          .collection('inventory_items')
          .where('isPerishable', isEqualTo: true)
          .get();

      final immediateAttentionItems = querySnapshot.docs
          .map((doc) => InventoryItem.fromDoc(doc))
          .where((item) {
        if (item.expiryDate == null) return false;
        final daysUntilExpiry = item.expiryDate!.difference(now).inDays;
        final isFoodItem = _isFoodCategory(item.category);

        // Include if expired, expiring soon, or food item ≤6 months
        return daysUntilExpiry < 0 ||
            daysUntilExpiry <= 30 ||
            (isFoodItem && daysUntilExpiry <= 180);
      }).toList()
        ..sort((a, b) => a.expiryDate!
            .compareTo(b.expiryDate!)); // Sort by expiry date ascending

      return immediateAttentionItems;
    } catch (e) {
      return [];
    }
  }

  /// Get notification message for an item
  static String getNotificationMessage(InventoryItem item) {
    final priority = getExpiryPriority(item);
    final daysUntilExpiry = item.daysUntilExpiry ?? 0;

    switch (priority) {
      case ExpiryPriority.expired:
        return '${item.name} has expired ${daysUntilExpiry.abs()} days ago';
      case ExpiryPriority.critical:
        return '${item.name} expires in $daysUntilExpiry days - URGENT!';
      case ExpiryPriority.high:
        return '${item.name} expires in $daysUntilExpiry days';
      case ExpiryPriority.medium:
        return '${item.name} expires in $daysUntilExpiry days';
      case ExpiryPriority.low:
        return '${item.name} expires in $daysUntilExpiry days';
      case ExpiryPriority.none:
        return '';
    }
  }

  /// Stream of expiring items for real-time updates
  static Stream<List<InventoryItem>> getExpiringItemsStream(
      {int daysThreshold = 180}) {
    return _firestore
        .collection('inventory_items')
        .where('isPerishable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final thresholdDate = now.add(Duration(days: daysThreshold));

      return snapshot.docs
          .map((doc) => InventoryItem.fromDoc(doc))
          .where((item) =>
              item.expiryDate != null &&
              item.expiryDate!.isAfter(now) &&
              item.expiryDate!.isBefore(thresholdDate))
          .toList()
        ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    });
  }
}

enum ExpiryPriority {
  none,
  low,
  medium,
  high,
  critical,
  expired,
}

extension ExpiryPriorityExtension on ExpiryPriority {
  String get displayName {
    switch (this) {
      case ExpiryPriority.none:
        return 'No Alert';
      case ExpiryPriority.low:
        return 'Low Priority';
      case ExpiryPriority.medium:
        return 'Medium Priority';
      case ExpiryPriority.high:
        return 'High Priority';
      case ExpiryPriority.critical:
        return 'Critical';
      case ExpiryPriority.expired:
        return 'Expired';
    }
  }

  String get color {
    switch (this) {
      case ExpiryPriority.none:
        return 'green';
      case ExpiryPriority.low:
        return 'blue';
      case ExpiryPriority.medium:
        return 'orange';
      case ExpiryPriority.high:
        return 'deepOrange';
      case ExpiryPriority.critical:
        return 'red';
      case ExpiryPriority.expired:
        return 'red';
    }
  }
}
