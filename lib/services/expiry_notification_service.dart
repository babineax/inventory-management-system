import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item.dart';

class ExpiryNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all items that are expiring within the specified number of days
  static Future<List<InventoryItem>> getExpiringItems(
      {int daysThreshold = 180}) async {
    try {
      final now = DateTime.now();
      final thresholdDate = now.add(Duration(days: daysThreshold));

      final querySnapshot = await _firestore
          .collection('inventory_items')
          .where('isPerishable', isEqualTo: true)
          .where('expiryDate',
              isLessThanOrEqualTo: Timestamp.fromDate(thresholdDate))
          .orderBy('expiryDate')
          .get();

      return querySnapshot.docs
          .map<InventoryItem>((doc) => InventoryItem.fromDoc(doc))
          .where((item) =>
              item.expiryDate != null && item.expiryDate!.isAfter(now))
          .toList();
    } catch (e) {
      print('Error getting expiring items: $e');
      return [];
    }
  }

  /// Get expired items
  static Future<List<InventoryItem>> getExpiredItems() async {
    try {
      final now = DateTime.now();

      final querySnapshot = await _firestore
          .collection('inventory_items')
          .where('isPerishable', isEqualTo: true)
          .where('expiryDate', isLessThan: Timestamp.fromDate(now))
          .orderBy('expiryDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => InventoryItem.fromDoc(doc))
          .toList();
    } catch (e) {
      print('Error getting expired items: $e');
      return [];
    }
  }

  /// Get items expiring soon (within 30 days)
  static Future<List<InventoryItem>> getItemsExpiringSoon() async {
    return getExpiringItems(daysThreshold: 30);
  }

  /// Get items expiring within 6 months
  static Future<List<InventoryItem>> getItemsExpiringWithin6Months() async {
    return getExpiringItems(daysThreshold: 180);
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
      print('Error getting expiry summary: $e');
      return {
        'expired': 0,
        'expiringSoon': 0,
        'expiringWithin6Months': 0,
        'immediateAttention': 0,
      };
    }
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
      final sixMonthsFromNow = now.add(const Duration(days: 180));

      final querySnapshot = await _firestore
          .collection('inventory_items')
          .where('isPerishable', isEqualTo: true)
          .where('expiryDate',
              isLessThanOrEqualTo: Timestamp.fromDate(sixMonthsFromNow))
          .orderBy('expiryDate')
          .get();

      return querySnapshot.docs
          .map((doc) => InventoryItem.fromDoc(doc))
          .where((item) {
        if (item.expiryDate == null) return false;
        final daysUntilExpiry = item.expiryDate!.difference(now).inDays;
        final isFoodItem = _isFoodCategory(item.category);

        // Include if expired, expiring soon, or food item ≤6 months
        return daysUntilExpiry < 0 ||
            daysUntilExpiry <= 30 ||
            (isFoodItem && daysUntilExpiry <= 180);
      }).toList();
    } catch (e) {
      print('Error getting items needing immediate attention: $e');
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
    final now = DateTime.now();
    final thresholdDate = now.add(Duration(days: daysThreshold));

    return _firestore
        .collection('inventory_items')
        .where('isPerishable', isEqualTo: true)
        .where('expiryDate',
            isLessThanOrEqualTo: Timestamp.fromDate(thresholdDate))
        .orderBy('expiryDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryItem.fromDoc(doc))
            .where((item) =>
                item.expiryDate != null && item.expiryDate!.isAfter(now))
            .toList());
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
