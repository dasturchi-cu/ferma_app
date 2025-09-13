import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity.g.dart';

@HiveType(typeId: 15)
@JsonSerializable()
class Activity {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String farmId;

  @HiveField(2)
  final ActivityType type;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final int quantity;

  @HiveField(6)
  final double? amount;

  @HiveField(7)
  final DateTime timestamp;

  @HiveField(8)
  final String? note;

  @HiveField(9)
  final Map<String, dynamic>? metadata;

  Activity({
    required this.id,
    required this.farmId,
    required this.type,
    required this.title,
    required this.description,
    required this.quantity,
    this.amount,
    required this.timestamp,
    this.note,
    this.metadata,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => _$ActivityFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityToJson(this);

  // Helper constructors for common activities
  factory Activity.eggProduction({
    required String farmId,
    required int trays,
    String? note,
  }) {
    return Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      farmId: farmId,
      type: ActivityType.eggProduction,
      title: 'Tuxum Yig\'ildi',
      description: '$trays fletka tuxum ishlab chiqarildi',
      quantity: trays,
      timestamp: DateTime.now(),
      note: note,
    );
  }

  factory Activity.eggSale({
    required String farmId,
    required int trays,
    required double totalAmount,
    String? note,
  }) {
    return Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      farmId: farmId,
      type: ActivityType.eggSale,
      title: 'Tuxum Sotildi',
      description: '$trays fletka tuxum sotildi',
      quantity: trays,
      amount: totalAmount,
      timestamp: DateTime.now(),
      note: note,
    );
  }

  factory Activity.chickenAdded({
    required String farmId,
    required int count,
    String? note,
  }) {
    return Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      farmId: farmId,
      type: ActivityType.chickenAdded,
      title: 'Tovuq Qo\'shildi',
      description: '$count ta tovuq qo\'shildi',
      quantity: count,
      timestamp: DateTime.now(),
      note: note,
    );
  }

  factory Activity.chickenDeath({
    required String farmId,
    required int count,
    String? note,
  }) {
    return Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      farmId: farmId,
      type: ActivityType.chickenDeath,
      title: 'Tovuq O\'limi',
      description: '$count ta tovuq o\'limi qayd qilindi',
      quantity: count,
      timestamp: DateTime.now(),
      note: note,
    );
  }

  factory Activity.customerAdded({
    required String farmId,
    required String customerName,
    String? note,
  }) {
    return Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      farmId: farmId,
      type: ActivityType.customerAdded,
      title: 'Mijoz Qo\'shildi',
      description: '$customerName mijoz qo\'shildi',
      quantity: 1,
      timestamp: DateTime.now(),
      note: note,
    );
  }

  factory Activity.orderPaid({
    required String farmId,
    required String customerName,
    required double amount,
    String? note,
  }) {
    return Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      farmId: farmId,
      type: ActivityType.orderPaid,
      title: 'Buyurtma To\'landi',
      description: '$customerName buyurtmasini to\'ladi',
      quantity: 1,
      amount: amount,
      timestamp: DateTime.now(),
      note: note,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return 'Hozir';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} daqiqa oldin';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} soat oldin';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} kun oldin';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }
  }
}

@HiveType(typeId: 16)
enum ActivityType {
  @HiveField(0)
  eggProduction,
  
  @HiveField(1)
  eggSale,
  
  @HiveField(2)
  chickenAdded,
  
  @HiveField(3)
  chickenDeath,
  
  @HiveField(4)
  customerAdded,
  
  @HiveField(5)
  orderPaid,
  
  @HiveField(6)
  brokenEgg,
  
  @HiveField(7)
  largeEgg,
}