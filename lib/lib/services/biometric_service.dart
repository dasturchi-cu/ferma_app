import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

// Error codes from local_auth package
const String _kPasscodeNotSet = 'PasscodeNotSet';
const String _kNotEnrolled = 'NotEnrolled';
const String _kNotAvailable = 'NotAvailable';
const String _kLockedOut = 'LockedOut';
const String _kPermanentlyLockedOut = 'PermanentlyLockedOut';
const String _kUserCanceled = 'UserCancel';

enum BiometricAuthResult {
  success,
  failed,
  notAvailable,
  notEnrolled,
  cancelled,
  error,
  lockedOut,
  permanentlyLocked,
  passcodeNotSet,
  notConfigured
}

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static SharedPreferences? _prefs;
  
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _pinCodeKey = 'pin_code';
  static const String _lastAuthTimeKey = 'last_auth_time';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _lastFailedAttemptKey = 'last_failed_attempt';
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 5);
  
  // Initialize SharedPreferences
  static Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Checks if the device supports biometric authentication
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Checks if biometric authentication is supported on the device
  /// without checking if the user has enrolled biometrics
  static Future<bool> isBiometricSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      print('Error checking biometric support: $e');
      return false;
    }
  }

  // Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  static Future<bool> isEnrolled() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.isNotEmpty;
  }

  /// Authenticate with biometrics
  /// Returns BiometricAuthResult indicating the result of the authentication
  static Future<BiometricAuthResult> authenticateWithBiometrics() async {
    try {
      // Check if device is locked out
      if (await _isLockedOut()) {
        return BiometricAuthResult.lockedOut;
      }

      if (!await isBiometricAvailable()) {
        return BiometricAuthResult.notAvailable;
      }

      if (!await isEnrolled()) {
        return BiometricAuthResult.notEnrolled;
      }

      try {
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Ferma App ga kirish uchun identifikatsiya qiling',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
            useErrorDialogs: true,
          ),
        );

        if (didAuthenticate) {
          await _resetFailedAttempts();
          await _updateLastAuthTime();
          return BiometricAuthResult.success;
        } else {
          await _recordFailedAttempt();
          return BiometricAuthResult.failed;
        }
      } on PlatformException catch (e) {
        print('Biometric authentication platform error: ${e.code} - ${e.message}');
        
        // Handle platform-specific error codes
        if (e.code == _kPasscodeNotSet) {
          return BiometricAuthResult.passcodeNotSet;
        } else if (e.code == _kNotEnrolled) {
          return BiometricAuthResult.notEnrolled;
        } else if (e.code == _kNotAvailable) {
          return BiometricAuthResult.notAvailable;
        } else if (e.code == _kLockedOut) {
          return BiometricAuthResult.lockedOut;
        } else if (e.code == _kPermanentlyLockedOut) {
          return BiometricAuthResult.permanentlyLocked;
        } else if (e.code == _kUserCanceled) {
          return BiometricAuthResult.cancelled;
        } else {
          return BiometricAuthResult.error;
        }
      }
    } catch (e) {
      print('Biometric authentication error: $e');
      return BiometricAuthResult.error;
    }
  }

  /// Authenticate with PIN code as fallback
  static Future<BiometricAuthResult> authenticateWithPin(String pin) async {
    if (await _isLockedOut()) {
      return BiometricAuthResult.lockedOut;
    }

    final isPinValid = await verifyPinCode(pin);
    if (isPinValid) {
      await _resetFailedAttempts();
      await _updateLastAuthTime();
      return BiometricAuthResult.success;
    } else {
      await _recordFailedAttempt();
      return BiometricAuthResult.failed;
    }
  }

  /// Change the current PIN code
  static Future<bool> changePinCode(String currentPin, String newPin) async {
    if (!await verifyPinCode(currentPin)) {
      return false;
    }
    return await setPinCode(newPin);
  }

  // Enable biometric authentication
  static Future<bool> enableBiometricAuth() async {
    await _initPrefs();
    final result = await authenticateWithBiometrics();
    if (result == BiometricAuthResult.success) {
      await _prefs!.setBool(_biometricEnabledKey, true);
      return true;
    }
    return false;
  }

  // Disable biometric authentication
  static Future<void> disableBiometricAuth() async {
    await _initPrefs();
    await _prefs!.setBool(_biometricEnabledKey, false);
  }

  // Check if biometric authentication is enabled
  static Future<bool> isBiometricEnabled() async {
    await _initPrefs();
    return _prefs!.getBool(_biometricEnabledKey) ?? false;
  }

  // Set PIN code for offline access
  static Future<bool> setPinCode(String pinCode) async {
    try {
      // Encrypt the PIN code before storing
      final encryptedPin = _encryptPin(pinCode);
      await _secureStorage.write(key: _pinCodeKey, value: encryptedPin);
      return true;
    } catch (e) {
      print('Error setting PIN code: $e');
      return false;
    }
  }

  // Verify PIN code
  static Future<bool> verifyPinCode(String pinCode) async {
    try {
      final storedPin = await _secureStorage.read(key: _pinCodeKey);
      if (storedPin == null) return false;
      
      final decryptedPin = _decryptPin(storedPin);
      final isValid = decryptedPin == pinCode;
      
      if (isValid) {
        await _updateLastAuthTime();
      }
      
      return isValid;
    } catch (e) {
      print('Error verifying PIN code: $e');
      return false;
    }
  }

  // Check if PIN code is set
  static Future<bool> isPinCodeSet() async {
    final storedPin = await _secureStorage.read(key: _pinCodeKey);
    return storedPin != null;
  }

  // Remove PIN code
  static Future<void> removePinCode() async {
    await _secureStorage.delete(key: _pinCodeKey);
  }

  // Check if authentication is required
  static Future<bool> isAuthRequired() async {
    await _initPrefs();
    final lastAuthTimeStr = _prefs!.getString(_lastAuthTimeKey);
    
    if (lastAuthTimeStr == null) return true;
    
    final lastAuthTime = DateTime.parse(lastAuthTimeStr);
    final now = DateTime.now();
    
    // Require authentication if more than 5 minutes have passed
    return now.difference(lastAuthTime).inMinutes > 5;
  }

  // Update last authentication time
  static Future<void> _updateLastAuthTime() async {
    await _initPrefs();
    await _prefs!.setString(_lastAuthTimeKey, DateTime.now().toIso8601String());
  }

  // Track failed authentication attempts
  static Future<void> _recordFailedAttempt() async {
    await _initPrefs();
    final attempts = (_prefs!.getInt(_failedAttemptsKey) ?? 0) + 1;
    await _prefs!.setInt(_failedAttemptsKey, attempts);
    await _prefs!.setString(_lastFailedAttemptKey, DateTime.now().toIso8601String());
  }

  // Reset failed attempts counter
  static Future<void> _resetFailedAttempts() async {
    await _initPrefs();
    await _prefs!.remove(_failedAttemptsKey);
    await _prefs!.remove(_lastFailedAttemptKey);
  }

  // Check if authentication is locked out due to too many failed attempts
  static Future<bool> _isLockedOut() async {
    await _initPrefs();
    final attempts = _prefs!.getInt(_failedAttemptsKey) ?? 0;
    
    if (attempts >= _maxFailedAttempts) {
      final lastAttemptStr = _prefs!.getString(_lastFailedAttemptKey);
      if (lastAttemptStr != null) {
        final lastAttempt = DateTime.parse(lastAttemptStr);
        final now = DateTime.now();
        final difference = now.difference(lastAttempt);
        
        if (difference < _lockoutDuration) {
          return true;
        } else {
          // Lockout period has passed, reset attempts
          await _resetFailedAttempts();
          return false;
        }
      }
    }
    
    return false;
  }

  // Get remaining lockout time in seconds
  static Future<int> getRemainingLockoutTime() async {
    await _initPrefs();
    final lastAttemptStr = _prefs!.getString(_lastFailedAttemptKey);
    
    if (lastAttemptStr != null) {
      final lastAttempt = DateTime.parse(lastAttemptStr);
      final now = DateTime.now();
      final difference = now.difference(lastAttempt);
      
      if (difference < _lockoutDuration) {
        return _lockoutDuration.inSeconds - difference.inSeconds;
      }
    }
    
    return 0;
  }

  // Simple PIN encryption (for demo purposes - in production use proper encryption)
  static String _encryptPin(String pin) {
    // In a production app, use a proper encryption library like Flutter Secure Storage
    // or encrypt/decrypt with platform channels using platform security features
    const key = 'FermaAppSecureKey2024';
    String encrypted = '';
    
    for (int i = 0; i < pin.length; i++) {
      final charCode = pin.codeUnitAt(i) ^ key.codeUnitAt(i % key.length);
      encrypted += charCode.toRadixString(16).padLeft(2, '0');
    }
    
    return encrypted;
  }

  // Simple PIN decryption
  static String _decryptPin(String encryptedPin) {
    const key = 'FermaAppSecureKey2024';
    String decrypted = '';
    
    try {
      for (int i = 0; i < encryptedPin.length; i += 2) {
        final hexCode = encryptedPin.substring(i, i + 2);
        final charCode = int.parse(hexCode, radix: 16) ^ key.codeUnitAt((i ~/ 2) % key.length);
        decrypted += String.fromCharCode(charCode);
      }
    } catch (e) {
      print('Decryption error: $e');
      return '';
    }
    
    return decrypted;
  }

  // Get biometric type name in Uzbek
  static String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Yuz tanish (Face ID)';
      case BiometricType.fingerprint:
        return 'Barmoq izi';
      case BiometricType.iris:
        return 'Ko\'z qorachig\'i';
      case BiometricType.strong:
        return 'Kuchli biometrik';
      case BiometricType.weak:
        return 'Zaif biometrik';
      default:
        return 'Biometrik identifikatsiya';
    }
  }

  // Get authentication error message in Uzbek
  static String getErrorMessage(BiometricAuthResult result) {
    switch (result) {
      case BiometricAuthResult.success:
        return 'Muvaffaqiyatli identifikatsiya qilindi';
      case BiometricAuthResult.failed:
        return 'Identifikatsiya muvaffaqiyatsiz';
      case BiometricAuthResult.notAvailable:
        return 'Biometrik identifikatsiya mavjud emas';
      case BiometricAuthResult.notEnrolled:
        return 'Biometrik ma\'lumot sozlanmagan';
      case BiometricAuthResult.cancelled:
        return 'Foydalanuvchi tomonidan bekor qilindi';
      case BiometricAuthResult.error:
        return 'Identifikatsiyada xatolik yuz berdi';
      case BiometricAuthResult.lockedOut:
        return 'Juda ko\'p noto\'g\'ri urinishlar. Iltimos, keyinroq urinib ko\'ring';
      case BiometricAuthResult.permanentlyLocked:
        return 'Hisob bloklandi. Iltimos, qayta o\'rnating';
      case BiometricAuthResult.passcodeNotSet:
        return 'Qurilmada parol sozlanmagan';
      case BiometricAuthResult.notConfigured:
        return 'Biometrik autentifikatsiya sozlanmagan';
    }
  }

  // Quick authentication check (biometric or PIN)
  static Future<bool> quickAuth() async {
    if (await isBiometricEnabled()) {
      final result = await authenticateWithBiometrics();
      return result == BiometricAuthResult.success;
    } else if (await isPinCodeSet()) {
      // For PIN, we'll need to show a dialog - this should be handled by UI
      return false;
    }
    return true; // No authentication required
  }

  // Clear all authentication data
  static Future<void> clearAllAuthData() async {
    await disableBiometricAuth();
    await removePinCode();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastAuthTimeKey);
  }
} 