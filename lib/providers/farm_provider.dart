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
  
  // Ensure Farm has Egg and Chicken objects initialized
  Farm _ensureFarmObjectsInitialized(Farm farm) {
    Chicken? chicken = farm.chicken;
    Egg? egg = farm.egg;
    bool needsUpdate = false;
    
    // Create Chicken object if null (only once)
    if (chicken == null) {
      print('🐔 Chicken object yaratilmoqda farm: ${farm.name}');
      chicken = Chicken(
        id: farm.id,
        totalCount: farm.chickenCount,
        deaths: const [],
      );
      needsUpdate = true;
    }
    
    // Create Egg object if null (only once)  
    if (egg == null) {
      print('🥚 Egg object yaratilmoqda farm: ${farm.name}');
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
      
      // Schedule async save without blocking
      Future.microtask(() async {
        try {
          await _saveToHive();
          print('✅ Farm objects saqlandi: ${updatedFarm.name}');
        } catch (e) {
          print('❌ Farm objects saqlashda xatolik: $e');
        }
      });
      return updatedFarm;
    }
    
    return farm;
  }
  
  // Load egg data from Supabase
  Future<void> _loadEggDataFromSupabase(String farmId) async {
    if (_farm?.egg == null) return;
    
    try {
      // Load egg productions
      final productions = await _supabase
          .from('egg_productions')
          .select()
          .eq('farm_id', farmId);
      
      if (productions.isNotEmpty) {
        print('💾 ${productions.length} ta egg record Supabase dan yuklandi');
        
        // Parse productions
        for (final record in productions) {
          final recordType = record['record_type'] as String? ?? 'production';
          final trayCount = (record['tray_count'] as num?)?.toInt() ?? 0;
          final dateStr = record['created_at'] as String? ?? record['date'] as String?;
          final note = record['note'] as String?;
          
          DateTime recordDate = DateTime.now();
          if (dateStr != null) {
            try {
              recordDate = DateTime.parse(dateStr);
            } catch (e) {
              recordDate = DateTime.now();
            }
          }
          
          switch (recordType) {
            case 'production':
              _farm!.egg!.production.add(EggProduction(
                id: UuidGenerator.generateUuid(),
                trayCount: trayCount,
                date: recordDate,
                note: note,
              ));
              break;
            case 'sale':
              final pricePerTray = (record['price_per_tray'] as num?)?.toDouble() ?? 0.0;
              _farm!.egg!.sales.add(EggSale(
                id: UuidGenerator.generateUuid(),
                trayCount: trayCount,
                pricePerTray: pricePerTray,
                date: recordDate,
                note: note,
              ));
              break;
          }
        }
        
        print('🥚 Egg zaxira yangilandi: ${_farm!.egg!.currentStock} fletka');
      }
    } catch (e) {
      print('⚠️ Supabase dan egg ma\'lumotlarini yuklashda xatolik: $e');
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
      // Farm stream
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
                  
                  // Additional data sanitization
                  final sanitizedData = Map<String, dynamic>.from(farmData);
                  
                  // Ensure description is not null
                  sanitizedData['description'] ??= '';
                  
                  final updated = Farm.fromJson(sanitizedData);
                  _farm = updated;
                  await _saveToHive();
                  print('📡 Realtime farm yangilandi: ${_farm?.name}');
                  notifyListeners();
                } else {
                  print('⚠️ Realtime da noto\'g\'ri farm ma\'lumoti, e\'tibor berilmadi: $farmData');
                }
              } catch (e) {
                print('⚠️ Realtime farm ma\'lumotini parse qilishda xatolik: $e');
                // Don't crash the app, just log the error
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
              notifyListeners();
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

    for (final record in records) {
      final trayCount = (record['tray_count'] as num?)?.toInt() ?? 0;
      final pricePerTray =
          (record['price_per_tray'] as num?)?.toDouble() ?? 0.0;
      final note = record['note'] as String?;
      final type = record['record_type'] as String? ?? 'production';

      switch (type) {
        case 'production':
          _farm!.egg!.addProduction(trayCount, note: note);
          break;
        case 'sale':
          _farm!.egg!.addSale(trayCount, pricePerTray, note: note);
          break;
        case 'broken':
          _farm!.addBrokenEgg(trayCount, note: note);
          break;
        case 'large':
          _farm!.addLargeEgg(trayCount, note: note);
          break;
        default:
          _farm!.egg!.addProduction(trayCount, note: note);
          break;
      }
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
      await _persist();
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

  Future<bool> addEggProduction(int trays, {String? note}) async {
    if (_farm == null) {
      print('❌ Farm null, tuxum qo\'shib bo\'lmaydi');
      return false;
    }
    
    // Egg objectini tekshirish va yaratish
    if (_farm!.egg == null) {
      print('🥚 Egg object yaratilmoqda production uchun: ${_farm!.name}');
      _farm = _farm!.copyWith(egg: Egg(id: _farm!.id));
    }
    
    try {
      print('📝 Tuxum ishlab chiqarish qo\'shilmoqda: $trays fletka');
      
      _farm!.addEggProduction(trays, note: note);
      final currentStock = _farm!.egg?.currentStock ?? 0;
      
      // Immediate UI update
      notifyListeners();
      
      print('✅ Tuxum qo\'shildi. Yangi zaxira: $currentStock fletka');
      
      await _addActivityLog('Tuxum ishlab chiqarildi', 
        '$trays fletka tuxum ishlab chiqarildi. Jami zaxira: $currentStock fletka${note != null ? '. Izoh: $note' : ''}');
      
      await _persist();
      return true;
    } catch (e) {
      print('❌ Tuxum ishlab chiqarishda xatolik: $e');
      _error = 'Tuxum ishlab chiqarishda xatolik: $e';
      await _addActivityLog('Xatolik', 'Tuxum ishlab chiqarishda xatolik: $e');
      return false;
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
      return false;
    }
    
    try {
      _farm!.addEggSale(trays, pricePerTray, note: note);
      final totalAmount = trays * pricePerTray;
      final remainingStock = _farm!.egg?.currentStock ?? 0;
      await _addActivityLog('Tuxum sotildi', 
        '$trays fletka tuxum ${totalAmount.toStringAsFixed(0)} so\'mga sotildi. Qolgan: $remainingStock fletka${note != null ? '. Izoh: $note' : ''}');
      await _persist();
      return true;
    } catch (e) {
      _error = 'Tuxum sotishda xatolik: $e';
      await _addActivityLog('Xatolik', 'Tuxum sotishda xatolik: $e');
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
    if (_farm == null) return false;
    try {
      _farm!.addCustomerOrder(
        customerId,
        trays,
        pricePerTray,
        deliveryDate,
        note: note,
      );
      await _persist();
      return true;
    } catch (e) {
      _error = 'Mijoz buyurtmasini qo‘shishda xatolik: $e';
      return false;
    }
  }

  Future<bool> markCustomerOrderAsPaid(
    String customerId,
    String orderId,
  ) async {
    if (_farm == null) return false;
    try {
      _farm!.markCustomerOrderAsPaid(customerId, orderId);
      await _persist();
      return true;
    } catch (e) {
      _error = 'Buyurtmani to‘langan deb belgilashda xatolik: $e';
      return false;
    }
  }

  Future<bool> removeCustomerOrder(String customerId, String orderId) async {
    if (_farm == null) return false;
    try {
      _farm!.removeCustomerOrder(customerId, orderId);
      await _persist();
      return true;
    } catch (e) {
      _error = 'Buyurtmani o‘chirishda xatolik: $e';
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
      return false;
    }
    
    try {
      // First, add or find the customer
      String? customerId;
      final existingCustomer = _farm!.customers.where(
        (c) => c.phone.replaceAll(RegExp(r'\s+'), '') == customerPhone.replaceAll(RegExp(r'\s+'), '')
      ).firstOrNull;
      
      if (existingCustomer != null) {
        // Update existing customer info if needed
        await updateCustomerInfo(
          existingCustomer.id,
          name: customerName,
          phone: customerPhone,
          address: customerAddress.isNotEmpty ? customerAddress : null,
        );
        customerId = existingCustomer.id;
      } else {
        // Add new customer
        _farm!.addCustomer(
          customerName,
          phone: customerPhone,
          address: customerAddress.isNotEmpty ? customerAddress : null,
        );
        // Get the newly added customer's ID
        customerId = _farm!.customers.last.id;
      }
      
      // Reduce egg stock
      _farm!.addEggSale(trayCount, pricePerTray, note: 'Sotildi: $customerName');
      
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
      
      // If fully paid, mark as paid
      if (remainingDebt <= 0) {
        final customer = _farm!.customers.firstWhere((c) => c.id == customerId);
        final lastOrder = customer.orders.last;
        _farm!.markCustomerOrderAsPaid(customerId, lastOrder.id);
      }
      
      await _persist();
      return true;
    } catch (e) {
      _error = 'Tuxum sotishda xatolik: $e';
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
        print('✅ Ma\'lumotlar lokal Hive ga saqlandi');
      } catch (hiveError) {
        print('❌ Hive saqlashda xatolik: $hiveError');
        lastError = 'Lokal saqlash xatosi: $hiveError';
        
        // Fallback: direct storage service
        try {
          await _storage.saveFarmOffline(_farm!);
          hiveSuccess = true;
          print('🔄 Rezerv Hive saqlash muvaffaqiyatli');
        } catch (backupError) {
          print('💥 Rezerv saqlash ham muvaffaqiyatsiz: $backupError');
          lastError = 'KRITIK: Lokal ma\'lumotlar saqlanmadi: $backupError';
        }
      }
      
      // STEP 2: Activity Log qo'shish (agar Hive ishlasa)
      if (hiveSuccess) {
        try {
          await _addActivityLog('Ma\'lumotlar saqlandi', 
            'Farm ma\'lumotlari ${DateTime.now().toString().substring(0, 16)} da yangilandi');
        } catch (activityError) {
          print('⚠️ Activity log qo\'shishda xatolik: $activityError');
          // Activity log xatosi asosiy jarayonni to'xtatmasin
        }
      }
      
      // STEP 3: Supabase sinxronizatsiya (agar offline bo'lmasa)
      if (!_isOfflineMode && hiveSuccess) {
        try {
          await _syncToSupabaseWithRetry();
          supabaseSuccess = true;
          print('✅ Supabase sinxronizatsiyasi muvaffaqiyatli');
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
        print('🎉 Ma\'lumotlar muvaffaqiyatli saqlandi (Hive: ✅, Supabase: ${supabaseSuccess ? "✅" : "❌"})');
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

  // RETRY MEXANIZMI BILAN SUPABASE SYNC
  Future<void> _syncToSupabaseWithRetry({int maxRetries = 3}) async {
    if (_farm == null) return;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔄 Supabase ga sinxronizatsiya urinishi #$attempt...');
        
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
        print('✅ Farm ma\'lumotlari Supabase ga saqlandi');
        
        // Egg productions ni saqlash
        if (_farm!.egg != null && _farm!.egg!.production.isNotEmpty) {
          for (final production in _farm!.egg!.production) {
            final productionData = {
              'id': UuidGenerator.generateUuid(),
              'farm_id': _farm!.id,
              'tray_count': production.trayCount,
              'note': production.note,
              'record_type': 'production',
              'production_date': production.date.toIso8601String(),
              'created_at': production.date.toIso8601String(),
            };
            
            try {
              await _supabase.from('egg_productions').upsert(productionData);
            } catch (e) {
              print('⚠️ Egg production saqlashda xatolik: $e');
            }
          }
          print('✅ ${_farm!.egg!.production.length} ta egg production Supabase ga saqlandi');
        }
        
        // Egg sales ni saqlash
        if (_farm!.egg != null && _farm!.egg!.sales.isNotEmpty) {
          for (final sale in _farm!.egg!.sales) {
            final saleData = {
              'id': UuidGenerator.generateUuid(),
              'farm_id': _farm!.id,
              'tray_count': sale.trayCount,
              'price_per_tray': sale.pricePerTray,
              'note': sale.note,
              'record_type': 'sale',
              'production_date': sale.date.toIso8601String(),
              'created_at': sale.date.toIso8601String(),
            };
            
            try {
              await _supabase.from('egg_productions').upsert(saleData);
            } catch (e) {
              print('⚠️ Egg sale saqlashda xatolik: $e');
            }
          }
          print('✅ ${_farm!.egg!.sales.length} ta egg sale Supabase ga saqlandi');
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
                final orderData = {
                  'id': order.id,
                  'customer_id': customer.id,
                  'farm_id': _farm!.id,
                  'tray_count': order.trayCount,
                  'price_per_tray': order.pricePerTray,
                  'total_amount': order.totalAmount,
                  'delivery_date': order.deliveryDate.toIso8601String(),
                  'is_paid': order.isPaid,
                  'paid_at': order.paidAt?.toIso8601String(),
                  'notes': order.note,
                };
                
                await _supabase.from('orders').upsert(orderData);
              }
            }
          }
          print('✅ ${_farm!.customers.length} ta customer Supabase ga saqlandi');
        }
        
        // Muvaffaqiyatli sync
        await _storage.markDataAsSynced(_farm!.id);
        print('✅ Supabase ga muvaffaqiyatli sinxronizatsiya!');
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
  
  // ACTIVITY LOG QO'SHISH
  Future<void> _addActivityLog(String title, String description) async {
    try {
      if (_farm == null) return;
      
      // ActivityLogService import qilmasdan to'g'ridan-to'g'ri activity log qo'shamiz
      final activityId = UuidGenerator.generateUuid();
      
      final activityData = {
        'farm_id': _farm!.id, // ID ni olib tashladik, Supabase avtomatik yaratadi
        'type': 'other',
        'title': title,
        'description': description,
        'metadata': {'timestamp': DateTime.now().toIso8601String()},
        'importance': 'normal',
        'created_at': DateTime.now().toIso8601String(),
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
            // Farm yo'q bo'lsa, avval Farm ni sync qilishga harakat qilish
            await _saveToSupabase();
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
      print('🔄 Ma\'lumotlarni yangilash boshlandi...');
      
      // Force refresh from Supabase
      await _refreshFarmData();
      
      // Restart realtime if needed
      if (!_isOfflineMode) {
        await startRealtime();
      }
      
      print('✅ Ma\'lumotlar muvaffaqiyatli yangilandi!');
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
    super.dispose();
  }
}
