import 'package:hive/hive.dart';


@HiveType(typeId: 9)
class DailyRecord extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String farmId;
  
  @HiveField(2)
  final DateTime date;
  
  @HiveField(3)
  final int totalEggsCollected;
  
  @HiveField(4)
  final int goodEggs;
  
  @HiveField(5)
  final int brokenEggs;
  
  @HiveField(6)
  final int eggsSold;
  
  @HiveField(7)
  final double revenue;
  
  @HiveField(8)
  final int chickenDeaths;
  
  @HiveField(9)
  final int newChickensAdded;
  
  @HiveField(10)
  final double feedConsumption;
  
  @HiveField(11)
  final double waterConsumption;
  
  @HiveField(12)
  final double temperature;
  
  @HiveField(13)
  final double humidity;
  
  @HiveField(14)
  final String? weatherCondition;
  
  @HiveField(15)
  final String? notes;
  
  @HiveField(16)
  final String recordedBy;
  
  @HiveField(17)
  final DateTime createdAt;
  
  @HiveField(18)
  final DateTime? updatedAt;

  DailyRecord({
    required this.id,
    required this.farmId,
    required this.date,
    required this.totalEggsCollected,
    required this.goodEggs,
    required this.brokenEggs,
    this.eggsSold = 0,
    this.revenue = 0.0,
    this.chickenDeaths = 0,
    this.newChickensAdded = 0,
    this.feedConsumption = 0.0,
    this.waterConsumption = 0.0,
    this.temperature = 0.0,
    this.humidity = 0.0,
    this.weatherCondition,
    this.notes,
    required this.recordedBy,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      id: json['id'],
      farmId: json['farm_id'],
      date: DateTime.parse(json['date']),
      totalEggsCollected: json['total_eggs_collected'],
      goodEggs: json['good_eggs'],
      brokenEggs: json['broken_eggs'],
      eggsSold: json['eggs_sold'] ?? 0,
      revenue: (json['revenue'] ?? 0.0).toDouble(),
      chickenDeaths: json['chicken_deaths'] ?? 0,
      newChickensAdded: json['new_chickens_added'] ?? 0,
      feedConsumption: (json['feed_consumption'] ?? 0.0).toDouble(),
      waterConsumption: (json['water_consumption'] ?? 0.0).toDouble(),
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      weatherCondition: json['weather_condition'],
      notes: json['notes'],
      recordedBy: json['recorded_by'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm_id': farmId,
      'date': date.toIso8601String().substring(0, 10), // YYYY-MM-DD
      'total_eggs_collected': totalEggsCollected,
      'good_eggs': goodEggs,
      'broken_eggs': brokenEggs,
      'eggs_sold': eggsSold,
      'revenue': revenue,
      'chicken_deaths': chickenDeaths,
      'new_chickens_added': newChickensAdded,
      'feed_consumption': feedConsumption,
      'water_consumption': waterConsumption,
      'temperature': temperature,
      'humidity': humidity,
      'weather_condition': weatherCondition,
      'notes': notes,
      'recorded_by': recordedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  double get eggQualityPercentage => totalEggsCollected > 0 
      ? (goodEggs / totalEggsCollected) * 100 
      : 0;

  double get breakagePercentage => totalEggsCollected > 0 
      ? (brokenEggs / totalEggsCollected) * 100 
      : 0;

  DailyRecord copyWith({
    String? id,
    String? farmId,
    DateTime? date,
    int? totalEggsCollected,
    int? goodEggs,
    int? brokenEggs,
    int? eggsSold,
    double? revenue,
    int? chickenDeaths,
    int? newChickensAdded,
    double? feedConsumption,
    double? waterConsumption,
    double? temperature,
    double? humidity,
    String? weatherCondition,
    String? notes,
    String? recordedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyRecord(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      date: date ?? this.date,
      totalEggsCollected: totalEggsCollected ?? this.totalEggsCollected,
      goodEggs: goodEggs ?? this.goodEggs,
      brokenEggs: brokenEggs ?? this.brokenEggs,
      eggsSold: eggsSold ?? this.eggsSold,
      revenue: revenue ?? this.revenue,
      chickenDeaths: chickenDeaths ?? this.chickenDeaths,
      newChickensAdded: newChickensAdded ?? this.newChickensAdded,
      feedConsumption: feedConsumption ?? this.feedConsumption,
      waterConsumption: waterConsumption ?? this.waterConsumption,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      notes: notes ?? this.notes,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@HiveType(typeId: 10)
class MonthlySummary extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String farmId;
  
  @HiveField(2)
  final int year;
  
  @HiveField(3)
  final int month;
  
  @HiveField(4)
  final int totalEggsCollected;
  
  @HiveField(5)
  final int goodEggs;
  
  @HiveField(6)
  final int brokenEggs;
  
  @HiveField(7)
  final int eggsSold;
  
  @HiveField(8)
  final double totalRevenue;
  
  @HiveField(9)
  final int chickenDeaths;
  
  @HiveField(10)
  final int newChickensAdded;
  
  @HiveField(11)
  final double totalExpenses;
  
  @HiveField(12)
  final double totalFeedConsumption;
  
  @HiveField(13)
  final double totalWaterConsumption;
  
  @HiveField(14)
  final double averageTemperature;
  
  @HiveField(15)
  final double averageHumidity;
  
  @HiveField(16)
  final int daysRecorded;
  
  @HiveField(17)
  final DateTime? lastUpdated;
  
  @HiveField(18)
  final DateTime createdAt;

  MonthlySummary({
    required this.id,
    required this.farmId,
    required this.year,
    required this.month,
    required this.totalEggsCollected,
    required this.goodEggs,
    required this.brokenEggs,
    this.eggsSold = 0,
    this.totalRevenue = 0.0,
    this.chickenDeaths = 0,
    this.newChickensAdded = 0,
    this.totalExpenses = 0.0,
    this.totalFeedConsumption = 0.0,
    this.totalWaterConsumption = 0.0,
    this.averageTemperature = 0.0,
    this.averageHumidity = 0.0,
    this.daysRecorded = 0,
    this.lastUpdated,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      id: json['id'],
      farmId: json['farm_id'],
      year: json['year'],
      month: json['month'],
      totalEggsCollected: json['total_eggs_collected'],
      goodEggs: json['good_eggs'],
      brokenEggs: json['broken_eggs'],
      eggsSold: json['eggs_sold'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0.0).toDouble(),
      chickenDeaths: json['chicken_deaths'] ?? 0,
      newChickensAdded: json['new_chickens_added'] ?? 0,
      totalExpenses: (json['total_expenses'] ?? 0.0).toDouble(),
      totalFeedConsumption: (json['total_feed_consumption'] ?? 0.0).toDouble(),
      totalWaterConsumption: (json['total_water_consumption'] ?? 0.0).toDouble(),
      averageTemperature: (json['average_temperature'] ?? 0.0).toDouble(),
      averageHumidity: (json['average_humidity'] ?? 0.0).toDouble(),
      daysRecorded: json['days_recorded'] ?? 0,
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm_id': farmId,
      'year': year,
      'month': month,
      'total_eggs_collected': totalEggsCollected,
      'good_eggs': goodEggs,
      'broken_eggs': brokenEggs,
      'eggs_sold': eggsSold,
      'total_revenue': totalRevenue,
      'chicken_deaths': chickenDeaths,
      'new_chickens_added': newChickensAdded,
      'total_expenses': totalExpenses,
      'total_feed_consumption': totalFeedConsumption,
      'total_water_consumption': totalWaterConsumption,
      'average_temperature': averageTemperature,
      'average_humidity': averageHumidity,
      'days_recorded': daysRecorded,
      'last_updated': lastUpdated?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get eggQualityPercentage => totalEggsCollected > 0 
      ? (goodEggs / totalEggsCollected) * 100 
      : 0;

  double get breakagePercentage => totalEggsCollected > 0 
      ? (brokenEggs / totalEggsCollected) * 100 
      : 0;

  double get profit => totalRevenue - totalExpenses;

  double get profitMargin => totalRevenue > 0 
      ? (profit / totalRevenue) * 100 
      : 0;

  MonthlySummary copyWith({
    String? id,
    String? farmId,
    int? year,
    int? month,
    int? totalEggsCollected,
    int? goodEggs,
    int? brokenEggs,
    int? eggsSold,
    double? totalRevenue,
    int? chickenDeaths,
    int? newChickensAdded,
    double? totalExpenses,
    double? totalFeedConsumption,
    double? totalWaterConsumption,
    double? averageTemperature,
    double? averageHumidity,
    int? daysRecorded,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return MonthlySummary(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      year: year ?? this.year,
      month: month ?? this.month,
      totalEggsCollected: totalEggsCollected ?? this.totalEggsCollected,
      goodEggs: goodEggs ?? this.goodEggs,
      brokenEggs: brokenEggs ?? this.brokenEggs,
      eggsSold: eggsSold ?? this.eggsSold,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      chickenDeaths: chickenDeaths ?? this.chickenDeaths,
      newChickensAdded: newChickensAdded ?? this.newChickensAdded,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalFeedConsumption: totalFeedConsumption ?? this.totalFeedConsumption,
      totalWaterConsumption: totalWaterConsumption ?? this.totalWaterConsumption,
      averageTemperature: averageTemperature ?? this.averageTemperature,
      averageHumidity: averageHumidity ?? this.averageHumidity,
      daysRecorded: daysRecorded ?? this.daysRecorded,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
