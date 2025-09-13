// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityLogAdapter extends TypeAdapter<ActivityLog> {
  @override
  final int typeId = 9;

  @override
  ActivityLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityLog(
      id: fields[0] as String,
      farmId: fields[1] as String,
      type: fields[2] as ActivityType,
      title: fields[3] as String,
      description: fields[4] as String,
      metadata: Map<String, dynamic>.from(fields[5] as Map),
      createdAt: fields[6] as DateTime,
      importance: fields[7] as ActivityImportance,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityLog obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.farmId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.metadata)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.importance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActivityTypeAdapter extends TypeAdapter<ActivityType> {
  @override
  final int typeId = 10;

  @override
  ActivityType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActivityType.eggProduction;
      case 1:
        return ActivityType.eggSale;
      case 2:
        return ActivityType.customerAdded;
      case 3:
        return ActivityType.debtAdded;
      case 4:
        return ActivityType.debtPaid;
      case 5:
        return ActivityType.chickenAdded;
      case 6:
        return ActivityType.chickenDeath;
      case 7:
        return ActivityType.brokenEggs;
      case 8:
        return ActivityType.largeEggs;
      case 9:
        return ActivityType.other;
      default:
        return ActivityType.other;
    }
  }

  @override
  void write(BinaryWriter writer, ActivityType obj) {
    switch (obj) {
      case ActivityType.eggProduction:
        writer.writeByte(0);
        break;
      case ActivityType.eggSale:
        writer.writeByte(1);
        break;
      case ActivityType.customerAdded:
        writer.writeByte(2);
        break;
      case ActivityType.debtAdded:
        writer.writeByte(3);
        break;
      case ActivityType.debtPaid:
        writer.writeByte(4);
        break;
      case ActivityType.chickenAdded:
        writer.writeByte(5);
        break;
      case ActivityType.chickenDeath:
        writer.writeByte(6);
        break;
      case ActivityType.brokenEggs:
        writer.writeByte(7);
        break;
      case ActivityType.largeEggs:
        writer.writeByte(8);
        break;
      case ActivityType.other:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActivityImportanceAdapter extends TypeAdapter<ActivityImportance> {
  @override
  final int typeId = 11;

  @override
  ActivityImportance read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActivityImportance.low;
      case 1:
        return ActivityImportance.normal;
      case 2:
        return ActivityImportance.high;
      case 3:
        return ActivityImportance.critical;
      default:
        return ActivityImportance.normal;
    }
  }

  @override
  void write(BinaryWriter writer, ActivityImportance obj) {
    switch (obj) {
      case ActivityImportance.low:
        writer.writeByte(0);
        break;
      case ActivityImportance.normal:
        writer.writeByte(1);
        break;
      case ActivityImportance.high:
        writer.writeByte(2);
        break;
      case ActivityImportance.critical:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityImportanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityLog _$ActivityLogFromJson(Map<String, dynamic> json) => ActivityLog(
  id: json['id'] as String,
  farmId: json['farmId'] as String,
  type: $enumDecode(_$ActivityTypeEnumMap, json['type']),
  title: json['title'] as String,
  description: json['description'] as String,
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  importance:
      $enumDecodeNullable(_$ActivityImportanceEnumMap, json['importance']) ??
      ActivityImportance.normal,
);

Map<String, dynamic> _$ActivityLogToJson(ActivityLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'farmId': instance.farmId,
      'type': _$ActivityTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
      'importance': _$ActivityImportanceEnumMap[instance.importance]!,
    };

const _$ActivityTypeEnumMap = {
  ActivityType.eggProduction: 'eggProduction',
  ActivityType.eggSale: 'eggSale',
  ActivityType.customerAdded: 'customerAdded',
  ActivityType.debtAdded: 'debtAdded',
  ActivityType.debtPaid: 'debtPaid',
  ActivityType.chickenAdded: 'chickenAdded',
  ActivityType.chickenDeath: 'chickenDeath',
  ActivityType.brokenEggs: 'brokenEggs',
  ActivityType.largeEggs: 'largeEggs',
  ActivityType.other: 'other',
};

const _$ActivityImportanceEnumMap = {
  ActivityImportance.low: 'low',
  ActivityImportance.normal: 'normal',
  ActivityImportance.high: 'high',
  ActivityImportance.critical: 'critical',
};
