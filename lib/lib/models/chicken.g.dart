// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chicken.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChickenAdapter extends TypeAdapter<Chicken> {
  @override
  final int typeId = 0;

  @override
  Chicken read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Chicken(
      id: fields[0] as String,
      totalCount: fields[1] as int,
      deaths: (fields[2] as List?)?.cast<ChickenDeath>(),
      createdAt: fields[3] as DateTime?,
      updatedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Chicken obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.totalCount)
      ..writeByte(2)
      ..write(obj.deaths)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChickenAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChickenDeathAdapter extends TypeAdapter<ChickenDeath> {
  @override
  final int typeId = 1;

  @override
  ChickenDeath read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChickenDeath(
      id: fields[0] as String,
      count: fields[1] as int,
      date: fields[2] as DateTime,
      note: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChickenDeath obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.count)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChickenDeathAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
