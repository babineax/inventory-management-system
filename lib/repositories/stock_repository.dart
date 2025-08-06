import 'package:cloud_firestore/cloud_firestore.dart';

class StockRepository {
  final FirebaseFirestore _firestore;

  StockRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _collection => _firestore.collection('coll_stock');

  // CREATE
  Future<Map<String, dynamic>> createItem({
    required String name,
    required String category,
    required int quantity,
    String description = '',
  }) async {
    try {
      final docRef = await _collection.add({
        'item_name': name,
        'item_cat': category,
        'item_qty': quantity,
        'item_desc': description,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      final snapshot = await docRef.get();
      return _parseDocument(snapshot);
    } catch (e) {
      throw Exception('Failed to create item: ${e.toString()}');
    }
  }

  // READ (single)
  Future<Map<String, dynamic>> getItem(String id) async {
    try {
      final snapshot = await _collection.doc(id).get();
      if (!snapshot.exists) throw Exception('Item not found');
      return _parseDocument(snapshot);
    } catch (e) {
      throw Exception('Failed to get item: ${e.toString()}');
    }
  }

  // READ (all)
  Future<List<Map<String, dynamic>>> getAllItems() async {
    try {
      final snapshot =
          await _collection.orderBy('created_at', descending: true).get();
      return snapshot.docs.map(_parseDocument).toList();
    } catch (e) {
      throw Exception('Failed to get items: ${e.toString()}');
    }
  }

  // UPDATE
  Future<Map<String, dynamic>> updateItem({
    required String id,
    String? name,
    String? category,
    int? quantity,
    String? description,
  }) async {
    try {
      final updates = {
        if (name != null) 'item_name': name,
        if (category != null) 'item_cat': category,
        if (quantity != null) 'item_qty': quantity,
        if (description != null) 'item_desc': description,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _collection.doc(id).update(updates);
      return await getItem(id); // Return updated document
    } catch (e) {
      throw Exception('Failed to update item: ${e.toString()}');
    }
  }

  // DELETE
  Future<void> deleteItem(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete item: ${e.toString()}');
    }
  }

  // Parse Firestore document to consistent format
  Map<String, dynamic> _parseDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return {
      'id': doc.id,
      'name': data['item_name'] ?? '',
      'category': data['item_cat'] ?? '',
      'quantity': data['item_qty'] ?? 0,
      'description': data['item_desc'] ?? '',
      'created_at': (data['created_at'] as Timestamp?)?.toDate(),
      'updated_at': (data['updated_at'] as Timestamp?)?.toDate(),
    };
  }
}
