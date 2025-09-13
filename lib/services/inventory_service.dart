import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory.dart';
import '../config/supabase_config.dart';
import '../services/notification_service.dart';
import '../services/activity_log_service.dart';
import '../models/activity_log.dart';

class InventoryService {
  static const String _inventoryBoxName = 'inventory_items';
  static const String _transactionsBoxName = 'inventory_transactions';
  static const String _inventoryTable = 'inventory_items';
  static const String _transactionsTable = 'inventory_transactions';
  
  static final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Get Hive boxes
  static Future<Box<InventoryItem>> _getInventoryBox() async {
    if (!Hive.isBoxOpen(_inventoryBoxName)) {
      await Hive.openBox<InventoryItem>(_inventoryBoxName);
    }
    return Hive.box<InventoryItem>(_inventoryBoxName);
  }

  static Future<Box<InventoryTransaction>> _getTransactionsBox() async {
    if (!Hive.isBoxOpen(_transactionsBoxName)) {
      await Hive.openBox<InventoryTransaction>(_transactionsBoxName);
    }
    return Hive.box<InventoryTransaction>(_transactionsBoxName);
  }

  // Add new inventory item
  static Future<void> addInventoryItem(InventoryItem item) async {
    try {
      // Save to Hive first
      final box = await _getInventoryBox();
      await box.put(item.id, item);

      // Try to save to Supabase
      try {
        await _supabase.from(_inventoryTable).insert(item.toJson());
      } catch (supabaseError) {
        print('Failed to sync inventory item to Supabase: $supabaseError');
      }

      // Log activity
      await ActivityLogService.addActivityLog(ActivityLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        farmId: item.farmId,
        type: ActivityType.other,
        title: 'Inventar qo\'shildi',
        description: '${item.name} inventarga qo\'shildi (${item.quantity} ${item.unit})',
        metadata: {'itemId': item.id, 'category': item.category},
        importance: ActivityImportance.normal,
      ));
    } catch (e) {
      print('Error adding inventory item: $e');
      rethrow;
    }
  }

  // Update inventory item
  static Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      final box = await _getInventoryBox();
      final updatedItem = item.copyWith(updatedAt: DateTime.now());
      await box.put(updatedItem.id, updatedItem);

      // Try to update in Supabase
      try {
        await _supabase
            .from(_inventoryTable)
            .update(updatedItem.toJson())
            .eq('id', updatedItem.id);
      } catch (supabaseError) {
        print('Failed to update inventory item in Supabase: $supabaseError');
      }
    } catch (e) {
      print('Error updating inventory item: $e');
      rethrow;
    }
  }

  // Get all inventory items for a farm
  static Future<List<InventoryItem>> getInventoryItems(String farmId) async {
    try {
      final box = await _getInventoryBox();
      return box.values
          .where((item) => item.farmId == farmId)
          .toList();
    } catch (e) {
      print('Error getting inventory items: $e');
      return [];
    }
  }

  // Get inventory items by category
  static Future<List<InventoryItem>> getInventoryByCategory(
    String farmId,
    String category,
  ) async {
    try {
      final box = await _getInventoryBox();
      return box.values
          .where((item) => item.farmId == farmId && item.category == category)
          .toList();
    } catch (e) {
      print('Error getting inventory by category: $e');
      return [];
    }
  }

  // Get low stock items
  static Future<List<InventoryItem>> getLowStockItems(String farmId) async {
    try {
      final box = await _getInventoryBox();
      return box.values
          .where((item) => item.farmId == farmId && item.isLowStock)
          .toList();
    } catch (e) {
      print('Error getting low stock items: $e');
      return [];
    }
  }

  // Add stock (purchase)
  static Future<void> addStock(
    String itemId,
    double quantity,
    double unitPrice, {
    String? supplier,
    String? notes,
  }) async {
    try {
      final box = await _getInventoryBox();
      final item = box.get(itemId);
      if (item == null) throw Exception('Inventory item not found');

      // Update item quantity
      final updatedItem = item.copyWith(
        quantity: item.quantity + quantity,
        unitPrice: unitPrice,
        updatedAt: DateTime.now(),
      );
      await updateInventoryItem(updatedItem);

      // Add transaction record
      final transaction = InventoryTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        farmId: item.farmId,
        itemId: itemId,
        transactionType: 'in',
        quantity: quantity,
        unit: item.unit,
        unitPrice: unitPrice,
        totalAmount: quantity * unitPrice,
        transactionDate: DateTime.now(),
        notes: notes ?? 'Zaxira qo\'shildi',
        recordedBy: 'system', // You might want to pass user ID here
      );

      await addTransaction(transaction);

      // Log activity
      await ActivityLogService.addActivityLog(ActivityLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        farmId: item.farmId,
        type: ActivityType.other,
        title: 'Zaxira qo\'shildi',
        description: '${item.name}: $quantity ${item.unit} qo\'shildi',
        metadata: {
          'itemId': itemId,
          'quantity': quantity,
          'unitPrice': unitPrice,
          'supplier': supplier,
        },
        importance: ActivityImportance.high,
      ));
    } catch (e) {
      print('Error adding stock: $e');
      rethrow;
    }
  }

  // Use stock (consumption)
  static Future<void> useStock(
    String itemId,
    double quantity, {
    String? notes,
  }) async {
    try {
      final box = await _getInventoryBox();
      final item = box.get(itemId);
      if (item == null) throw Exception('Inventory item not found');

      if (item.quantity < quantity) {
        throw Exception('Yetarli zaxira yo\'q! Mavjud: ${item.quantity} ${item.unit}');
      }

      // Update item quantity
      final updatedItem = item.copyWith(
        quantity: item.quantity - quantity,
        updatedAt: DateTime.now(),
      );
      await updateInventoryItem(updatedItem);

      // Add transaction record
      final transaction = InventoryTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        farmId: item.farmId,
        itemId: itemId,
        transactionType: 'out',
        quantity: quantity,
        unit: item.unit,
        unitPrice: item.unitPrice,
        totalAmount: quantity * (item.unitPrice ?? 0),
        transactionDate: DateTime.now(),
        notes: notes ?? 'Ishlatildi',
        recordedBy: 'system',
      );

      await addTransaction(transaction);

      // Check if item is now low stock and notify
      if (updatedItem.isLowStock) {
        await NotificationService.showNotification(
          id: itemId.hashCode,
          title: '⚠️ Zaxira kam!',
          body: '${item.name} tugab qolmoqda. Qolgan: ${updatedItem.quantity} ${item.unit}',
          payload: 'low_stock_$itemId',
        );
      }

      // Log activity
      await ActivityLogService.addActivityLog(ActivityLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        farmId: item.farmId,
        type: ActivityType.other,
        title: 'Zaxira ishlatildi',
        description: '${item.name}: $quantity ${item.unit} ishlatildi',
        metadata: {
          'itemId': itemId,
          'quantity': quantity,
          'remainingStock': updatedItem.quantity,
        },
        importance: updatedItem.isLowStock 
            ? ActivityImportance.high 
            : ActivityImportance.normal,
      ));
    } catch (e) {
      print('Error using stock: $e');
      rethrow;
    }
  }

  // Add transaction
  static Future<void> addTransaction(InventoryTransaction transaction) async {
    try {
      final box = await _getTransactionsBox();
      await box.put(transaction.id, transaction);

      // Try to save to Supabase
      try {
        await _supabase.from(_transactionsTable).insert(transaction.toJson());
      } catch (supabaseError) {
        print('Failed to sync transaction to Supabase: $supabaseError');
      }
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  // Get transactions for an item
  static Future<List<InventoryTransaction>> getItemTransactions(String itemId) async {
    try {
      final box = await _getTransactionsBox();
      var transactions = box.values
          .where((transaction) => transaction.itemId == itemId)
          .toList();
      
      // Sort by date (newest first)
      transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return transactions;
    } catch (e) {
      print('Error getting item transactions: $e');
      return [];
    }
  }

  // Get transactions for a farm
  static Future<List<InventoryTransaction>> getFarmTransactions(
    String farmId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final box = await _getTransactionsBox();
      var transactions = box.values
          .where((transaction) => transaction.farmId == farmId)
          .toList();

      // Filter by date range if provided
      if (startDate != null && endDate != null) {
        transactions = transactions
            .where((transaction) =>
                transaction.transactionDate.isAfter(startDate) &&
                transaction.transactionDate.isBefore(endDate))
            .toList();
      }

      // Sort by date (newest first)
      transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return transactions;
    } catch (e) {
      print('Error getting farm transactions: $e');
      return [];
    }
  }

  // Check all low stock items and send notifications
  static Future<void> checkLowStockAndNotify(String farmId) async {
    try {
      final lowStockItems = await getLowStockItems(farmId);
      
      if (lowStockItems.isNotEmpty) {
        final itemNames = lowStockItems.map((item) => item.name).join(', ');
        await NotificationService.showNotification(
          id: 999, // Special ID for low stock summary
          title: '⚠️ Zaxiralar tugab qolmoqda!',
          body: '$itemNames - bu mahsulotlar kam qoldi. Yangi sotib oling!',
          payload: 'low_stock_summary',
        );

        // Log activity
        await ActivityLogService.addActivityLog(ActivityLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          farmId: farmId,
          type: ActivityType.other,
          title: 'Kam qolgan zaxiralar',
          description: '${lowStockItems.length} ta mahsulot kam qoldi: $itemNames',
          metadata: {
            'lowStockCount': lowStockItems.length,
            'items': lowStockItems.map((item) => item.id).toList(),
          },
          importance: ActivityImportance.critical,
        ));
      }
    } catch (e) {
      print('Error checking low stock: $e');
    }
  }

  // Get inventory statistics
  static Future<Map<String, dynamic>> getInventoryStats(String farmId) async {
    try {
      final items = await getInventoryItems(farmId);
      final lowStockItems = items.where((item) => item.isLowStock).toList();
      final outOfStockItems = items.where((item) => item.isOutOfStock).toList();
      
      final totalValue = items
          .map((item) => (item.unitPrice ?? 0) * item.quantity)
          .fold(0.0, (sum, value) => sum + value);

      final categoryStats = <String, int>{};
      for (final item in items) {
        categoryStats[item.category] = (categoryStats[item.category] ?? 0) + 1;
      }

      return {
        'totalItems': items.length,
        'lowStockItems': lowStockItems.length,
        'outOfStockItems': outOfStockItems.length,
        'totalValue': totalValue,
        'categoryStats': categoryStats,
      };
    } catch (e) {
      print('Error getting inventory stats: $e');
      return {};
    }
  }

  // Initialize service
  static Future<void> initialize() async {
    try {
      // Register Hive adapters if not already registered
      if (!Hive.isAdapterRegistered(13)) {
        Hive.registerAdapter(InventoryItemAdapter());
      }
      if (!Hive.isAdapterRegistered(14)) {
        Hive.registerAdapter(InventoryTransactionAdapter());
      }

      print('Inventory Service initialized with Hive adapters');
    } catch (e) {
      print('Error initializing Inventory Service: $e');
    }
  }

  // Quick methods for common operations
  static Future<void> addFeedStock({
    required String farmId,
    required String feedType,
    required double quantity,
    required double unitPrice,
    String? supplier,
  }) async {
    // Check if feed already exists
    final items = await getInventoryByCategory(farmId, 'feed');
    final existingFeed = items.cast<InventoryItem?>().firstWhere(
      (item) => item?.name == feedType,
      orElse: () => null,
    );

    if (existingFeed != null) {
      // Add to existing stock
      await addStock(
        existingFeed.id,
        quantity,
        unitPrice,
        supplier: supplier,
        notes: 'Yem zaxirasi qo\'shildi',
      );
    } else {
      // Create new feed item
      final newFeed = InventoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        farmId: farmId,
        name: feedType,
        category: 'feed',
        quantity: quantity,
        unit: 'kg',
        unitPrice: unitPrice,
        minStockLevel: 50.0, // Default minimum for feed
        supplier: supplier,
        description: '$feedType yemi',
      );
      await addInventoryItem(newFeed);
    }
  }

  static Future<void> useFeedStock({
    required String farmId,
    required String feedType,
    required double quantity,
  }) async {
    final items = await getInventoryByCategory(farmId, 'feed');
    final feed = items.cast<InventoryItem?>().firstWhere(
      (item) => item?.name == feedType,
      orElse: () => null,
    );

    if (feed == null) {
      throw Exception('$feedType yemi topilmadi');
    }

    await useStock(
      feed.id,
      quantity,
      notes: 'Tovuqlarga berildi',
    );
  }
}