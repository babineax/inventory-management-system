import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  // final String id;
  // final String name;
  // final String description;
  // final String category;
  // final int quantity;
  // final double unitPrice;
  // final String supplier;
  // final DateTime createdAt;
  // final DateTime updatedAt;
  // final int reorderLevel;
  // final String? imageUrl;
  // final DateTime? expiryDate;
  // final bool isPerishable;

  // InventoryItem({
  //   required this.id,
  //   required this.name,
  //   required this.description,
  //   required this.category,
  //   required this.quantity,
  //   required this.unitPrice,
  //   required this.supplier,
  //   required this.createdAt,
  //   required this.updatedAt,
  //   required this.reorderLevel,
  //   this.imageUrl,
  //   this.expiryDate,
  //   this.isPerishable = false,
  // });

  // factory InventoryItem.fromMap(Map<String, dynamic> map, String documentId) {
  //   return InventoryItem(
  //     id: documentId,
  //     name: map['name'] ?? '',
  //     description: map['description'] ?? '',
  //     category: map['category'] ?? '',
  //     quantity: map['quantity'] ?? 0,
  //     unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
  //     supplier: map['supplier'] ?? '',
  //     createdAt: map['createdAt'] != null
  //         ? DateTime.parse(map['createdAt'])
  //         : DateTime.now(),
  //     updatedAt: map['updatedAt'] != null
  //         ? DateTime.parse(map['updatedAt'])
  //         : DateTime.now(),
  //     reorderLevel: map['reorderLevel'] ?? 10,
  //     imageUrl: map['imageUrl'],
  //     expiryDate:
  //         map['expiryDate'] != null ? DateTime.parse(map['expiryDate']) : null,
  //     isPerishable: map['isPerishable'] ?? false,
  //   );
  // }

  final String id;
  final String name;
  final String description;
  final String category;
  final int quantity;
  final double unitPrice;
  final String supplier;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int reorderLevel;
  final String? imageUrl;
  final DateTime? expiryDate;
  final bool isPerishable;

  // Add this:
  final DocumentSnapshot? snapshot;

  InventoryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.supplier,
    required this.createdAt,
    required this.updatedAt,
    required this.reorderLevel,
    this.imageUrl,
    this.expiryDate,
    this.isPerishable = false,
    this.snapshot,
  });

  // factory InventoryItem.fromDoc(DocumentSnapshot doc) {
  //   final map = doc.data() as Map<String, dynamic>;
  //   return InventoryItem(
  //     id: doc.id,
  //     name: map['name'] ?? '',
  //     description: map['description'] ?? '',
  //     category: map['category'] ?? '',
  //     quantity: map['quantity'] ?? 0,
  //     unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
  //     supplier: map['supplier'] ?? '',
  //     createdAt: map['createdAt'] != null
  //         ? (map['createdAt'] as Timestamp).toDate()
  //         : DateTime.now(),
  //     updatedAt: map['updatedAt'] != null
  //         ? (map['updatedAt'] as Timestamp).toDate()
  //         : DateTime.now(),
  //     reorderLevel: map['reorderLevel'] ?? 10,
  //     imageUrl: map['imageUrl'],
  //     expiryDate: map['expiryDate'] != null
  //         ? (map['expiryDate'] as Timestamp).toDate()
  //         : null,
  //     isPerishable: map['isPerishable'] ?? false,
  //     snapshot: doc, // store the snapshot for pagination
  //   );
  // }

  factory InventoryItem.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return InventoryItem(
      id: doc.id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      supplier: map['supplier'] ?? '',
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(map['updatedAt']) ?? DateTime.now(),
      expiryDate: parseDate(map['expiryDate']),
      reorderLevel: map['reorderLevel'] ?? 10,
      imageUrl: map['imageUrl'],
      isPerishable: map['isPerishable'] ?? false,
      snapshot: doc, // keep snapshot for pagination
    );
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return InventoryItem(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      supplier: map['supplier'] ?? '',
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(map['updatedAt']) ?? DateTime.now(),
      expiryDate: parseDate(map['expiryDate']),
      reorderLevel: map['reorderLevel'] ?? 10,
      imageUrl: map['imageUrl'],
      isPerishable: map['isPerishable'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'supplier': supplier,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reorderLevel': reorderLevel,
      'imageUrl': imageUrl,
      'expiryDate': expiryDate?.toIso8601String(),
      'isPerishable': isPerishable,
    };
  }

  // JSON serialization methods for offline storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'supplier': supplier,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reorderLevel': reorderLevel,
      'imageUrl': imageUrl,
      'expiryDate': expiryDate?.toIso8601String(),
      'isPerishable': isPerishable,
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      supplier: json['supplier'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      reorderLevel: json['reorderLevel'] ?? 10,
      imageUrl: json['imageUrl'],
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      isPerishable: json['isPerishable'] ?? false,
    );
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? quantity,
    double? unitPrice,
    String? supplier,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? reorderLevel,
    String? imageUrl,
    DateTime? expiryDate,
    bool? isPerishable,
    DocumentSnapshot? snapshot,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      supplier: supplier ?? this.supplier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      imageUrl: imageUrl ?? this.imageUrl,
      expiryDate: expiryDate ?? this.expiryDate,
      isPerishable: isPerishable ?? this.isPerishable,
      snapshot: snapshot ?? this.snapshot,
    );
  }

  /// Check if the item is expiring within the specified number of months
  bool isExpiringSoon({int monthsThreshold = 6}) {
    if (!isPerishable || expiryDate == null) return false;

    final now = DateTime.now();
    final thresholdDate =
        DateTime(now.year, now.month + monthsThreshold, now.day);

    return expiryDate!.isBefore(thresholdDate) ||
        expiryDate!.isAtSameMomentAs(thresholdDate);
  }

  /// Check if the item has already expired
  bool get isExpired {
    if (!isPerishable || expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  /// Get the number of days until expiry (negative if expired)
  int? get daysUntilExpiry {
    if (!isPerishable || expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }
}

// import 'package:inventory_management_system/models/stock_movement.dart';

// class InventoryItem {
//   final String id;
//   final String name;
//   final String description;
//   final String category;
//   final int quantity;
//   final double unitPrice;
//   final String supplier;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   final int reorderLevel;
//   final String? imageUrl;

//   // NEW: Optional last movement type for filtering
//   final MovementType? lastMovementType;

//   InventoryItem({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.category,
//     required this.quantity,
//     required this.unitPrice,
//     required this.supplier,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.reorderLevel,
//     this.imageUrl,
//     this.lastMovementType, // optional
//   });

//   factory InventoryItem.fromMap(Map<String, dynamic> map, String documentId) {
//     MovementType? movementType;

//     // If the map contains lastMovementType as string, convert to enum
//     if (map['lastMovementType'] != null) {
//       switch (map['lastMovementType'] as String) {
//         case 'stockIn':
//           movementType = MovementType.stockIn;
//           break;
//         case 'stockOut':
//           movementType = MovementType.stockOut;
//           break;
//         case 'adjustment':
//           movementType = MovementType.adjustment;
//           break;
//       }
//     }

//     return InventoryItem(
//       id: documentId,
//       name: map['name'] ?? '',
//       description: map['description'] ?? '',
//       category: map['category'] ?? '',
//       quantity: map['quantity'] ?? 0,
//       unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
//       supplier: map['supplier'] ?? '',
//       createdAt: map['createdAt'] != null
//           ? DateTime.parse(map['createdAt'])
//           : DateTime.now(),
//       updatedAt: map['updatedAt'] != null
//           ? DateTime.parse(map['updatedAt'])
//           : DateTime.now(),
//       reorderLevel: map['reorderLevel'] ?? 10,
//       imageUrl: map['imageUrl'],
//       lastMovementType: movementType,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'name': name,
//       'description': description,
//       'category': category,
//       'quantity': quantity,
//       'unitPrice': unitPrice,
//       'supplier': supplier,
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt.toIso8601String(),
//       'reorderLevel': reorderLevel,
//       'imageUrl': imageUrl,
//       'lastMovementType': lastMovementType?.toString().split('.').last,
//     };
//   }

//   InventoryItem copyWith({
//     String? id,
//     String? name,
//     String? description,
//     String? category,
//     int? quantity,
//     double? unitPrice,
//     String? supplier,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//     int? reorderLevel,
//     String? imageUrl,
//     MovementType? lastMovementType,
//   }) {
//     return InventoryItem(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       description: description ?? this.description,
//       category: category ?? this.category,
//       quantity: quantity ?? this.quantity,
//       unitPrice: unitPrice ?? this.unitPrice,
//       supplier: supplier ?? this.supplier,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//       reorderLevel: reorderLevel ?? this.reorderLevel,
//       imageUrl: imageUrl ?? this.imageUrl,
//       lastMovementType: lastMovementType ?? this.lastMovementType,
//     );
//   }
// }
