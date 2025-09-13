import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/farm_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/customers/customers_screen.dart';
import 'screens/chickens/chickens_screen.dart';
import 'screens/error/error_screen.dart';
import 'utils/app_theme.dart';
import 'services/notification_service.dart';
import 'services/activity_log_service.dart';
import 'services/inventory_service.dart';

// SAFE HIVE BOX MANAGEMENT
Future<void> _openHiveBoxSafely<T>(String boxName, T defaultValue) async {
  try {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<T>(boxName);
      print('📬 Box ochildi: $boxName');
    } else {
      print('ℹ️ Box allaqachon ochiq: $boxName');
    }
  } catch (e) {
    print('⚠️ Box ochishda xatolik ($boxName): $e');
    // Try to delete corrupted box and recreate
    try {
      await Hive.deleteBoxFromDisk(boxName);
      await Hive.openBox<T>(boxName);
      print('🔄 Box qayta yaratildi: $boxName');
    } catch (recreateError) {
      print('❌ Box qayta yaratishda ham xatolik ($boxName): $recreateError');
      // Continue without this box
    }
  }
}

// ESKI HIVE BOXLARNI TOZALASH
Future<void> _cleanupOldHiveBoxes() async {
  final boxesToCleanup = ['farms', 'activity_logs', 'farm_backup', 'inventory_items', 'inventory_transactions'];
  
  for (final boxName in boxesToCleanup) {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
        print('🗋 Box yopildi: $boxName');
      }
      
      // Delete from disk to prevent type conflicts
      await Hive.deleteBoxFromDisk(boxName);
      print('🧹 Box diskdan tozalandi: $boxName');
      
    } catch (e) {
      print('⚠️ Box tozalashda xatolik ($boxName): $e');
      // Continue with other boxes
    }
  }
  
  print('✅ Barcha eski boxlar tozalandi');
}

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Enable edge-to-edge mode for modern Android
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Initialize error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint(details.exceptionAsString());
      debugPrint(details.stack.toString());
    }
  };

  // KUCHLI HIVE INITIALIZATION
  await Hive.initFlutter();
  
  // Register all necessary adapters
  print('📦 Hive adapterlarini ro\'yxatga olish...');
  
  // Ensure adapter registration is safe
  try {
    // Activity Log adapters are already registered in ActivityLogService
    // Inventory adapters are already registered in InventoryService
    
    // Clean up old boxes first to prevent type conflicts
    await _cleanupOldHiveBoxes();
    
    // Open critical boxes with error handling - using consistent Map types
    await _openHiveBoxSafely<Map>('farms', <String, dynamic>{});
    await _openHiveBoxSafely<Map>('activity_logs', <String, dynamic>{});
    await _openHiveBoxSafely<Map>('farm_backup', <String, dynamic>{});
    await _openHiveBoxSafely<Map>('inventory_items', <String, dynamic>{});
    await _openHiveBoxSafely<Map>('inventory_transactions', <String, dynamic>{});
    
    print('✅ Barcha Hive boxes muvaffaqiyatli ochildi');
    
  } catch (e) {
    print('❌ Hive adapter/box xatosi: $e');
    // Continue without crashing
  }
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  // Initialize Notification Service
  await NotificationService.initialize();
  
  // Initialize Activity Log Service  
  await ActivityLogService.initialize();
  
  // Initialize Inventory Service
  await InventoryService.initialize();
}

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      try {
        await initializeApp();
        runApp(const FermaApp());
      } catch (e, stackTrace) {
        debugPrint('Fatal error during app initialization: $e\n$stackTrace');
        runApp(
          MaterialApp(
            home: ErrorScreen(
              error: e.toString(),
              stackTrace: stackTrace.toString(),
            ),
          ),
        );
      }
    },
    (error, stackTrace) {
      debugPrint('Uncaught error: $error\n$stackTrace');
      runApp(
        MaterialApp(
          home: ErrorScreen(
            error: error.toString(),
            stackTrace: stackTrace.toString(),
          ),
        ),
      );
    },
  );
}

class FermaApp extends StatefulWidget {
  const FermaApp({super.key});

  @override
  State<FermaApp> createState() => _FermaAppState();
}

class _FermaAppState extends State<FermaApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupResources();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.resumed:
        // App returned to foreground
        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          authProvider.checkAuthStatus();
          
          final farmProvider = Provider.of<FarmProvider>(context, listen: false);
          farmProvider.startRealtime();
        } catch (e) {
          debugPrint('Error resuming app: $e');
        }
        break;
        
      case AppLifecycleState.paused:
        // App going to background - save data
        try {
          final farmProvider = Provider.of<FarmProvider>(context, listen: false);
          farmProvider.stopRealtime();
        } catch (e) {
          debugPrint('Error pausing app: $e');
        }
        break;
        
      case AppLifecycleState.detached:
        // App being terminated - final cleanup
        _cleanupResources();
        break;
        
      default:
        break;
    }
  }
  
  void _cleanupResources() {
    try {
      // Close all Hive boxes
      Hive.close();
      debugPrint('🧹 Hive boxes yopildi');
    } catch (e) {
      debugPrint('Hive cleanup xatosi: $e');
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Add any additional initialization here
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      // Handle initialization error
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, FarmProvider>(
          create: (context) => FarmProvider(),
          update: (_, auth, farmProv) {
            final provider = farmProv ?? FarmProvider();
            final farm = auth.farm;
            if (farm != null) {
              provider.setFarm(farm);
              provider.startRealtime();
            } else {
              provider.stopRealtime();
            }
            return provider;
          },
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Ferma App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            navigatorKey: _navigatorKey,
            onGenerateRoute: (settings) {
              // Handle deep linking here if needed
              return null;
            },
            home: _isInitialized 
                ? (authProvider.isAuthenticated || authProvider.farm != null)
                    ? const MainScreen() 
                    : const LoginScreen()
                : const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const MainScreen(),
              '/customers': (context) => const CustomersScreen(),
              '/chickens': (context) => const ChickensScreen(),
            },
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}