import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../utils/uuid_generator.dart';

part 'customer.g.dart';

DateTime _parseDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) {
    final asInt = int.tryParse(v);
    if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
    try {
      return DateTime.parse(v);
    } catch (_) {}
  }
  return DateTime.now();
}

@HiveType(typeId: 7)
@JsonSerializable()
class Customer {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String address;

  @HiveField(4)
  List<CustomerOrder> orders;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    List<CustomerOrder>? orders,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : orders = orders ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Customer.fromJson(Map<String, dynamic> json) {
    final created = json.containsKey('createdAt')
        ? json['createdAt']
        : json['created_at'];
    final updated = json.containsKey('updatedAt')
        ? json['updatedAt']
        : json['updated_at'];

    final dynamic ordersRaw = json['orders'];
    final List<CustomerOrder> parsedOrders = ordersRaw is List
        ? ordersRaw
              .whereType<Map<String, dynamic>>()
              .map((e) => CustomerOrder.fromJson(e))
              .toList()
        : <CustomerOrder>[];

    return Customer(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      orders: parsedOrders,
      createdAt: _parseDate(created),
      updatedAt: _parseDate(updated),
    );
  }

  Map<String, dynamic> toJson() => _$CustomerToJson(this);

  // Umumiy qarzdorlik
  double get totalDebt {
    return orders
        .where((order) => !order.isPaid)
        .fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  // Bugungi buyurtmalar
  List<CustomerOrder> get todayOrders {
    DateTime today = DateTime.now();
    return orders
        .where(
          (order) =>
              order.deliveryDate.year == today.year &&
              order.deliveryDate.month == today.month &&
              order.deliveryDate.day == today.day,
        )
        .toList();
  }

  // Ertangi buyurtmalar
  List<CustomerOrder> get tomorrowOrders {
    DateTime tomorrow = DateTime.now().add(Duration(days: 1));
    return orders
        .where(
          (order) =>
              order.deliveryDate.year == tomorrow.year &&
              order.deliveryDate.month == tomorrow.month &&
              order.deliveryDate.day == tomorrow.day,
        )
        .toList();
  }

  // Kelgusi hafta buyurtmalari
  List<CustomerOrder> get upcomingOrders {
    DateTime now = DateTime.now();
    DateTime weekLater = now.add(Duration(days: 7));
    return orders
        .where(
          (order) =>
              order.deliveryDate.isAfter(now) &&
              order.deliveryDate.isBefore(weekLater),
        )
        .toList();
  }

  // Buyurtma qo'shish
  void addOrder(
    int trayCount,
    double pricePerTray,
    DateTime deliveryDate, {
    String? note,
  }) {
    orders.add(
      CustomerOrder(
        id: UuidGenerator.generateUuid(),
        trayCount: trayCount,
        pricePerTray: pricePerTray,
        deliveryDate: deliveryDate,
        note: note,
      ),
    );
    updatedAt = DateTime.now();
  }

  // To'lov qilish
  void markOrderAsPaid(String orderId) {
    final orderIndex = orders.indexWhere((order) => order.id == orderId);
    if (orderIndex != -1) {
      orders[orderIndex].isPaid = true;
      orders[orderIndex].paidAt = DateTime.now();
      updatedAt = DateTime.now();
    }
  }

  // Buyurtmani o'chirish
  void removeOrder(String orderId) {
    orders.removeWhere((order) => order.id == orderId);
    updatedAt = DateTime.now();
  }

  // Mijoz ma'lumotlarini yangilash
  void updateInfo({String? name, String? phone, String? address}) {
    if (name != null) this.name = name;
    if (phone != null) this.phone = phone;
    if (address != null) this.address = address;
    updatedAt = DateTime.now();
  }

  // Copy with method for immutable updates
  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    List<CustomerOrder>? orders,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      orders: orders ?? List.from(this.orders),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@HiveType(typeId: 8)
@JsonSerializable()
class CustomerOrder {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int trayCount;

  @HiveField(2)
  final double pricePerTray;

  @HiveField(3)
  final DateTime deliveryDate;

  @HiveField(4)
  bool isPaid;

  @HiveField(5)
  DateTime? paidAt;

  @HiveField(6)
  final String? note;

  @HiveField(7)
  final DateTime createdAt;

  CustomerOrder({
    required this.id,
    required this.trayCount,
    required this.pricePerTray,
    required this.deliveryDate,
    this.isPaid = false,
    this.paidAt,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    int _readInt(dynamic v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    double _readDouble(dynamic v, {double fallback = 0.0}) {
      if (v == null) return fallback;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    bool _readBool(dynamic v, {bool fallback = false}) {
      if (v == null) return fallback;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase();
        if (s == 'true' || s == '1' || s == 'yes') return true;
        if (s == 'false' || s == '0' || s == 'no') return false;
      }
      return fallback;
    }

    final tray = json.containsKey('trayCount')
        ? json['trayCount']
        : json['tray_count'];
    final price = json.containsKey('pricePerTray')
        ? json['pricePerTray']
        : json['price_per_tray'];
    final delivery = json.containsKey('deliveryDate')
        ? json['deliveryDate']
        : json['delivery_date'];
    final paid = json.containsKey('isPaid') ? json['isPaid'] : json['is_paid'];
    final paidAt = json.containsKey('paidAt')
        ? json['paidAt']
        : json['paid_at'];
    final created = json.containsKey('createdAt')
        ? json['createdAt']
        : json['created_at'];

    return CustomerOrder(
      id: (json['id'] as String?) ?? UuidGenerator.generateUuid(),
      trayCount: _readInt(tray),
      pricePerTray: _readDouble(price),
      deliveryDate: _parseDate(delivery),
      isPaid: _readBool(paid),
      paidAt: paidAt == null ? null : _parseDate(paidAt),
      note: json['note'] as String?,
      createdAt: _parseDate(created),
    );
  }

  Map<String, dynamic> toJson() => _$CustomerOrderToJson(this);

  // Umumiy summa
  double get totalAmount => trayCount * pricePerTray;

  // Yetkazib berish muddati keldimi?
  bool get isDeliveryDue => DateTime.now().isAfter(deliveryDate);

  // Yetkazib berish muddatiga qancha qoldi?
  Duration get timeUntilDelivery => deliveryDate.difference(DateTime.now());

  // Ertangi yetkazib berish?
  bool get isTomorrowDelivery {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return deliveryDate.year == tomorrow.year &&
        deliveryDate.month == tomorrow.month &&
        deliveryDate.day == tomorrow.day;
  }

  // Copy with method for immutable updates
  CustomerOrder copyWith({
    String? id,
    int? trayCount,
    double? pricePerTray,
    DateTime? deliveryDate,
    bool? isPaid,
    DateTime? paidAt,
    String? note,
    DateTime? createdAt,
  }) {
    return CustomerOrder(
      id: id ?? this.id,
      trayCount: trayCount ?? this.trayCount,
      pricePerTray: pricePerTray ?? this.pricePerTray,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
