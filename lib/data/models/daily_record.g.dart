// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_record.dart';

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
      'deathReason': ?instance.deathReason,
      'totalChickens': instance.totalChickens,
      'dailyRevenue': instance.dailyRevenue,
      'dailyExpenses': instance.dailyExpenses,
      'netProfit': instance.netProfit,
      'currentStock': instance.currentStock,
      'weatherCondition': ?instance.weatherCondition,
      'notes': ?instance.notes,
      'dataSource': instance.dataSource,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'syncStatus': instance.syncStatus,
    };
