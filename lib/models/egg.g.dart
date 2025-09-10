// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'egg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Egg _$EggFromJson(Map<String, dynamic> json) => Egg(
  id: json['id'] as String,
  production: (json['production'] as List<dynamic>?)
      ?.map((e) => EggProduction.fromJson(e as Map<String, dynamic>))
      .toList(),
  sales: (json['sales'] as List<dynamic>?)
      ?.map((e) => EggSale.fromJson(e as Map<String, dynamic>))
      .toList(),
  brokenEggs: (json['brokenEggs'] as List<dynamic>?)
      ?.map((e) => BrokenEgg.fromJson(e as Map<String, dynamic>))
      .toList(),
  largeEggs: (json['largeEggs'] as List<dynamic>?)
      ?.map((e) => LargeEgg.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$EggToJson(Egg instance) => <String, dynamic>{
  'id': instance.id,
  'production': instance.production.map((e) => e.toJson()).toList(),
  'sales': instance.sales.map((e) => e.toJson()).toList(),
  'brokenEggs': instance.brokenEggs.map((e) => e.toJson()).toList(),
  'largeEggs': instance.largeEggs.map((e) => e.toJson()).toList(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
