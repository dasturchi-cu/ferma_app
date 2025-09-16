import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/farm.dart';
import '../models/customer.dart';
import '../models/chicken.dart';
import '../models/egg.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../config/supabase_config.dart';
import '../utils/uuid_generator.dart';

class FarmProvider with ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final StorageService _storage = StorageService();

  Farm? _farm;
  bool _isLoading = false;
  String? _error;
  bool _isOfflineMode = false;
  bool _isLoadingEggData = false;

  // UI UPDATE DEBOUNCING
  Timer? _notifyTimer;
  static const Duration _notifyDelay = Duration(milliseconds: 300);

  // ACTIVITY LOG UPDATE CALLBACK
  static Function()? onActivityLogUpdated;

  // PERSIST DEBOUNCING
  Timer? _persistTimer;
  static const Duration _persistDelay = Duration(seconds: 2);
  bool _hasPendingChanges = false;

  // REALTIME UPDATE THROTTLING
  DateTime? _lastRealtimeUpdate;
  static const Duration _realtimeThrottle = Duration(seconds: 3);

  // Realtime subscriptions
  StreamSubscription<List<Map<String, dynamic>>>? _farmStreamSub;
  StreamSubscription<List<Map<String, dynamic>>>? _customersStreamSub;
  StreamSubscription<List<Map<String, dynamic>>>? _eggRecordsStreamSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivityStreamSub;

  // Getters
  Farm? get farm => _farm;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOfflineMode => _isOfflineMode;

  // DEBOUNCED UI UPDATE to prevent excessive re-renders
  void _notifyListenersDebounced() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(_notifyDelay, () {
      notifyListeners();
    });
  }

  // Immediate notify for critical updates
  void _notifyListenersImmediate() {
    _notifyTimer?.cancel();
    notifyListeners();
  }

  // DEBOUNCED PERSIST to prevent too many saves
  void _persistDebounced() {
    _hasPendingChanges = true;
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDelay, () async {
      if (_hasPendingChanges) {
        await _persist();
        _hasPendingChanges = false;
      }
    });
  }

  // Force immediate persist for critical operations
  Future<void> _persistImmediate() async {
    _persistTimer?.cancel();
    _hasPendingChanges = false;
    await _persist();
  }

  // Farmni o'rnatish
  void setFarm(Farm farm) {
    // Initialize Egg and Chicken objects if they are null
    _farm = _ensureFarmObjectsInitialized(farm);
    notifyListeners();
    // Auto-load data when farm is set
    _loadAllData();
    // Start connectivity monitoring
    _startConnectivityMonitoring();
  }

  // Ensure Farm has Egg and Chicken objects initialized (optimized)
  Farm _ensureFarmObjectsInitialized(Farm farm) {
    // Skip if already properly initialized
    if (farm.chicken != null && farm.egg != null) {
      return farm;
    }

    Chicken? chicken = farm.chicken;
    Egg? egg = farm.egg;
    bool needsUpdate = false;

    // Create Chicken object if null (only once)
    if (chicken == null) {
      chicken = Chicken(
        id: farm.id,
        totalCount: farm.chickenCount,
        deaths: const [],
      );
      needsUpdate = true;
    }

    // Create Egg object if null (only once)
    if (egg == null) {
      egg = Egg(id: farm.id);
      needsUpdate = true;
    }

    // Return farm with initialized objects only if needed
    if (needsUpdate) {
      final updatedFarm = farm.copyWith(
        chicken: chicken,
        egg: egg,
        updatedAt: DateTime.now(),
      );

      // Update internal farm reference immediately to prevent re-initialization
      _farm = updatedFarm;
      return updatedFarm;
    }

    return farm;
  }

  // Load egg data from Supabase (memory-optimized)
  Future<void> _loadEggDataFromSupabase(String farmId) async {
    if (_farm?.egg == null) return;

    // Prevent concurrent loading
    if (_isLoadingEggData) return;
    _isLoadingEggData = true;

    try {
      // Load egg productions with memory-conscious limit
      final productions = await _supabase
          .from('egg_productions')
          .select()
          .eq('farm_id', farmId)
          .order('production_date', ascending: false)
          .limit(30); // Reduced limit to save memory

      if (productions.isNotEmpty) {
        // MEMORY OPTIMIZATION: Only clear if we have new data
        final Set<String> existingIds = _farm?.egg?.production.map((p) => p.id).toSet() ?? {};
        final bool hasNewData = productions.any((record) =>
            !existingIds.contains(record['id'] as String? ?? ''));

        if (hasNewData && _farm?.egg != null) {
          // Smart clear: preserve recent 10 items to reduce object creation
          final recentProductions = _farm!.egg!.production.take(10).toList();
          final recentSales = _farm!.egg!.sales.take(10).toList();

          _farm!.egg!.production.clear();
          _farm!.egg!.sales.clear();

          // Restore recent items
          _farm!.egg!.production.addAll(recentProductions);
          _farm!.egg!.sales.addAll(recentSales);
        }

        // Parse productions with optimized processing
        final processedIds = <String>{};

        for (final record in productions) {
          final recordId = record['id'] as String? ?? '';

          // Skip if already processed
          if (recordId.isNotEmpty && processedIds.contains(recordId)) {
            continue; // Removed print to reduce log spam
          }
          processedIds.add(recordId);

          final recordType = record['record_type'] as String? ?? 'production';
          final trayCount = (record['tray_count'] as num?)?.toInt() ?? 0;
          final dateStr = record['created_at'] as String? ?? record['production_date'] as String?;
          final note = record['note'] as String?;

          // Skip invalid records
          if (trayCount <= 0) continue;

          // OPTIMIZED DATE PARSING - reuse DateTime objects where possible
          DateTime recordDate;
          if (dateStr != null) {
            try {
              recordDate = DateTime.parse(dateStr);
            } catch (e) {
              recordDate = DateTime.now();
            }
          } else {
            recordDate = DateTime.now();
          }

          // MEMORY OPTIMIZATION: Create objects only if needed
          if (_farm?.egg == null) continue;

          switch (recordType) {
            case 'production':
              _farm!.egg!.production.add(EggProduction(
                id: recordId.isNotEmpty ? recordId : UuidGenerator.generateUuid(),
                trayCount: trayCount,
                date: recordDate,
                note: note,
              ));
              break;
            case 'sale':
              final pricePerTray = (record['price_per_tray'] as num?)?.toDouble() ?? 0.0;
              _farm!.egg!.sales.add(EggSale(
                id: recordId.isNotEmpty ? recordId : UuidGenerator.generateUuid(),
                trayCount: trayCount,
                pricePerTray: pricePerTray,
                date: recordDate,
                note: note,
              ));
              break;
          }
        }

        // PERFORMANCE: Only print if stock changed significantly
        final currentStock = _farm?.egg?.currentStock ?? 0;
        if (currentStock % 100 == 0 || currentStock < 100) { // Only log round numbers or low stock
          print('🥚 Egg zaxira: $currentStock fletka');
        }
      }
    } catch (e) {
      print('⚠️ Supabase egg ma\'lumot xatolik: $e');
    } finally {
      _isLoadingEggData = false;
    }
  }

  // Load egg data from Hive if available
  Future<Egg?> _loadEggDataFromHive(String farmId) async {
    try {
      // Try to load egg productions from activity logs or egg records
      if (!Hive.isBoxOpen('activity_logs')) {
        await Hive.openBox<Map>('activity_logs');
      }

      final activityBox = Hive.box<Map>('activity_logs');
      final activities = activityBox.values.where(
        (activity) => activity is Map &&
                     activity['farm_id'] == farmId &&
                     activity['type'] == 'eggProduction'
      ).toList();

      if (activities.isNotEmpty) {
        print('💾 ${activities.length} ta egg production topildi Hive dan');
        // TODO: Parse activities and create proper Egg object
      }

      return null; // For now, return null and let it create fresh Egg
    } catch (e) {
      print('⚠️ Egg data Hive dan yuklashda xatolik: $e');
      return null;
    }
  }

  // Load all data automatically
  Future<void> _loadAllData() async {
    try {
      await _refreshFarmData();
      await startRealtime();
    } catch (e) {
      print('Auto load data error: $e');
    }
  }

  // Start monitoring internet connectivity
  void _startConnectivityMonitoring() {
    _connectivityStreamSub = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      final isConnected = results.any((result) => result != ConnectivityResult.none);

      if (isConnected && _isOfflineMode) {
        print('Internet ga ulandi! Offline ma\'lumotlarni sync qilish...');
        _isOfflineMode = false;
        // Sync offline data to Supabase
        await _syncOfflineData();
        await startRealtime();
        notifyListeners();
      } else if (!isConnected && !_isOfflineMode) {
        print('Internet uzildi! Offline rejimga o\'tish...');
        _isOfflineMode = true;
        await stopRealtime();
        notifyListeners();
      }
    });
  }

  // Sync offline data to Supabase when internet comes back
  Future<void> _syncOfflineData() async {
    if (_farm == null) return;

    try {
      await _saveToSupabase();
      print('Offline ma\'lumotlar muvaffaqiyatli Supabase ga yuklandi!');
    } catch (e) {
      print('Offline ma\'lumotlarni sync qilishda xatolik: $e');
      _isOfflineMode = true; // Stay offline if sync fails
    }
  }

  // -----------------------------
  // Realtime
  // -----------------------------
  Future<void> startRealtime() async {
    if (_farm == null) return;
    await stopRealtime();

    try {
      // Farm stream (optimized)
      _farmStreamSub = _supabase
          .from('farms')
          .stream(primaryKey: ['id'])
          .eq('id', _farm!.id)
          .listen((rows) async {
            if (rows.isNotEmpty) {
              try {
                final farmData = rows.first;

                // Enhanced null check - validate all critical fields
                if (farmData != null &&
                    farmData['id'] != null &&
                    farmData['name'] != null &&
                    farmData['owner_id'] != null &&
                    farmData['id'] is String &&
                    farmData['name'] is String &&
                    farmData['owner_id'] is String) {

                  // THROTTLE: Skip if update is too frequent
                  final now = DateTime.now();
                  if (_lastRealtimeUpdate != null &&
                      now.difference(_lastRealtimeUpdate!) < _realtimeThrottle) {
                    return;
                  }

                  // Skip if data hasn't actually changed
                  if (_farm?.name == farmData['name'] &&
                      _farm?.description == farmData['description']) {
                    return;
                  }

                  _lastRealtimeUpdate = now;

                  // Additional data sanitization
                  final sanitizedData = Map<String, dynamic>.from(farmData);
                  sanitizedData['description'] ??= '';

                  final updated = Farm.fromJson(sanitizedData);
                  _farm = _ensureFarmObjectsInitialized(updated);

                  // Only save if significant change
                  await _saveToHive();
                  _notifyListenersDebounced(); // Use debounced for realtime updates
                }
              } catch (e) {
                print('⚠️ Realtime farm ma\'lumotini parse qilishda xatolik: $e');
              }
            }
          });

      // Customers stream
      _customersStreamSub = _supabase
          .from('customers')
          .stream(primaryKey: ['id'])
          .eq('farm_id', _farm!.id)
          .listen((rows) async {
            await _refreshFarmData();
          });

      // Egg records stream
      _eggRecordsStreamSub = _supabase
          .from('egg_productions')
          .stream(primaryKey: ['id'])
          .eq('farm_id', _farm!.id)
          .listen((rows) async {
            if (_farm != null && _farm!.egg != null) {
              await _processEggRecords(rows);
              await _saveToHive();
              _notifyListenersDebounced(); // Debounced for egg stream updates
            }
          });
    } catch (e) {
      _error = 'Realtime ulanishda xatolik: $e';
      notifyListeners();
    }
  }

  Future<void> stopRealtime() async {
    await _farmStreamSub?.cancel();
    await _customersStreamSub?.cancel();
    await _eggRecordsStreamSub?.cancel();
    await _connectivityStreamSub?.cancel();
    _farmStreamSub = null;
    _customersStreamSub = null;
    _eggRecordsStreamSub = null;
    _connectivityStreamSub = null;
  }

  // -----------------------------
  // Supabase dan farmni yangilash
  // -----------------------------
  Future<void> _refreshFarmData() async {
    if (_farm == null) return;
    try {
      // Internet bor yoki yo'qligini tekshirish
      final response = await _supabase
          .from('farms')
          .select()
          .eq('id', _farm!.id)
          .maybeSingle();

      if (response != null) {
        try {
          // Sanitize response data
          final sanitizedResponse = Map<String, dynamic>.from(response);

          // Ensure required fields are not null
          sanitizedResponse['description'] ??= '';
          sanitizedResponse['chicken_count'] ??= 0;
          sanitizedResponse['egg_production_rate'] ??= 0;

          final loadedFarm = Farm.fromJson(sanitizedResponse);
          _farm = _ensureFarmObjectsInitialized(loadedFarm);

          // Load egg productions from Supabase
          await _loadEggDataFromSupabase(_farm!.id);

          await _saveToHive();
          _isOfflineMode = false;
          notifyListeners();
        } catch (parseError) {
          print('Supabase dan yuklashda xatolik: $parseError');
          // If JSON parsing fails, load from Hive
          await _loadFromHive();
        }
      } else {
        print('! Primary farm data topilmadi, backup dan qidirilmoqda...');
        await _loadFromHive();
      }
    } catch (e) {
      print('Farmni yangilashda xatolik, offline rejimga o\'tildi: $e');
      _isOfflineMode = true;
      // Load from Hive if online fails
      await _loadFromHive();
    }
  }

  // Egg recordsni qayta ishlash
  Future<void> _processEggRecords(List<Map<String, dynamic>> records) async {
    if (_farm?.egg == null) return;

    try {
      for (final record in records) {
        try {
          // Safely extract data with null checks
          final trayCount = (record['tray_count'] as num?)?.toInt() ?? 0;
          final pricePerTray = (record['price_per_tray'] as num?)?.toDouble() ?? 0.0;
          final note = record['note'] as String?;
          final type = record['record_type'] as String? ?? 'production';

          // Skip empty records
          if (trayCount <= 0) continue;

          // Additional safety check
          if (_farm?.egg == null) {
            print('⚠️ _farm.egg null bo\'lib qoldi, qayta yaratilmoqda');
            _farm = _farm!.copyWith(egg: Egg(id: _farm!.id));
          }

          switch (type) {
            case 'production':
              _farm!.egg!.addProduction(trayCount, note: note);
              break;
            case 'sale':
              _farm!.egg!.addSale(trayCount, pricePerTray, note: note);
              break;
            case 'broken':
              if (_farm!.egg != null) {
                _farm!.egg!.addBroken(trayCount, note: note);
              }
              break;
            case 'large':
              if (_farm!.egg != null) {
                _farm!.egg!.addLarge(trayCount, note: note);
              }
              break;
            default:
              _farm!.egg!.addProduction(trayCount, note: note);
              break;
          }
        } catch (recordError) {
          print('⚠️ Bitta egg record qayta ishlashda xatolik: $recordError');
          print('⚠️ Record ma\'lumoti: $record');
        }
      }
    } catch (e) {
      print('❌ _processEggRecords da umumiy xatolik: $e');
    }
  }

  // -----------------------------
  // Farm actions
  // -----------------------------
  Future<bool> addChickens(int count) async {
    if (_farm == null) return false;
    try {
      _farm!.addChickens(count);

      // Immediate UI update
      notifyListeners();

      await _addActivityLog('Tovuqlar qo\'shildi',
        '$count dona tovuq ferma ga qo\'shildi. Jami: ${_farm!.chicken?.currentCount ?? 0}');
      _persistDebounced(); // Use debounced persist
      return true;
    } catch (e) {
      _error = 'Tovuqlar qo\'shishda xatolik: $e';
      await _addActivityLog('Xatolik', 'Tovuq qo\'shishda xatolik: $e');
      return false;
    }
  }

  Future<bool> addChickenDeath(int count) async {
    if (_farm == null) return false;
    try {
      _farm!.addChickenDeath(count);
      await _addActivityLog('Tovuq o\'limi',
        '$count dona tovuq o\'ldi. Qolgan: ${_farm!.chicken?.currentCount ?? 0}');
      await _persist();
      return true;
    } catch (e) {
      _error = 'Tovuq o\'limini qo\'shishda xatolik: $e';
      await _addActivityLog('Xatolik', 'Tovuq o\'limini qo\'shishda xatolik: $e');
      return false;
    }
  }

  // DUPLICATE PREVENTION: Track pending operations
  final Set<String> _pendingOperations = {};

  Future<bool> addEggProduction(int trays, {String? note}) async {
    if (_farm == null) {
      print('❌ Farm null, tuxum qo\'shib bo\'lmaydi');
      return false;
    }

    // DUPLICATE PREVENTION: Create unique operation ID
    final operationId = 'egg_prod_${DateTime.now().millisecondsSinceEpoch}_${trays}_${note ?? ""}';
    if (_pendingOperations.contains(operationId)) {
      print('⚠️ Takroriy operation o\'tkazildi: $operationId');
      return true; // Return success but don't duplicate
    }
    _pendingOperations.add(operationId);

    // Egg objectini tekshirish va yaratish
    if (_farm!.egg == null) {
      _farm = _farm!.copyWith(egg: Egg(id: _farm!.id));
    }

    try {
      print('📝 Tuxum ishlab chiqarish qo\'shilmoqda: $trays fletka');

      // Add to local data ONCE
      _farm!.addEggProduction(trays, note: note);
      final currentStock = _farm!.egg?.currentStock ?? 0;

      print('✅ Tuxum qo\'shildi. Yangi zaxira: $currentStock fletka');

      // IMPORTANT: Update UI immediately
      _notifyListenersImmediate();

      // Add activity log immediately (not async)
      await _addActivityLog('⏰ ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} - Tuxum ishlab chiqarildi',
        '$trays fletka tuxum ishlab chiqarildi. Jami zaxira: $currentStock fletka${note != null ? '. Izoh: $note' : ''}');

      // Use immediate persist for critical egg data
      await _persistImmediate();

      return true;
    } catch (e) {
      print('❌ Tuxum ishlab chiqarishda xatolik: $e');
      _error = 'Tuxum ishlab chiqarishda xatolik: $e';
      notifyListeners();
      return false;
    } finally {
      // CLEANUP: Remove operation ID after completion
      _pendingOperations.remove(operationId);
    }
  }

  Future<bool> addEggSale(
    int trays,
    double pricePerTray, {
    String? note,
  }) async {
    if (_farm == null) return false;

    // Check if enough stock is available
    final currentStock = _farm!.egg?.currentStock ?? 0;
    if (trays > currentStock) {
      _error = 'Yetarli tuxum yo\'q! Mavjud: $currentStock fletka';
      notifyListeners();
      return false;
    }

    // BACKUP current state before making changes
    final backupEgg = _farm!.egg != null ?
        Egg(
          id: _farm!.egg!.id,
          production: List.from(_farm!.egg!.production),
          sales: List.from(_farm!.egg!.sales),
          brokenEggs: List.from(_farm!.egg!.brokenEggs),
          largeEggs: List.from(_farm!.egg!.largeEggs),
        ) : null;

    try {
      // Make changes to local data
      _farm!.addEggSale(trays, pricePerTray, note: note);
      final totalAmount = trays * pricePerTray;
      final remainingStock = _farm!.egg?.currentStock ?? 0;

      // Update UI immediately
      _notifyListenersImmediate();

      // Try to save data with rollback on failure
      try {
        await _addActivityLog('Tuxum sotildi',
          '$trays fletka tuxum ${totalAmount.toStringAsFixed(0)} so\'mga sotildi. Qolgan: $remainingStock fletka${note != null ? '. Izoh: $note' : ''}');
        await _persist();

        print('✅ Tuxum sotish muvaffaqiyatli saqlandi');
        return true;
      } catch (saveError) {
        // ROLLBACK: Restore backup state if save failed
        if (backupEgg != null) {
          _farm = _farm!.copyWith(egg: backupEgg);
          _notifyListenersImmediate();
          print('🔄 Ma\'lumotlar qaytarildi (rollback)');
        }
        throw saveError;
      }
    } catch (e) {
      print('❌ Tuxum sotishda xatolik: $e');
      _error = 'Tuxum sotishda xatolik: $e';
      notifyListeners();

      // Try to log error (but don't fail if this fails too)
      try {
        await _addActivityLog('Xatolik', 'Tuxum sotishda xatolik: $e');
      } catch (logError) {
        print('⚠️ Activity log yozishda ham xatolik: $logError');
      }

      return false;
    }
  }

  Future<bool> addBrokenEgg(int trays, {String? note}) async {
    if (_farm == null) return false;

    // Check if enough stock is available
    final currentStock = _farm!.egg?.currentStock ?? 0;
    if (trays > currentStock) {
      _error = 'Yetarli tuxum yo\'q! Mavjud: $currentStock fletka';
      return false;
    }

    try {
      _farm!.addBrokenEgg(trays, note: note);
      await _persist();
      return true;
    } catch (e) {
      _error = 'Siniq tuxum qo\'shishda xatolik: $e';
      return false;
    }
  }

  Future<bool> addLargeEgg(int trays, {String? note}) async {
    if (_farm == null) return false;
    try {
      _farm!.addLargeEgg(trays, note: note);
      await _persist();
      return true;
    } catch (e) {
      _error = 'Katta tuxum qo‘shishda xatolik: $e';
      return false;
    }
  }

  Future<bool> addCustomer(
    String name, {
    String? phone,
    String? address,
  }) async {
    if (_farm == null) return false;
    try {
      _farm!.addCustomer(name, phone: phone, address: address);

      // Immediate UI update
      notifyListeners();

      await _addActivityLog('Yangi mijoz',
        'Mijoz qo\'shildi: $name${phone != null ? ' ($phone)' : ''}${address != null ? ', $address' : ''}');
      await _persist();
      return true;
    } catch (e) {
      _error = 'Mijoz qo\'shishda xatolik: $e';
      await _addActivityLog('Xatolik', 'Mijoz qo\'shishda xatolik: $e');
      return false;
    }
  }

  Future<bool> removeCustomer(String customerId) async {
    if (_farm == null) return false;
    try {
      _farm!.removeCustomer(customerId);
      await _persist();
      return true;
    } catch (e) {
      _error = 'Mijozni o‘chirishda xatolik: $e';
      return false;
    }
  }

  Future<bool> addCustomerOrder(
    String customerId,
    int trays,
    double pricePerTray,
    DateTime deliveryDate, {
    String? note,
  }) async {
    if (_farm == null) {
      _error = 'Fermer xo\'jaligi topilmadi';
      return false;
    }

    // Validate input
    if (trays <= 0) {
      _error = 'Noto\'g\'ri tuxum soni kiritildi';
      return false;
    }

    if (pricePerTray < 0) {
      _error = 'Noto\'g\'ri narx kiritildi';
      return false;
    }

    try {
      // Process the order
      final success = _farm!.addCustomerOrder(
        customerId,
        trays,
        pricePerTray,
        deliveryDate,
        note: note,
      );

      if (!success) {
        _error = _farm!.egg != null ?
          'Yetarli tuxum yo\'q. Mavjud: ${_farm!.egg!.currentStock}' :
          'Buyurtmani qo\'shishda xatolik sodir bo\'ldi';
        return false;
      }

      // Persist changes
      await _persist();

      // Update the UI
      _notifyListenersImmediate();

      // Add to activity log
      final customer = _farm!.findCustomer(customerId);
      if (customer != null) {
        await _addActivityLog(
          'Yangi buyurtma',
          '${customer.name} uchun $trays ta tuxum buyurtma qilindi',
          activityType: 'order',
          importance: 'high',
        );
      }

      return true;
    } catch (e) {
      _error = 'Buyurtmani qo\'shishda xatolik: $e';
      return false;
    }
  }

  Future<bool> markCustomerOrderAsPaid(
    String customerId,
    String orderId,
  ) async {
    if (_farm == null) {
      _error = 'Fermer xo\'jaligi topilmadi';
      return false;
    }

    try {
      // Mark the order as paid
      _farm!.markCustomerOrderAsPaid(customerId, orderId);

      // Persist the changes
      await _persist();

      // Update the UI immediately
      _notifyListenersImmediate();

      // Add to activity log
      final customer = _farm!.findCustomer(customerId);
      if (customer != null) {
        final order = customer.orders.firstWhere(
          (o) => o.id == orderId,
          orElse: () => throw Exception('Buyurtma topilmadi'),
        );

        await _addActivityLog(
          'Buyurtma to\'lovi',
          '${customer.name} uchun ${order.trayCount} ta tuxum to\'lovi qabul qilindi',
          activityType: 'payment',
          importance: 'high',
        );
      }

      return true;
    } catch (e) {
      _error = 'Buyurtmani to\'langan deb belgilashda xatolik: $e';
      return false;
    }
  }

  Future<bool> removeCustomerOrder(String customerId, String orderId) async {
    if (_farm == null) {
      _error = 'Fermer xo\'jaligi topilmadi';
      return false;
    }

    try {
      // Find the customer and order first
      final customer = _farm!.findCustomer(customerId);
      if (customer == null) {
        _error = 'Mijoz topilmadi';
        return false;
      }

      final order = customer.orders.firstWhere(
        (o) => o.id == orderId,
        orElse: () => throw Exception('Buyurtma topilmadi'),
      );

      // If order is not paid, we need to return the stock
      if (!order.isPaid && _farm!.egg != null) {
        // Add the stock back by adding a negative sale
        _farm!.egg!.addSale(-order.trayCount, 0.0, note: 'Bekor qilingan buyurtma: $orderId');
      }

      // Remove the order
      _farm!.removeCustomerOrder(customerId, orderId);

      // Persist changes
      await _persist();

      // Update the UI
      _notifyListenersImmediate();

      // Add to activity log
      await _addActivityLog(
        'Buyurtma o\'chirildi',
        '${customer.name} uchun ${order.trayCount} ta tuxum buyurtmasi o\'chirildi',
        activityType: 'order',
        importance: 'high',
      );

      return true;
    } catch (e) {
      _error = 'Buyurtmani o\'chirishda xatolik: $e';
      return false;
    }
  }

  Future<bool> updateCustomerInfo(
    String customerId, {
    String? name,
    String? phone,
    String? address,
  }) async {
    if (_farm == null) return false;
    try {
      _farm!.updateCustomerInfo(
        customerId,
        name: name,
        phone: phone,
        address: address,
      );
      await _persist();
      return true;
    } catch (e) {
      _error = 'Mijozni yangilashda xatolik: $e';
      return false;
    }
  }

  Future<bool> addCustomerEggSale(
    String customerId,
    int trays,
    double pricePerTray, {
    String? note,
  }) async {
    if (_farm == null) return false;

    // Check if enough stock is available
    final currentStock = _farm!.egg?.currentStock ?? 0;
    if (trays > currentStock) {
      _error = 'Yetarli tuxum yo\'q! Mavjud: $currentStock fletka';
      return false;
    }

    try {
      // Reduce egg stock
      _farm!.addEggSale(trays, pricePerTray, note: note ?? 'Mijozga sotildi');

      // Add as unpaid order (debt) to customer
      final deliveryDate = DateTime.now();
      _farm!.addCustomerOrder(
        customerId,
        trays,
        pricePerTray,
        deliveryDate,
        note: note ?? 'Tuxum sotildi - qarz',
      );

      await _persist();
      return true;
    } catch (e) {
      _error = 'Mijozga tuxum sotishda xatolik: $e';
      return false;
    }
  }

  Future<bool> addManualDebt({
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required double debtAmount,
    required String note,
  }) async {
    if (_farm == null) return false;

    try {
      // Create a SEPARATE debt record (not in regular customers list)
      // This debt will ONLY show in Debts screen, not in Customers screen

      // Check if this person already has a debt record
      String? existingDebtorId;
      final existingDebtor = _farm!.customers.where(
        (c) => c.phone.replaceAll(RegExp(r'\s+'), '') == customerPhone.replaceAll(RegExp(r'\s+'), '') &&
               c.name.startsWith('QARZ:')
      ).firstOrNull;

      if (existingDebtor != null) {
        // Update existing debt record
        existingDebtorId = existingDebtor.id;
      } else {
        // Create new debt-only customer (marked with QARZ: prefix)
        _farm!.addCustomer(
          'QARZ: $customerName', // Special prefix to identify debt-only customers
          phone: customerPhone,
          address: customerAddress.isNotEmpty ? customerAddress : null,
        );
        existingDebtorId = _farm!.customers.last.id;
      }

      // Add debt as unpaid order
      final deliveryDate = DateTime.now();
      _farm!.addCustomerOrder(
        existingDebtorId,
        1, // 1 tray to ensure totalAmount calculation works
        debtAmount, // price per tray = total debt amount
        deliveryDate,
        note: 'MANUAL_DEBT: ${note.isNotEmpty ? note : "Qo'lda qo'shilgan qarz"}',
      );

      await _persist();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Qarz qo\'shishda xatolik: $e';
      notifyListeners();
      return false;
    }
  }

  // Get only regular customers (not debt-only ones)
  List<Customer> getRegularCustomers() {
    if (_farm == null) return [];
    return _farm!.customers.where((c) => !c.name.startsWith('QARZ:')).toList();
  }

  // Get only debt customers (for Debts screen)
  List<Customer> getDebtOnlyCustomers() {
    if (_farm == null) return [];
    return _farm!.customers.where((c) => c.name.startsWith('QARZ:') && c.totalDebt > 0).toList();
  }

  Future<bool> addEggSaleWithCustomer({
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required int trayCount,
    required double pricePerTray,
    required double paidAmount,
  }) async {
    if (_farm == null) return false;

    // Check if enough stock is available
    final currentStock = _farm!.egg?.currentStock ?? 0;
    if (trayCount > currentStock) {
      _error = 'Yetarli tuxum yo\'q! Mavjud: $currentStock fletka';
      notifyListeners();
      return false;
    }

    try {
      print('📝 Mijozga tuxum sotish boshlandi: $trayCount fletka - $customerName');

      // DEBUG: Mijozlar ro'yxatini tekshirish
      print('🔍 Hozirgi mijozlar soni: ${_farm!.customers.length}');
      print('🔍 QARZ mijozlar: ${_farm!.customers.where((c) => c.name.startsWith("QARZ:")).length}');
      print('🔍 Oddiy mijozlar: ${_farm!.customers.where((c) => !c.name.startsWith("QARZ:")).length}');

      // First, add or find the customer (QARZ: prefixi bilan emas!)
      String? customerId;
      final existingCustomer = _farm!.customers.where(
        (c) => c.phone.replaceAll(RegExp(r'\s+'), '') == customerPhone.replaceAll(RegExp(r'\s+'), '') &&
               !c.name.startsWith('QARZ:') // Exclude debt-only customers
      ).firstOrNull;

      if (existingCustomer != null) {
        // Update existing customer info if needed (but don't call updateCustomerInfo to avoid extra persist)
        existingCustomer.name = customerName;
        existingCustomer.phone = customerPhone;
        if (customerAddress.isNotEmpty) {
          existingCustomer.address = customerAddress;
        }
        customerId = existingCustomer.id;
        print('✅ Mavjud mijoz topildi: $customerName (ID: $customerId)');
      } else {
        // Add new regular customer (NOT debt-only)
        print('🔶 Yangi mijoz yaratilmoqda: $customerName');

        // IMPORTANT: Call addCustomer method to ensure customer is properly added
        final success = await addCustomer(
          customerName,
          phone: customerPhone,
          address: customerAddress.isNotEmpty ? customerAddress : null,
        );

        if (!success) {
          print('❌ Mijoz qo\'shishda xatolik: ${_error}');
          throw Exception('Mijoz qo\'shib bo\'lmadi');
        }

        // Get the newly added customer's ID from the last added customer
        final newCustomer = _farm!.customers.where((c) =>
            c.name == customerName &&
            c.phone == customerPhone &&
            !c.name.startsWith('QARZ:')
        ).lastOrNull;

        if (newCustomer != null) {
          customerId = newCustomer.id;
          print('✅ Yangi mijoz muvaffaqiyatli qo\'shildi: $customerName (ID: $customerId)');
        } else {
          print('❌ Yangi mijoz topilmadi!');
          throw Exception('Mijoz yaratilgandan keyin topilmadi');
        }
      }

      // Reduce egg stock ONCE
      _farm!.addEggSale(trayCount, pricePerTray, note: 'Sotildi: $customerName');
      final remainingStock = _farm!.egg?.currentStock ?? 0;
      print('🥚 Tuxum stock kamaydi: $remainingStock fletka qoldi');

      // Calculate debt
      final totalAmount = trayCount * pricePerTray;
      final remainingDebt = totalAmount - paidAmount;

      // Add order to customer (as debt if not fully paid)
      final deliveryDate = DateTime.now();
      _farm!.addCustomerOrder(
        customerId,
        trayCount,
        pricePerTray,
        deliveryDate,
        note: 'Tuxum sotildi. To\'landi: ${paidAmount.toStringAsFixed(0)} so\'m',
      );

      // If fully paid, mark as paid immediately
      if (remainingDebt <= 0) {
        final customer = _farm!.customers.firstWhere((c) => c.id == customerId);
        final lastOrder = customer.orders.last;
        _farm!.markCustomerOrderAsPaid(customerId, lastOrder.id);
        print('💰 To\'langan buyurtma belgilandi');
      } else {
        print('💳 Qarz qoldi: ${remainingDebt.toStringAsFixed(0)} so\'m');
      }

      // Update UI immediately
      notifyListeners();

      // Log the transaction
      final stockAfter = _farm!.egg?.currentStock ?? 0;
      await _addActivityLog('Mijozga sotish',
        '$trayCount fletka tuxum $customerName ga sotildi. ${totalAmount.toStringAsFixed(0)} so\'m. To\'langan: ${paidAmount.toStringAsFixed(0)} so\'m. Zaxira: $stockAfter fletka');

      // Save changes
      await _persist();

      print('✅ Mijozga sotish muvaffaqiyatli yakunlandi');
      return true;
    } catch (e) {
      print('❌ Mijozga sotishda xatolik: $e');
      _error = 'Tuxum sotishda xatolik: $e';
      notifyListeners();
      return false;
    }
  }

  // -----------------------------
  // KUCHLI SAQLASH TIZIMI
  // -----------------------------
  Future<void> _persist() async {
    if (_farm == null) return;

    bool hiveSuccess = false;
    bool supabaseSuccess = false;
    String? lastError;

    try {
      // STEP 1: MAJBURIY lokal Hive saqlash
      try {
        await _saveToHive();
        hiveSuccess = true;
        // Silent save - no logs
      } catch (hiveError) {
        print('❌ Hive saqlashda xatolik: $hiveError');
        lastError = 'Lokal saqlash xatosi: $hiveError';

        // Fallback: direct storage service
        try {
          await _storage.saveFarmOffline(_farm!);
          hiveSuccess = true;
          // Silent backup save
        } catch (backupError) {
          print('💥 Rezerv saqlash ham muvaffaqiyatsiz: $backupError');
          lastError = 'KRITIK: Lokal ma\'lumotlar saqlanmadi: $backupError';
        }
      }

      // STEP 2: Skip automatic "data saved" activity logs to reduce noise
      // Only meaningful user actions should be logged

      // STEP 3: Supabase sinxronizatsiya (agar offline bo'lmasa)
      if (!_isOfflineMode && hiveSuccess) {
        try {
          await _syncToSupabaseWithRetry();
          supabaseSuccess = true;
          // Silent sync success
        } catch (supabaseError) {
          print('⚠️ Supabase sinxronizatsiyasida xatolik: $supabaseError');
          // Supabase xatosi offline mode ga o'tishni belgilaydi
          _isOfflineMode = true;

          if (hiveSuccess) {
            print('📱 Offline rejimga o\'tish: ma\'lumotlar lokal saqlanadi');
            lastError = null; // Clear error if local save succeeded
          }
        }
      } else if (_isOfflineMode) {
        print('📱 Offline rejimda: ma\'lumotlar faqat lokal saqlanadi');
      }

      // SUCCESS: Agar hech bo'lmaganda lokal saqlash muvaffaqiyatli bo'lsa
      if (hiveSuccess) {
        _error = null; // Clear any previous errors
        // All saves are silent now
      } else {
        _error = lastError ?? 'Noma\'lum saqlash xatosi';
      }

    } catch (e) {
      print('❌ _persist() da kutilmagan xatolik: $e');
      _error = 'Ma\'lumotlarni saqlashda kutilmagan xatolik: $e';
      // Faqat error bo'lsa UI ni update qilish
      notifyListeners();
    }
    // SUCCESS: persist() da notifyListeners() chaqirilmaydi
    // chunki alohida methodlarda allaqachon chaqirilgan
  }

  // RETRY MEXANIZMI BILAN SUPABASE SYNC (Thread-safe)
  Future<void> _syncToSupabaseWithRetry({int maxRetries = 3}) async {
    if (_farm == null) return;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Silent sync attempt

        // SODDA FARM MA'LUMOTLARINI SAQLASH (faqat mavjud maydonlar)
        final farmData = {
          'id': _farm!.id,
          'owner_id': _farm!.ownerId,
          'name': _farm!.name,
          'description': _farm!.description,
          // 'address' maydoni hozircha o'tkazilmaydi
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _supabase.from('farms').upsert(farmData);
        // Silent upsert

        // THREAD-SAFE: Create copies of lists to avoid concurrent modification
        List<EggProduction> productionsCopy = [];
        List<EggSale> salesCopy = [];

        if (_farm!.egg != null) {
          // Create defensive copies to prevent concurrent modification
          productionsCopy = List<EggProduction>.from(_farm!.egg!.production);
          salesCopy = List<EggSale>.from(_farm!.egg!.sales);
        }

        // Egg productions ni saqlash (copy dan)
        if (productionsCopy.isNotEmpty) {
          for (final production in productionsCopy) {
            // Safe null check for date
            final productionDate = production.date ?? DateTime.now();
            final productionData = {
              'id': UuidGenerator.generateUuid(),
              'farm_id': _farm!.id,
              'tray_count': production.trayCount,
              'note': production.note,
              'record_type': 'production',
              'production_date': productionDate.toIso8601String(),
              'created_at': productionDate.toIso8601String(),
            };

            try {
              await _supabase.from('egg_productions').upsert(productionData);
            } catch (e) {
              print('⚠️ Egg production saqlashda xatolik: $e');
            }
          }
          // Silent save
        }

        // Egg sales ni saqlash (copy dan)
        if (salesCopy.isNotEmpty) {
          for (final sale in salesCopy) {
            // Safe null check for date
            final saleDate = sale.date ?? DateTime.now();
            final saleData = {
              'id': UuidGenerator.generateUuid(),
              'farm_id': _farm!.id,
              'tray_count': sale.trayCount,
              'price_per_tray': sale.pricePerTray,
              'note': sale.note,
              'record_type': 'sale',
              'production_date': saleDate.toIso8601String(),
              'created_at': saleDate.toIso8601String(),
            };

            try {
              await _supabase.from('egg_productions').upsert(saleData);
            } catch (e) {
              print('⚠️ Egg sale saqlashda xatolik: $e');
            }
          }
          // Silent save
        }

        // Customers ni saqlash
        if (_farm!.customers.isNotEmpty) {
          for (final customer in _farm!.customers) {
            final customerData = {
              'id': customer.id,
              'farm_id': _farm!.id,
              'name': customer.name,
              'phone': customer.phone,
              'address': customer.address,
              'total_debt': customer.totalDebt,
              'updated_at': DateTime.now().toIso8601String(),
            };

            await _supabase.from('customers').upsert(customerData);

            // Orders ni saqlash
            if (customer.orders.isNotEmpty) {
              for (final order in customer.orders) {
                // Safe null check for dates
                final deliveryDate = order.deliveryDate ?? DateTime.now();
                final orderData = {
                  'id': order.id,
                  'customer_id': customer.id,
                  'farm_id': _farm!.id,
                  'tray_count': order.trayCount,
                  'price_per_tray': order.pricePerTray,
                  'total_amount': order.totalAmount,
                  'delivery_date': deliveryDate.toIso8601String(),
                  'is_paid': order.isPaid,
                  'paid_at': order.paidAt?.toIso8601String(),
                  'notes': order.note,
                };

                await _supabase.from('orders').upsert(orderData);
              }
            }
          }
          // Silent customer save
        }

        // Muvaffaqiyatli sync
        await _storage.markDataAsSynced(_farm!.id);
        // Silent sync completion
        return;

      } catch (e) {
        print('⚠️ Supabase sync urinishi #$attempt muvaffaqiyatsiz: $e');

        if (attempt == maxRetries) {
          print('❌ Barcha sync urinishlari muvaffaqiyatsiz, offline rejimga o\'tish');
          _isOfflineMode = true;
          _error = null; // Don't show error for offline mode

          // Activity log qo'shish
          await _addActivityLog('Sync xatosi',
            'Internet bilan aloqa yo\'q, offline rejimda davom etilmoqda');

          rethrow;
        }

        // Keyingi urinishdan oldin biroz kutish
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
  }

  Future<void> _saveToSupabase() async {
    await _syncToSupabaseWithRetry();
  }

  // ACTIVITY LOG QO'SHISH (improved with better formatting)
  Future<void> _addActivityLog(String title, String description, {String? activityType, String? importance}) async {
    try {
      if (_farm == null) return;

      // Auto-generate better descriptions with timestamps
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final dateStr = '${now.day}/${now.month}/${now.year}';

      final enhancedTitle = title.contains('⏰') ? title : '⏰ $timeStr - $title';
      final enhancedDescription = '$description\n📅 $dateStr da amalga oshirildi';

      // ActivityLogService import qilmasdan to'g'ridan-to'g'ri activity log qo'shamiz
      final activityId = UuidGenerator.generateUuid();

      final activityData = {
        'farm_id': _farm!.id,
        'type': activityType ?? _determineActivityType(title),
        'title': enhancedTitle,
        'description': enhancedDescription,
        'metadata': {
          'timestamp': now.toIso8601String(),
          'farm_name': _farm!.name,
          'auto_generated': true,
        },
        'importance': importance ?? _determineImportance(title, description),
        'created_at': now.toIso8601String(),
      };

      // Hive ga saqlash (ID yaratib)
      final hiveActivityData = {
        'id': activityId,
        ...activityData,
      };

      if (!Hive.isBoxOpen('activity_logs')) {
        await Hive.openBox<Map>('activity_logs');
      }
      final activityBox = Hive.box<Map>('activity_logs');
      await activityBox.put(activityId, hiveActivityData);

      // OPTIMIZED: Auto-clean old logs only when really needed (keep last 75, clean when > 100)
      if (activityBox.length > 100) {
        final keys = activityBox.keys.toList();
        final oldKeys = keys.take(keys.length - 75); // Keep more logs, clean less frequently
        for (final key in oldKeys) {
          await activityBox.delete(key);
        }
      print('🧹 ${oldKeys.length} eski activity log tozalandi (${activityBox.length} qoldi)');
      }

      // NOTIFY activity log widgets to refresh
      if (onActivityLogUpdated != null) {
        onActivityLogUpdated!();
      }

      // Supabase ga ham saqlash (offline bo'lmasa)
      if (!_isOfflineMode) {
        try {
          // Avval Farm Supabase da mavjudligini tekshirish
          final farmExists = await _supabase
              .from('farms')
              .select('id')
              .eq('id', _farm!.id)
              .maybeSingle();

          if (farmExists != null) {
            await _supabase.from('activity_logs').insert(activityData);
            print('✅ Activity log Supabase ga saqlandi');
          } else {
            print('⚠️ Farm Supabase da topilmadi, activity log faqat lokal saqlandi');
          }
        } catch (e) {
          // Activity log Supabase ga saqlanmasa ham davom etamiz
          print('Activity log Supabase ga saqlanmadi: $e');
        }
      }

    } catch (e) {
      print('Activity log qo\'shishda xatolik: $e');
      // Activity log xatosi asosiy jarayonni to'xtatmasligi kerak
    }
  }

  // Activity type ni aniqlash
  String _determineActivityType(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('tuxum') && titleLower.contains('ishlab chiqar')) return 'eggProduction';
    if (titleLower.contains('tuxum') && titleLower.contains('sotildi')) return 'eggSale';
    if (titleLower.contains('tovuq') && titleLower.contains('qo\'shildi')) return 'chickenAdded';
    if (titleLower.contains('tovuq') && titleLower.contains('o\'ldi')) return 'chickenDeath';
    if (titleLower.contains('mijoz') || titleLower.contains('customer')) return 'customerAdded';
    if (titleLower.contains('qarz') || titleLower.contains('debt')) return 'debtAdded';
    if (titleLower.contains('siniq')) return 'brokenEggs';
    if (titleLower.contains('katta')) return 'largeEggs';
    return 'other';
  }

  // Muhimlik darajasini aniqlash
  String _determineImportance(String title, String description) {
    final combined = '${title.toLowerCase()} ${description.toLowerCase()}';
    if (combined.contains('xatolik') || combined.contains('error') || combined.contains('o\'ldi')) return 'high';
    if (combined.contains('kritik') || combined.contains('critical')) return 'critical';
    if (combined.contains('muhim') || combined.contains('important')) return 'high';
    return 'normal';
  }

  Future<void> _saveToHive() async {
    if (_farm == null) return;
    await _storage.saveFarmOffline(_farm!);
  }

  Future<void> _loadFromHive() async {
    try {
      final savedFarm = await _storage.loadFarmOffline(_farm?.id ?? '');
      if (savedFarm != null) {
        _farm = _ensureFarmObjectsInitialized(savedFarm);
        print('💾 Farm offline dan yuklandi: ${_farm?.name}');
        notifyListeners();
      }
    } catch (e) {
      print('Offline ma\'lumotlarni yuklashda xatolik: $e');
    }
  }

  // -----------------------------
  // REFRESH VA CACHE CLEAR
  // -----------------------------
  Future<void> refreshData() async {
    if (_farm == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Removed: repetitive log

      // Force refresh from Supabase
      await _refreshFarmData();

      // Restart realtime if needed
      if (!_isOfflineMode) {
        await startRealtime();
      }

      // Silent refresh
    } catch (e) {
      print('❌ Ma\'lumotlarni yangilashda xatolik: $e');
      _error = 'Ma\'lumotlarni yangilashda xatolik: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCacheAndRefresh() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🧹 Cache tozalanmoqda...');

      // Clear Hive boxes
      await _storage.clearAllData();

      // Force refresh from Supabase
      await _refreshFarmData();

      // Restart realtime
      if (!_isOfflineMode) {
        await startRealtime();
      }

      print('✅ Cache tozalandi va ma\'lumotlar yangilandi!');
    } catch (e) {
      print('❌ Cache tozalashda xatolik: $e');
      _error = 'Cache tozalashda xatolik: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -----------------------------
  // Misc
  // -----------------------------
  void setOfflineMode(bool offline) {
    _isOfflineMode = offline;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopRealtime();
    _notifyTimer?.cancel(); // Clean up debounce timer
    _persistTimer?.cancel(); // Clean up persist timer
    // Save any pending changes before disposing
    if (_hasPendingChanges) {
      _persist();
    }
    super.dispose();
  }
}
