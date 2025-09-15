import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'customer.dart';
import 'chicken.dart';
import 'egg.dart';
import '../utils/uuid_generator.dart';

part 'farm.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class Farm {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String? address;

  @HiveField(4)
  @JsonKey(name: 'owner_id')
  final String ownerId;

  @HiveField(5)
  @JsonKey(name: 'chicken_count')
  int chickenCount;

  @HiveField(6)
  @JsonKey(name: 'egg_production_rate')
  final int eggProductionRate;

  @HiveField(7)
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @HiveField(8)
  @JsonKey(name: 'updated_at')
  DateTime? updatedAt;

  @HiveField(9)
  final Chicken? chicken;

  @HiveField(10)
  final Egg? egg;

  @HiveField(11)
  final List<Customer> customers;

  Farm({
    required this.id,
    required this.name,
    this.description,
    this.address,
    required this.ownerId,
    this.chickenCount = 0,
    this.eggProductionRate = 0,
    this.chicken,
    this.egg,
    List<Customer>? customers,
    this.createdAt,
    this.updatedAt,
  }) : customers = customers ?? [];

  factory Farm.fromJson(Map<String, dynamic> json) => _$FarmFromJson(json);

  Map<String, dynamic> toJson() => _$FarmToJson(this);

  // For backward compatibility
  String get userId => ownerId;

  Farm copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? ownerId,
    int? chickenCount,
    int? eggProductionRate,
    Chicken? chicken,
    Egg? egg,
    List<Customer>? customers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Farm(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      ownerId: ownerId ?? this.ownerId,
      chickenCount: chickenCount ?? this.chickenCount,
      eggProductionRate: eggProductionRate ?? this.eggProductionRate,
      chicken: chicken ?? this.chicken,
      egg: egg ?? this.egg,
      customers: customers ?? List.from(this.customers),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Farm(id: $id, name: $name, ownerId: $ownerId, chickenCount: $chickenCount)';
  }

  // Chicken management methods
  void addChickens(int count) {
    chickenCount += count;
    if (chicken != null) {
      chicken!.totalCount += count;
      chicken!.updatedAt = DateTime.now();
    }
    updatedAt = DateTime.now();
  }

  void addChickenDeath(int count) {
    if (chicken != null) {
      chicken!.addDeath(count);
      updatedAt = DateTime.now();
    }
  }

  // Egg management methods
  void addEggProduction(int trayCount, {String? note}) {
    if (egg != null) {
      egg!.addProduction(trayCount, note: note);
      updatedAt = DateTime.now();
    }
  }

  void addEggSale(int trayCount, double pricePerTray, {String? note}) {
    if (egg != null) {
      egg!.addSale(trayCount, pricePerTray, note: note);
      updatedAt = DateTime.now();
    }
  }

  void addBrokenEgg(int trayCount, {String? note}) {
    if (egg != null) {
      egg!.addBroken(trayCount, note: note);
      updatedAt = DateTime.now();
    }
  }

  void addLargeEgg(int trayCount, {String? note}) {
    if (egg != null) {
      egg!.addLarge(trayCount, note: note);
      updatedAt = DateTime.now();
    }
  }

  // Customer management methods
  void addCustomer(String name, {String? phone, String? address}) {
    // Generate a proper UUID
    final customerId = UuidGenerator.generateUuid();
    
    final customer = Customer(
      id: customerId,
      name: name,
      phone: phone ?? '',
      address: address ?? '',
    );
    customers.add(customer);
    updatedAt = DateTime.now();
  }

  void removeCustomer(String customerId) {
    customers.removeWhere((customer) => customer.id == customerId);
    updatedAt = DateTime.now();
  }

  Customer? findCustomer(String customerId) {
    try {
      return customers.firstWhere((customer) => customer.id == customerId);
    } catch (e) {
      return null;
    }
  }

  void addCustomerOrder(
    String customerId,
    int trayCount,
    double pricePerTray,
    DateTime deliveryDate, {
    String? note,
  }) {
    final customer = findCustomer(customerId);
    if (customer != null) {
      customer.addOrder(trayCount, pricePerTray, deliveryDate, note: note);
      updatedAt = DateTime.now();
    }
  }

  void markCustomerOrderAsPaid(String customerId, String orderId) {
    final customer = findCustomer(customerId);
    if (customer != null) {
      customer.markOrderAsPaid(orderId);
      updatedAt = DateTime.now();
    }
  }

  void removeCustomerOrder(String customerId, String orderId) {
    final customer = findCustomer(customerId);
    if (customer != null) {
      customer.removeOrder(orderId);
      updatedAt = DateTime.now();
    }
  }

  void updateCustomerInfo(
    String customerId, {
    String? name,
    String? phone,
    String? address,
  }) {
    final customer = findCustomer(customerId);
    if (customer != null) {
      customer.updateInfo(name: name, phone: phone, address: address);
      updatedAt = DateTime.now();
    }
  }

  // Farm statistics
  Map<String, dynamic> get farmStats {
    int totalEggs =
        egg?.production.fold<int>(
          0,
          (sum, prod) => sum + (prod.trayCount ?? 0),
        ) ??
        0;
    int totalChickens = chicken?.totalCount ?? 0;
    int currentStock = egg?.currentStock ?? 0;
    double averageEggs = egg?.productionDailyAverageLastNDays(30) ?? 0.0;
    return {
      'totalEggs': totalEggs,
      'totalChickens': totalChickens,
      'currentStock': currentStock,
      'averageEggs': averageEggs,
      'monthlyProfit': 0.0, // Placeholder
      'weeklyDeaths':
          chicken?.deaths.fold<int>(
            0,
            (sum, death) => sum + (death.count ?? 0),
          ) ??
          0,
      'monthlyDeaths':
          chicken?.deaths.fold<int>(
            0,
            (sum, death) => sum + (death.count ?? 0),
          ) ??
          0,
      'weeklyEggs': [], // Placeholder
      'maxEggsInDay': 0, // Placeholder
      'healthyDays': 0, // Placeholder
      'consecutiveDays': 1, // Placeholder
      'totalPoints': 0, // Placeholder
    };
  }

  // Today's activity
  Map<String, dynamic> get todayActivity {
    DateTime today = DateTime.now();
    int eggsCollected =
        egg?.production
            .where(
              (prod) =>
                  prod.date.year == today.year &&
                  prod.date.month == today.month &&
                  prod.date.day == today.day,
            )
            .fold<int>(0, (sum, prod) => sum + (prod.trayCount ?? 0)) ??
        0;
    int chickenDeaths =
        chicken?.deaths
            .where(
              (death) =>
                  death.date.year == today.year &&
                  death.date.month == today.month &&
                  death.date.day == today.day,
            )
            .fold<int>(0, (sum, death) => sum + (death.count ?? 0)) ??
        0;
    return {
      'eggsCollected': eggsCollected,
      'chickenDeaths': chickenDeaths,
      'weather': '', // Placeholder
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Farm &&
        other.id == id &&
        other.name == name &&
        other.ownerId == ownerId;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ ownerId.hashCode;
}
