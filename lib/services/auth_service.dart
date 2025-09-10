import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  final dynamic error;

  AuthException(this.message, [this.error]);

  @override
  String toString() => error != null 
      ? 'AuthException: $message\nError: $error' 
      : 'AuthException: $message';
}

class AuthService {
  final _supabase = SupabaseConfig.client;
  
  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;
  
  // Get current user
  User? get currentUser => _supabase.auth.currentUser;
  
  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;
  
  /// Signs up a new user with email and password
  /// 
  /// Throws [AuthException] if sign up fails
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required Map<String, dynamic> userMetadata,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: userMetadata,
      );
      
      if (response.user == null) {
        throw AuthException('Failed to create user account');
      }
      
      return response;
    } catch (e, stackTrace) {
      debugPrint('Sign up error: $e\n$stackTrace');
      throw AuthException('Failed to sign up: ${e.toString()}', e);
    }
  }
  
  /// Signs in a user with email and password
  /// 
  /// Throws [AuthException] if sign in fails
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw AuthException('Invalid email or password');
      }
      
      return response;
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Sign in error: $e\n$stackTrace');
      throw AuthException('Failed to sign in: ${e.toString()}', e);
    }
  }
  
  /// Signs out the current user
  /// 
  /// Throws [AuthException] if sign out fails
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e, stackTrace) {
      debugPrint('Sign out error: $e\n$stackTrace');
      throw AuthException('Failed to sign out', e);
    }
  }
  
  /// Sends a password reset email to the specified email address
  /// 
  /// Throws [AuthException] if the request fails
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : 'io.supabase.fermani://reset-password',
      );
    } catch (e, stackTrace) {
      debugPrint('Password reset error: $e\n$stackTrace');
      throw AuthException('Failed to send password reset email', e);
    }
  }
  
  /// Updates the user's password
  /// 
  /// Throws [AuthException] if the update fails
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e, stackTrace) {
      debugPrint('Update password error: $e\n$stackTrace');
      throw AuthException('Failed to update password', e);
    }
  }
  
  /// Updates the user's profile information
  /// 
  /// Throws [AuthException] if the update fails
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    } catch (e, stackTrace) {
      debugPrint('Update profile error: $e\n$stackTrace');
      throw AuthException('Failed to update profile', e);
    }
  }
  
  /// Sends a password reset email to the specified email address
  /// 
  /// Throws [AuthException] if the request fails
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        // TODO: Configure redirect URL in Supabase dashboard
        // redirectTo: 'your-app-scheme://reset-password',
      );
    } catch (e, stackTrace) {
      debugPrint('Reset password error: $e\n$stackTrace');
      throw AuthException('Failed to send password reset email', e);
    }
  }
  
  /// Gets the user's profile information
  /// 
  /// Returns null if the profile is not found
  /// Throws [AuthException] if the request fails
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
          
return response;
    } catch (e, stackTrace) {
      debugPrint('Get profile error: $e\n$stackTrace');
      throw AuthException('Failed to get user profile', e);
    }
  }
  
  /// Gets the current user's session data
  /// 
  /// Returns null if no user is signed in
  Map<String, dynamic>? get sessionData {
    final session = currentSession;
    if (session == null) return null;
    
    return {
      'accessToken': session.accessToken,
      'refreshToken': session.refreshToken,
      'expiresAt': _formatTimestamp(session.expiresAt),
      'user': {
        'id': currentUser?.id,
        'email': currentUser?.email,
        'phone': currentUser?.phone,
        'role': currentUser?.role,
        'lastSignInAt': _formatTimestamp(currentUser?.lastSignInAt),
        'createdAt': _formatTimestamp(currentUser?.createdAt),
        'updatedAt': _formatTimestamp(currentUser?.updatedAt),
      },
    };
  }
  
  // Helper method to format timestamps
  String? _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    
    if (timestamp is DateTime) {
      return timestamp.toIso8601String();
    } else if (timestamp is int || timestamp is String) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(timestamp is String ? int.parse(timestamp) : timestamp)
            .toIso8601String();
      } catch (e) {
        debugPrint('Error formatting timestamp: $e');
        return timestamp.toString();
      }
    }
    
    return timestamp.toString();
  }
  
  /// Stream of authentication state changes
  /// 
  /// This stream emits events when the user's authentication state changes
  /// (e.g., signed in, signed out, token refreshed)
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;
  
  /// Gets the current authentication state
  /// 
  /// Returns a map containing the current user and session information
  Map<String, dynamic>? get currentAuthState {
    final user = currentUser;
    final session = currentSession;
    
    if (user == null || session == null) return null;
    
    return {
      'isAuthenticated': true,
      'user': {
        'id': user.id,
        'email': user.email,
        'phone': user.phone,
        'role': user.role,
      },
      'session': {
        'accessToken': session.accessToken,
        'refreshToken': session.refreshToken,
        'expiresAt': _formatTimestamp(session.expiresAt),
      },
    };
  }
}
