// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_summary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MonthlySummaryAdapter extends TypeAdapter<MonthlySummary> {
  @override
  final int typeId = 13;

  @override
  MonthlySummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonthlySummary(
      id: fields[0] as String,
      year: fields[1] as int,
      month: fields[2] as int,
      totalEggsCollected: fields[3] as int,
      totalEggsSold: fields[4] as int,
      totalEggsBroken: fields[5] as int,
      averageDailyEggs: fields[6] as double,
      bestDay: (fields[7] as Map).cast<String, dynamic>(),
      worstDay: (fields[8] as Map).cast<String, dynamic>(),
      totalRevenue: fields[9] as double,
      totalExpenses: fields[10] as double,
      netProfit: fields[11] as double,
      averageDailyProfit: fields[12] as double,
      startingChickens: fields[13] as int,
      endingChickens: fields[14] as int,
      totalDeaths: fields[15] as int,
      mortalityRate: fields[16] as double,
      activeCustomers: fields[17] as int,
      totalDebts: fields[18] as double,
      newCustomers: fields[19] as int,
      generatedAt: fields[20] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MonthlySummary obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.year)
      ..writeByte(2)
      ..write(obj.month)
      ..writeByte(3)
      ..write(obj.totalEggsCollected)
      ..writeByte(4)
      ..write(obj.totalEggsSold)
      ..writeByte(5)
      ..write(obj.totalEggsBroken)
      ..writeByte(6)
      ..write(obj.averageDailyEggs)
      ..writeByte(7)
      ..write(obj.bestDay)
      ..writeByte(8)
      ..write(obj.worstDay)
      ..writeByte(9)
      ..write(obj.totalRevenue)
      ..writeByte(10)
      ..write(obj.totalExpenses)
      ..writeByte(11)
      ..write(obj.netProfit)
      ..writeByte(12)
      ..write(obj.averageDailyProfit)
      ..writeByte(13)
      ..write(obj.startingChickens)
      ..writeByte(14)
      ..write(obj.endingChickens)
      ..writeByte(15)
      ..write(obj.totalDeaths)
      ..writeByte(16)
      ..write(obj.mortalityRate)
      ..writeByte(17)
      ..write(obj.activeCustomers)
      ..writeByte(18)
      ..write(obj.totalDebts)
      ..writeByte(19)
      ..write(obj.newCustomers)
      ..writeByte(20)
      ..write(obj.generatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlySummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
