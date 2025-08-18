enum MovementType { stockIn, stockOut, adjustment }

class StockMovement {
  final String id;
  final String itemId;
  final String itemName;
  final MovementType type;
  final int quantity;
  final String reason;
  final DateTime timestamp;
  final String userId;
  final String userName;

  StockMovement({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.timestamp,
    required this.userId,
    required this.userName,
  });

  factory StockMovement.fromMap(Map<String, dynamic> map, String documentId) {
    return StockMovement(
      id: documentId,
      itemId: map['itemId'] ?? map['item_id'] ?? '',
      itemName: map['itemName'] ?? map['item_name'] ?? '',
      type: MovementType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MovementType.adjustment,
      ),
      quantity: map['quantity'] ?? 0,
      reason: map['reason'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : (map['date'] != null
              ? DateTime.parse(map['date'])
              : DateTime.now()),
      userId: map['userId'] ?? map['user_id'] ?? '',
      userName: map['userName'] ?? map['user_name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'type': type.toString().split('.').last,
      'quantity': quantity,
      'reason': reason,
      'date': timestamp.toIso8601String(),
      'user_id': userId,
      'user_name': userName,
    };
  }
}
