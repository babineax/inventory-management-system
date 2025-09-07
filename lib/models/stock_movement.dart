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
    DateTime parseTimestamp(dynamic timestampValue) {
      if (timestampValue == null) return DateTime.now();

      // Handle Firestore Timestamp
      if (timestampValue.runtimeType.toString() == 'Timestamp') {
        return (timestampValue as dynamic).toDate();
      }

      // Handle string timestamp
      if (timestampValue is String) {
        try {
          return DateTime.parse(timestampValue);
        } catch (e) {
          return DateTime.now();
        }
      }

      return DateTime.now();
    }

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
      timestamp: parseTimestamp(map['timestamp'] ?? map['date']),
      userId: map['userId'] ?? map['user_id'] ?? '',
      userName: map['userName'] ?? map['user_name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'type': type.toString().split('.').last,
      'quantity': quantity,
      'reason': reason,
      'timestamp': timestamp,
      'userId': userId,
      'userName': userName,
    };
  }
}
