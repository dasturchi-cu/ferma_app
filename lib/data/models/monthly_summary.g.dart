// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MonthlySummary _$MonthlySummaryFromJson(Map<String, dynamic> json) =>
    MonthlySummary(
      id: json['id'] as String,
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      totalEggsCollected: (json['totalEggsCollected'] as num).toInt(),
      totalEggsSold: (json['totalEggsSold'] as num).toInt(),
      totalEggsBroken: (json['totalEggsBroken'] as num).toInt(),
      averageDailyEggs: (json['averageDailyEggs'] as num).toDouble(),
      bestDay: json['bestDay'] as Map<String, dynamic>,
      worstDay: json['worstDay'] as Map<String, dynamic>,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      netProfit: (json['netProfit'] as num).toDouble(),
      averageDailyProfit: (json['averageDailyProfit'] as num).toDouble(),
      startingChickens: (json['startingChickens'] as num).toInt(),
      endingChickens: (json['endingChickens'] as num).toInt(),
      totalDeaths: (json['totalDeaths'] as num).toInt(),
      mortalityRate: (json['mortalityRate'] as num).toDouble(),
      activeCustomers: (json['activeCustomers'] as num).toInt(),
      totalDebts: (json['totalDebts'] as num).toDouble(),
      newCustomers: (json['newCustomers'] as num).toInt(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );

Map<String, dynamic> _$MonthlySummaryToJson(MonthlySummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'year': instance.year,
      'month': instance.month,
      'totalEggsCollected': instance.totalEggsCollected,
      'totalEggsSold': instance.totalEggsSold,
      'totalEggsBroken': instance.totalEggsBroken,
      'averageDailyEggs': instance.averageDailyEggs,
      'bestDay': instance.bestDay,
      'worstDay': instance.worstDay,
      'totalRevenue': instance.totalRevenue,
      'totalExpenses': instance.totalExpenses,
      'netProfit': instance.netProfit,
      'averageDailyProfit': instance.averageDailyProfit,
      'startingChickens': instance.startingChickens,
      'endingChickens': instance.endingChickens,
      'totalDeaths': instance.totalDeaths,
      'mortalityRate': instance.mortalityRate,
      'activeCustomers': instance.activeCustomers,
      'totalDebts': instance.totalDebts,
      'newCustomers': instance.newCustomers,
      'generatedAt': instance.generatedAt.toIso8601String(),
    };
