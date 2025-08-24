// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SaleAdapter extends TypeAdapter<Sale> {
  @override
  final int typeId = 12;

  @override
  Sale read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sale(
      id: fields[0] as String,
      saleDate: fields[1] as DateTime,
      customerId: fields[2] as String,
      customerName: fields[3] as String,
      eggsCount: fields[4] as int,
      pricePerTray: fields[5] as double,
      totalAmount: fields[6] as double,
      paymentStatus: fields[7] as String,
      paidAmount: fields[8] as double,
      remainingDebt: fields[9] as double,
      paymentMethod: fields[10] as String,
      paymentDate: fields[11] as DateTime?,
      deliveryDate: fields[12] as DateTime?,
      deliveryStatus: fields[13] as String,
      deliveryAddress: fields[14] as String,
      discount: fields[15] as double,
      notes: fields[16] as String?,
      createdAt: fields[17] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Sale obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.saleDate)
      ..writeByte(2)
      ..write(obj.customerId)
      ..writeByte(3)
      ..write(obj.customerName)
      ..writeByte(4)
      ..write(obj.eggsCount)
      ..writeByte(5)
      ..write(obj.pricePerTray)
      ..writeByte(6)
      ..write(obj.totalAmount)
      ..writeByte(7)
      ..write(obj.paymentStatus)
      ..writeByte(8)
      ..write(obj.paidAmount)
      ..writeByte(9)
      ..write(obj.remainingDebt)
      ..writeByte(10)
      ..write(obj.paymentMethod)
      ..writeByte(11)
      ..write(obj.paymentDate)
      ..writeByte(12)
      ..write(obj.deliveryDate)
      ..writeByte(13)
      ..write(obj.deliveryStatus)
      ..writeByte(14)
      ..write(obj.deliveryAddress)
      ..writeByte(15)
      ..write(obj.discount)
      ..writeByte(16)
      ..write(obj.notes)
      ..writeByte(17)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
      'paymentDate': instance.paymentDate?.toIso8601String(),
      'deliveryDate': instance.deliveryDate?.toIso8601String(),
      'deliveryStatus': instance.deliveryStatus,
      'deliveryAddress': instance.deliveryAddress,
      'discount': instance.discount,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
    };
