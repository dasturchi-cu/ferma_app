import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'daily_record.g.dart';

@HiveType(typeId: 10)
@JsonSerializable()
class DailyRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String date;

  @HiveField(2)
  final int eggsCollected;

  @HiveField(3)
  final int eggsSold;

  @HiveField(4)
  final int eggsBroken;

  @HiveField(5)
  final int eggsLarge;

  @HiveField(6)
  final double eggsPrice;

  @HiveField(7)
  final int chickenDeaths;

  @HiveField(8)
  final String? deathReason;

  @HiveField(9)
  final int totalChickens;

  @HiveField(10)
  final double dailyRevenue;

  @HiveField(11)
  final double dailyExpenses;

  @HiveField(12)
  final double netProfit;

  @HiveField(13)
  final int currentStock;

  @HiveField(14)
  final String? weatherCondition;

  @HiveField(15)
  final String? notes;

  @HiveField(16)
  final String dataSource;

  @HiveField(17)
  final DateTime createdAt;

  @HiveField(18)
  final DateTime updatedAt;

  @HiveField(19)
  final String syncStatus;

  DailyRecord({
    required this.id,
    required this.date,
    required this.eggsCollected,
    required this.eggsSold,
    required this.eggsBroken,
    required this.eggsLarge,
    required this.eggsPrice,
    required this.chickenDeaths,
    this.deathReason,
    required this.totalChickens,
    required this.dailyRevenue,
    required this.dailyExpenses,
    required this.netProfit,
    required this.currentStock,
    this.weatherCondition,
    this.notes,
    required this.dataSource,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
  });

  factory DailyRecord.fromJson(Map<String, dynamic> json) =>
      _$DailyRecordFromJson(json);
  Map<String, dynamic> toJson() => _$DailyRecordToJson(this);

  DailyRecord copyWith({
    String? id,
    String? date,
    int? eggsCollected,
    int? eggsSold,
    int? eggsBroken,
    int? eggsLarge,
    double? eggsPrice,
    int? chickenDeaths,
    String? deathReason,
    int? totalChickens,
    double? dailyRevenue,
    double? dailyExpenses,
    double? netProfit,
    int? currentStock,
    String? weatherCondition,
    String? notes,
    String? dataSource,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return DailyRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      eggsCollected: eggsCollected ?? this.eggsCollected,
      eggsSold: eggsSold ?? this.eggsSold,
      eggsBroken: eggsBroken ?? this.eggsBroken,
      eggsLarge: eggsLarge ?? this.eggsLarge,
      eggsPrice: eggsPrice ?? this.eggsPrice,
      chickenDeaths: chickenDeaths ?? this.chickenDeaths,
      deathReason: deathReason ?? this.deathReason,
      totalChickens: totalChickens ?? this.totalChickens,
      dailyRevenue: dailyRevenue ?? this.dailyRevenue,
      dailyExpenses: dailyExpenses ?? this.dailyExpenses,
      netProfit: netProfit ?? this.netProfit,
      currentStock: currentStock ?? this.currentStock,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      notes: notes ?? this.notes,
      dataSource: dataSource ?? this.dataSource,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() {
    return 'DailyRecord(id: $id, date: $date, eggsCollected: $eggsCollected, eggsSold: $eggsSold, eggsBroken: $eggsBroken, eggsLarge: $eggsLarge, eggsPrice: $eggsPrice, chickenDeaths: $chickenDeaths, deathReason: $deathReason, totalChickens: $totalChickens, dailyRevenue: $dailyRevenue, dailyExpenses: $dailyExpenses, netProfit: $netProfit, currentStock: $currentStock, weatherCondition: $weatherCondition, notes: $notes, dataSource: $dataSource, createdAt: $createdAt, updatedAt: $updatedAt, syncStatus: $syncStatus)';
  }
}
