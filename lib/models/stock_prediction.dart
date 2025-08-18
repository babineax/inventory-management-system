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
    return StockPrediction(
      itemId: map['itemId'] ?? map['item_id'] ?? '',
      itemName: map['itemName'] ?? map['item_name'] ?? '',
      currentQuantity: map['currentQuantity'] ?? map['current_quantity'] ?? 0,
      averageDailyUsage:
          (map['averageDailyUsage'] ?? map['average_daily_usage'] ?? 0.0)
              .toDouble(),
      daysLeft: map['daysLeft'] ?? map['days_left'] ?? 0,
      predictedDepletionDate: map['predictedDepletionDate'] != null
          ? DateTime.parse(map['predictedDepletionDate'])
          : (map['predicted_depletion_date'] != null
              ? DateTime.parse(map['predicted_depletion_date'])
              : DateTime.now()),
      needsRestock: (map['needsRestock'] ?? map['needs_restock'] ?? 0) == 1,
      confidence: PredictionConfidence.values.firstWhere(
        (e) => e.toString().split('.').last == map['confidence'],
        orElse: () => PredictionConfidence.low,
      ),
      calculatedAt: map['calculatedAt'] != null
          ? DateTime.parse(map['calculatedAt'])
          : (map['calculated_at'] != null
              ? DateTime.parse(map['calculated_at'])
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'current_quantity': currentQuantity,
      'average_daily_usage': averageDailyUsage,
      'days_left': daysLeft,
      'predicted_depletion_date': predictedDepletionDate.toIso8601String(),
      'needs_restock': needsRestock ? 1 : 0,
      'confidence': confidence.toString().split('.').last,
      'calculated_at': calculatedAt.toIso8601String(),
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
