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
  ownerId: json['ownerId'] as String,
  chickenCount: (json['chickenCount'] as num?)?.toInt() ?? 0,
  eggProductionRate: (json['eggProductionRate'] as num?)?.toInt() ?? 0,
  chicken: json['chicken'] == null
      ? null
      : Chicken.fromJson(json['chicken'] as Map<String, dynamic>),
  egg: json['egg'] == null
      ? null
      : Egg.fromJson(json['egg'] as Map<String, dynamic>),
  customers: (json['customers'] as List<dynamic>?)
      ?.map((e) => Customer.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$FarmToJson(Farm instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': ?instance.description,
  'address': ?instance.address,
  'ownerId': instance.ownerId,
  'chickenCount': instance.chickenCount,
  'eggProductionRate': instance.eggProductionRate,
  'createdAt': ?instance.createdAt?.toIso8601String(),
  'updatedAt': ?instance.updatedAt?.toIso8601String(),
  'chicken': ?instance.chicken?.toJson(),
  'egg': ?instance.egg?.toJson(),
  'customers': instance.customers.map((e) => e.toJson()).toList(),
};
