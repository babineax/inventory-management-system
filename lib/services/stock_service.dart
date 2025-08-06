import '../repositories/stock_repository.dart';

class StockService {
  final StockRepository _repository;

  StockService({StockRepository? repository})
      : _repository = repository ?? StockRepository();

  // CREATE with validation
  Future<Map<String, dynamic>> addItem({
    required String name,
    required String category,
    required int quantity,
    String description = '',
  }) async {
    if (name.isEmpty) throw Exception('Item name cannot be empty');
    if (quantity < 0) throw Exception('Quantity cannot be negative');

    return _repository.createItem(
      name: name,
      category: category,
      quantity: quantity,
      description: description,
    );
  }

  // UPDATE with validation
  Future<Map<String, dynamic>> modifyItem({
    required String id,
    String? name,
    String? category,
    int? quantity,
    String? description,
  }) async {
    if (quantity != null && quantity < 0) {
      throw Exception('Quantity cannot be negative');
    }
    return _repository.updateItem(
      id: id,
      name: name,
      category: category,
      quantity: quantity,
      description: description,
    );
  }

  // Get all items, optional filtering
  Future<List<Map<String, dynamic>>> getItems({String? categoryFilter}) async {
    final items = await _repository.getAllItems();
    if (categoryFilter != null) {
      return items.where((item) => item['category'] == categoryFilter).toList();
    }
    return items;
  }
}
