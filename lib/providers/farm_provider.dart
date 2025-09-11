import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/farm.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../config/supabase_config.dart';

class FarmProvider with ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final StorageService _storage = StorageService();

  Farm? _farm;
  bool _isLoading = false;
  String? _error;
  bool _isOfflineMode = false;
  StreamSubscription<List<Map<String, dynamic>>>? _farmStreamSub;

  // Getters
  Farm? get farm => _farm;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOfflineMode => _isOfflineMode;

  // Farm ma'lumotlarini o'rnatish
  void setFarm(Farm farm) {
    _farm = farm;
    notifyListeners();
  }

  // Start realtime streaming for current farm row
  Future<void> startRealtime() async {
    if (_farm == null) return;
    await stopRealtime();
    try {
      _farmStreamSub = _supabase
          .from('farms')
          .stream(primaryKey: ['id'])
          .eq('id', _farm!.id)
          .listen((rows) async {
            if (rows.isNotEmpty) {
              final updated = Farm.fromJson(rows.first);
              _farm = updated;
              // keep offline in sync
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
    _farmStreamSub = null;
  }

  // Tovuqlar qo'shish
  Future<bool> addChickens(int count) async {
    if (_farm == null) {
      _error =
          'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
      notifyListeners();
      return false;
    }

    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      _farm!.addChickens(count);

      // Save data (offline first, then sync if online)
      await _saveToHive();
      if (!_isOfflineMode) {
        try {
          await _saveToSupabase();
        } catch (e) {
          // If Firebase fails, continue in offline mode
          _isOfflineMode = true;
          print('Switching to offline mode: $e');
        }
      }

      return true;
    } catch (e) {
      _error = 'Tovuqlar qo\'shishda xatolik: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tovuq o'limi qo'shish
  Future<bool> addChickenDeath(int count) async {
    if (_farm == null) {
      _error =
          'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
      notifyListeners();
      return false;
    }

    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      _farm!.addChickenDeath(count);

      // Save data (offline first, then sync if online)
      await _saveToHive();
      if (!_isOfflineMode) {
        try {
          await _saveToSupabase();
        } catch (e) {
          // If Firebase fails, continue in offline mode
          _isOfflineMode = true;
          print('Switching to offline mode: $e');
        }
      }

      return true;
    } catch (e) {
      final msg = e.toString();
      // Modeldan kelgan aniq xabarlarni toza ko'rsatamiz
      if (msg.contains('Tovuqlar soni yetarli emas')) {
        _error = 'Tovuqlar soni yetarli emas';
      } else if (msg.contains('Tovuqlar mavjud emas')) {
        _error = 'Tovuqlar mavjud emas';
      } else if (msg.contains('0 dan katta')) {
        _error = 'O\'lim soni 0 dan katta bo\'lishi kerak';
      } else {
        _error = 'Tovuq o\'limi qo\'shishda xatolik: $e';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tuxum ishlab chiqarish qo'shish
  Future<bool> addEggProduction(int trayCount, {String? note}) async {
    if (_farm == null) {
      _error =
          'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
      notifyListeners();
      return false;
    }

    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      _farm!.addEggProduction(trayCount, note: note);

      // Save data (offline first, then sync if online)
      await _saveToHive();
      if (!_isOfflineMode) {
        try {
          await _saveToSupabase();
        } catch (e) {
          // If Firebase fails, continue in offline mode
          _isOfflineMode = true;
          print('Switching to offline mode: $e');
        }
      }

      return true;
    } catch (e) {
      _error = 'Tuxum ishlab chiqarish qo\'shishda xatolik: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tuxum sotuvini qo'shish
  Future<bool> addEggSale(
    int trayCount,
    double pricePerTray, {
    String? note,
  }) async {
    if (_farm == null) {
      _error =
          'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
      notifyListeners();
      return false;
    }

    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      _farm!.addEggSale(trayCount, pricePerTray, note: note);

      // Save data (offline first, then sync if online)
      await _saveToHive();
      if (!_isOfflineMode) {
        try {
          await _saveToSupabase();
        } catch (e) {
          // If Firebase fails, continue in offline mode
          _isOfflineMode = true;
          print('Switching to offline mode: $e');
        }
      }

      return true;
    } catch (e) {
      _error = 'Tuxum sotuvini qo\'shishda xatolik: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Siniq tuxum qo'shish
  Future<bool> addBrokenEgg(int trayCount, {String? note}) async {
    if (_farm == null) {
      _error =
          'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
      notifyListeners();
      return false;
    }

    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      _farm!.addBrokenEgg(trayCount, note: note);

      // Save data (offline first, then sync if online)
      await _saveToHive();
      if (!_isOfflineMode) {
        try {
          await _saveToSupabase();
        } catch (e) {
          // If Firebase fails, continue in offline mode
          _isOfflineMode = true;
          print('Switching to offline mode: $e');
        }
      }

      return true;
    } catch (e) {
      _error = 'Siniq tuxum qo\'shishda xatolik: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Katta tuxum qo'shish
  Future<bool> addLargeEgg(int trayCount, {String? note}) async {
    if (_farm == null) {
      _error =
          'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
      notifyListeners();
      return false;
    }

    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      _farm!.addLargeEgg(trayCount, note: note);

      // Save data (offline first, then sync if online)
      await _saveToHive();
      if (!_isOfflineMode) {
        try {
          await _saveToSupabase();
        } catch (e) {
          // If Firebase fails, continue in offline mode
          _isOfflineMode = true;
          print('Switching to offline mode: $e');
        }
      }

      return true;
    } catch (e) {
      _error = 'Katta tuxum qo\'shishda xatolik: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mijoz qo'shish
  Future<bool> addCustomer(
    String name, {
    String? phone,
    String? address,
  }) async {
    if (_farm == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      _farm!.addCustomer(name, phone: phone, address: address);

      // Save data (offline first, then sync if online)
      await _saveToHive();
      if (!_isOfflineMode) {
        try {
          await _saveToSupabase();
        } catch (e) {
          // If Firebase fails, continue in offline mode
          _isOfflineMode = true;
          print('Switching to offline mode: $e');
        }
      }

      return true;
    } catch (e) {
      _error = 'Mijoz qo\'shishda xatolik: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mijozni o'chirish
  Future<bool> removeCustomer(String customerId) async {
    if (_farm == null) {
      _error =
          'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
      notifyListeners();
      return false;
    }

    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      _farm!.removeCustomer(customerId);

      // Save data (offline first, then sync if online)
      await _saveToHive();
      if (!_isOfflineMode) {
        try {
          await _saveToSupabase();
        } catch (e) {
          // If Firebase fails, continue in offline mode
          _isOfflineMode = true;
          print('Switching to offline mode: $e');
        }
      }

      return true;
    } catch (e) {
      _error = 'Mijozni o\'chirishda xatolik: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mijoz buyurtmasini qo'shish
  Future<bool> addCustomerOrder(
    String customerId,
    int trayCount,
    double pricePerTray,
    DateTime deliveryDate, {
    String? note,
  }) async {
    if (_farm == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      _farm!.addCustomerOrder(
        customerId,
        trayCount,
        pricePerTray,
        deliveryDate,
        note: note,
      );

      // Save data (offline first, then sync if online)
      await _saveToHive();
      if (!_isOfflineMode) {
        try {
          await _saveToSupabase();
        } catch (e) {
          // If Firebase fails, continue in offline mode
          _isOfflineMode = true;
          print('Switching to offline mode: $e');
        }
      }

      return true;
    } catch (e) {
      _error = 'Mijoz buyurtmasini qo\'shishda xatolik: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mijoz buyurtmasini to'langan deb belgilash
  Future<bool> markCustomerOrderAsPaid(
    String customerId,
    String orderId,
  ) async {
    if (_farm == null) {
      _error =
          'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
      notifyListeners();
      return false;
    }

    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      _farm!.markCustomerOrderAsPaid(customerId, orderId);

      // Save data (offline first, then sync if online)
      await _saveToHive();
      if (!_isOfflineMode) {
        try {
          await _saveToSupabase();
        } catch (e) {
          // If Firebase fails, continue in offline mode
          _isOfflineMode = true;
          print('Switching to offline mode: $e');
        }
      }

      return true;
    } catch (e) {
      _error = 'Buyurtmani to\'langan deb belgilashda xatolik: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mijoz buyurtmasini o'chirish
  Future<bool> removeCustomerOrder(String customerId, String orderId) async {
    if (_farm == null) {
      _error =
          'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
      notifyListeners();
      return false;
    }

    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      final customer = _farm!.findCustomer(customerId);
      if (customer != null) {
        customer.removeOrder(orderId);
        // Save data (offline first, then sync if online)
        await _saveToHive();
        if (!_isOfflineMode) {
          try {
            await _saveToSupabase();
          } catch (e) {
            // If Firebase fails, continue in offline mode
            _isOfflineMode = true;
            print('Switching to offline mode: $e');
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Mijoz buyurtmasini o\'chirishda xatolik: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mijoz ma'lumotlarini yangilash
  Future<bool> updateCustomerInfo(
    String customerId, {
    String? name,
    String? phone,
    String? address,
  }) async {
    if (_farm == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      _farm!.updateCustomerInfo(
        customerId,
        name: name,
        phone: phone,
        address: address,
      );

      // Save data (offline first, then sync if online)
      await _saveToHive();
      if (!_isOfflineMode) {
        try {
          await _saveToSupabase();
        } catch (e) {
          // If Firebase fails, continue in offline mode
          _isOfflineMode = true;
          print('Switching to offline mode: $e');
        }
      }

      return true;
    } catch (e) {
      _error = 'Mijoz ma\'lumotlarini yangilashda xatolik: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Supabase'ga saqlash
  Future<void> _saveToSupabase() async {
    if (_farm == null) return;

    try {
      // Asosiy ferma ma'lumotlari
      await _supabase
          .from(AppConstants.farmsCollection)
          .upsert(_farm!.toJson());
    } catch (e) {
      _error = 'Supabase\'ga saqlashda xatolik: $e';
      notifyListeners();
    }
  }

  // Hive'ga saqlash
  Future<void> _saveToHive() async {
    if (_farm == null) return;

    try {
      await _storage.saveFarmOffline(_farm!);
    } catch (e) {
      _error = 'Ma\'lumotlarni saqlashda xatolik: $e';
      notifyListeners();
    }
  }

  // Toggle offline mode
  void setOfflineMode(bool offline) {
    _isOfflineMode = offline;
    notifyListeners();
  }

  // Sync data when back online
  Future<void> syncWhenOnline() async {
    if (_farm != null && _isOfflineMode) {
      try {
        await _saveToSupabase();
        _isOfflineMode = false;
        notifyListeners();
      } catch (e) {
        print('Sync failed, staying offline: $e');
      }
    }
  }

  // Xatolik xabarini o'chirish
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _farmStreamSub?.cancel();
    super.dispose();
  }
}
