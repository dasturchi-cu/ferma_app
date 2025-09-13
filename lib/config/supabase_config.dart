import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Configuration class for Supabase client
class SupabaseConfig {
  static const String _supabaseUrl = 'https://hucjvlyjeqoiridxyqjz.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh1Y2p2bHlqZXFvaXJpZHh5cWp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcyMzEwMzgsImV4cCI6MjA3MjgwNzAzOH0.BmjOFS915qS8K_6m6PV1zBplqdnXNKqUzHEdfM_C6gw';
  
  static late final SupabaseClient _client;
  static bool _isInitialized = false;
  
  /// Private constructor to prevent instantiation
  SupabaseConfig._();
  
  /// KUCHLI SUPABASE INITIALIZATION
  static Future<void> initialize({int maxRetries = 3}) async {
    if (_isInitialized) return;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔄 Supabase initialization urinishi #$attempt...');
        
        await Supabase.initialize(
          url: _supabaseUrl,
          anonKey: _supabaseAnonKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
          storageOptions: const StorageClientOptions(
            retryAttempts: 10, // Ko'proq retry
          ),
          realtimeClientOptions: const RealtimeClientOptions(
            eventsPerSecond: 10,
          ),
          debug: !kReleaseMode,
        );
        
        _client = Supabase.instance.client;
        
        // Connection test
        await _testConnection();
        
        _isInitialized = true;
        debugPrint('✅ Supabase muvaffaqiyatli ishga tushdi');
        return;
        
      } catch (e, stackTrace) {
        debugPrint('⚠️ Supabase init urinishi #$attempt muvaffaqiyatsiz: $e');
        
        if (attempt == maxRetries) {
          debugPrint('❌ Barcha Supabase init urinishlari muvaffaqiyatsiz');
          _isInitialized = false;
          _handleError(e, stackTrace);
          
          // Don't throw - allow app to work offline
          debugPrint('📱 Offline rejimda davom etish...');
          return;
        }
        
        // Wait before retry
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
  }
  
  /// TEST CONNECTION
  static Future<void> _testConnection() async {
    try {
      // Simple health check query
      await _client.from('farms').select('id').limit(1).withConverter((data) => data);
      debugPrint('🌐 Supabase aloqasi tasdiqlandi');
    } catch (e) {
      debugPrint('⚡ Supabase aloqa testi muvaffaqiyatsiz: $e');
      // Still allow initialization to proceed
    }
  }
  
  /// NETWORK-SAFE QUERY WRAPPER
  static Future<T> safeQuery<T>(
    Future<T> Function() query, {
    T? defaultValue,
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await query();
      } catch (e) {
        debugPrint('🚫 Query attempt #$attempt failed: $e');
        
        if (attempt == maxRetries) {
          debugPrint('❌ Barcha query urinishlari muvaffaqiyatsiz');
          if (defaultValue != null) {
            debugPrint('💾 Default qiymat qaytarilmoqda');
            return defaultValue;
          }
          rethrow;
        }
        
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    
    throw Exception('Unreachable code');
  }
  
  /// Get Supabase client instance
  static SupabaseClient get client {
    _checkInitialized();
    return _client;
  }
  
  /// Get Supabase auth instance
  static GoTrueClient get auth => client.auth;
  
  /// Get Supabase storage instance
  static SupabaseStorageClient get storage => client.storage;
  
  /// Get Supabase database instance (PostgREST)
  static PostgrestClient get database => client.rest;
  
  /// Get Supabase realtime instance
  static RealtimeClient get realtime => client.realtime;
  
  /// Check if user is authenticated
  static bool get isAuthenticated => _isInitialized && _client.auth.currentSession != null;
  
  /// Get current user ID if authenticated
  static String? get currentUserId => _client.auth.currentUser?.id;
  
  /// Get current user session if authenticated
  static Session? get currentSession => _client.auth.currentSession;
  
  /// Sign out the current user
  static Future<void> signOut() async {
    if (_isInitialized) {
      try {
        await _client.auth.signOut();
      } catch (e, stackTrace) {
        _handleError(e, stackTrace);
        rethrow;
      }
    }
  }
  
  /// Check if Supabase is initialized
  static void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception('Supabase has not been initialized. Call SupabaseConfig.initialize() first.');
    }
  }
  
  /// Handle errors in a consistent way
  static void _handleError(dynamic error, [StackTrace? stackTrace]) {
    String errorMessage = 'An unexpected error occurred';
    
    if (error is PostgrestException) {
      errorMessage = 'Database error: ${error.message}';
    } else if (error is AuthException) {
      errorMessage = 'Authentication error: ${error.message}';
    } else if (error is StorageException) {
      errorMessage = 'Storage error: ${error.message}';
    } else if (error is String) {
      errorMessage = error;
    } else if (error is Error) {
      errorMessage = error.toString();
    }
    
    if (kDebugMode) {
      debugPrint('🔴 Error: $errorMessage');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }
}
