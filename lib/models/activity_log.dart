import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity_log.g.dart';

@HiveType(typeId: 9)
@JsonSerializable()
class ActivityLog {
  @HiveField(0)
  String id;

  @HiveField(1)
  String farmId;

  @HiveField(2)
  ActivityType type;

  @HiveField(3)
  String title;

  @HiveField(4)
  String description;

  @HiveField(5)
  Map<String, dynamic> metadata;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  ActivityImportance importance;

  ActivityLog({
    required this.id,
    required this.farmId,
    required this.type,
    required this.title,
    required this.description,
    this.metadata = const {},
    DateTime? createdAt,
    this.importance = ActivityImportance.normal,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ActivityLog.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityLogToJson(this);

  // Quick constructor methods
  factory ActivityLog.eggProduction({
    required String farmId,
    required int trayCount,
  }) {
    return ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      farmId: farmId,
      type: ActivityType.eggProduction,
      title: 'Tuxum ishlab chiqarish',
      description: '$trayCount ta fletka tuxum ishlab chiqarildi',
      metadata: {'trayCount': trayCount},
      importance: ActivityImportance.high,
    );
  }

  factory ActivityLog.eggSale({
    required String farmId,
    required int trayCount,
    required double pricePerTray,
    String? customerName,
  }) {
    return ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      farmId: farmId,
      type: ActivityType.eggSale,
      title: 'Tuxum sotildi',
      description: customerName != null
          ? '$customerName ga $trayCount ta fletka sotildi'
          : '$trayCount ta fletka tuxum sotildi',
      metadata: {
        'trayCount': trayCount,
        'pricePerTray': pricePerTray,
        'customerName': customerName,
      },
      importance: ActivityImportance.high,
    );
  }

  factory ActivityLog.customerAdded({
    required String farmId,
    required String customerName,
  }) {
    return ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      farmId: farmId,
      type: ActivityType.customerAdded,
      title: 'Yangi mijoz',
      description: '$customerName mijoz qo\'shildi',
      metadata: {'customerName': customerName},
      importance: ActivityImportance.normal,
    );
  }

  factory ActivityLog.debtAdded({
    required String farmId,
    required String customerName,
    required double amount,
  }) {
    return ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      farmId: farmId,
      type: ActivityType.debtAdded,
      title: 'Qarz qo\'shildi',
      description: '$customerName ga ${amount.toStringAsFixed(0)} so\'m qarz qo\'shildi',
      metadata: {'customerName': customerName, 'amount': amount},
      importance: ActivityImportance.high,
    );
  }

  factory ActivityLog.chickenAdded({
    required String farmId,
    required int count,
  }) {
    return ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      farmId: farmId,
      type: ActivityType.chickenAdded,
      title: 'Tovuq qo\'shildi',
      description: '$count ta tovuq qo\'shildi',
      metadata: {'count': count},
      importance: ActivityImportance.normal,
    );
  }

  factory ActivityLog.chickenDeath({
    required String farmId,
    required int count,
    String? reason,
  }) {
    return ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      farmId: farmId,
      type: ActivityType.chickenDeath,
      title: 'Tovuq o\'limi',
      description: '$count ta tovuq o\'ldi${reason != null ? ' ($reason)' : ''}',
      metadata: {'count': count, 'reason': reason},
      importance: ActivityImportance.high,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Hozir';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} daqiqa oldin';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} soat oldin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} kun oldin';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}

@HiveType(typeId: 10)
enum ActivityType {
  @HiveField(0)
  eggProduction,
  
  @HiveField(1)
  eggSale,
  
  @HiveField(2)
  customerAdded,
  
  @HiveField(3)
  debtAdded,
  
  @HiveField(4)
  debtPaid,
  
  @HiveField(5)
  chickenAdded,
  
  @HiveField(6)
  chickenDeath,
  
  @HiveField(7)
  brokenEggs,
  
  @HiveField(8)
  largeEggs,
  
  @HiveField(9)
  other,
}

@HiveType(typeId: 11)
enum ActivityImportance {
  @HiveField(0)
  low,
  
  @HiveField(1)
  normal,
  
  @HiveField(2)
  high,
  
  @HiveField(3)
  critical,
}

extension ActivityTypeExtension on ActivityType {
  String get displayName {
    switch (this) {
      case ActivityType.eggProduction:
        return 'Tuxum ishlab chiqarish';
      case ActivityType.eggSale:
        return 'Tuxum sotildi';
      case ActivityType.customerAdded:
        return 'Mijoz qo\'shildi';
      case ActivityType.debtAdded:
        return 'Qarz qo\'shildi';
      case ActivityType.debtPaid:
        return 'Qarz to\'landi';
      case ActivityType.chickenAdded:
        return 'Tovuq qo\'shildi';
      case ActivityType.chickenDeath:
        return 'Tovuq o\'limi';
      case ActivityType.brokenEggs:
        return 'Singan tuxumlar';
      case ActivityType.largeEggs:
        return 'Katta tuxumlar';
      case ActivityType.other:
        return 'Boshqa';
    }
  }

  String get icon {
    switch (this) {
      case ActivityType.eggProduction:
        return '🥚';
      case ActivityType.eggSale:
        return '💰';
      case ActivityType.customerAdded:
        return '👤';
      case ActivityType.debtAdded:
        return '💳';
      case ActivityType.debtPaid:
        return '✅';
      case ActivityType.chickenAdded:
        return '🐓';
      case ActivityType.chickenDeath:
        return '💔';
      case ActivityType.brokenEggs:
        return '💥';
      case ActivityType.largeEggs:
        return '🥇';
      case ActivityType.other:
        return '📝';
    }
  }
}