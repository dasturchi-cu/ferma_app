import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 11)
@JsonSerializable()
class UserProfile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String displayName;

  @HiveField(3)
  final String phone;

  @HiveField(4)
  final String farmName;

  @HiveField(5)
  final String location;

  @HiveField(6)
  final int totalChickens;

  @HiveField(7)
  final DateTime farmStartDate;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime lastActiveAt;

  @HiveField(10)
  final Map<String, dynamic> settings;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.phone,
    required this.farmName,
    required this.location,
    required this.totalChickens,
    required this.farmStartDate,
    required this.createdAt,
    required this.lastActiveAt,
    required this.settings,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phone,
    String? farmName,
    String? location,
    int? totalChickens,
    DateTime? farmStartDate,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Map<String, dynamic>? settings,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      farmName: farmName ?? this.farmName,
      location: location ?? this.location,
      totalChickens: totalChickens ?? this.totalChickens,
      farmStartDate: farmStartDate ?? this.farmStartDate,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      settings: settings ?? this.settings,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, displayName: $displayName, phone: $phone, farmName: $farmName, location: $location, totalChickens: $totalChickens, farmStartDate: $farmStartDate, createdAt: $createdAt, lastActiveAt: $lastActiveAt, settings: $settings)';
  }
} 