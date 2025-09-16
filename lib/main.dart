import 'dart:async';
import 'package:ferma_app/screens/eggs/eggs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode, BindingBase;

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
import 'utils/modern_theme.dart';
import 'services/notification_service.dart';
import 'services/activity_log_service.dart';
import 'services/inventory_service.dart';
import 'models/farm.dart'; // Model fayllarini import qilish
import 'models/chicken.dart';
import 'models/egg.dart';
import 'models/activity_log.dart';
import 'models/inventory.dart';

// Xavfsiz Hive Boxlarini Boshqarish
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
    // Buzilgan boxni tozalab, qayta ochishga harakat qilish
    try {
      await Hive.deleteBoxFromDisk(boxName);
      await Hive.openBox<T>(boxName);
      print('✅ Buzilgan box tozalanib qayta ochildi: $boxName');
    } catch (recreateError) {
      print('❌ Box qayta yaratishda ham xatolik ($boxName): $recreateError');
      // Bu boxsiz davom etish
    }
  }
}

// Eski Hive boxlarni to'g'ri tozalash
Future<void> _cleanupOldHiveBoxes() async {
  final boxesToCleanup = ['farms', 'activity_logs', 'farm_backup', 'inventory_items', 'inventory_transactions'];

  for (final boxName in boxesToCleanup) {
    try {
      // Birinchi, boxni yopish
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
        print('🗋 Box yopildi: $boxName');
      }

      // Keyin, boxni diskdan o'chirish
      await Hive.deleteBoxFromDisk(boxName);
      print('🧹 Box diskdan tozalandi: $boxName');

    } catch (e) {
      print('⚠️ Box tozalashda xatolik ($boxName): $e');
      // Boshqa boxlar bilan davom etish
    }
  }

  print('✅ Barcha eski boxlar tozalandi');
}

Future<void> initializeApp() async {
  // Orientatsiya va UI sozlamalari
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Xatolarni boshqarishni sozlash
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint(details.exceptionAsString());
      debugPrint(details.stack.toString());
    }
  };

  // Hive va Supabase'ni ishga tushirish
  await Hive.initFlutter();

  // Adapterlarni ro'yxatdan o'tkazish
  // print('📦 Hive adapterlarini ro\'yxatga olish...');
  // Hive.registerAdapter(FarmProvider());
  // Hive.registerAdapter(ChickenAdapter());
  // Hive.registerAdapter(EggsScreen() as TypeAdapter);
  // Hive.registerAdapter(EggProductionAdapter());
  // Hive.registerAdapter(EggsScreen() as TypeAdapter);
  // Hive.registerAdapter(ActivityLogAdapter());
  // Hive.registerAdapter(InventoryItemAdapter());
  // Hive.registerAdapter(InventoryTransactionAdapter());

  // Eski boxlarni tozalash
  await _cleanupOldHiveBoxes();

  // Yangi boxlarni xavfsiz ochish
  await _openHiveBoxSafely<Map>('farms', <String, dynamic>{});
  await _openHiveBoxSafely<Map>('activity_logs', <String, dynamic>{});
  await _openHiveBoxSafely<Map>('farm_backup', <String, dynamic>{});
  await _openHiveBoxSafely<Map>('inventory_items', <String, dynamic>{});
  await _openHiveBoxSafely<Map>('inventory_transactions', <String, dynamic>{});

  print('✅ Barcha Hive boxes muvaffaqiyatli ochildi');

  await SupabaseConfig.initialize();
  await NotificationService.initialize();
  await ActivityLogService.initialize();
  await InventoryService.initialize();
}

void main() async {
  BindingBase.debugZoneErrorsAreFatal = true;
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded<Future<void>>(
        () async {
      await initializeApp();
      runApp(const FermaApp());
    },
        (error, stackTrace) {
      debugPrint('Uncaught error: $error\n$stackTrace');
    },
  );
}

class FermaApp extends StatefulWidget {
  const FermaApp({super.key});

  @override
  State<FermaApp> createState() => _FermaAppState();
}

class _FermaAppState extends State<FermaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Hive.close(); // Ilova yopilayotganda barcha boxlarni yopish
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      Hive.close();
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
            theme: ModernTheme.lightTheme,
            home: (authProvider.isAuthenticated || authProvider.farm != null)
                ? const MainScreen()
                : const LoginScreen(),
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