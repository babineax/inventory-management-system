class StockPrediction {
  final String itemId;
  final String itemName;
  final int currentQuantity;
  final double averageDailyUsage;
  final int daysLeft;
  final DateTime predictedDepletionDate;
  final bool needsRestock;
  final PredictionConfidence confidence;
  final DateTime calculatedAt;

  StockPrediction({
    required this.itemId,
    required this.itemName,
    required this.currentQuantity,
    required this.averageDailyUsage,
    required this.daysLeft,
    required this.predictedDepletionDate,
    required this.needsRestock,
    required this.confidence,
    required this.calculatedAt,
  });

  factory StockPrediction.fromMap(Map<String, dynamic> map) {
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

    return StockPrediction(
      itemId: map['itemId'] ?? map['item_id'] ?? '',
      itemName: map['itemName'] ?? map['item_name'] ?? '',
      currentQuantity: map['currentQuantity'] ?? map['current_quantity'] ?? 0,
      averageDailyUsage:
          (map['averageDailyUsage'] ?? map['average_daily_usage'] ?? 0.0)
              .toDouble(),
      daysLeft: map['daysLeft'] ?? map['days_left'] ?? 0,
      predictedDepletionDate: parseTimestamp(
          map['predictedDepletionDate'] ?? map['predicted_depletion_date']),
      needsRestock: map['needsRestock'] ?? map['needs_restock'] ?? false,
      confidence: PredictionConfidence.values.firstWhere(
        (e) => e.toString().split('.').last == map['confidence'],
        orElse: () => PredictionConfidence.low,
      ),
      calculatedAt: parseTimestamp(map['calculatedAt'] ?? map['calculated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'currentQuantity': currentQuantity,
      'averageDailyUsage': averageDailyUsage,
      'daysLeft': daysLeft,
      'predictedDepletionDate': predictedDepletionDate,
      'needsRestock': needsRestock,
      'confidence': confidence.toString().split('.').last,
      'calculatedAt': calculatedAt,
    };
  }

  String get daysLeftText {
    if (daysLeft <= 0) return 'Out of stock';
    if (daysLeft == 1) return '1 day left';
    return '$daysLeft days left';
  }

  String get confidenceText {
    switch (confidence) {
      case PredictionConfidence.high:
        return 'High confidence';
      case PredictionConfidence.medium:
        return 'Medium confidence';
      case PredictionConfidence.low:
        return 'Low confidence';
    }
  }

  String get usageText {
    if (averageDailyUsage < 1) {
      return '${(averageDailyUsage * 7).toStringAsFixed(1)} per week';
    }
    return '${averageDailyUsage.toStringAsFixed(1)} per day';
  }

  StockPrediction copyWith({
    String? itemId,
    String? itemName,
    int? currentQuantity,
    double? averageDailyUsage,
    int? daysLeft,
    DateTime? predictedDepletionDate,
    bool? needsRestock,
    PredictionConfidence? confidence,
    DateTime? calculatedAt,
  }) {
    return StockPrediction(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      averageDailyUsage: averageDailyUsage ?? this.averageDailyUsage,
      daysLeft: daysLeft ?? this.daysLeft,
      predictedDepletionDate:
          predictedDepletionDate ?? this.predictedDepletionDate,
      needsRestock: needsRestock ?? this.needsRestock,
      confidence: confidence ?? this.confidence,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }
}

enum PredictionConfidence { high, medium, low }
