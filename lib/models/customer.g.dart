// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Customer _$CustomerFromJson(Map<String, dynamic> json) => Customer(
  id: json['id'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String,
  address: json['address'] as String,
  orders: (json['orders'] as List<dynamic>?)
      ?.map((e) => CustomerOrder.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CustomerToJson(Customer instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'phone': instance.phone,
  'address': instance.address,
  'orders': instance.orders.map((e) => e.toJson()).toList(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

CustomerOrder _$CustomerOrderFromJson(Map<String, dynamic> json) =>
    CustomerOrder(
      id: json['id'] as String,
      trayCount: (json['trayCount'] as num).toInt(),
      pricePerTray: (json['pricePerTray'] as num).toDouble(),
      deliveryDate: DateTime.parse(json['deliveryDate'] as String),
      isPaid: json['isPaid'] as bool? ?? false,
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.parse(json['paidAt'] as String),
      note: json['note'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CustomerOrderToJson(CustomerOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trayCount': instance.trayCount,
      'pricePerTray': instance.pricePerTray,
      'deliveryDate': instance.deliveryDate.toIso8601String(),
      'isPaid': instance.isPaid,
      'paidAt': ?instance.paidAt?.toIso8601String(),
      'note': ?instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
    };
