import 'package:ferma_app/screens/main/main_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/farm.dart';
import '../models/customer.dart';
import '../models/chicken.dart';
import '../models/egg.dart';
import '../screens/main/main_screen.dart';
import '../services/storage_service.dart';
import '../config/supabase_config.dart';
import '../utils/uuid_generator.dart';

class FarmProvider with ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final StorageService _storage = StorageService();

  // Auth-aware Supabase executor: retries once on JWT expiry (PGRST303)
  Future<T> _executeWithAuthRetry<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      final msg = e.message?.toString() ?? '';
      if (e.code == 'PGRST303' || msg.contains('JWT expired')) {
        try {
          await _supabase.auth.refreshSession();
        } catch (_) {}
        return await action();
      }
      rethrow;
    }
  }

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

  // Avoid redundant Supabase writes: keep last synced signatures
  String? _lastEggSignature;
  String? _lastCustomersSignature;

  // REALTIME UPDATE THROTTLING
  DateTime? _lastRealtimeUpdate;
  static const Duration _realtimeThrottle = Duration(seconds: 5);

  // CUSTOMER UPDATE TRACKING
  DateTime? _lastCustomerUpdate;
  static const Duration _customerUpdateThrottle = Duration(seconds: 2);

  // Realtime subscriptions
  StreamSubscription<List<Map<String, dynamic>>>? _farmStreamSub;
  StreamSubscription<List<Map<String, dynamic>>>? _customersStreamSub;
  StreamSubscription<List<Map<String, dynamic>>>? _eggRecordsStreamSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivityStreamSub;

  // Realtime update control
  Timer? _realtimeDebounceTimer;
  bool _isProcessingRealtimeUpdate = false;

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
        _notifyListenersImmediate();
        await _persist();
        _hasPendingChanges = false;
      }
    });
  }

  // Force immediate persist for critical operations
  Future<void> _persistImmediate() async {
    _persistTimer?.cancel();
    _hasPendingChanges = false;
    _notifyListenersImmediate();
    await _persist();
  }

  // Fast path: persist only to local Hive, and return immediately
  Future<void> _persistLocalImmediate() async {
    _persistTimer?.cancel();
    _hasPendingChanges = false;
    _notifyListenersImmediate();
    try {
      await _saveToHive();
    } catch (_) {}
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
      // If server didn't send chicken, preserve previous local chicken if exists
      if (_farm?.chicken != null) {
        chicken = _farm!.chicken;
      } else {
        // Fallback: create new chicken using chickenCount if available
        chicken = Chicken(
          id: farm.id,
          totalCount: farm.chickenCount > 0 ? farm.chickenCount : 0,
          deaths: [],
        );
      }
      needsUpdate = true;
    } else {
      // Sync chickenCount with actual chicken data
      if (farm.chickenCount != chicken.totalCount && farm.chickenCount > 0) {
        chicken = chicken.copyWith(totalCount: farm.chickenCount);
        needsUpdate = true;
      }
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
      final productions = await _executeWithAuthRetry(() async {
        return await _supabase
            .from('egg_productions')
            .select()
            .eq('farm_id', farmId)
            .order('production_date', ascending: false)
            .limit(30);
      }); // Reduced limit to save memory

      if (productions.isNotEmpty) {
        // MEMORY OPTIMIZATION: Only clear if we have new data
        final Set<String> existingIds =
            _farm?.egg?.production.map((p) => p.id).toSet() ?? {};
        final bool hasNewData = productions.any(
          (record) => !existingIds.contains(record['id'] as String? ?? ''),
        );

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
          final dateStr =
              record['created_at'] as String? ??
              record['production_date'] as String?;
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
              _farm!.egg!.production.add(
                EggProduction(
                  id: recordId.isNotEmpty
                      ? recordId
                      : UuidGenerator.generateUuid(),
                  trayCount: trayCount,
                  date: recordDate,
                  note: note,
                ),
              );
              break;
            case 'sale':
              final pricePerTray =
                  (record['price_per_tray'] as num?)?.toDouble() ?? 0.0;
              _farm!.egg!.sales.add(
                EggSale(
                  id: recordId.isNotEmpty
                      ? recordId
                      : UuidGenerator.generateUuid(),
                  trayCount: trayCount,
                  pricePerTray: pricePerTray,
                  date: recordDate,
                  note: note,
                ),
              );
              break;
          }
        }

        // PERFORMANCE: Only print if stock changed significantly
        final currentStock = _farm?.egg?.currentStock ?? 0;
        if (currentStock % 100 == 0 || currentStock < 100) {
          // Only log round numbers or low stock
          print('🥚 Egg zaxira: $currentStock fletka');
        }
      }
    } catch (e) {
      print('⚠️ Supabase egg ma\'lumot xatolik: $e');
    } finally {
      _isLoadingEggData = false;
    }
  }

  // Load chicken counts and deaths from Supabase if available
  Future<void> _loadChickenFromSupabase(String farmId) async {
    try {
      // 1) Try to read chickens row
      final rows = await _executeWithAuthRetry(() async {
        return await _supabase
            .from('chickens')
            .select()
            .eq('farm_id', farmId)
            .limit(1);
      });

      Chicken? chicken = _farm?.chicken;
      if (rows.isNotEmpty) {
        final row = rows.first;
        final total =
            (row['total_count'] as num?)?.toInt() ?? chicken?.totalCount ?? 0;
        // Build or update chicken object
        chicken = Chicken(
          id: farmId,
          totalCount: total,
          deaths: chicken?.deaths ?? [],
        );
      }

      // 2) Load deaths timeline (optional table)
      try {
        final deathsRows = await _executeWithAuthRetry(() async {
          return await _supabase
              .from('chicken_deaths')
              .select()
              .eq('farm_id', farmId)
              .order('death_date', ascending: true);
        });

        if (deathsRows.isNotEmpty) {
          final List<ChickenDeath> loadedDeaths = deathsRows.map<ChickenDeath>((
            row,
          ) {
            final cnt = (row['death_count'] as num?)?.toInt() ?? 0;
            final dateStr = row['death_date'] as String?;
            final date = dateStr != null
                ? DateTime.parse(dateStr)
                : DateTime.now();
            return ChickenDeath(
              id: row['id'] as String? ?? UuidGenerator.generateUuid(),
              count: cnt,
              date: date,
              note: row['cause'] as String? ?? row['notes'] as String?,
            );
          }).toList();

          if (chicken != null) {
            chicken = chicken.copyWith(deaths: loadedDeaths);
          }
        }
      } catch (_) {
        // Table may not exist; ignore
      }

      if (chicken != null) {
        // Preserve in farm and sync chickenCount
        _farm = _farm!.copyWith(
          chicken: chicken,
          chickenCount: chicken.totalCount,
        );
      }
    } catch (_) {
      // Ignore; app can run with local chicken data
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
      final activities = activityBox.values
          .where(
            (activity) =>
                activity is Map &&
                activity['farm_id'] == farmId &&
                activity['type'] == 'eggProduction',
          )
          .toList();

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
    _connectivityStreamSub = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      final isConnected = results.any(
        (result) => result != ConnectivityResult.none,
      );

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
                      now.difference(_lastRealtimeUpdate!) <
                          _realtimeThrottle) {
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
                print(
                  '⚠️ Realtime farm ma\'lumotini parse qilishda xatolik: $e',
                );
              }
            }
          });

      // Customers stream with throttling
      _customersStreamSub = _supabase
          .from('customers')
          .stream(primaryKey: ['id'])
          .eq('farm_id', _farm!.id)
          .listen((rows) async {
            // THROTTLE: Skip if customer update is too frequent
            final now = DateTime.now();
            if (_lastCustomerUpdate != null &&
                now.difference(_lastCustomerUpdate!) <
                    _customerUpdateThrottle) {
              return;
            }
            _lastCustomerUpdate = now;

            print(
              '👥 Customer realtime update received: ${rows.length} customers',
            );
            await _refreshCustomersFromSupabase();
            _notifyListenersDebounced();
          });

      // Egg records stream with better throttling
      _eggRecordsStreamSub = _supabase
          .from('egg_productions')
          .stream(primaryKey: ['id'])
          .eq('farm_id', _farm!.id)
          .listen((rows) async {
            if (_farm != null &&
                _farm!.egg != null &&
                !_isProcessingRealtimeUpdate) {
              _isProcessingRealtimeUpdate = true;

              // Debounce rapid updates
              _realtimeDebounceTimer?.cancel();
              _realtimeDebounceTimer = Timer(
                const Duration(milliseconds: 1000),
                () async {
                  try {
                    await _processEggRecords(rows);
                    await _saveToHive();
                    _notifyListenersDebounced();
                  } finally {
                    _isProcessingRealtimeUpdate = false;
                  }
                },
              );
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
    _realtimeDebounceTimer?.cancel();
    _farmStreamSub = null;
    _customersStreamSub = null;
    _eggRecordsStreamSub = null;
    _connectivityStreamSub = null;
    _isProcessingRealtimeUpdate = false;
  }

  // Refresh only customers data from Supabase
  Future<void> _refreshCustomersData() async {
    if (_farm == null) return;

    try {
      // Load customers for this farm
      final customersResponse = await _supabase
          .from('customers')
          .select('*, orders(*)')
          .eq('farm_id', _farm!.id);

      if (customersResponse.isNotEmpty) {
        // Clear existing customers and reload
        _farm!.customers.clear();

        for (final customerData in customersResponse) {
          final customer = Customer.fromJson(customerData);
          _farm!.customers.add(customer);
        }

        print(
          '👥 Customers refreshed: ${_farm!.customers.length} customers loaded',
        );
        await _saveToHive();
        _notifyListenersDebounced();
      }
    } catch (e) {
      print('⚠️ Error refreshing customers: $e');
    }
  }

  // -----------------------------
  // Supabase dan farmni yangilash
  // -----------------------------
  Future<void> _refreshFarmData() async {
    if (_farm == null) return;
    try {
      // Internet bor yoki yo'qligini tekshirish
      final response = await _executeWithAuthRetry(() async {
        return await _supabase
            .from('farms')
            .select()
            .eq('id', _farm!.id)
            .maybeSingle();
      });

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

          // Load egg productions from Supabase - authoritative refresh to avoid drift
          await _reloadEggsAuthoritative(_farm!.id);

          // Load chickens from Supabase (counts and deaths)
          await _loadChickenFromSupabase(_farm!.id);

          // Load customers from Supabase
          await _refreshCustomersFromSupabase();

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

  // Authoritative eggs reload used on manual refresh to prevent double counting
  Future<void> _reloadEggsAuthoritative(String farmId) async {
    if (_farm == null) return;
    // Ensure egg object exists
    if (_farm!.egg == null) {
      _farm = _farm!.copyWith(egg: Egg(id: farmId));
    }

    try {
      final rows = await _executeWithAuthRetry(() async {
        return await _supabase
            .from('egg_productions')
            .select()
            .eq('farm_id', farmId)
            .order('production_date', ascending: true)
            .limit(1000);
      }); // hard cap to avoid memory blowups

      // Reset lists to avoid duplicates
      _farm!.egg!.production.clear();
      _farm!.egg!.sales.clear();
      _farm!.egg!.brokenEggs.clear();
      _farm!.egg!.largeEggs.clear();

      for (final record in rows) {
        final type = record['record_type'] as String? ?? 'production';
        final trayCount = (record['tray_count'] as num?)?.toInt() ?? 0;
        if (trayCount <= 0) continue;
        final pricePerTray =
            (record['price_per_tray'] as num?)?.toDouble() ?? 0.0;
        final id = record['id'] as String? ?? UuidGenerator.generateUuid();
        final dateStr =
            record['production_date'] as String? ??
            record['created_at'] as String?;
        DateTime date;
        try {
          date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
        } catch (_) {
          date = DateTime.now();
        }
        switch (type) {
          case 'production':
            _farm!.egg!.production.add(
              EggProduction(
                id: id,
                trayCount: trayCount,
                date: date,
                note: record['note'] as String?,
              ),
            );
            break;
          case 'sale':
            _farm!.egg!.sales.add(
              EggSale(
                id: id,
                trayCount: trayCount,
                pricePerTray: pricePerTray,
                date: date,
                note: record['note'] as String?,
              ),
            );
            break;
          case 'broken':
            _farm!.egg!.brokenEggs.add(
              BrokenEgg(
                id: id,
                trayCount: trayCount,
                date: date,
                note: record['note'] as String?,
              ),
            );
            break;
          case 'large':
            _farm!.egg!.largeEggs.add(
              LargeEgg(
                id: id,
                trayCount: trayCount,
                date: date,
                note: record['note'] as String?,
              ),
            );
            break;
          default:
            _farm!.egg!.production.add(
              EggProduction(
                id: id,
                trayCount: trayCount,
                date: date,
                note: record['note'] as String?,
              ),
            );
        }
      }

      // Deduplicate by ID to be safe
      _farm!.egg!.production
        ..clear()
        ..addAll({for (final p in _farm!.egg!.production) p.id: p}.values);
      _farm!.egg!.sales
        ..clear()
        ..addAll({for (final s in _farm!.egg!.sales) s.id: s}.values);
      _farm!.egg!.brokenEggs
        ..clear()
        ..addAll({for (final b in _farm!.egg!.brokenEggs) b.id: b}.values);
      _farm!.egg!.largeEggs
        ..clear()
        ..addAll({for (final l in _farm!.egg!.largeEggs) l.id: l}.values);

      _pendingLocalProductionIds.clear();
    } catch (e) {
      print('⚠️ _reloadEggsAuthoritative xatolik: $e');
      // Fallback to incremental loader
      await _loadEggDataFromSupabase(farmId);
    }
  }

  // Refresh customers from Supabase separately
  Future<void> _refreshCustomersFromSupabase() async {
    if (_farm == null) return;

    try {
      // Load customers with nested orders to preserve debts
      final customersData = await _executeWithAuthRetry(() async {
        return await _supabase
            .from('customers')
            .select('*, orders(*)')
            .eq('farm_id', _farm!.id);
      });

      if (customersData.isNotEmpty) {
        print('📥 Loading ${customersData.length} customers from Supabase');

        // Create a new list instead of modifying the existing one during iteration
        final newCustomers = <Customer>[];

        for (final customerData in customersData) {
          try {
            final customer = Customer.fromJson(customerData);
            newCustomers.add(customer);
          } catch (e) {
            print('⚠️ Customer parsing error: $e');
          }
        }

        // Replace the entire customers list atomically (includes debts)
        _farm!.customers.clear();
        _farm!.customers.addAll(newCustomers);

        print('✅ Loaded ${_farm!.customers.length} customers successfully');
      }
    } catch (e) {
      print('⚠️ Error loading customers from Supabase: $e');
    }
  }

  // Egg recordsni qayta ishlash (Authoritative sync from server)
  Future<void> _processEggRecords(List<Map<String, dynamic>> records) async {
    if (_farm?.egg == null) return;

    try {
      // Prepare new authoritative lists from server data
      final List<EggProduction> newProductions = [];
      final List<EggSale> newSales = [];
      final List<BrokenEgg> newBroken = [];
      final List<LargeEgg> newLarge = [];

      for (final record in records) {
        try {
          // Extract record ID for duplicate prevention
          final recordId = record['id'] as String? ?? '';

          // Safely extract data with null checks
          final trayCount = (record['tray_count'] as num?)?.toInt() ?? 0;
          final pricePerTray =
              (record['price_per_tray'] as num?)?.toDouble() ?? 0.0;
          final note = record['note'] as String?;
          final type = record['record_type'] as String? ?? 'production';
          final createdAt = record['created_at'] as String?;
          final productionDateStr = record['production_date'] as String?;
          DateTime recordDate;
          try {
            if (productionDateStr != null) {
              recordDate = DateTime.parse(productionDateStr);
            } else if (createdAt != null) {
              recordDate = DateTime.parse(createdAt);
            } else {
              recordDate = DateTime.now();
            }
          } catch (_) {
            recordDate = DateTime.now();
          }

          // Skip empty records
          if (trayCount <= 0) continue;
          // Build authoritative lists
          switch (type) {
            case 'production':
              newProductions.add(
                EggProduction(
                  id: recordId.isNotEmpty
                      ? recordId
                      : UuidGenerator.generateUuid(),
                  trayCount: trayCount,
                  date: recordDate,
                  note: note,
                ),
              );
              break;
            case 'sale':
              newSales.add(
                EggSale(
                  id: recordId.isNotEmpty
                      ? recordId
                      : UuidGenerator.generateUuid(),
                  trayCount: trayCount,
                  pricePerTray: pricePerTray,
                  date: recordDate,
                  note: note,
                ),
              );
              break;
            case 'broken':
              newBroken.add(
                BrokenEgg(
                  id: recordId.isNotEmpty
                      ? recordId
                      : UuidGenerator.generateUuid(),
                  trayCount: trayCount,
                  date: recordDate,
                  note: note,
                ),
              );
              break;
            case 'large':
              newLarge.add(
                LargeEgg(
                  id: recordId.isNotEmpty
                      ? recordId
                      : UuidGenerator.generateUuid(),
                  trayCount: trayCount,
                  date: recordDate,
                  note: note,
                ),
              );
              break;
            default:
              newProductions.add(
                EggProduction(
                  id: recordId.isNotEmpty
                      ? recordId
                      : UuidGenerator.generateUuid(),
                  trayCount: trayCount,
                  date: recordDate,
                  note: note,
                ),
              );
              break;
          }

          // Mark this record as processed
          if (recordId.isNotEmpty) {
            _processedRecordIds.add(recordId);
            if (_processedRecordIds.length > 2000) {
              final oldIds = _processedRecordIds
                  .take(_processedRecordIds.length - 1500)
                  .toList();
              _processedRecordIds.removeAll(oldIds);
            }
          }
        } catch (recordError) {
          print('⚠️ Bitta egg record qayta ishlashda xatolik: $recordError');
          print('⚠️ Record ma\'lumoti: $record');
        }
      }

      // Merge optimistic pending local productions not yet visible on server
      try {
        if (_farm?.egg != null && _pendingLocalProductionIds.isNotEmpty) {
          final serverProdIds = newProductions.map((e) => e.id).toSet();

          // If server already has some of the pending IDs, clear them from pending set
          final confirmedIds = _pendingLocalProductionIds.intersection(
            serverProdIds,
          );
          if (confirmedIds.isNotEmpty) {
            _pendingLocalProductionIds.removeAll(confirmedIds);
          }

          // Add remaining pending productions to snapshot so UI doesn't jump back
          final remainingPending = _pendingLocalProductionIds.difference(
            serverProdIds,
          );
          if (remainingPending.isNotEmpty) {
            final localById = {for (final p in _farm!.egg!.production) p.id: p};
            for (final pid in remainingPending) {
              final p = localById[pid];
              if (p != null) {
                newProductions.add(
                  EggProduction(
                    id: p.id,
                    trayCount: p.trayCount,
                    date: p.date,
                    note: p.note,
                  ),
                );
              }
            }
          }
        }
      } catch (e) {
        print('⚠️ Pending merge xatosi: $e');
      }

      // Upsert-merge with existing lists (realtime may send partial batches)
      if (_farm?.egg != null) {
        // Production merge
        final prodById = {for (final p in _farm!.egg!.production) p.id: p};
        for (final p in newProductions) {
          final exist = prodById[p.id];
          if (exist == null) {
            _farm!.egg!.production.add(p);
          } else {
            exist.trayCount = p.trayCount;
            exist.date = p.date;
            exist.note = p.note;
          }
        }

        // Sales merge
        final saleById = {for (final s in _farm!.egg!.sales) s.id: s};
        for (final s in newSales) {
          final exist = saleById[s.id];
          if (exist == null) {
            _farm!.egg!.sales.add(s);
          } else {
            exist.trayCount = s.trayCount;
            exist.pricePerTray = s.pricePerTray;
            exist.date = s.date;
            exist.note = s.note;
          }
        }

        // Broken merge
        final brokenById = {for (final b in _farm!.egg!.brokenEggs) b.id: b};
        for (final b in newBroken) {
          final exist = brokenById[b.id];
          if (exist == null) {
            _farm!.egg!.brokenEggs.add(b);
          } else {
            exist.trayCount = b.trayCount;
            exist.date = b.date;
            exist.note = b.note;
          }
        }

        // Large merge
        final largeById = {for (final l in _farm!.egg!.largeEggs) l.id: l};
        for (final l in newLarge) {
          final exist = largeById[l.id];
          if (exist == null) {
            _farm!.egg!.largeEggs.add(l);
          } else {
            exist.trayCount = l.trayCount;
            exist.date = l.date;
            exist.note = l.note;
          }
        }

        // Reduced verbose logging to keep UI snappy
      }
    } catch (e) {
      print('❌ _processEggRecords da umumiy xatolik: $e');
    }
  }

  // -----------------------------
  // Farm actions
  // -----------------------------
  Future<bool> addChickens(int count) async {
    if (_farm == null) {
      _error = 'Ferma ma\'lumotlari topilmadi';
      return false;
    }

    if (count <= 0) {
      _error = 'Tovuqlar soni 0 dan katta bo\'lishi kerak';
      return false;
    }

    try {
      print('🐔 Tovuqlar qo\'shilmoqda: $count dona');

      // Get counts before adding
      final beforeCount = _farm!.chicken?.currentCount ?? 0;
      final beforeTotal = _farm!.chickenCount;

      // Add chickens to farm
      _farm!.addChickens(count);

      // Verify addition
      final afterCount = _farm!.chicken?.currentCount ?? 0;
      final afterTotal = _farm!.chickenCount;

      print('📊 Tovuqlar statistikasi:');
      print('  Avval: $beforeCount ($beforeTotal total)');
      print('  Keyin: $afterCount ($afterTotal total)');

      // Force immediate UI update
      _notifyListenersImmediate();

      await _addActivityLog(
        'Tovuqlar qo\'shildi',
        '$count dona tovuq qo\'shildi. Jami: $afterCount dona',
        activityType: 'chickenAdded',
        importance: 'high',
      );

      // Use immediate persist for critical data
      await _persistImmediate();

      // Save snapshot to Supabase chickens table if available
      try {
        await _supabase.from('chickens').upsert({
          'farm_id': _farm!.id,
          'total_count': _farm!.chicken?.totalCount ?? _farm!.chickenCount,
          'current_count': _farm!.chicken?.currentCount ?? _farm!.chickenCount,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      print('✅ Tovuqlar muvaffaqiyatli qo\'shildi');
      return true;
    } catch (e) {
      print('❌ Tovuqlar qo\'shishda xatolik: $e');
      _error = 'Tovuqlar qo\'shishda xatolik: $e';
      await _addActivityLog('Xatolik', 'Tovuq qo\'shishda xatolik: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> addChickenDeath(int count, {String? note}) async {
    if (_farm == null) return false;
    try {
      _farm!.addChickenDeath(count, note: note);
      await _addActivityLog(
        'Tovuq o\'limi',
        '$count dona tovuq o\'ldi. Qolgan: ${_farm!.chicken?.currentCount ?? 0}${note != null && note.isNotEmpty ? '. Izoh: ' + note : ''}',
      );
      await _persist();

      // Persist death to Supabase if table exists
      try {
        await _supabase.from('chicken_deaths').insert({
          'farm_id': _farm!.id,
          'death_count': count,
          'death_date': DateTime.now().toIso8601String(),
          'notes': note,
          'created_at': DateTime.now().toIso8601String(),
        });
        await _supabase.from('chickens').upsert({
          'farm_id': _farm!.id,
          'total_count': _farm!.chicken?.totalCount ?? _farm!.chickenCount,
          'current_count': _farm!.chicken?.currentCount ?? _farm!.chickenCount,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
      return true;
    } catch (e) {
      _error = 'Tovuq o\'limini qo\'shishda xatolik: $e';
      await _addActivityLog(
        'Xatolik',
        'Tovuq o\'limini qo\'shishda xatolik: $e',
      );
      return false;
    }
  }

  // DUPLICATE PREVENTION: Track pending operations and processed records
  final Set<String> _pendingOperations = {};
  final Set<String> _processedRecordIds = {};
  // Optimistic UI: pending local productions not yet confirmed by server
  final Set<String> _pendingLocalProductionIds = {};

  Future<bool> addEggProduction(int trays, {String? note}) async {
    if (_farm == null) {
      print('❌ Farm null, tuxum qo\'shib bo\'lmaydi');
      return false;
    }

    // DUPLICATE PREVENTION: Create unique operation ID based on content and timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final operationId = 'egg_prod_${timestamp}_${trays}_${note?.hashCode ?? 0}';

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

      // Store current stock before adding
      final stockBefore = _farm!.egg?.currentStock ?? 0;

      // Generate a stable ID for this local record so we can track it
      final newId = UuidGenerator.generateUuid();
      final now = DateTime.now();

      // Add to local data ONCE with the chosen ID (optimistic)
      _farm!.egg!.addProductionWithId(newId, trays, now, note: note);
      _pendingLocalProductionIds.add(newId);
      final currentStock = _farm!.egg?.currentStock ?? 0;

      // Verify the addition was successful and not duplicated
      final expectedStock = stockBefore + trays;
      if (currentStock != expectedStock) {
        print(
          '⚠️ Stock mismatch detected. Expected: $expectedStock, Actual: $currentStock',
        );
        // Don't throw error, just log the discrepancy
      }

      print('✅ Tuxum qo\'shildi. Yangi zaxira: $currentStock fletka');

      // IMPORTANT: Update UI immediately
      _notifyListenersImmediate();

      // Add activity log immediately (not async)
      await _addActivityLog(
        '⏰ ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} - Tuxum ishlab chiqarildi',
        '$trays fletka tuxum ishlab chiqarildi. Jami zaxira: $currentStock fletka${note != null ? '. Izoh: $note' : ''}',
      );

      // FAST: local persist first for instant UI, then background sync
      await _persistLocalImmediate();
      unawaited(_saveToSupabase());

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
    final backupEgg = _farm!.egg != null
        ? Egg(
            id: _farm!.egg!.id,
            production: List.from(_farm!.egg!.production),
            sales: List.from(_farm!.egg!.sales),
            brokenEggs: List.from(_farm!.egg!.brokenEggs),
            largeEggs: List.from(_farm!.egg!.largeEggs),
          )
        : null;

    try {
      // Make changes to local data
      _farm!.addEggSale(trays, pricePerTray, note: note);
      final totalAmount = trays * pricePerTray;
      final remainingStock = _farm!.egg?.currentStock ?? 0;

      // Update UI immediately
      _notifyListenersImmediate();

      // Try to save data with rollback on failure
      try {
        await _addActivityLog(
          'Tuxum sotildi',
          '$trays fletka tuxum ${totalAmount.toStringAsFixed(0)} so\'mga sotildi. Qolgan: $remainingStock fletka${note != null ? '. Izoh: $note' : ''}',
        );
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
      _notifyListenersImmediate();
      await _persistImmediate();
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
      _notifyListenersImmediate();
      await _persistImmediate();
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
    if (_farm == null) {
      print('❌ addCustomer: Farm null');
      return false;
    }

    try {
      print('📝 addCustomer: Boshlandi - $name | $phone | $address');

      // Check for duplicate customers
      // Rule: If phone is provided, treat as duplicate ONLY when BOTH name and phone match.
      // This allows multiple customers with same phone but different names.
      final normalizedPhone = phone?.replaceAll(RegExp(r'\s+'), '') ?? '';
      final normalizedName = name.trim().toLowerCase();
      final existingCustomer = _farm!.customers
          .where((c) => !c.name.startsWith('QARZ:'))
          .where((c) {
            final sameName = c.name.trim().toLowerCase() == normalizedName;
            if (normalizedPhone.isNotEmpty) {
              final customerPhone = c.phone.replaceAll(RegExp(r'\s+'), '');
              return sameName && customerPhone == normalizedPhone;
            }
            return sameName;
          })
          .firstOrNull;

      if (existingCustomer != null) {
        print(
          '🔍 Mijoz allaqachon mavjud: ${existingCustomer.name} (${existingCustomer.id})',
        );
        print(
          '📊 Hozirgi mijozlar soni: ${_farm!.customers.where((c) => !c.name.startsWith('QARZ:')).length}',
        );
        // Update existing customer info instead of creating duplicate
        existingCustomer.name = name.trim();
        existingCustomer.phone = phone?.trim() ?? '';
        existingCustomer.address = address?.trim() ?? '';
        existingCustomer.updatedAt = DateTime.now();

        // Immediate UI update
        _notifyListenersImmediate();

        await _addActivityLog(
          'Mijoz yangilandi',
          'Mijoz ma\'lumotlari yangilandi: $name${phone != null ? ' ($phone)' : ''}${address != null ? ', $address' : ''}',
        );

        // Use immediate persist for critical customer data
        await _persistImmediate();

        print(
          '✅ Mijoz ma\'lumotlari yangilandi. Mijozlar soni: ${_farm!.customers.where((c) => !c.name.startsWith('QARZ:')).length}',
        );
        return true;
      }

      // Add new customer
      print(
        '📊 Mijozlar soni qo\'shishdan oldin: ${_farm!.customers.where((c) => !c.name.startsWith('QARZ:')).length}',
      );
      _farm!.addCustomer(name, phone: phone, address: address);
      print('✅ addCustomer: Mijoz qo\'shildi');
      print(
        '📊 Mijozlar soni qo\'shishdan keyin: ${_farm!.customers.where((c) => !c.name.startsWith('QARZ:')).length}',
      );

      // Immediate UI update
      _notifyListenersImmediate();

      await _addActivityLog(
        'Yangi mijoz',
        'Mijoz qo\'shildi: $name${phone != null ? ' ($phone)' : ''}${address != null ? ', $address' : ''}',
      );

      // Use immediate persist for critical customer data
      await _persistImmediate();

      print('✅ addCustomer: Muvaffaqiyatli yakunlandi');
      return true;
    } catch (e) {
      print('❌ addCustomer: Xatolik - $e');
      _error = 'Mijoz qo\'shishda xatolik: $e';
      await _addActivityLog('Xatolik', 'Mijoz qo\'shishda xatolik: $e');
      notifyListeners();
      return false;
    }
  }

  // Create customer and return its ID immediately (no duplicate update logic)
  Future<String?> _addCustomerAndGetId(
    String name, {
    String? phone,
    String? address,
  }) async {
    if (_farm == null) return null;
    try {
      _farm!.addCustomer(name, phone: phone, address: address);
      _notifyListenersImmediate();
      await _persistImmediate();
      return _farm!.customers.last.id;
    } catch (_) {
      return null;
    }
  }

  Future<bool> removeCustomer(String customerId) async {
    if (_farm == null) return false;
    try {
      // First remove from Supabase so realtime won't re-create it locally
      if (!_isOfflineMode) {
        try {
          await _supabase.from('orders').delete().eq('customer_id', customerId);
          await _supabase.from('customers').delete().eq('id', customerId);
        } catch (e) {
          print('⚠️ Supabase delete failed for customer $customerId: $e');
        }
      }

      _farm!.removeCustomer(customerId);
      await _persist();
      _notifyListenersImmediate();

      // Log activity for traceability
      await _addActivityLog(
        'Mijoz o\'chirildi',
        'Mijoz ID: $customerId o\'chirildi va Supabase dan ham tozalandi',
        activityType: 'customer',
        importance: 'high',
      );
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
        _error = _farm!.egg != null
            ? 'Yetarli tuxum yo\'q. Mavjud: ${_farm!.egg!.currentStock}'
            : 'Buyurtmani qo\'shishda xatolik sodir bo\'ldi';
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
        _farm!.egg!.addSale(
          -order.trayCount,
          0.0,
          note: 'Bekor qilingan buyurtma: $orderId',
        );
      }

      // Remove the order
      _farm!.removeCustomerOrder(customerId, orderId);

      // Also delete from Supabase to avoid it being re-sent via realtime
      if (!_isOfflineMode) {
        try {
          await _supabase.from('orders').delete().eq('id', orderId);
        } catch (e) {
          print('⚠️ Supabase delete failed for order $orderId: $e');
        }
      }

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

  // Qisman to'lov: buyurtma uchun ma'lum miqdorni qabul qilish
  Future<bool> payCustomerOrderAmount(
    String customerId,
    String orderId,
    double amount,
  ) async {
    if (_farm == null) {
      _error = 'Fermer xo\'jaligi topilmadi';
      return false;
    }
    if (amount <= 0) {
      _error = 'To\'lov summasi noto\'g\'ri';
      return false;
    }

    try {
      final customer = _farm!.findCustomer(customerId);
      if (customer == null) {
        _error = 'Mijoz topilmadi';
        return false;
      }
      final order = customer.orders.firstWhere(
        (o) => o.id == orderId,
        orElse: () => throw Exception('Buyurtma topilmadi'),
      );

      final total = order.totalAmount;

      if (amount >= total) {
        // To'liq yoki ortiqcha to'lov: buyurtmani to'langan deb belgilash
        _farm!.markCustomerOrderAsPaid(customerId, orderId);
      } else {
        // Qisman to'lov: manfiy "payment" yozuvi qo'shish
        _farm!.addCustomerOrder(
          customerId,
          1,
          -amount, // manfiy summa qarzni kamaytiradi
          DateTime.now(),
          note: 'PAYMENT for $orderId',
          deductFromStock: false,
        );
      }

      _notifyListenersImmediate();
      await _persistImmediate();

      // Activity log
      await _addActivityLog(
        'To\'lov',
        '${customer.name} uchun ${amount.toStringAsFixed(0)} so\'m to\'lov qabul qilindi',
        activityType: 'payment',
        importance: 'high',
      );

      return true;
    } catch (e) {
      _error = 'To\'lovni qabul qilishda xatolik: $e';
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
    if (_farm == null) {
      _error = 'Ferma ma\'lumotlari topilmadi';
      return false;
    }

    // Check if customer exists
    final customer = _farm!.findCustomer(customerId);
    if (customer == null) {
      _error = 'Mijoz topilmadi';
      return false;
    }

    // Check if enough stock is available
    final currentStock = _farm!.egg?.currentStock ?? 0;
    if (trays > currentStock) {
      _error = 'Yetarli tuxum yo\'q! Mavjud: $currentStock fletka';
      return false;
    }

    try {
      print('🐔 Mijozga tuxum sotish: ${customer.name} ga $trays fletka');

      // First reduce egg stock
      _farm!.addEggSale(trays, pricePerTray, note: note ?? 'Mijozga sotildi');

      // Add as unpaid order (debt) to customer
      final deliveryDate = DateTime.now();
      final success = _farm!.addCustomerOrder(
        customerId,
        trays,
        pricePerTray,
        deliveryDate,
        note: note ?? 'Tuxum sotildi - qarz',
      );

      if (!success) {
        _error = 'Mijozga buyurtma qo\'shishda xatolik';
        return false;
      }

      // Add activity log
      await _addActivityLog(
        'Tuxum sotildi',
        '${customer.name} ga $trays fletka tuxum sotildi. Qarz: ${(trays * pricePerTray).toStringAsFixed(0)} so\'m',
        activityType: 'eggSale',
        importance: 'high',
      );

      // Force immediate UI update and persist
      _notifyListenersImmediate();
      await _persistImmediate();
      // Reload customers to ensure dialogs see fresh orders
      try {
        await _refreshCustomersFromSupabase();
        _notifyListenersImmediate();
      } catch (_) {}

      print('✅ Mijozga tuxum sotish muvaffaqiyatli yakunlandi');
      return true;
    } catch (e) {
      print('❌ Mijozga tuxum sotishda xatolik: $e');
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

      // Check if this person already has a debt-only record (QARZ:)
      String? existingDebtorId;
      final existingDebtor = _farm!.customers
          .where(
            (c) =>
                c.phone.replaceAll(RegExp(r'\s+'), '') ==
                    customerPhone.replaceAll(RegExp(r'\s+'), '') &&
                c.name.startsWith('QARZ:'),
          )
          .firstOrNull;

      if (existingDebtor != null) {
        // Update existing debt-only customer
        existingDebtorId = existingDebtor.id;
      } else {
        // Create debt-only customer (separate from regular customers)
        _farm!.addCustomer(
          'QARZ: $customerName', // mark as debt-only
          phone: customerPhone,
          address: customerAddress.isNotEmpty ? customerAddress : null,
        );
        existingDebtorId = _farm!.customers.last.id;
      }

      // Add debt as unpaid order (stable ID so it persists correctly)
      final deliveryDate = DateTime.now();
      final added = _farm!.addCustomerOrder(
        existingDebtorId,
        1, // 1 tray to ensure totalAmount calculation works
        debtAmount, // price per tray = total debt amount
        deliveryDate,
        note:
            'MANUAL_DEBT: ${note.isNotEmpty ? note : "Qo'lda qo'shilgan qarz"}',
        deductFromStock: false,
      );
      if (!added) {
        _error = 'Qarz yozuvini qo\'shib bo\'lmadi';
        return false;
      }

      // Debug: Check the customer after adding debt
      final customer = _farm!.customers.firstWhere(
        (c) => c.id == existingDebtorId,
      );
      print(
        '🔍 Qarz qo\'shilgandan keyin mijoz: ${customer.name}, qarz: ${customer.totalDebt}',
      );

      await _persistImmediate();
      try {
        await _refreshCustomersFromSupabase();
      } catch (_) {}

      // Force UI update multiple times to ensure it refreshes
      _notifyListenersImmediate();
      await Future.delayed(const Duration(milliseconds: 100));
      _notifyListenersImmediate();
      await Future.delayed(const Duration(milliseconds: 100));
      _notifyListenersImmediate();

      print('🔄 UI yangilandi. Mijozlar soni: ${_farm!.customers.length}');
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
    // Show ONLY normal customers. Exclude all debt-only (QARZ:) entries
    final regularCustomers = _farm!.customers
        .where((c) => !c.name.startsWith('QARZ:'))
        .toList();
    // Only log once every 5 seconds to prevent spam
    final now = DateTime.now();
    if (_lastCustomerUpdate == null ||
        now.difference(_lastCustomerUpdate!).inSeconds > 5) {
      print('📊 Regular mijozlar: ${regularCustomers.length} ta');
      _lastCustomerUpdate = now;
    }
    return regularCustomers;
  }

  // Get only debt customers (for Debts screen)
  List<Customer> getDebtOnlyCustomers() {
    if (_farm == null) return [];
    return _farm!.customers
        .where((c) => c.name.startsWith('QARZ:') && c.totalDebt > 0)
        .toList();
  }

  Future<bool> addEggSaleWithCustomer({
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required int trayCount,
    required double pricePerTray,
    required double paidAmount,
    Function()? onSuccess,
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
      print(
        '📝 Mijozga tuxum sotish boshlandi: $trayCount fletka - $customerName',
      );

      // DEBUG: Mijozlar ro'yxatini tekshirish
      print('🔍 Hozirgi mijozlar soni: ${_farm!.customers.length}');
      print(
        '🔍 QARZ mijozlar: ${_farm!.customers.where((c) => c.name.startsWith("QARZ:")).length}',
      );
      print(
        '🔍 Oddiy mijozlar: ${_farm!.customers.where((c) => !c.name.startsWith("QARZ:")).length}',
      );

      // First, add or find the customer (QARZ: prefixi bilan emas!)
      String? customerId;

      // Normalize phone number for comparison
      final normalizedInputPhone = customerPhone.replaceAll(RegExp(r'\s+'), '');

      final existingCustomer = _farm!.customers
          .where(
            (c) => !c.name.startsWith('QARZ:'),
          ) // Exclude debt-only customers
          .where((c) {
            final normalizedCustomerPhone = c.phone.replaceAll(
              RegExp(r'\s+'),
              '',
            );
            // Match by phone if both have phone numbers
            if (normalizedInputPhone.isNotEmpty &&
                normalizedCustomerPhone.isNotEmpty) {
              return normalizedCustomerPhone == normalizedInputPhone;
            }
            // If no phone, match by name
            return c.name.trim().toLowerCase() ==
                customerName.trim().toLowerCase();
          })
          .firstOrNull;

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
        print('📞 Input telefon: "$customerPhone"');
        print('📍 Input manzil: "$customerAddress"');

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
        print('✅ addCustomer() muvaffaqiyatli bajarildi');

        // DEBUG: Log current customers after addition
        print('🔍 Mijoz qo\'shishdan keyin:');
        print('🔍 Jami mijozlar: ${_farm!.customers.length}');
        for (int i = 0; i < _farm!.customers.length; i++) {
          final c = _farm!.customers[i];
          print('🔍   [$i] ${c.name} | ${c.phone} | ${c.id}');
        }

        // Wait a brief moment to ensure the customer is properly added
        await Future.delayed(const Duration(milliseconds: 100));

        // Get the newly added customer's ID - use multiple search strategies
        Customer? newCustomer;

        // Strategy 1: Find by exact name and normalized phone
        final normalizedInputPhone = customerPhone.replaceAll(
          RegExp(r'\s+'),
          '',
        );
        newCustomer = _farm!.customers
            .where((c) => !c.name.startsWith('QARZ:'))
            .where((c) => c.name.trim() == customerName.trim())
            .where(
              (c) =>
                  c.phone.replaceAll(RegExp(r'\s+'), '') ==
                  normalizedInputPhone,
            )
            .firstOrNull;

        // Strategy 2: If not found, try just by name (in case phone was empty or different)
        if (newCustomer == null && customerName.trim().isNotEmpty) {
          newCustomer = _farm!.customers
              .where((c) => !c.name.startsWith('QARZ:'))
              .where((c) => c.name.trim() == customerName.trim())
              .lastOrNull; // Get the latest one with this name
        }

        // Strategy 3: Get the most recently added customer if others fail
        if (newCustomer == null) {
          final regularCustomers = _farm!.customers
              .where((c) => !c.name.startsWith('QARZ:'))
              .toList();
          if (regularCustomers.isNotEmpty) {
            newCustomer = regularCustomers.last;
            print(
              '⚠️ Using last added customer as fallback: ${newCustomer.name}',
            );
          }
        }

        if (newCustomer != null) {
          customerId = newCustomer.id;
          print(
            '✅ Yangi mijoz muvaffaqiyatli qo\'shildi: $customerName (ID: $customerId)',
          );
        } else {
          print('❌ Yangi mijoz topilmadi!');
          print('🔍 Jami mijozlar: ${_farm!.customers.length}');
          print(
            '🔍 Regular mijozlar: ${_farm!.customers.where((c) => !c.name.startsWith("QARZ:")).length}',
          );
          throw Exception('Mijoz yaratilgandan keyin topilmadi');
        }
      }

      // Reduce egg stock ONCE
      _farm!.addEggSale(
        trayCount,
        pricePerTray,
        note: 'Sotildi: $customerName',
      );
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
        note:
            'Tuxum sotildi. To\'landi: ${paidAmount.toStringAsFixed(0)} so\'m',
        deductFromStock: false, // Stock already deducted by addEggSale above
      );

      // If fully paid, mark as paid immediately
      if (remainingDebt <= 0) {
        final customer = _farm!.customers.firstWhere((c) => c.id == customerId);
        final lastOrder = customer.orders.last;
        _farm!.markCustomerOrderAsPaid(customerId, lastOrder.id);
        print('💰 To\'langan buyurtma belgilandi');
      } else {
        print('💳 Qarz qoldi: ${remainingDebt.toStringAsFixed(0)} so\'m');

        // Mirror remaining debt into a dedicated Debts customer (QARZ: prefix)
        String debtorId;
        final normalizedPhone = customerPhone.replaceAll(RegExp(r'\s+'), '');
        final existingDebtor = _farm!.customers
            .where((c) => c.name.startsWith('QARZ:'))
            .where((c) {
              if (normalizedPhone.isNotEmpty) {
                return c.phone.replaceAll(RegExp(r'\s+'), '') ==
                    normalizedPhone;
              }
              return c.name.trim().toLowerCase() ==
                  'qarz: ' + customerName.trim().toLowerCase();
            })
            .firstOrNull;

        if (existingDebtor != null) {
          debtorId = existingDebtor.id;
        } else {
          // Create debt-only customer and get ID
          final newId = await _addCustomerAndGetId(
            'QARZ: $customerName',
            phone: customerPhone,
            address: customerAddress,
          );
          if (newId == null) {
            _error = 'Qarz mijoz yaratib bo\'lmadi';
            notifyListeners();
            return false;
          }
          debtorId = newId;
        }

        // Add debt as a single-item order, price = remainingDebt
        _farm!.addCustomerOrder(
          debtorId,
          1,
          remainingDebt,
          DateTime.now(),
          note:
              'DEBT_FROM_SALE: $trayCount fletka x ${pricePerTray.toStringAsFixed(0)} so\'m',
          deductFromStock: false,
        );
      }

      // IMPORTANT: Force immediate UI update
      _notifyListenersImmediate();

      // Log the transaction
      final stockAfter = _farm!.egg?.currentStock ?? 0;
      await _addActivityLog(
        'Mijozga sotish',
        '$trayCount fletka tuxum $customerName ga sotildi. ${totalAmount.toStringAsFixed(0)} so\'m. To\'langan: ${paidAmount.toStringAsFixed(0)} so\'m. Zaxira: $stockAfter fletka',
      );

      // FAST: local persist first for instant UI, then background sync
      await _persistLocalImmediate();
      unawaited(_saveToSupabase());
      // Avoid heavy immediate reload which causes UI lag/flicker; local state is already correct
      _notifyListenersImmediate();

      print('✅ Mijozga sotish muvaffaqiyatli yakunlandi');

      // Call success callback if provided
      if (onSuccess != null) {
        onSuccess();
      }

      // Navigate to Debts tab immediately if there is remaining debt
      if (remainingDebt > 0) {
        try {
          MainScreen.switchToDebtsTab();
        } catch (_) {}
      }

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
        List<BrokenEgg> brokenCopy = [];
        List<LargeEgg> largeCopy = [];

        if (_farm!.egg != null) {
          // Create defensive copies to prevent concurrent modification
          productionsCopy = List<EggProduction>.from(_farm!.egg!.production);
          salesCopy = List<EggSale>.from(_farm!.egg!.sales);
          brokenCopy = List<BrokenEgg>.from(_farm!.egg!.brokenEggs);
          largeCopy = List<LargeEgg>.from(_farm!.egg!.largeEggs);

          // Build lightweight signature to avoid redundant writes
          final prodIds = productionsCopy.map((e) => e.id).toList()..sort();
          final saleIds = salesCopy.map((e) => e.id).toList()..sort();
          final brokenIds = brokenCopy.map((e) => e.id).toList()..sort();
          final largeIds = largeCopy.map((e) => e.id).toList()..sort();
          final currentEggSignature = [
            prodIds.join(','),
            saleIds.join(','),
            brokenIds.join(','),
            largeIds.join(','),
          ].join('|');
          if (_lastEggSignature == currentEggSignature) {
            productionsCopy = [];
            salesCopy = [];
            brokenCopy = [];
            largeCopy = [];
          } else {
            _lastEggSignature = currentEggSignature;
            // Local dedupe by ID to prevent duplicates being saved
            productionsCopy = List<EggProduction>.from(
              {for (final p in productionsCopy) p.id: p}.values,
            );
            salesCopy = List<EggSale>.from(
              {for (final s in salesCopy) s.id: s}.values,
            );
            brokenCopy = List<BrokenEgg>.from(
              {for (final b in brokenCopy) b.id: b}.values,
            );
            largeCopy = List<LargeEgg>.from(
              {for (final l in largeCopy) l.id: l}.values,
            );
          }
        }

        // Egg productions ni saqlash (copy dan) - STABLE IDs
        if (productionsCopy.isNotEmpty) {
          for (final production in productionsCopy) {
            // Safe null check for date
            final productionDate = production.date ?? DateTime.now();
            final productionData = {
              // IMPORTANT: use existing local ID to avoid duplicates
              'id': production.id,
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

        // Egg sales ni saqlash (copy dan) - STABLE IDs
        if (salesCopy.isNotEmpty) {
          for (final sale in salesCopy) {
            // Safe null check for date
            final saleDate = sale.date ?? DateTime.now();
            final saleData = {
              // IMPORTANT: use existing local ID to avoid duplicates
              'id': sale.id,
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

        // Customers ni saqlash - with signature + local dedupe
        if (_farm!.customers.isNotEmpty) {
          print(
            '💾 Saving ${_farm!.customers.length} customers to Supabase...',
          );

          // Create a copy of the customers list to avoid concurrent modification
          List<Customer> customersCopy = List<Customer>.from(_farm!.customers);

          // Skip if unchanged since last sync
          final ids = customersCopy.map((c) => c.id).toList()..sort();
          final orderIds =
              customersCopy.expand((c) => c.orders.map((o) => o.id)).toList()
                ..sort();
          final currentCustomersSignature =
              ids.join(',') + '|' + orderIds.join(',');
          if (_lastCustomersSignature == currentCustomersSignature) {
            customersCopy = [];
          } else {
            _lastCustomersSignature = currentCustomersSignature;
            // Local dedupe by ID
            customersCopy = List<Customer>.from(
              {for (final c in customersCopy) c.id: c}.values,
            );
          }

          for (final customer in customersCopy) {
            // Sanity: ensure each customer has a stable UUID
            if (customer.id.isEmpty) {
              // Skip invalid customer without id to avoid overwriting
              print('⚠️ Skipping customer without id to prevent overwrite');
              continue;
            }
            try {
              final customerData = {
                'id': customer.id,
                'farm_id': _farm!.id,
                'name': customer.name,
                'phone': customer.phone,
                'address': customer.address,
                'total_debt': customer.totalDebt,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              };

              await _supabase.from('customers').upsert(customerData);
              print('✅ Customer saved: ${customer.name} (${customer.id})');

              // Orders ni saqlash
              if (customer.orders.isNotEmpty) {
                // Also copy orders list to avoid concurrent modification
                final ordersCopy = List.from(
                  {for (final o in customer.orders) o.id: o}.values,
                );
                for (final order in ordersCopy) {
                  try {
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
                      'created_at': DateTime.now().toIso8601String(),
                    };

                    await _supabase.from('orders').upsert(orderData);
                    print('✅ Order saved for customer ${customer.name}');
                  } catch (orderError) {
                    print('⚠️ Order saqlashda xatolik: $orderError');
                  }
                }
              }
            } catch (customerError) {
              print('⚠️ Customer saqlashda xatolik: $customerError');
              print('⚠️ Customer data: ${customer.toJson()}');
            }
          }
        }

        // Muvaffaqiyatli sync
        await _storage.markDataAsSynced(_farm!.id);
        // Silent sync completion
        return;
      } catch (e) {
        print('⚠️ Supabase sync urinishi #$attempt muvaffaqiyatsiz: $e');

        if (attempt == maxRetries) {
          print(
            '❌ Barcha sync urinishlari muvaffaqiyatsiz, offline rejimga o\'tish',
          );
          _isOfflineMode = true;
          _error = null; // Don't show error for offline mode

          // Activity log qo'shish
          await _addActivityLog(
            'Sync xatosi',
            'Internet bilan aloqa yo\'q, offline rejimda davom etilmoqda',
          );

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
  Future<void> _addActivityLog(
    String title,
    String description, {
    String? activityType,
    String? importance,
  }) async {
    try {
      if (_farm == null) return;

      // Auto-generate better descriptions with timestamps
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final dateStr = '${now.day}/${now.month}/${now.year}';

      final enhancedTitle = title.contains('⏰') ? title : '⏰ $timeStr - $title';
      final enhancedDescription =
          '$description\n📅 $dateStr da amalga oshirildi';

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
      final hiveActivityData = {'id': activityId, ...activityData};

      if (!Hive.isBoxOpen('activity_logs')) {
        await Hive.openBox<Map>('activity_logs');
      }
      final activityBox = Hive.box<Map>('activity_logs');
      await activityBox.put(activityId, hiveActivityData);

      // OPTIMIZED: Auto-clean old logs only when really needed (keep last 75, clean when > 100)
      if (activityBox.length > 100) {
        final keys = activityBox.keys.toList();
        final oldKeys = keys.take(
          keys.length - 75,
        ); // Keep more logs, clean less frequently
        for (final key in oldKeys) {
          await activityBox.delete(key);
        }
        print(
          '🧹 ${oldKeys.length} eski activity log tozalandi (${activityBox.length} qoldi)',
        );
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
            print(
              '⚠️ Farm Supabase da topilmadi, activity log faqat lokal saqlandi',
            );
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
    if (titleLower.contains('tuxum') && titleLower.contains('ishlab chiqar'))
      return 'eggProduction';
    if (titleLower.contains('tuxum') && titleLower.contains('sotildi'))
      return 'eggSale';
    if (titleLower.contains('tovuq') && titleLower.contains('qo\'shildi'))
      return 'chickenAdded';
    if (titleLower.contains('tovuq') && titleLower.contains('o\'ldi'))
      return 'chickenDeath';
    if (titleLower.contains('mijoz') || titleLower.contains('customer'))
      return 'customerAdded';
    if (titleLower.contains('qarz') || titleLower.contains('debt'))
      return 'debtAdded';
    if (titleLower.contains('siniq')) return 'brokenEggs';
    if (titleLower.contains('katta')) return 'largeEggs';
    return 'other';
  }

  // Muhimlik darajasini aniqlash
  String _determineImportance(String title, String description) {
    final combined = '${title.toLowerCase()} ${description.toLowerCase()}';
    if (combined.contains('xatolik') ||
        combined.contains('error') ||
        combined.contains('o\'ldi'))
      return 'high';
    if (combined.contains('kritik') || combined.contains('critical'))
      return 'critical';
    if (combined.contains('muhim') || combined.contains('important'))
      return 'high';
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

      // Clear duplicate prevention caches
      _pendingOperations.clear();
      _processedRecordIds.clear();
      print('🧹 Duplicate prevention cache tozalandi');

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
    _realtimeDebounceTimer?.cancel(); // Clean up realtime debounce timer
    // Save any pending changes before disposing
    if (_hasPendingChanges) {
      _persist();
    }
    super.dispose();
  }
}
