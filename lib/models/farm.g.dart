// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'farm.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Farm _$FarmFromJson(Map<String, dynamic> json) => Farm(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  address: json['address'] as String?,
  ownerId: json['owner_id'] as String,
  chickenCount: (json['chicken_count'] as num?)?.toInt() ?? 0,
  eggProductionRate: (json['egg_production_rate'] as num?)?.toInt() ?? 0,
  chicken: json['chicken'] == null
      ? null
      : Chicken.fromJson(json['chicken'] as Map<String, dynamic>),
  egg: json['egg'] == null
      ? null
      : Egg.fromJson(json['egg'] as Map<String, dynamic>),
  customers: (json['customers'] as List<dynamic>?)
      ?.map((e) => Customer.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$FarmToJson(Farm instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': ?instance.description,
  'address': ?instance.address,
  'owner_id': instance.ownerId,
  'chicken_count': instance.chickenCount,
  'egg_production_rate': instance.eggProductionRate,
  'created_at': ?instance.createdAt?.toIso8601String(),
  'updated_at': ?instance.updatedAt?.toIso8601String(),
  'chicken': ?instance.chicken?.toJson(),
  'egg': ?instance.egg?.toJson(),
  'customers': instance.customers.map((e) => e.toJson()).toList(),
};
