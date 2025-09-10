// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

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
