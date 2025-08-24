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

  // Farm data offline storage
  Future<void> saveFarmOffline(Farm farm) async {
    try {
      final box = await Hive.openBox<Farm>(AppConstants.farmBoxName);
      await box.put(farm.id, farm);
      
      // Also save as backup with timestamp
      final backupBox = await Hive.openBox<Map>('farm_backup');
      await backupBox.put('${farm.id}_${DateTime.now().millisecondsSinceEpoch}', {
        'farm': farm.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Keep only last 10 backups
      final keys = backupBox.keys.where((key) => key.toString().startsWith(farm.id)).toList();
      if (keys.length > 10) {
        keys.sort();
        for (int i = 0; i < keys.length - 10; i++) {
          await backupBox.delete(keys[i]);
        }
      }
    } catch (e) {
      print('Error saving farm offline: $e');
    }
  }

  Future<Farm?> loadFarmOffline(String userId) async {
    try {
      final box = await Hive.openBox<Farm>(AppConstants.farmBoxName);
      return box.get(userId);
    } catch (e) {
      print('Error loading farm offline: $e');
      return null;
    }
  }

  Future<List<Farm>> getAllOfflineFarms() async {
    try {
      final box = await Hive.openBox<Farm>(AppConstants.farmBoxName);
      return box.values.toList();
    } catch (e) {
      print('Error loading offline farms: $e');
      return [];
    }
  }

  // Check if app can work offline
  Future<bool> hasOfflineData(String userId) async {
    final farm = await loadFarmOffline(userId);
    return farm != null;
  }

  // Sync status
  Future<void> markDataAsSynced(String userId) async {
    await init();
    await _prefs!.setString('last_sync_$userId', DateTime.now().toIso8601String());
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
}
