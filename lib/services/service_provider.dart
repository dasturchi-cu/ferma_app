import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'storage_service.dart';
import 'realtime_service.dart';

class ServiceProvider with ChangeNotifier {
  static final ServiceProvider _instance = ServiceProvider._internal();
  
  // Services
  late final AuthService _authService;
  late final DatabaseService _databaseService;
  late final StorageService _storageService;
  late final RealtimeService _realtimeService;
  
  // Getters
  AuthService get auth => _authService;
  DatabaseService get database => _databaseService;
  StorageService get storage => _storageService;
  RealtimeService get realtime => _realtimeService;
  
  // Private constructor
  ServiceProvider._internal() {
    _initializeServices();
  }
  
  // Factory constructor to return the same instance
  factory ServiceProvider() => _instance;
  
  // Initialize all services
  void _initializeServices() {
    try {
      // Get Supabase client
      final supabaseClient = Supabase.instance.client;
      
      // Initialize services with proper error handling
      _authService = AuthService();
      _databaseService = DatabaseService();
      _storageService = StorageService();
      _realtimeService = RealtimeService(supabaseClient: supabaseClient);
      
      // Initialize any necessary listeners or subscriptions
      _initializeListeners();
    } catch (e) {
      print('Error initializing services: $e');
      // Consider showing an error to the user or retrying
      rethrow;
    }
  }
  
  // Initialize any listeners or subscriptions
  void _initializeListeners() {
    try {
      // Listen for auth state changes
      _authService.onAuthStateChange.listen((authState) {
        if (authState.event == AuthChangeEvent.signedIn) {
          // User signed in, initialize user-specific services
          _initializeUserServices();
        } else if (authState.event == AuthChangeEvent.signedOut) {
          // User signed out, clean up
          _cleanupUserServices();
        } else if (authState.event == AuthChangeEvent.tokenRefreshed) {
          // Token was refreshed, update any necessary services
          _onTokenRefreshed();
        }
        
        // Notify listeners (UI) about auth state changes
        notifyListeners();
      });
    } catch (e) {
      print('Error initializing auth state listener: $e');
    }
  }
  
  // Initialize services that require an authenticated user
  void _initializeUserServices() async {
    try {
      // Initialize any user-specific services or subscriptions here
      await _realtimeService.initializeUserSubscriptions();
      
      // Pre-fetch any initial data the app needs
      await _prefetchUserData();
    } catch (e) {
      print('Error initializing user services: $e');
    }
  }
  
  // Handle token refresh
  void _onTokenRefreshed() {
    // Update any services that depend on the auth token
    _realtimeService.updateAuthToken();
  }
  
  // Pre-fetch user data after sign in
  Future<void> _prefetchUserData() async {
    try {
      // Add any initial data fetching needed after sign in
      // Example: await _databaseService.getUserProfile();
    } catch (e) {
      print('Error prefetching user data: $e');
    }
  }
  
  // Clean up user-specific services when signing out
  Future<void> _cleanupUserServices() async {
    try {
      // Clean up any user-specific services or subscriptions
      await _realtimeService.unsubscribeAll();
      
      // Clear any cached user data
      // _cacheService.clearUserData();
    } catch (e) {
      print('Error cleaning up user services: $e');
    }
  }
  
  // Dispose method to clean up resources
  @override
  void dispose() async {
    await _cleanupUserServices();
    await _realtimeService.dispose();
    super.dispose();
  }
  
  // Static method to get the instance
  static ServiceProvider get instance => _instance;
}
