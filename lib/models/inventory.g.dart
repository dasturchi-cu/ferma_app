// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InventoryItemAdapter extends TypeAdapter<InventoryItem> {
  @override
  final int typeId = 13;

  @override
  InventoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InventoryItem(
      id: fields[0] as String,
      farmId: fields[1] as String,
      name: fields[2] as String,
      category: fields[3] as String,
      description: fields[4] as String?,
      quantity: fields[5] as double,
      unit: fields[6] as String,
      unitPrice: fields[7] as double?,
      minStockLevel: fields[8] as double?,
      maxStockLevel: fields[9] as double?,
      supplier: fields[10] as String?,
      storageLocation: fields[11] as String?,
      expiryDate: fields[12] as DateTime?,
      batchNumber: fields[13] as String?,
      notes: fields[14] as String?,
      imageUrl: fields[15] as String?,
      createdAt: fields[16] as DateTime?,
      updatedAt: fields[17] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, InventoryItem obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.farmId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.unit)
      ..writeByte(7)
      ..write(obj.unitPrice)
      ..writeByte(8)
      ..write(obj.minStockLevel)
      ..writeByte(9)
      ..write(obj.maxStockLevel)
      ..writeByte(10)
      ..write(obj.supplier)
      ..writeByte(11)
      ..write(obj.storageLocation)
      ..writeByte(12)
      ..write(obj.expiryDate)
      ..writeByte(13)
      ..write(obj.batchNumber)
      ..writeByte(14)
      ..write(obj.notes)
      ..writeByte(15)
      ..write(obj.imageUrl)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InventoryTransactionAdapter extends TypeAdapter<InventoryTransaction> {
  @override
  final int typeId = 14;

  @override
  InventoryTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InventoryTransaction(
      id: fields[0] as String,
      farmId: fields[1] as String,
      itemId: fields[2] as String,
      transactionType: fields[3] as String,
      quantity: fields[4] as double,
      unit: fields[5] as String,
      unitPrice: fields[6] as double?,
      totalAmount: fields[7] as double?,
      referenceId: fields[8] as String?,
      referenceType: fields[9] as String?,
      transactionDate: fields[10] as DateTime,
      notes: fields[11] as String?,
      recordedBy: fields[12] as String,
      createdAt: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, InventoryTransaction obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.farmId)
      ..writeByte(2)
      ..write(obj.itemId)
      ..writeByte(3)
      ..write(obj.transactionType)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.unit)
      ..writeByte(6)
      ..write(obj.unitPrice)
      ..writeByte(7)
      ..write(obj.totalAmount)
      ..writeByte(8)
      ..write(obj.referenceId)
      ..writeByte(9)
      ..write(obj.referenceType)
      ..writeByte(10)
      ..write(obj.transactionDate)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.recordedBy)
      ..writeByte(13)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}