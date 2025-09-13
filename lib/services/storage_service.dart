import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/farm.dart';
import '../utils/constants.dart';

class StorageService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _rememberLoginKey = 'remember_login';

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Login state management
  Future<void> saveLoginState({
    required String userId,
    required String email,
    bool rememberLogin = true,
  }) async {
    await init();
    await _prefs!.setBool(_isLoggedInKey, true);
    await _prefs!.setString(_userIdKey, userId);
    await _prefs!.setString(_userEmailKey, email);
    await _prefs!.setBool(_rememberLoginKey, rememberLogin);
  }

  Future<void> clearLoginState() async {
    await init();
    await _prefs!.remove(_isLoggedInKey);
    await _prefs!.remove(_userIdKey);
    await _prefs!.remove(_userEmailKey);
    await _prefs!.remove(_rememberLoginKey);
  }

  bool get isLoggedIn {
    return _prefs?.getBool(_isLoggedInKey) ?? false;
  }

  bool get shouldRememberLogin {
    return _prefs?.getBool(_rememberLoginKey) ?? false;
  }

  String? get savedUserId {
    return _prefs?.getString(_userIdKey);
  }

  String? get savedUserEmail {
    return _prefs?.getString(_userEmailKey);
  }

  // KUCHLI FARM DATA OFFLINE STORAGE
  Future<void> saveFarmOffline(Farm farm) async {
    try {
      // Store as Map to avoid adapter requirement
      await _openBoxSafely<Map>(AppConstants.farmBoxName);
      final box = Hive.box<Map>(AppConstants.farmBoxName);
      await box.put(farm.id, farm.toJson());
      print('✅ Farm ma\'lumotlari lokal saqlanadi: ${farm.id}');

      // Also save as backup with timestamp
      await _openBoxSafely<Map>('farm_backup');
      final backupBox = Hive.box<Map>('farm_backup');
      final backupKey = '${farm.id}_${DateTime.now().millisecondsSinceEpoch}';
      await backupBox.put(backupKey, {
        'farm': farm.toJson(), 
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0'
      });

      // Keep only last 10 backups per farm
      await _cleanupOldBackups(backupBox, farm.id);
      
      print('💾 Backup ham yaratildi: $backupKey');
      
    } catch (e) {
      print('❌ Farm offline saqlashda xatolik: $e');
      throw Exception('Ma\'lumotlar saqlanmadi: $e');
    }
  }
  
  Future<void> _openBoxSafely<T>(String boxName) async {
    try {
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox<T>(boxName);
      }
    } catch (e) {
      print('⚠️ Box ochishda xatolik ($boxName): $e');
      try {
        await Hive.deleteBoxFromDisk(boxName);
        await Hive.openBox<T>(boxName);
        print('🔄 Box qayta yaratildi: $boxName');
      } catch (recreateError) {
        print('❌ Box qayta yaratishda xatolik ($boxName): $recreateError');
        rethrow;
      }
    }
  }
  
  Future<void> _cleanupOldBackups(Box<Map> backupBox, String farmId) async {
    try {
      final keys = backupBox.keys
          .where((key) => key.toString().startsWith(farmId))
          .map((key) => key.toString())
          .toList();
          
      if (keys.length > 10) {
        keys.sort();
        final keysToDelete = keys.take(keys.length - 10);
        for (final key in keysToDelete) {
          await backupBox.delete(key);
        }
        print('🧹 ${keysToDelete.length} eski backup tozalandi');
      }
    } catch (e) {
      print('⚠️ Backup tozalashda xatolik: $e');
    }
  }

  Future<Farm?> loadFarmOffline(String userId) async {
    try {
      await _openBoxSafely<Map>(AppConstants.farmBoxName);
      final box = Hive.box<Map>(AppConstants.farmBoxName);
      final data = box.get(userId);
      
      if (data != null) {
        try {
          // Enhanced safe conversion using helper methods
          final Map<String, dynamic> farmData = _convertToStringMap(data);
          
          final farm = Farm.fromJson(farmData);
          print('💾 Farm offline dan yuklandi: ${farm.name}');
          return farm;
        } catch (castError) {
          print('❌ Farm data casting xatosi: $castError');
          print('Attempting to fix corrupted data...');
          
          // Try to salvage the data by reconstructing basic structure
          try {
            final fixedData = _reconstructFarmData(data, userId);
            final farm = Farm.fromJson(fixedData);
            
            // Save the fixed data back
            await saveFarmOffline(farm);
            print('✅ Farm data restored and saved');
            return farm;
          } catch (reconstructError) {
            print('❌ Could not reconstruct farm data: $reconstructError');
            // Continue to backup loading
          }
        }
      }
      
      // Try loading from backup
      print('⚠️ Primary farm data topilmadi, backup dan qidirilmoqda...');
      final backupFarm = await _loadFromBackup(userId);
      if (backupFarm != null) {
        // Restore to primary storage
        await saveFarmOffline(backupFarm);
        print('🔄 Farm backup dan tiklandi');
        return backupFarm;
      }
      
      print('❌ Offline farm data topilmadi: $userId');
      return null;
      
    } catch (e) {
      print('❌ Farm offline dan yuklashda xatolik: $e');
      
      // Last resort: try backup
      try {
        final backupFarm = await _loadFromBackup(userId);
        if (backupFarm != null) {
          print('🎆 Xatolikdan keyin backup dan muvaffaqiyatli yuklandi!');
          return backupFarm;
        }
      } catch (backupError) {
        print('❌ Backup dan ham yuklash muvaffaqiyatsiz: $backupError');
      }
      
      return null;
    }
  }
  
  Future<Farm?> _loadFromBackup(String farmId) async {
    try {
      await _openBoxSafely<Map>('farm_backup');
      final backupBox = Hive.box<Map>('farm_backup');
      
      // Find latest backup for this farm
      final backupKeys = backupBox.keys
          .where((key) => key.toString().startsWith(farmId))
          .map((key) => key.toString())
          .toList();
      
      if (backupKeys.isEmpty) return null;
      
      backupKeys.sort();
      final latestBackupKey = backupKeys.last;
      
      final backupData = backupBox.get(latestBackupKey);
      if (backupData is Map && backupData['farm'] != null) {
        return Farm.fromJson(Map<String, dynamic>.from(backupData['farm']));
      }
      
      return null;
    } catch (e) {
      print('❌ Backup yuklashda xatolik: $e');
      return null;
    }
  }

  Future<List<Farm>> getAllOfflineFarms() async {
    try {
      if (!Hive.isBoxOpen(AppConstants.farmBoxName)) {
        await Hive.openBox<Map>(AppConstants.farmBoxName);
      }
      final box = Hive.box<Map>(AppConstants.farmBoxName);
      return box.values
          .whereType<Map>()
          .map((e) => Farm.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Error loading offline farms: $e');
      return [];
    }
  }

  // Check if app can work offline
  Future<bool> hasOfflineData(String userId) async {
    try {
      if (!Hive.isBoxOpen(AppConstants.farmBoxName)) {
        await Hive.openBox<Map>(AppConstants.farmBoxName);
      }
      final box = Hive.box<Map>(AppConstants.farmBoxName);
      return box.containsKey(userId);
    } catch (e) {
      print('Error checking offline data: $e');
      return false;
    }
  }

  // Sync status
  Future<void> markDataAsSynced(String userId) async {
    await init();
    await _prefs!.setString(
      'last_sync_$userId',
      DateTime.now().toIso8601String(),
    );
  }

  DateTime? getLastSyncTime(String userId) {
    final syncTimeStr = _prefs?.getString('last_sync_$userId');
    if (syncTimeStr != null) {
      return DateTime.tryParse(syncTimeStr);
    }
    return null;
  }

  // App settings
  Future<void> setOfflineMode(bool enabled) async {
    await init();
    await _prefs!.setBool('offline_mode', enabled);
  }

  bool get isOfflineMode {
    return _prefs?.getBool('offline_mode') ?? false;
  }

  // HELPER METHODS FOR TYPE CONVERSION
  Map<String, dynamic> _convertToStringMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      final result = <String, dynamic>{};
      data.forEach((key, value) {
        final stringKey = key.toString();
        result[stringKey] = _convertValue(value);
      });
      return result;
    } else {
      throw Exception('Cannot convert ${data.runtimeType} to Map<String, dynamic>');
    }
  }

  dynamic _convertValue(dynamic value) {
    if (value is Map && value is! Map<String, dynamic>) {
      return _convertToStringMap(value);
    } else if (value is List) {
      return value.map((item) => _convertValue(item)).toList();
    }
    return value;
  }

  Map<String, dynamic> _reconstructFarmData(dynamic corruptedData, String farmId) {
    // Try to create a basic farm structure from corrupted data
    final basicFarm = {
      'id': farmId,
      'name': 'Tiklangan Farm',
      'description': 'Buzilgan ma\'lumotlar tiklandi',
      'address': null,
      'ownerId': farmId,
      'chickenCount': 0,
      'eggProductionRate': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'chicken': null,
      'egg': null,
      'customers': <Map>[],
    };

    // Try to salvage any usable data
    if (corruptedData is Map) {
      try {
        final convertedData = _convertToStringMap(corruptedData);
        // Preserve important fields if they exist
        if (convertedData.containsKey('name')) {
          basicFarm['name'] = convertedData['name'].toString();
        }
        if (convertedData.containsKey('description')) {
          basicFarm['description'] = convertedData['description'].toString();
        }
        if (convertedData.containsKey('address')) {
          basicFarm['address'] = convertedData['address'].toString();
        }
        if (convertedData.containsKey('chickenCount') && convertedData['chickenCount'] is num) {
          basicFarm['chickenCount'] = convertedData['chickenCount'];
        }
      } catch (e) {
        print('Warning: Could not salvage corrupted data: $e');
      }
    }

    return basicFarm;
  }
}
