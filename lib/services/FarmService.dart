import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/farm.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../config/supabase_config.dart';

class FarmService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final StorageService _storage = StorageService();

  Farm? _farm;
  bool _isOfflineMode = false;

  StreamSubscription<List<Map<String, dynamic>>>? _farmStreamSub;
  StreamSubscription<List<Map<String, dynamic>>>? _customersStreamSub;
  StreamSubscription<List<Map<String, dynamic>>>? _eggRecordsStreamSub;

  Farm? get farm => _farm;
  bool get isOfflineMode => _isOfflineMode;

  void setFarm(Farm farm) {
    _farm = farm;
  }

  Future<void> startRealtime() async {
    if (_farm == null) return;
    await stopRealtime();

    _farmStreamSub = _supabase
        .from('farms')
        .stream(primaryKey: ['id'])
        .eq('id', _farm!.id)
        .listen((rows) async {
          if (rows.isNotEmpty) {
            _farm = Farm.fromJson(rows.first);
            await _saveToHive();
          }
        });

    _customersStreamSub = _supabase
        .from('customers')
        .stream(primaryKey: ['id'])
        .eq('farm_id', _farm!.id)
        .listen((_) async {
          await _refreshFarmData();
        });

    _eggRecordsStreamSub = _supabase
        .from('egg_productions')
        .stream(primaryKey: ['id'])
        .eq('farm_id', _farm!.id)
        .listen((rows) async {
          await _processEggRecords(rows);
          await _saveToHive();
        });
  }

  Future<void> stopRealtime() async {
    await _farmStreamSub?.cancel();
    await _customersStreamSub?.cancel();
    await _eggRecordsStreamSub?.cancel();
    _farmStreamSub = null;
    _customersStreamSub = null;
    _eggRecordsStreamSub = null;
  }

  Future<void> _refreshFarmData() async {
    if (_farm == null) return;
    final response = await _supabase
        .from('farms')
        .select()
        .eq('id', _farm!.id)
        .maybeSingle();

    if (response != null) {
      _farm = Farm.fromJson(response);
      await _saveToHive();
    }
  }

  Future<void> _processEggRecords(List<Map<String, dynamic>> records) async {
    if (_farm?.egg == null) return;

    for (final record in records) {
      final trayCount = (record['tray_count'] as num?)?.toInt() ?? 0;
      final pricePerTray =
          (record['price_per_tray'] as num?)?.toDouble() ?? 0.0;
      final note = record['note'] as String?;
      final recordType = record['record_type'] as String? ?? 'production';

      switch (recordType) {
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

  Future<void> _saveToSupabase() async {
    if (_farm == null) return;
    await _supabase.from(AppConstants.farmsCollection).upsert(_farm!.toJson());
  }

  Future<void> _saveToHive() async {
    if (_farm == null) return;
    await _storage.saveFarmOffline(_farm!);
  }

  void setOfflineMode(bool offline) {
    _isOfflineMode = offline;
  }

  Future<void> syncWhenOnline() async {
    if (_farm != null && _isOfflineMode) {
      await _saveToSupabase();
      _isOfflineMode = false;
    }
  }

  // --- CRUD Methods ---

  Future<void> addChickens(int count) async {
    _farm?.addChickens(count);
    await _saveToHive();
    if (!_isOfflineMode) await _saveToSupabase();
  }

  Future<void> addChickenDeath(int count) async {
    _farm?.addChickenDeath(count);
    await _saveToHive();
    if (!_isOfflineMode) await _saveToSupabase();
  }

  Future<void> addEggProduction(int trayCount, {String? note}) async {
    _farm?.addEggProduction(trayCount, note: note);
    await _saveToHive();
    if (!_isOfflineMode) await _saveToSupabase();
  }

  Future<void> addEggSale(
    int trayCount,
    double pricePerTray, {
    String? note,
  }) async {
    _farm?.addEggSale(trayCount, pricePerTray, note: note);
    await _saveToHive();
    if (!_isOfflineMode) await _saveToSupabase();
  }

  Future<void> addBrokenEgg(int trayCount, {String? note}) async {
    _farm?.addBrokenEgg(trayCount, note: note);
    await _saveToHive();
    if (!_isOfflineMode) await _saveToSupabase();
  }

  Future<void> addLargeEgg(int trayCount, {String? note}) async {
    _farm?.addLargeEgg(trayCount, note: note);
    await _saveToHive();
    if (!_isOfflineMode) await _saveToSupabase();
  }

  Future<void> addCustomer(
    String name, {
    String? phone,
    String? address,
  }) async {
    _farm?.addCustomer(name, phone: phone, address: address);
    await _saveToHive();
    if (!_isOfflineMode) await _saveToSupabase();
  }

  Future<void> removeCustomer(String customerId) async {
    _farm?.removeCustomer(customerId);
    await _saveToHive();
    if (!_isOfflineMode) await _saveToSupabase();
  }

  Future<void> updateCustomerInfo(
    String customerId, {
    String? name,
    String? phone,
    String? address,
  }) async {
    _farm?.updateCustomerInfo(
      customerId,
      name: name,
      phone: phone,
      address: address,
    );
    await _saveToHive();
    if (!_isOfflineMode) await _saveToSupabase();
  }

  Future<void> addCustomerOrder(
    String customerId,
    int trayCount,
    double pricePerTray,
    DateTime deliveryDate, {
    String? note,
  }) async {
    _farm?.addCustomerOrder(
      customerId,
      trayCount,
      pricePerTray,
      deliveryDate,
      note: note,
    );
    await _saveToHive();
    if (!_isOfflineMode) await _saveToSupabase();
  }

  Future<void> markCustomerOrderAsPaid(
    String customerId,
    String orderId,
  ) async {
    _farm?.markCustomerOrderAsPaid(customerId, orderId);
    await _saveToHive();
    if (!_isOfflineMode) await _saveToSupabase();
  }

  Future<void> removeCustomerOrder(String customerId, String orderId) async {
    final customer = _farm?.findCustomer(customerId);
    customer?.removeOrder(orderId);
    await _saveToHive();
    if (!_isOfflineMode) await _saveToSupabase();
  }

  void dispose() {
    _farmStreamSub?.cancel();
    _customersStreamSub?.cancel();
    _eggRecordsStreamSub?.cancel();
  }
}
