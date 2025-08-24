import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chicken.dart';
import 'egg.dart';
import 'customer.dart';

part 'farm.g.dart';

// Helper to safely parse Firestore Timestamp/int/String into DateTime
DateTime _parseDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is Timestamp) return v.toDate();
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) {
    // try parse as int millis or ISO8601
    final asInt = int.tryParse(v);
    if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
    try { return DateTime.parse(v); } catch (_) {}
  }
  return DateTime.now();
}

@HiveType(typeId: 9)
class Farm extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String userId;

  @HiveField(3)
  Chicken? chicken;

  @HiveField(4)
  Egg? egg;

  @HiveField(5)
  List<Customer> customers;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  Farm({
    required this.id,
    required this.name,
    required this.userId,
    this.chicken,
    this.egg,
    List<Customer>? customers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : customers = customers ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Firebase serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'chicken': chicken != null
          ? {
              'id': chicken!.id,
              'totalCount': chicken!.totalCount,
              'currentCount': chicken!.currentCount,
              // Boshqa chicken ma'lumotlari qo'shing
            }
          : null,
      'egg': egg != null
          ? {
              'id': egg!.id,
              'currentStock': egg!.currentStock,
              // Boshqa egg ma'lumotlari qo'shing
            }
          : null,
      'customers': customers.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Firebase deserialization
  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      chicken: json['chicken'] != null
          ? Chicken(
              id: json['chicken']['id'] ?? '${json['id']}_chicken',
              totalCount: json['chicken']['totalCount'] ?? 0,
              deaths:
                  (json['chicken']['deaths'] as List<dynamic>?)
                      ?.map(
                        (death) => ChickenDeath.fromJson(
                          death as Map<String, dynamic>,
                        ),
                      )
                      .toList() ??
                  [],
              createdAt: _parseDate(json['chicken']['createdAt']),
              updatedAt: _parseDate(json['chicken']['updatedAt']),
            )
          : null,
      egg: json['egg'] != null
          ? Egg(
              id: json['egg']['id'] ?? '${json['id']}_egg',
              production:
                  (json['egg']['production'] as List<dynamic>?)
                      ?.map(
                        (prod) => EggProduction.fromJson(
                          prod as Map<String, dynamic>,
                        ),
                      )
                      .toList() ??
                  [],
              sales:
                  (json['egg']['sales'] as List<dynamic>?)
                      ?.map(
                        (sale) =>
                            EggSale.fromJson(sale as Map<String, dynamic>),
                      )
                      .toList() ??
                  [],
              brokenEggs:
                  (json['egg']['brokenEggs'] as List<dynamic>?)
                      ?.map(
                        (broken) =>
                            BrokenEgg.fromJson(broken as Map<String, dynamic>),
                      )
                      .toList() ??
                  [],
              largeEggs:
                  (json['egg']['largeEggs'] as List<dynamic>?)
                      ?.map(
                        (large) =>
                            LargeEgg.fromJson(large as Map<String, dynamic>),
                      )
                      .toList() ??
                  [],
              createdAt: _parseDate(json['egg']['createdAt']),
              updatedAt: _parseDate(json['egg']['updatedAt']),
            )
          : null,
      customers:
          (json['customers'] as List<dynamic>?)
              ?.map((c) => Customer.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  // Farm statistikalari
  Map<String, dynamic> get farmStats {
    final stats = <String, dynamic>{};

    // Tovuqlar
    if (chicken != null) {
      stats['totalChickens'] = chicken!.totalCount;
      stats['currentChickens'] = chicken!.currentCount;
      stats['totalDeaths'] = chicken!.totalCount - chicken!.currentCount;
    } else {
      stats['totalChickens'] = 0;
      stats['currentChickens'] = 0;
      stats['totalDeaths'] = 0;
    }

    // Tuxumlar
    if (egg != null) {
      stats['totalProduction'] = egg!.productionStats['totalProduction'] ?? 0;
      stats['currentStock'] = egg!.currentStock;
      stats['totalSales'] = egg!.sales.length;
      stats['todayEggs'] = egg!.todayProduction;
    } else {
      stats['totalProduction'] = 0;
      stats['currentStock'] = 0;
      stats['totalSales'] = 0;
      stats['todayEggs'] = 0;
    }

    // Mijozlar
    stats['totalCustomers'] = customers.length;
    stats['totalDebt'] = customers.fold<double>(
      0.0,
      (sum, customer) => sum + customer.totalDebt,
    );

    // Kelgusi yetkazib berishlar
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    stats['upcomingDeliveries'] = customers
        .expand((customer) => customer.orders)
        .where((order) => _isSameDay(order.deliveryDate, tomorrow))
        .length;

    return stats;
  }

  // Bugungi faoliyat
  Map<String, dynamic> get todayActivity {
    final activity = <String, dynamic>{};

    // Bugungi tovuq o'limlari
    activity['chickenDeaths'] = chicken?.todayDeaths ?? 0;

    // Bugungi tuxum ishlab chiqarish
    activity['todayProduction'] = egg?.todayProduction ?? 0;

    // Bugungi sotuvlar
    activity['eggSales'] = egg?.todaySales ?? 0;

    // Bugungi siniq tuxumlar
    activity['brokenEggs'] = egg?.todayBroken ?? 0;

    // Bugungi katta tuxumlar
    activity['largeEggs'] = egg?.todayLarge ?? 0;

    // Ertangi yetkazib berishlar
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    activity['tomorrowDeliveries'] = customers
        .expand((customer) => customer.orders)
        .where((order) => _isSameDay(order.deliveryDate, tomorrow))
        .length;

    return activity;
  }

  // Kun solishtirish helper metodi
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Tovuq qo'shish
  void addChickens(int count) {
    if (count <= 0)
      throw ArgumentError('Tovuq soni 0 dan katta bo\'lishi kerak');

    if (chicken == null) {
      chicken = Chicken(id: '${id}_chicken', totalCount: count);
    } else {
      chicken!.totalCount += count;
    }
    _updateTimestamp();
  }

  // Tovuq o'limi kiritish
  void addChickenDeath(int count, {String? note}) {
    if (count <= 0)
      throw ArgumentError('O\'lim soni 0 dan katta bo\'lishi kerak');

    if (chicken == null) {
      throw StateError('Tovuqlar mavjud emas');
    }

    // Joriy sonidan ko'p o'lim kiritishni bloklash
    final remaining = chicken!.currentCount;
    if (count > remaining) {
      throw StateError('Tovuqlar soni yetarli emas');
    }

    // Chicken klassida addDeath metodini chaqiramiz
    chicken!.addDeath(count);
    _updateTimestamp();
  }

  // Tuxum ishlab chiqarish qo'shish
  void addEggProduction(int trayCount, {String? note}) {
    if (trayCount <= 0)
      throw ArgumentError('Tray soni 0 dan katta bo\'lishi kerak');

    if (egg == null) {
      egg = Egg(id: '${id}_egg');
    }

    egg!.addProduction(trayCount, note: note);
    _updateTimestamp();
  }

  // Tuxum sotuvi qo'shish
  void addEggSale(int trayCount, double pricePerTray, {String? note}) {
    if (trayCount <= 0)
      throw ArgumentError('Tray soni 0 dan katta bo\'lishi kerak');
    if (pricePerTray < 0)
      throw ArgumentError('Narx manfiy bo\'lishi mumkin emas');

    if (egg == null) {
      throw StateError('Tuxum mavjud emas, avval ishlab chiqarish qo\'shing');
    }

    egg!.addSale(trayCount, pricePerTray, note: note);
    _updateTimestamp();
  }

  // Siniq tuxum qo'shish
  void addBrokenEgg(int trayCount, {String? note}) {
    if (trayCount <= 0)
      throw ArgumentError('Siniq tuxum soni 0 dan katta bo\'lishi kerak');

    if (egg == null) {
      throw StateError('Tuxum mavjud emas');
    }

    egg!.addBroken(trayCount, note: note);
    _updateTimestamp();
  }

  // Katta tuxum qo'shish
  void addLargeEgg(int trayCount, {String? note}) {
    if (trayCount <= 0)
      throw ArgumentError('Katta tuxum soni 0 dan katta bo\'lishi kerak');

    if (egg == null) {
      egg = Egg(id: '${id}_egg');
    }

    egg!.addLarge(trayCount, note: note);
    _updateTimestamp();
  }

  // Mijoz qo'shish
  void addCustomer(String name, {String? phone, String? address}) {
    if (name.trim().isEmpty)
      throw ArgumentError('Mijoz nomi bo\'sh bo\'lishi mumkin emas');

    final customer = Customer(
      id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      phone: phone?.trim() ?? '',
      address: address?.trim() ?? '',
      orders: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    customers.add(customer);
    _updateTimestamp();
  }

  // Mijoz o'chirish
  void removeCustomer(String customerId) {
    if (customerId.isEmpty)
      throw ArgumentError('Mijoz ID bo\'sh bo\'lishi mumkin emas');

    final initialLength = customers.length;
    customers.removeWhere((customer) => customer.id == customerId);

    if (customers.length == initialLength) {
      throw StateError('Mijoz topilmadi');
    }

    _updateTimestamp();
  }

  // Mijoz topish
  Customer? findCustomer(String customerId) {
    if (customerId.isEmpty) return null;

    try {
      return customers.firstWhere((customer) => customer.id == customerId);
    } catch (e) {
      return null;
    }
  }

  // Mijoz buyurtmasi qo'shish
  void addCustomerOrder(
    String customerId,
    int trayCount,
    double pricePerTray,
    DateTime deliveryDate, {
    String? note,
  }) {
    if (trayCount <= 0)
      throw ArgumentError('Tray soni 0 dan katta bo\'lishi kerak');
    if (pricePerTray < 0)
      throw ArgumentError('Narx manfiy bo\'lishi mumkin emas');

    // Delivery date ni bugungi kun bilan solishtirish (vaqt hisobga olinmaydi)
    final today = DateTime.now();
    final deliveryDateOnly = DateTime(
      deliveryDate.year,
      deliveryDate.month,
      deliveryDate.day,
    );
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (deliveryDateOnly.isBefore(todayOnly)) {
      throw ArgumentError(
        'Yetkazib berish sanasi o\'tmishda bo\'lishi mumkin emas',
      );
    }

    final customer = findCustomer(customerId);
    if (customer == null) throw StateError('Mijoz topilmadi');

    customer.addOrder(trayCount, pricePerTray, deliveryDate, note: note);
    _updateTimestamp();
  }

  // Mijoz buyurtmasini to'landi deb belgilash
  void markCustomerOrderAsPaid(String customerId, String orderId) {
    if (orderId.trim().isEmpty)
      throw ArgumentError('Buyurtma ID bo\'sh bo\'lishi mumkin emas');

    final customer = findCustomer(customerId);
    if (customer == null) throw StateError('Mijoz topilmadi');

    customer.markOrderAsPaid(orderId);
    _updateTimestamp();
  }

  // Mijoz ma'lumotlarini yangilash
  void updateCustomerInfo(
    String customerId, {
    String? name,
    String? phone,
    String? address,
  }) {
    final customer = findCustomer(customerId);
    if (customer == null) throw StateError('Mijoz topilmadi');

    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Mijoz nomi bo\'sh bo\'lishi mumkin emas');
    }

    customer.updateInfo(
      name: name?.trim(),
      phone: phone?.trim(),
      address: address?.trim(),
    );
    _updateTimestamp();
  }

  // Private helper method for updating timestamp
  void _updateTimestamp() {
    updatedAt = DateTime.now();
    // Agar obyekt Hive box ichida bo'lsa, saqlaymiz. Aks holda, provider keyinroq saqlaydi.
    if (isInBox) {
      save(); // HiveObject dan meros olgan save() metodini chaqirish
    }
  }

  // toString method for debugging
  @override
  String toString() {
    return 'Farm(id: $id, name: $name, userId: $userId, customers: ${customers.length})';
  }

  // Equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Farm && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
