import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'monthly_summary.g.dart';

@HiveType(typeId: 13)
@JsonSerializable()
class MonthlySummary extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int year;

  @HiveField(2)
  final int month;

  // Tuxum statistikalari
  @HiveField(3)
  final int totalEggsCollected;

  @HiveField(4)
  final int totalEggsSold;

  @HiveField(5)
  final int totalEggsBroken;

  @HiveField(6)
  final double averageDailyEggs;

  @HiveField(7)
  final Map<String, dynamic> bestDay;

  @HiveField(8)
  final Map<String, dynamic> worstDay;

  // Moliyaviy statistikalar
  @HiveField(9)
  final double totalRevenue;

  @HiveField(10)
  final double totalExpenses;

  @HiveField(11)
  final double netProfit;

  @HiveField(12)
  final double averageDailyProfit;

  // Tovuqlar statistikalari
  @HiveField(13)
  final int startingChickens;

  @HiveField(14)
  final int endingChickens;

  @HiveField(15)
  final int totalDeaths;

  @HiveField(16)
  final double mortalityRate;

  // Mijozlar statistikalari
  @HiveField(17)
  final int activeCustomers;

  @HiveField(18)
  final double totalDebts;

  @HiveField(19)
  final int newCustomers;

  @HiveField(20)
  final DateTime generatedAt;

  MonthlySummary({
    required this.id,
    required this.year,
    required this.month,
    required this.totalEggsCollected,
    required this.totalEggsSold,
    required this.totalEggsBroken,
    required this.averageDailyEggs,
    required this.bestDay,
    required this.worstDay,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.averageDailyProfit,
    required this.startingChickens,
    required this.endingChickens,
    required this.totalDeaths,
    required this.mortalityRate,
    required this.activeCustomers,
    required this.totalDebts,
    required this.newCustomers,
    required this.generatedAt,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) => _$MonthlySummaryFromJson(json);
  Map<String, dynamic> toJson() => _$MonthlySummaryToJson(this);

  String get monthName {
    const months = [
      'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
      'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr'
    ];
    return months[month - 1];
  }

  MonthlySummary copyWith({
    String? id,
    int? year,
    int? month,
    int? totalEggsCollected,
    int? totalEggsSold,
    int? totalEggsBroken,
    double? averageDailyEggs,
    Map<String, dynamic>? bestDay,
    Map<String, dynamic>? worstDay,
    double? totalRevenue,
    double? totalExpenses,
    double? netProfit,
    double? averageDailyProfit,
    int? startingChickens,
    int? endingChickens,
    int? totalDeaths,
    double? mortalityRate,
    int? activeCustomers,
    double? totalDebts,
    int? newCustomers,
    DateTime? generatedAt,
  }) {
    return MonthlySummary(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      totalEggsCollected: totalEggsCollected ?? this.totalEggsCollected,
      totalEggsSold: totalEggsSold ?? this.totalEggsSold,
      totalEggsBroken: totalEggsBroken ?? this.totalEggsBroken,
      averageDailyEggs: averageDailyEggs ?? this.averageDailyEggs,
      bestDay: bestDay ?? this.bestDay,
      worstDay: worstDay ?? this.worstDay,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netProfit: netProfit ?? this.netProfit,
      averageDailyProfit: averageDailyProfit ?? this.averageDailyProfit,
      startingChickens: startingChickens ?? this.startingChickens,
      endingChickens: endingChickens ?? this.endingChickens,
      totalDeaths: totalDeaths ?? this.totalDeaths,
      mortalityRate: mortalityRate ?? this.mortalityRate,
      activeCustomers: activeCustomers ?? this.activeCustomers,
      totalDebts: totalDebts ?? this.totalDebts,
      newCustomers: newCustomers ?? this.newCustomers,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  String toString() {
    return 'MonthlySummary(id: $id, year: $year, month: $month, monthName: $monthName, totalEggsCollected: $totalEggsCollected, totalEggsSold: $totalEggsSold, totalRevenue: $totalRevenue, netProfit: $netProfit, totalDeaths: $totalDeaths, activeCustomers: $activeCustomers)';
  }
} 