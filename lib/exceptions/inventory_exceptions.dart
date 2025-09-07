class InventoryException implements Exception {
  final String message;
  final String? code;

  InventoryException(this.message, [this.code]);

  @override
  String toString() {
    if (code != null) {
      return 'InventoryException: $message (Code: $code)';
    }
    return 'InventoryException: $message';
  }
}

class InventoryItemNotFoundException extends InventoryException {
  InventoryItemNotFoundException(String itemId)
      : super('Inventory item with ID $itemId not found', 'item_not_found');
}

class InventoryItemCreationException extends InventoryException {
  InventoryItemCreationException(String reason)
      : super(
            'Failed to create inventory item: $reason', 'item_creation_failed');
}

class InventoryItemUpdateException extends InventoryException {
  InventoryItemUpdateException(String reason)
      : super('Failed to update inventory item: $reason', 'item_update_failed');
}

class InventoryItemDeletionException extends InventoryException {
  InventoryItemDeletionException(String reason)
      : super(
            'Failed to delete inventory item: $reason', 'item_deletion_failed');
}

class StockAdjustmentException extends InventoryException {
  StockAdjustmentException(String reason)
      : super('Failed to adjust stock: $reason', 'stock_adjustment_failed');
}

class StockMovementException extends InventoryException {
  StockMovementException(String reason)
      : super('Failed to log stock movement: $reason', 'stock_movement_failed');
}

class PredictionCalculationException extends InventoryException {
  PredictionCalculationException(String reason)
      : super('Failed to calculate prediction: $reason',
            'prediction_calculation_failed');
}

class CategoryException extends InventoryException {
  CategoryException(String reason)
      : super(
            'Category operation failed: $reason', 'category_operation_failed');
}

class DashboardStatsException extends InventoryException {
  DashboardStatsException(String reason)
      : super('Failed to get dashboard statistics: $reason',
            'dashboard_stats_failed');
}
