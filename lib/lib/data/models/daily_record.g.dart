// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyRecordAdapter extends TypeAdapter<DailyRecord> {
  @override
  final int typeId = 10;

  @override
  DailyRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyRecord(
      id: fields[0] as String,
      date: fields[1] as String,
      eggsCollected: fields[2] as int,
      eggsSold: fields[3] as int,
      eggsBroken: fields[4] as int,
      eggsLarge: fields[5] as int,
      eggsPrice: fields[6] as double,
      chickenDeaths: fields[7] as int,
      deathReason: fields[8] as String?,
      totalChickens: fields[9] as int,
      dailyRevenue: fields[10] as double,
      dailyExpenses: fields[11] as double,
      netProfit: fields[12] as double,
      currentStock: fields[13] as int,
      weatherCondition: fields[14] as String?,
      notes: fields[15] as String?,
      dataSource: fields[16] as String,
      createdAt: fields[17] as DateTime,
      updatedAt: fields[18] as DateTime,
      syncStatus: fields[19] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DailyRecord obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.eggsCollected)
      ..writeByte(3)
      ..write(obj.eggsSold)
      ..writeByte(4)
      ..write(obj.eggsBroken)
      ..writeByte(5)
      ..write(obj.eggsLarge)
      ..writeByte(6)
      ..write(obj.eggsPrice)
      ..writeByte(7)
      ..write(obj.chickenDeaths)
      ..writeByte(8)
      ..write(obj.deathReason)
      ..writeByte(9)
      ..write(obj.totalChickens)
      ..writeByte(10)
      ..write(obj.dailyRevenue)
      ..writeByte(11)
      ..write(obj.dailyExpenses)
      ..writeByte(12)
      ..write(obj.netProfit)
      ..writeByte(13)
      ..write(obj.currentStock)
      ..writeByte(14)
      ..write(obj.weatherCondition)
      ..writeByte(15)
      ..write(obj.notes)
      ..writeByte(16)
      ..write(obj.dataSource)
      ..writeByte(17)
      ..write(obj.createdAt)
      ..writeByte(18)
      ..write(obj.updatedAt)
      ..writeByte(19)
      ..write(obj.syncStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyRecord _$DailyRecordFromJson(Map<String, dynamic> json) => DailyRecord(
      id: json['id'] as String,
      date: json['date'] as String,
      eggsCollected: (json['eggsCollected'] as num).toInt(),
      eggsSold: (json['eggsSold'] as num).toInt(),
      eggsBroken: (json['eggsBroken'] as num).toInt(),
      eggsLarge: (json['eggsLarge'] as num).toInt(),
      eggsPrice: (json['eggsPrice'] as num).toDouble(),
      chickenDeaths: (json['chickenDeaths'] as num).toInt(),
      deathReason: json['deathReason'] as String?,
      totalChickens: (json['totalChickens'] as num).toInt(),
      dailyRevenue: (json['dailyRevenue'] as num).toDouble(),
      dailyExpenses: (json['dailyExpenses'] as num).toDouble(),
      netProfit: (json['netProfit'] as num).toDouble(),
      currentStock: (json['currentStock'] as num).toInt(),
      weatherCondition: json['weatherCondition'] as String?,
      notes: json['notes'] as String?,
      dataSource: json['dataSource'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      syncStatus: json['syncStatus'] as String,
    );

Map<String, dynamic> _$DailyRecordToJson(DailyRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'eggsCollected': instance.eggsCollected,
      'eggsSold': instance.eggsSold,
      'eggsBroken': instance.eggsBroken,
      'eggsLarge': instance.eggsLarge,
      'eggsPrice': instance.eggsPrice,
      'chickenDeaths': instance.chickenDeaths,
      'deathReason': instance.deathReason,
      'totalChickens': instance.totalChickens,
      'dailyRevenue': instance.dailyRevenue,
      'dailyExpenses': instance.dailyExpenses,
      'netProfit': instance.netProfit,
      'currentStock': instance.currentStock,
      'weatherCondition': instance.weatherCondition,
      'notes': instance.notes,
      'dataSource': instance.dataSource,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'syncStatus': instance.syncStatus,
    };
