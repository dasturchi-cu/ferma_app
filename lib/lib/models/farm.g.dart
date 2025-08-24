// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'farm.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FarmAdapter extends TypeAdapter<Farm> {
  @override
  final int typeId = 9;

  @override
  Farm read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Farm(
      id: fields[0] as String,
      name: fields[1] as String,
      userId: fields[2] as String,
      chicken: fields[3] as Chicken?,
      egg: fields[4] as Egg?,
      customers: (fields[5] as List?)?.cast<Customer>(),
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Farm obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.chicken)
      ..writeByte(4)
      ..write(obj.egg)
      ..writeByte(5)
      ..write(obj.customers)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FarmAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
