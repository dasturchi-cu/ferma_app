import 'package:hive/hive.dart';


@HiveType(typeId: 15)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String email;
  
  @HiveField(2)
  final String? fullName;
  
  @HiveField(3)
  final String? phoneNumber;
  
  @HiveField(4)
  final String? photoUrl;
  
  @HiveField(5)
  final String? role; // admin, manager, worker, etc.
  
  @HiveField(6)
  final String? farmId; // Primary farm ID if user has access to only one farm
  
  @HiveField(7)
  final List<String> farmIds; // List of farm IDs the user has access to
  
  @HiveField(8)
  final Map<String, String> farmRoles; // Map of farmId to role
  
  @HiveField(9)
  final String? address;
  
  @HiveField(10)
  final DateTime? dateOfBirth;
  
  @HiveField(11)
  final String? gender; // male, female, other, prefer_not_to_say
  
  @HiveField(12)
  final bool emailVerified;
  
  @HiveField(13)
  final bool phoneVerified;
  
  @HiveField(14)
  final DateTime? lastLoginAt;
  
  @HiveField(15)
  final String? timezone;
  
  @HiveField(16)
  final String? language;
  
  @HiveField(17)
  final Map<String, dynamic> preferences;
  
  @HiveField(18)
  final DateTime createdAt;
  
  @HiveField(19)
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.photoUrl,
    this.role = 'user',
    this.farmId,
    List<String>? farmIds,
    Map<String, String>? farmRoles,
    this.address,
    this.dateOfBirth,
    this.gender,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.lastLoginAt,
    this.timezone,
    this.language,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    this.updatedAt,
  })  : farmIds = farmIds ?? (farmId != null ? [farmId] : []),
        farmRoles = farmRoles ?? {},
        preferences = preferences ?? {},
        createdAt = createdAt ?? DateTime.now();

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      photoUrl: json['photo_url'],
      role: json['role'],
      farmId: json['farm_id'],
      farmIds: json['farm_ids'] != null 
          ? List<String>.from(json['farm_ids']) 
          : (json['farm_id'] != null ? [json['farm_id']] : []),
      farmRoles: json['farm_roles'] != null 
          ? Map<String, String>.from(json['farm_roles']) 
          : {},
      address: json['address'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      gender: json['gender'],
      emailVerified: json['email_verified'] ?? false,
      phoneVerified: json['phone_verified'] ?? false,
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at']) 
          : null,
      timezone: json['timezone'],
      language: json['language'],
      preferences: json['preferences'] != null 
          ? Map<String, dynamic>.from(json['preferences']) 
          : {},
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'photo_url': photoUrl,
      'role': role,
      'farm_id': farmId,
      'farm_ids': farmIds,
      'farm_roles': farmRoles,
      'address': address,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'timezone': timezone,
      'language': language,
      'preferences': preferences,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isAdmin => role?.toLowerCase() == 'admin';
  
  bool isFarmAdmin(String checkFarmId) => 
      farmRoles[checkFarmId]?.toLowerCase() == 'admin' || isAdmin;
  
  bool hasFarmAccess(String checkFarmId) => 
      isAdmin || farmIds.contains(checkFarmId);
  
  bool hasFarmPermission(String checkFarmId, String permission) {
    if (isAdmin) return true;
    if (!farmIds.contains(checkFarmId)) return false;
    
    final userRole = farmRoles[checkFarmId]?.toLowerCase() ?? 'viewer';
    
    // Simple role-based permission check
    switch (userRole) {
      case 'admin':
        return true;
      case 'manager':
        return !['manage_users', 'delete_farm'].contains(permission);
      case 'worker':
        return [
          'view_farm', 'view_chickens', 'add_chickens', 'update_chickens',
          'view_eggs', 'add_eggs', 'update_eggs', 'view_inventory',
          'update_inventory', 'view_dashboard'
        ].contains(permission);
      case 'viewer':
      default:
        return [
          'view_farm', 'view_chickens', 'view_eggs', 'view_inventory', 
          'view_dashboard'
        ].contains(permission);
    }
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? photoUrl,
    String? role,
    String? farmId,
    List<String>? farmIds,
    Map<String, String>? farmRoles,
    String? address,
    DateTime? dateOfBirth,
    String? gender,
    bool? emailVerified,
    bool? phoneVerified,
    DateTime? lastLoginAt,
    String? timezone,
    String? language,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      farmId: farmId ?? this.farmId,
      farmIds: farmIds ?? List.from(this.farmIds),
      farmRoles: farmRoles ?? Map.from(this.farmRoles),
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      timezone: timezone ?? this.timezone,
      language: language ?? this.language,
      preferences: preferences ?? Map.from(this.preferences),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Helper method to update a single preference
  UserProfile updatePreference(String key, dynamic value) {
    final updatedPrefs = Map<String, dynamic>.from(preferences);
    updatedPrefs[key] = value;
    return copyWith(preferences: updatedPrefs);
  }
  
  // Helper method to update multiple preferences at once
  UserProfile updatePreferences(Map<String, dynamic> newPreferences) {
    final updatedPrefs = Map<String, dynamic>.from(preferences);
    updatedPrefs.addAll(newPreferences);
    return copyWith(preferences: updatedPrefs);
  }
  
  // Helper to get a preference with a default value
  T getPreference<T>(String key, T defaultValue) {
    return preferences.containsKey(key) ? preferences[key] as T : defaultValue;
  }
}

@HiveType(typeId: 16)
class UserSession extends HiveObject {
  @HiveField(0)
  final String userId;
  
  @HiveField(1)
  final String accessToken;
  
  @HiveField(2)
  final String? refreshToken;
  
  @HiveField(3)
  final DateTime expiresAt;
  
  @HiveField(4)
  final String? deviceId;
  
  @HiveField(5)
  final String? deviceName;
  
  @HiveField(6)
  final String? deviceType; // mobile, tablet, web, desktop
  
  @HiveField(7)
  final String? ipAddress;
  
  @HiveField(8)
  final String? location;
  
  @HiveField(9)
  final bool isActive;
  
  @HiveField(10)
  final DateTime lastActivityAt;
  
  @HiveField(11)
  final DateTime createdAt;

  UserSession({
    required this.userId,
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
    this.deviceId,
    this.deviceName,
    this.deviceType,
    this.ipAddress,
    this.location,
    this.isActive = true,
    required this.lastActivityAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['user_id'],
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      expiresAt: DateTime.parse(json['expires_at']),
      deviceId: json['device_id'],
      deviceName: json['device_name'],
      deviceType: json['device_type'],
      ipAddress: json['ip_address'],
      location: json['location'],
      isActive: json['is_active'] ?? true,
      lastActivityAt: DateTime.parse(json['last_activity_at']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
      'device_id': deviceId,
      'device_name': deviceName,
      'device_type': deviceType,
      'ip_address': ipAddress,
      'location': location,
      'is_active': isActive,
      'last_activity_at': lastActivityAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  bool get needsRefresh => expiresAt.difference(DateTime.now()).inMinutes < 15;

  UserSession copyWith({
    String? userId,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? deviceId,
    String? deviceName,
    String? deviceType,
    String? ipAddress,
    String? location,
    bool? isActive,
    DateTime? lastActivityAt,
    DateTime? createdAt,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      ipAddress: ipAddress ?? this.ipAddress,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
