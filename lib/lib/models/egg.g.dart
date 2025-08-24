// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'egg.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EggAdapter extends TypeAdapter<Egg> {
  @override
  final int typeId = 2;

  @override
  Egg read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Egg(
      id: fields[0] as String,
      production: (fields[1] as List?)?.cast<EggProduction>(),
      sales: (fields[2] as List?)?.cast<EggSale>(),
      brokenEggs: (fields[3] as List?)?.cast<BrokenEgg>(),
      largeEggs: (fields[4] as List?)?.cast<LargeEgg>(),
      createdAt: fields[5] as DateTime?,
      updatedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Egg obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.production)
      ..writeByte(2)
      ..write(obj.sales)
      ..writeByte(3)
      ..write(obj.brokenEggs)
      ..writeByte(4)
      ..write(obj.largeEggs)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EggAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EggProductionAdapter extends TypeAdapter<EggProduction> {
  @override
  final int typeId = 3;

  @override
  EggProduction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EggProduction(
      id: fields[0] as String,
      trayCount: fields[1] as int,
      date: fields[2] as DateTime,
      note: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EggProduction obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.trayCount)
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
      other is EggProductionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EggSaleAdapter extends TypeAdapter<EggSale> {
  @override
  final int typeId = 4;

  @override
  EggSale read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EggSale(
      id: fields[0] as String,
      trayCount: fields[1] as int,
      pricePerTray: fields[2] as double,
      date: fields[3] as DateTime,
      note: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EggSale obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.trayCount)
      ..writeByte(2)
      ..write(obj.pricePerTray)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EggSaleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BrokenEggAdapter extends TypeAdapter<BrokenEgg> {
  @override
  final int typeId = 5;

  @override
  BrokenEgg read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BrokenEgg(
      id: fields[0] as String,
      trayCount: fields[1] as int,
      date: fields[2] as DateTime,
      note: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BrokenEgg obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.trayCount)
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
      other is BrokenEggAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LargeEggAdapter extends TypeAdapter<LargeEgg> {
  @override
  final int typeId = 6;

  @override
  LargeEgg read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LargeEgg(
      id: fields[0] as String,
      trayCount: fields[1] as int,
      date: fields[2] as DateTime,
      note: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LargeEgg obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.trayCount)
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
      other is LargeEggAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
