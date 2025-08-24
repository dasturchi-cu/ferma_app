import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'customer.g.dart';

DateTime _parseDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is Timestamp) return v.toDate();
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) {
    final asInt = int.tryParse(v);
    if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
    try { return DateTime.parse(v); } catch (_) {}
  }
  return DateTime.now();
}

@HiveType(typeId: 7)
class Customer extends HiveObject {
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
  })  : orders = orders ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

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
        .where((order) => order.deliveryDate.year == today.year &&
            order.deliveryDate.month == today.month &&
            order.deliveryDate.day == today.day)
        .toList();
  }

  // Ertangi buyurtmalar
  List<CustomerOrder> get tomorrowOrders {
    DateTime tomorrow = DateTime.now().add(Duration(days: 1));
    return orders
        .where((order) => order.deliveryDate.year == tomorrow.year &&
            order.deliveryDate.month == tomorrow.month &&
            order.deliveryDate.day == tomorrow.day)
        .toList();
  }

  // Kelgusi hafta buyurtmalari
  List<CustomerOrder> get upcomingOrders {
    DateTime now = DateTime.now();
    DateTime weekLater = now.add(Duration(days: 7));
    return orders
        .where((order) => order.deliveryDate.isAfter(now) &&
            order.deliveryDate.isBefore(weekLater))
        .toList();
  }

  // Buyurtma qo'shish
  void addOrder(int trayCount, double pricePerTray, DateTime deliveryDate, {String? note}) {
    orders.add(CustomerOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      trayCount: trayCount,
      pricePerTray: pricePerTray,
      deliveryDate: deliveryDate,
      note: note,
    ));
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

  // Firebase serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'orders': orders.map((order) => order.toJson()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Firebase deserialization
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      orders: (json['orders'] as List<dynamic>?)
          ?.map((order) => CustomerOrder.fromJson(order as Map<String, dynamic>))
          .toList() ??
          [],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

@HiveType(typeId: 8)
class CustomerOrder extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int trayCount;

  @HiveField(2)
  double pricePerTray;

  @HiveField(3)
  DateTime deliveryDate;

  @HiveField(4)
  bool isPaid;

  @HiveField(5)
  DateTime? paidAt;

  @HiveField(6)
  String? note;

  @HiveField(7)
  DateTime createdAt;

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

  // Umumiy summa
  double get totalAmount => trayCount * pricePerTray;

  // Yetkazib berish muddati keldimi?
  bool get isDeliveryDue {
    return DateTime.now().isAfter(deliveryDate);
  }

  // Yetkazib berish muddatiga qancha qoldi?
  Duration get timeUntilDelivery {
    return deliveryDate.difference(DateTime.now());
  }

  // Ertangi yetkazib berish?
  bool get isTomorrowDelivery {
    DateTime tomorrow = DateTime.now().add(Duration(days: 1));
    return deliveryDate.year == tomorrow.year &&
        deliveryDate.month == tomorrow.month &&
        deliveryDate.day == tomorrow.day;
  }

  // Firebase serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trayCount': trayCount,
      'pricePerTray': pricePerTray,
      'deliveryDate': deliveryDate.millisecondsSinceEpoch,
      'isPaid': isPaid,
      'paidAt': paidAt?.millisecondsSinceEpoch,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Firebase deserialization
  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    return CustomerOrder(
      id: json['id'] as String? ?? '',
      trayCount: json['trayCount'] as int? ?? 0,
      pricePerTray: (json['pricePerTray'] as num?)?.toDouble() ?? 0.0,
      deliveryDate: _parseDate(json['deliveryDate']),
      isPaid: json['isPaid'] as bool? ?? false,
      paidAt: json['paidAt'] != null ? _parseDate(json['paidAt']) : null,
      note: json['note'] as String?,
      createdAt: _parseDate(json['createdAt']),
    );
  }
} 