import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/farm.dart';
import '../models/egg.dart';
import '../models/chicken.dart';
import '../models/customer.dart';
// Removed unused import
import '../services/storage_service.dart';
import '../config/supabase_config.dart';
import 'dart:async';

class AuthProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  final SupabaseClient _supabase = SupabaseConfig.client;

  // STREAM SUBSCRIPTION FOR PROPER DISPOSAL
  StreamSubscription<AuthState>? _authSubscription;

  User? _user;
  Farm? _farm;
  bool _isLoading = false;
  String? _error;
  bool _isOfflineMode = false;

  // Getters
  User? get user => _user;
  Farm? get farm => _farm;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isOfflineMode => _isOfflineMode;

  AuthProvider() {
    _init();
    _checkSavedLogin();
  }

  // Check if user was previously logged in
  Future<void> _checkSavedLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final savedUserId = prefs.getString('saved_user_id');
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (isLoggedIn && savedEmail != null && savedUserId != null) {
        // Try to load offline data while checking online status
        final offlineFarm = await _storage.loadFarmOffline(savedUserId);
        if (offlineFarm != null) {
          _farm = offlineFarm;
          _isOfflineMode = true;
          notifyListeners();
        }

        // Try to refresh session in background
        _refreshSession();
      }
    } catch (e) {
      print('Error checking saved login: $e');
    }
  }

  Future<void> _refreshSession() async {
    try {
      await _supabase.auth.refreshSession();
      final currentSession = _supabase.auth.currentSession;
      if (currentSession != null) {
        _user = currentSession.user;
        _isOfflineMode = false;
        await _loadFarmData();
      }
    } catch (e) {
      print('Session refresh failed, staying offline: $e');
    }
  }

  // Initialize offline mode check
  Future<void> initOfflineMode() async {
    await _storage.init();
    _isOfflineMode = _storage.isOfflineMode;

    // If user was logged in and we have offline data, restore session
    if (_storage.isLoggedIn && _storage.shouldRememberLogin) {
      final userId = _storage.savedUserId;
      if (userId != null) {
        final offlineFarm = await _storage.loadFarmOffline(userId);
        if (offlineFarm != null) {
          _farm = offlineFarm;
          _isOfflineMode = true;
          notifyListeners();
        }
      }
    }
  }

  // Farm ma'lumotlarini qayta yuklash (public)
  Future<void> reloadFarm() async {
    await _loadFarmData();
  }

  Future<void> _init() async {
    // DISPOSE PREVIOUS SUBSCRIPTION IF EXISTS
    await _authSubscription?.cancel();

    // SET UP NEW SUBSCRIPTION WITH PROPER ERROR HANDLING
    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      (AuthState data) async {
        try {
          _user = data.session?.user;
          if (_user != null) {
            await _loadFarmData();
          } else {
            _farm = null;
          }
          if (mounted) {
            notifyListeners();
          }
        } catch (e) {
          print('Auth state change error: $e');
          // Don't let auth state errors crash the app
        }
      },
      onError: (error) {
        print('Auth stream error: $error');
        // Handle stream errors gracefully
      },
    );

    // Check current session
    final currentSession = _supabase.auth.currentSession;
    if (currentSession != null) {
      _user = currentSession.user;
      await _loadFarmData();
    }
  }

  // CHECK IF STILL MOUNTED TO PREVENT MEMORY LEAKS
  bool get mounted => hasListeners;

  // PROPER DISPOSAL OF RESOURCES
  @override
  void dispose() {
    print('🧹 AuthProvider dispose qilinmoqda...');

    // Cancel auth subscription
    _authSubscription?.cancel();
    _authSubscription = null;

    // Clear data
    _user = null;
    _farm = null;

    super.dispose();
    print('✅ AuthProvider dispose qilindi');
  }

  Future<void> _loadFarmData() async {
    if (_user == null) return;

    try {
      _isLoading = true;
      if (mounted) notifyListeners();

      // Try to load from Supabase with timeout
      try {
        final response = await _supabase
            .from('farms')
            .select()
            .eq('id', _user!.id)
            .single()
            .timeout(Duration(seconds: 10)); // Add timeout

        if (mounted) {
          _farm = Farm.fromJson(response);
          await _saveToHive();
          _isOfflineMode = false;
        }
      } catch (e) {
        print('Supabase dan yuklashda xatolik: $e');

        // Try to load from Hive first
        await _loadFromHive();

        // If no offline data, create new farm
        if (_farm == null && mounted) {
          _farm = Farm(
            id: _user!.id,
            name: 'Mening Fermam',
            ownerId: _user!.id,
            chicken: Chicken(id: _user!.id, totalCount: 0, deaths: const []),
            egg: Egg(id: _user!.id),
            customers: <Customer>[],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _saveToSupabase();
          await _saveToHive();
        }

        _isOfflineMode = true;
      }
    } catch (e) {
      print('Critical load error: $e');
      if (mounted) {
        _error = 'Ma\'lumotlarni yuklashda xatolik: $e';
        // Try to load from Hive as last resort
        await _loadFromHive();
      }
    } finally {
      if (mounted) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _saveToSupabase() async {
    if (_farm == null || _user == null) return;

    try {
      // Supabase farms jadvali uchun to'g'ri format
      final farmData = {
        'owner_id': _user!.id,
        'name': _farm!.name,
        'description': _farm!.description ?? '',
        'address': _farm!.address ?? '',
        'chicken_count': _farm!.chickenCount,
        'egg_production_rate': _farm!.eggProductionRate.toDouble(),
        'created_at': _farm!.createdAt?.toIso8601String(),
        'updated_at': _farm!.updatedAt?.toIso8601String(),
      };

      print('🔄 Supabase\'ga saqlash: ${farmData['name']}');

      // Supabase'ga saqlash
      await _supabase.from('farms').upsert(farmData);

      print('✅ Farm Supabase\'ga muvaffaqiyatli saqlandi: ${_farm!.name}');
    } catch (e) {
      print('❌ Supabase saqlash xatosi: $e');
      _error = 'Ma\'lumotlar bazasiga saqlashda xatolik: $e';
      notifyListeners();

      // Agar Supabase ishlamasa, offline rejimga o'tish
      _isOfflineMode = true;
    }
  }

  Future<void> _saveToHive() async {
    if (_farm == null) return;

    try {
      await _storage.saveFarmOffline(_farm!);
    } catch (e) {
      _error = 'Ma\'lumotlarni saqlashda xatolik: $e';
      notifyListeners();
    }
  }

  Future<void> _loadFromHive() async {
    try {
      if (_user != null) {
        _farm = await _storage.loadFarmOffline(_user!.id);
        if (_farm != null) {
          _isOfflineMode = true;
        }
      }
    } catch (e) {
      _error = 'Offline ma\'lumotlarni yuklashda xatolik: $e';
    }
  }

  // Email/Password bilan ro'yxatdan o'tish
  Future<bool> signUpWithEmail(
    String email,
    String password,
    String farmName,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🔄 Ro\'yxatdan o\'tish jarayoni boshlandi: $email');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('✅ Foydalanuvchi yaratildi: ${response.user!.id}');

        // Yangi ferma yaratish
        _farm = Farm(
          id: response.user!.id,
          name: farmName,
          ownerId: response.user!.id,
          chicken: Chicken(
            id: response.user!.id,
            totalCount: 0,
            deaths: const [],
          ),
          egg: Egg(id: response.user!.id),
          customers: <Customer>[],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        print('🏗️ Ferma obyekti yaratildi: ${_farm!.name}');

        // Avval Hive'ga saqlash (offline backup)
        await _saveToHive();
        print('💾 Ferma Hive\'ga saqlandi');

        // Keyin Supabase'ga saqlash
        await _saveToSupabase();
        print('☁️ Ferma Supabase\'ga saqlandi');

        // Save login state
        await _saveLoginState(response.user!.id, email);
        print('🔐 Login holati saqlandi');

        return true;
      } else {
        _error = 'Foydalanuvchi yaratilmadi';
        return false;
      }
    } on AuthException catch (e) {
      print('❌ Auth xatosi: ${e.message}');
      _error = _getAuthErrorMessage(e.message);
      return false;
    } catch (e) {
      print('❌ Umumiy xatolik: $e');
      _error = 'Ro\'yxatdan o\'tishda xatolik: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Email/Password bilan kirish
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Save login state
        await _saveLoginState(response.user!.id, email);
      }

      return true;
    } on AuthException catch (e) {
      _error = _getAuthErrorMessage(e.message);
      return false;
    } catch (e) {
      _error = 'Kutilmagan xatolik: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Chiqish qilish
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _user = null;
      _farm = null;
      await _clearLoginState();
    } catch (e) {
      _error = 'Chiqishda xatolik: $e';
    } finally {
      notifyListeners();
    }
  }

  // Toggle offline mode
  Future<void> toggleOfflineMode() async {
    _isOfflineMode = !_isOfflineMode;
    await _storage.setOfflineMode(_isOfflineMode);
    notifyListeners();
  }

  // Check if offline data is available
  Future<bool> hasOfflineData() async {
    if (_user != null) {
      return await _storage.hasOfflineData(_user!.id);
    }
    return false;
  }

  // Xatolikni tozalash
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Save login state to SharedPreferences
  Future<void> _saveLoginState(String userId, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_user_id', userId);
      await prefs.setString('saved_email', email);
      await prefs.setBool('is_logged_in', true);
    } catch (e) {
      print('Error saving login state: $e');
    }
  }

  // Clear login state from SharedPreferences
  Future<void> _clearLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_user_id');
      await prefs.remove('saved_email');
      await prefs.setBool('is_logged_in', false);
    } catch (e) {
      print('Error clearing login state: $e');
    }
  }

  // Ferma nomini yangilash
  Future<void> updateFarmName(String newName) async {
    if (_farm != null) {
      _farm = _farm!.copyWith(name: newName, updatedAt: DateTime.now());
      await _saveToSupabase();
      await _saveToHive();
      notifyListeners();
    }
  }

  // Check and refresh authentication status
  Future<void> checkAuthStatus() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get current session
      final currentSession = _supabase.auth.currentSession;

      if (currentSession == null) {
        _user = null;
        _farm = null;
        return;
      }

      // Check if session is expired
      final now = DateTime.now().toUtc();
      // Convert expiresAt timestamp to DateTime
      final expiresAt = currentSession.expiresAt != null
          ? DateTime.fromMillisecondsSinceEpoch(
              currentSession.expiresAt! * 1000,
            ).toUtc()
          : now.add(const Duration(days: 1));

      if (expiresAt.isBefore(now)) {
        // Session expired, try to refresh
        try {
          final response = await _supabase.auth.refreshSession();
          _user = response.session?.user;

          if (_user != null) {
            await _loadFarmData();
          } else {
            _farm = null;
          }
        } catch (e) {
          // If refresh fails, sign out
          await signOut();
        }
      } else if (_user == null) {
        // We have a valid session but no user object
        _user = currentSession.user;
        await _loadFarmData();
      }
    } catch (e) {
      _error = 'Auth status check failed: $e';
      debugPrint('Auth status check error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Xatolik xabarlarini o'zgartirish
  String _getAuthErrorMessage(String message) {
    if (message.contains('user not found')) {
      return 'Bunday foydalanuvchi topilmadi';
    } else if (message.contains('Invalid login credentials')) {
      return 'Noto\'g\'ri email yoki parol';
    } else if (message.contains('Email not confirmed')) {
      return 'Iltimos, email manzilingizni tasdiqlang';
    } else if (message.contains('Email rate limit exceeded')) {
      return 'Juda ko\'p urinishlar. Iltimos, biroz vaqt o\'tgach qayta urinib ko\'ring';
    } else if (message.contains('Email already in use')) {
      return 'Bu email allaqachon ro\'yxatdan o\'tgan';
    } else if (message.contains('Password should be at least 6 characters')) {
      return 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak';
    } else if (message.contains('Invalid email address')) {
      return 'Noto\'g\'ri email manzil';
    } else if (message.contains('User already registered')) {
      return 'Bu foydalanuvchi allaqachon mavjud';
    } else if (message.contains('Database error saving new user')) {
      return 'Ma\'lumotlar bazasida xatolik. Internet aloqasini tekshiring';
    } else if (message.contains('unexpected_failure')) {
      return 'Kutilmagan xatolik. Qayta urinib ko\'ring';
    } else if (message.contains('connection')) {
      return 'Internet aloqasi yo\'q. Qayta urinib ko\'ring';
    } else {
      return 'Xatolik yuz berdi: $message';
    }
  }
}
