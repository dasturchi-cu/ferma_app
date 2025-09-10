// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Sale _$SaleFromJson(Map<String, dynamic> json) => Sale(
  id: json['id'] as String,
  saleDate: DateTime.parse(json['saleDate'] as String),
  customerId: json['customerId'] as String,
  customerName: json['customerName'] as String,
  eggsCount: (json['eggsCount'] as num).toInt(),
  pricePerTray: (json['pricePerTray'] as num).toDouble(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  paymentStatus: json['paymentStatus'] as String,
  paidAmount: (json['paidAmount'] as num).toDouble(),
  remainingDebt: (json['remainingDebt'] as num).toDouble(),
  paymentMethod: json['paymentMethod'] as String,
  paymentDate: json['paymentDate'] == null
      ? null
      : DateTime.parse(json['paymentDate'] as String),
  deliveryDate: json['deliveryDate'] == null
      ? null
      : DateTime.parse(json['deliveryDate'] as String),
  deliveryStatus: json['deliveryStatus'] as String,
  deliveryAddress: json['deliveryAddress'] as String,
  discount: (json['discount'] as num).toDouble(),
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$SaleToJson(Sale instance) => <String, dynamic>{
  'id': instance.id,
  'saleDate': instance.saleDate.toIso8601String(),
  'customerId': instance.customerId,
  'customerName': instance.customerName,
  'eggsCount': instance.eggsCount,
  'pricePerTray': instance.pricePerTray,
  'totalAmount': instance.totalAmount,
  'paymentStatus': instance.paymentStatus,
  'paidAmount': instance.paidAmount,
  'remainingDebt': instance.remainingDebt,
  'paymentMethod': instance.paymentMethod,
  'paymentDate': ?instance.paymentDate?.toIso8601String(),
  'deliveryDate': ?instance.deliveryDate?.toIso8601String(),
  'deliveryStatus': instance.deliveryStatus,
  'deliveryAddress': instance.deliveryAddress,
  'discount': instance.discount,
  'notes': ?instance.notes,
  'createdAt': instance.createdAt.toIso8601String(),
};
