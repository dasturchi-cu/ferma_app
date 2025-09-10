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
  
  /// Initialize Supabase client
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        storageOptions: const StorageClientOptions(
          retryAttempts: 5,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          eventsPerSecond: 20,
        ),
        debug: !kReleaseMode,
      );
      
      _client = Supabase.instance.client;
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('✅ Supabase initialized successfully');
      }
    } catch (e, stackTrace) {
      _isInitialized = false;
      _handleError(e, stackTrace);
      rethrow;
    }
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
