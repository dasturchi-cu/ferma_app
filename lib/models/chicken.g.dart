// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chicken.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Chicken _$ChickenFromJson(Map<String, dynamic> json) => Chicken(
  id: json['id'] as String,
  totalCount: (json['totalCount'] as num).toInt(),
  deaths: (json['deaths'] as List<dynamic>?)
      ?.map((e) => ChickenDeath.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ChickenToJson(Chicken instance) => <String, dynamic>{
  'id': instance.id,
  'totalCount': instance.totalCount,
  'deaths': instance.deaths.map((e) => e.toJson()).toList(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

ChickenDeath _$ChickenDeathFromJson(Map<String, dynamic> json) => ChickenDeath(
  id: json['id'] as String,
  count: (json['count'] as num).toInt(),
  date: DateTime.parse(json['date'] as String),
  note: json['note'] as String?,
);

Map<String, dynamic> _$ChickenDeathToJson(ChickenDeath instance) =>
    <String, dynamic>{
      'id': instance.id,
      'count': instance.count,
      'date': instance.date.toIso8601String(),
      'note': ?instance.note,
    };
