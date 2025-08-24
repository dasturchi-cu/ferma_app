// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 11;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      id: fields[0] as String,
      email: fields[1] as String,
      displayName: fields[2] as String,
      phone: fields[3] as String,
      farmName: fields[4] as String,
      location: fields[5] as String,
      totalChickens: fields[6] as int,
      farmStartDate: fields[7] as DateTime,
      createdAt: fields[8] as DateTime,
      lastActiveAt: fields[9] as DateTime,
      settings: (fields[10] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.farmName)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.totalChickens)
      ..writeByte(7)
      ..write(obj.farmStartDate)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.lastActiveAt)
      ..writeByte(10)
      ..write(obj.settings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      phone: json['phone'] as String,
      farmName: json['farmName'] as String,
      location: json['location'] as String,
      totalChickens: (json['totalChickens'] as num).toInt(),
      farmStartDate: DateTime.parse(json['farmStartDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
      settings: json['settings'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'displayName': instance.displayName,
      'phone': instance.phone,
      'farmName': instance.farmName,
      'location': instance.location,
      'totalChickens': instance.totalChickens,
      'farmStartDate': instance.farmStartDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'lastActiveAt': instance.lastActiveAt.toIso8601String(),
      'settings': instance.settings,
    };
