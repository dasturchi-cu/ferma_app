import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode, BindingBase;

import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/farm_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/search_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/customers/customers_screen.dart';
import 'screens/chickens/chickens_screen.dart';
import 'services/notification_service.dart';
import 'services/activity_log_service.dart';
import 'services/inventory_service.dart';

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

  // Eski boxlarni tozalashni o‘chirildi: foydalanuvchi ma’lumotlari saqlanib qolishi kerak
  // Agar bir kun majburiy migratsiya kerak bo‘lsa, faqat vaqtinchalik flag orqali ishga tushiring.
  // await _cleanupOldHiveBoxes();

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

void main() {
  // Zone xatolarini faqatgina developmentda o'chirish
  if (kDebugMode) {
    BindingBase.debugZoneErrorsAreFatal = false;
  }

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
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
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, _) {
          return MaterialApp(
            title: 'Ferma App',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
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
