class InventoryItem {
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
  });

  factory InventoryItem.fromMap(Map<String, dynamic> map, String documentId) {
    return InventoryItem(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      supplier: map['supplier'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      reorderLevel: map['reorderLevel'] ?? 10,
      imageUrl: map['imageUrl'],
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
    };
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
    );
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
