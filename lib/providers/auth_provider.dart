import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/farm.dart';
// Removed unused import
import '../services/storage_service.dart';
import '../config/supabase_config.dart';

class AuthProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  final SupabaseClient _supabase = SupabaseConfig.client;

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
    _supabase.auth.onAuthStateChange.listen((AuthState data) async {
      _user = data.session?.user;
      if (_user != null) {
        await _loadFarmData();
      } else {
        _farm = null;
      }
      notifyListeners();
    });

    // Check current session
    final currentSession = _supabase.auth.currentSession;
    if (currentSession != null) {
      _user = currentSession.user;
      await _loadFarmData();
    }
  }

  Future<void> _loadFarmData() async {
    if (_user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Try to load from Supabase
      try {
        final response =
            await _supabase.from('farms').select().eq('id', _user!.id).single();

        _farm = Farm.fromJson(response);
        await _saveToHive();
      } catch (e) {
        // If farm doesn't exist, create a new one
        _farm = Farm(
          id: _user!.id,
          name: 'Mening Fermam',
          ownerId: _user!.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _saveToSupabase();
        await _saveToHive();
      }
    } catch (e) {
      _error = 'Ma\'lumotlarni yuklashda xatolik: $e';
      // Try to load from Hive
      await _loadFromHive();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveToSupabase() async {
    if (_farm == null || _user == null) return;

    try {
      await _supabase.from('farms').upsert(_farm!.toJson());
    } catch (e) {
      _error = 'Supabase\'ga saqlashda xatolik: $e';
      notifyListeners();
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

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Yangi ferma yaratish
        _farm = Farm(
          id: response.user!.id,
          name: farmName,
          ownerId: response.user!.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _saveToSupabase();
        await _saveToHive();

        // Save login state
        await _storage.saveLoginState(
          userId: response.user!.id,
          email: email,
        );

        return true;
      }
      return false;
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
        await _storage.saveLoginState(
          userId: response.user!.id,
          email: email,
        );
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
      await _storage.clearLoginState();
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

  // Ferma nomini yangilash
  Future<void> updateFarmName(String newName) async {
    if (_farm != null) {
      _farm = _farm!.copyWith(
        name: newName,
        updatedAt: DateTime.now(),
      );
      await _saveToSupabase();
      await _saveToHive();
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
    } else {
      return 'Xatolik yuz berdi: $message';
    }
  }
}
