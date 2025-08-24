import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/farm.dart';
import '../models/chicken.dart';
import '../models/egg.dart';
import '../models/customer.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';

class FarmProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  Farm? _farm;
  bool _isLoading = false;
  String? _error;
  bool _isOfflineMode = false;

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

  // Tovuqlar qo'shish
  Future<bool> addChickens(int count) async {
    if (_farm == null) {
      _error = 'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
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
          await _saveToFirebase();
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
      _error = 'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
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
          await _saveToFirebase();
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
      _error = 'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
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
          await _saveToFirebase();
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
      _error = 'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
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
          await _saveToFirebase();
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
      _error = 'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
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
          await _saveToFirebase();
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
      _error = 'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
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
          await _saveToFirebase();
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
          await _saveToFirebase();
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
      _error = 'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
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
          await _saveToFirebase();
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
          await _saveToFirebase();
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
      _error = 'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
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
          await _saveToFirebase();
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
      _error = 'Ferma ma\'lumotlari topilmadi. Avval tizimga kiring yoki fermani yuklang.';
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
            await _saveToFirebase();
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
          await _saveToFirebase();
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

  // Firebase'ga saqlash
  Future<void> _saveToFirebase() async {
    if (_farm == null) return;

    try {
      // Asosiy ferma ma'lumotlari
      await _firestore
          .collection(AppConstants.farmsCollection)
          .doc(_farm!.id)
          .set({
            'id': _farm!.id,
            'name': _farm!.name,

            'userId': _farm!.userId,
            'createdAt': Timestamp.fromDate(_farm!.createdAt),
            'updatedAt': Timestamp.fromDate(_farm!.updatedAt),
          }, SetOptions(merge: true));

      // Tovuqlar ma'lumotlari
      if (_farm!.chicken != null) {
        await _firestore
            .collection(AppConstants.chickensCollection)
            .doc(_farm!.id)
            .set({
              'id': _farm!.chicken!.id,
              'totalCount': _farm!.chicken!.totalCount,
              'deaths': _farm!.chicken!.deaths
                  .map(
                    (death) => {
                      'id': death.id,
                      'count': death.count,
                      'date': Timestamp.fromDate(death.date),
                      'note': death.note,
                    },
                  )
                  .toList(),
              'createdAt': Timestamp.fromDate(_farm!.chicken!.createdAt),
              'updatedAt': Timestamp.fromDate(_farm!.chicken!.updatedAt),
            }, SetOptions(merge: true));
      }

      // Tuxumlar ma'lumotlari
      if (_farm!.egg != null) {
        await _firestore
            .collection(AppConstants.eggsCollection)
            .doc(_farm!.id)
            .set({
              'id': _farm!.egg!.id,
              'production': _farm!.egg!.production
                  .map(
                    (prod) => {
                      'id': prod.id,
                      'trayCount': prod.trayCount,
                      'date': Timestamp.fromDate(prod.date),
                      'note': prod.note,
                    },
                  )
                  .toList(),
              'sales': _farm!.egg!.sales
                  .map(
                    (sale) => {
                      'id': sale.id,
                      'trayCount': sale.trayCount,
                      'date': Timestamp.fromDate(sale.date),
                      'note': sale.note,
                    },
                  )
                  .toList(),
              'brokenEggs': _farm!.egg!.brokenEggs
                  .map(
                    (broken) => {
                      'id': broken.id,
                      'trayCount': broken.trayCount,
                      'date': Timestamp.fromDate(broken.date),
                      'note': broken.note,
                    },
                  )
                  .toList(),
              'largeEggs': _farm!.egg!.largeEggs
                  .map(
                    (large) => {
                      'id': large.id,
                      'trayCount': large.trayCount,
                      'date': Timestamp.fromDate(large.date),
                      'note': large.note,
                    },
                  )
                  .toList(),
              'createdAt': Timestamp.fromDate(_farm!.egg!.createdAt),
              'updatedAt': Timestamp.fromDate(_farm!.egg!.updatedAt),
            }, SetOptions(merge: true));
      }

      // Mijozlar ma'lumotlari
      if (_farm!.customers.isNotEmpty) {
        for (var customer in _farm!.customers) {
          await _firestore
              .collection(AppConstants.customersCollection)
              .doc('${_farm!.id}_${customer.id}')
              .set({
                'id': customer.id,
                'name': customer.name,
                'phone': customer.phone,
                'address': customer.address,
                'orders': customer.orders
                    .map(
                      (order) => {
                        'id': order.id,
                        'trayCount': order.trayCount,
                        'pricePerTray': order.pricePerTray,
                        'deliveryDate': Timestamp.fromDate(order.deliveryDate),
                        'isPaid': order.isPaid,
                        'paidAt': order.paidAt != null
                            ? Timestamp.fromDate(order.paidAt!)
                            : null,
                        'note': order.note,
                        'createdAt': Timestamp.fromDate(order.createdAt),
                      },
                    )
                    .toList(),
                'createdAt': Timestamp.fromDate(customer.createdAt),
                'updatedAt': Timestamp.fromDate(customer.updatedAt),
              }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      _error = 'Firebase\'ga saqlashda xatolik: $e';
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
        await _saveToFirebase();
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
}
