import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/inventory_item.dart';
import '../models/user_model.dart';
import 'inventory_service.dart';
import 'auth_service.dart';

class OfflineService {
  static const String _inventoryKey = 'offline_inventory';
  static const String _usersKey = 'offline_users';
  static const String _pendingChangesKey = 'pending_changes';
  static const String _lastSyncKey = 'last_sync';

  static SharedPreferences? _prefs;
  static bool _isOnline = true;
  static final Connectivity _connectivity = Connectivity();

  // Initialize offline service
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _isOnline =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);
      if (_isOnline) {
        _syncPendingChanges();
      }
    });

    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _isOnline =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  // Check if device is online
  static bool get isOnline => _isOnline;

  // Save inventory items offline
  static Future<void> saveInventoryOffline(List<InventoryItem> items) async {
    if (_prefs == null) await initialize();

    final itemsJson = items.map((item) => item.toJson()).toList();
    await _prefs!.setString(_inventoryKey, jsonEncode(itemsJson));
    await _prefs!.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // Get inventory items from offline storage
  static Future<List<InventoryItem>> getInventoryOffline() async {
    if (_prefs == null) await initialize();

    final itemsString = _prefs!.getString(_inventoryKey);
    if (itemsString == null) return [];

    try {
      final itemsJson = jsonDecode(itemsString) as List;
      return itemsJson.map((json) => InventoryItem.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading offline inventory: $e');
      return [];
    }
  }

  // Save users offline (for admin)
  static Future<void> saveUsersOffline(List<AppUser> users) async {
    if (_prefs == null) await initialize();

    final usersJson = users.map((user) => user.toJson()).toList();
    await _prefs!.setString(_usersKey, jsonEncode(usersJson));
  }

  // Get users from offline storage
  static Future<List<AppUser>> getUsersOffline() async {
    if (_prefs == null) await initialize();

    final usersString = _prefs!.getString(_usersKey);
    if (usersString == null) return [];

    try {
      final usersJson = jsonDecode(usersString) as List;
      return usersJson.map((json) => AppUser.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading offline users: $e');
      return [];
    }
  }

  // Add pending change for sync when online
  static Future<void> addPendingChange(Map<String, dynamic> change) async {
    if (_prefs == null) await initialize();

    final pendingChangesString = _prefs!.getString(_pendingChangesKey) ?? '[]';
    final pendingChanges = jsonDecode(pendingChangesString) as List;

    change['timestamp'] = DateTime.now().toIso8601String();
    pendingChanges.add(change);

    await _prefs!.setString(_pendingChangesKey, jsonEncode(pendingChanges));
  }

  // Get pending changes
  static Future<List<Map<String, dynamic>>> getPendingChanges() async {
    if (_prefs == null) await initialize();

    final pendingChangesString = _prefs!.getString(_pendingChangesKey) ?? '[]';
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(pendingChangesString));
    } catch (e) {
      debugPrint('Error loading pending changes: $e');
      return [];
    }
  }

  // Clear pending changes after successful sync
  static Future<void> clearPendingChanges() async {
    if (_prefs == null) await initialize();
    await _prefs!.remove(_pendingChangesKey);
  }

  // Sync pending changes when online
  static Future<void> _syncPendingChanges() async {
    if (!_isOnline) return;

    final pendingChanges = await getPendingChanges();
    if (pendingChanges.isEmpty) return;

    debugPrint('Syncing ${pendingChanges.length} pending changes...');

    for (final change in pendingChanges) {
      try {
        await _processPendingChange(change);
      } catch (e) {
        debugPrint('Error syncing change: $e');
        // Continue with other changes even if one fails
      }
    }

    await clearPendingChanges();
    debugPrint('Sync completed successfully');
  }

  // Process individual pending change
  static Future<void> _processPendingChange(Map<String, dynamic> change) async {
    final type = change['type'] as String;
    final data = change['data'] as Map<String, dynamic>;

    switch (type) {
      case 'add_inventory':
        final item = InventoryItem.fromJson(data);
        await InventoryService.addInventoryItem(item);
        break;
      case 'update_inventory':
        final item = InventoryItem.fromJson(data);
        await InventoryService.updateInventoryItem(item);
        break;
      case 'delete_inventory':
        final itemId = data['id'] as String;
        await InventoryService.deleteInventoryItem(itemId);
        break;
      case 'update_user':
        final user = AppUser.fromJson(data);
        try {
          await AuthService.updateUserByAdmin(
            userId: user.id,
            displayName: user.displayName,
            phone: user.phone,
            role: user.role,
            isActive: user.isActive,
          );
          debugPrint('User update synced: ${user.id}');
        } catch (e) {
          debugPrint('Failed to sync user update: $e');
          rethrow;
        }
        break;
      case 'delete_user':
        final userId = data['id'] as String;
        try {
          await AuthService.deleteUser(userId);
          debugPrint('User delete synced: $userId');
        } catch (e) {
          debugPrint('Failed to sync user delete: $e');
          rethrow;
        }
        break;
      default:
        debugPrint('Unknown change type: $type');
    }
  }

  // Add inventory item (offline-first)
  static Future<void> addInventoryItemOffline(InventoryItem item) async {
    // Add to local storage immediately
    final items = await getInventoryOffline();
    items.add(item);
    await saveInventoryOffline(items);

    // Add to pending changes for sync when online
    await addPendingChange({
      'type': 'add_inventory',
      'data': item.toJson(),
    });

    // If online, try to sync immediately
    if (_isOnline) {
      _syncPendingChanges();
    }
  }

  // Update inventory item (offline-first)
  static Future<void> updateInventoryItemOffline(InventoryItem item) async {
    // Update in local storage immediately
    final items = await getInventoryOffline();
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      items[index] = item;
      await saveInventoryOffline(items);
    }

    // Add to pending changes for sync when online
    await addPendingChange({
      'type': 'update_inventory',
      'data': item.toJson(),
    });

    // If online, try to sync immediately
    if (_isOnline) {
      _syncPendingChanges();
    }
  }

  // Delete inventory item (offline-first)
  static Future<void> deleteInventoryItemOffline(String itemId) async {
    // Remove from local storage immediately
    final items = await getInventoryOffline();
    items.removeWhere((item) => item.id == itemId);
    await saveInventoryOffline(items);

    // Add to pending changes for sync when online
    await addPendingChange({
      'type': 'delete_inventory',
      'data': {'id': itemId},
    });

    // If online, try to sync immediately
    if (_isOnline) {
      _syncPendingChanges();
    }
  }

  // Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    if (_prefs == null) await initialize();

    final lastSyncString = _prefs!.getString(_lastSyncKey);
    if (lastSyncString == null) return null;

    try {
      return DateTime.parse(lastSyncString);
    } catch (e) {
      return null;
    }
  }

  // Force sync all data
  static Future<void> forceSyncAll() async {
    if (!_isOnline) {
      throw Exception('Cannot sync while offline');
    }

    try {
      // Sync pending changes first
      await _syncPendingChanges();

      // Then fetch fresh data from server
      final freshInventory = await InventoryService.getInventoryItems();
      await saveInventoryOffline(freshInventory);

      debugPrint('Force sync completed successfully');
    } catch (e) {
      debugPrint('Force sync failed: $e');
      rethrow;
    }
  }

  // Clear all offline data
  static Future<void> clearOfflineData() async {
    if (_prefs == null) await initialize();

    await _prefs!.remove(_inventoryKey);
    await _prefs!.remove(_usersKey);
    await _prefs!.remove(_pendingChangesKey);
    await _prefs!.remove(_lastSyncKey);

    debugPrint('All offline data cleared');
  }
}
