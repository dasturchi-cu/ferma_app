import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/farm.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

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
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _loadFarmData();
      } else {
        _farm = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadFarmData() async {
    if (_user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Firebase'dan yuklash
      final doc = await _firestore
          .collection(AppConstants.farmsCollection)
          .doc(_user!.uid)
          .get();

      if (doc.exists) {
        _farm = Farm.fromJson(doc.data()!);
        await _saveToHive();
      } else {
        // Yangi ferma yaratish
        _farm = Farm(id: _user!.uid, name: 'Mening Fermam', userId: _user!.uid);
        await _saveToFirebase();
        await _saveToHive();
      }
    } catch (e) {
      _error = 'Ma\'lumotlarni yuklashda xatolik: $e';
      // Hive'dan yuklashga urinish
      await _loadFromHive();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveToFirebase() async {
    if (_farm == null || _user == null) return;

    try {
      await _firestore
          .collection(AppConstants.farmsCollection)
          .doc(_user!.uid)
          .set(_farm!.toJson());
    } catch (e) {
      _error = 'Firebase\'ga saqlashda xatolik: $e';
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
        _farm = await _storage.loadFarmOffline(_user!.uid);
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

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Yangi ferma yaratish
        _farm = Farm(
          id: credential.user!.uid,
          name: farmName,
          userId: credential.user!.uid,
        );

        await _saveToFirebase();
        await _saveToHive();
        
        // Save login state
        await _storage.saveLoginState(
          userId: credential.user!.uid,
          email: email,
        );

        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
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

      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      if (credential.user != null) {
        // Save login state
        await _storage.saveLoginState(
          userId: credential.user!.uid,
          email: email,
        );
      }

      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      return false;
    } catch (e) {
      _error = 'Kutilmagan xatolik: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Google bilan kirish
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Firebase Auth with Google provider
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      try {
        final UserCredential userCredential = await _auth.signInWithProvider(
          googleProvider,
        );

        if (userCredential.user != null) {
          // Ferma ma'lumotlarini tekshirish
          final doc = await _firestore
              .collection(AppConstants.farmsCollection)
              .doc(userCredential.user!.uid)
              .get();

          if (!doc.exists) {
            // Yangi ferma yaratish
            _farm = Farm(
              id: userCredential.user!.uid,
              name:
                  '${userCredential.user!.displayName ?? 'Foydalanuvchi'} Fermasi',
              userId: userCredential.user!.uid,
            );

            await _saveToFirebase();
            await _saveToHive();
          }
          
          // Save login state
          await _storage.saveLoginState(
            userId: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
          );

          return true;
        }
        return false;
      } on FirebaseAuthMultiFactorException catch (e) {
        _error = 'Ko\'p faktorli autentifikatsiya talab qilinadi';
        return false;
      } on FirebaseAuthException catch (e) {
        _error = _getAuthErrorMessage(e.code);
        return false;
      }
    } catch (e) {
      _error = 'Google bilan kirishda xatolik: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check for saved login state on app start
  Future<void> checkSavedLoginState() async {
    try {
      final loginData = {
        'userId': _storage.savedUserId,
        'email': _storage.savedUserEmail,
        'rememberLogin': _storage.shouldRememberLogin,
      };
      if (loginData['rememberLogin'] == true) {
        final userId = loginData['userId'] as String?;
        final email = loginData['email'] as String?;
        
        if (userId != null && email != null) {
          // Load offline farm data
          _farm = await _storage.loadFarmOffline(userId);
          if (_farm != null) {
            _user = _auth.currentUser;
            _isOfflineMode = true; // Start in offline mode with cached data
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error loading saved login state: $e');
    }
  }

  // Chiqish
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _storage.clearLoginState();
      _user = null;
      _farm = null;
      _isOfflineMode = false;
      notifyListeners();
    } catch (e) {
      _error = 'Chiqishda xatolik: $e';
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
      return await _storage.hasOfflineData(_user!.uid);
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
      _farm!.name = newName;
      await _saveToFirebase();
      await _saveToHive();
      notifyListeners();
    }
  }

  // Firebase xatolik xabarlarini o'zbek tiliga o'girish
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bunday email topilmadi';
      case 'wrong-password':
        return 'Noto\'g\'ri parol';
      case 'email-already-in-use':
        return 'Bu email allaqachon ishlatilgan';
      case 'weak-password':
        return 'Parol juda zaif';
      case 'invalid-email':
        return 'Noto\'g\'ri email formati';
      case 'user-disabled':
        return 'Foydalanuvchi o\'chirilgan';
      case 'too-many-requests':
        return 'Juda ko\'p urinishlar. Keyinroq urinib ko\'ring';
      case 'operation-not-allowed':
        return 'Bu amal ruxsat etilmagan';
      default:
        return 'Autentifikatsiya xatoligi: $code';
    }
  }
}
