// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:provider/provider.dart';
// import 'package:workmanager/workmanager.dart';

// import 'firebase_options.dart';
// import 'models/farm.dart';
// import 'models/chicken.dart';
// import 'models/egg.dart';
// import 'models/customer.dart';
// import 'data/models/daily_record.dart';
// import 'data/models/user_profile.dart';
// import 'data/models/sale.dart';
// import 'data/models/monthly_summary.dart';
// import 'providers/auth_provider.dart';
// import 'providers/farm_provider.dart';
// import 'screens/splash_screen.dart';
// import 'screens/auth/login_screen.dart';
// import 'screens/main/main_screen.dart';
// import 'services/notification_service.dart';
// import 'utils/app_theme.dart';
// import 'utils/constants.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize timezone
//   // tz.initializeTimeZones();

//   // Initialize Firebase
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//   // Initialize Hive
//   await Hive.initFlutter();

//   // Register Hive adapters
//   if (!Hive.isAdapterRegistered(0)) {
//     Hive.registerAdapter(ChickenAdapter());
//   }
//   if (!Hive.isAdapterRegistered(1)) {
//     Hive.registerAdapter(ChickenDeathAdapter());
//   }
//   if (!Hive.isAdapterRegistered(2)) {
//     Hive.registerAdapter(EggAdapter());
//   }
//   if (!Hive.isAdapterRegistered(3)) {
//     Hive.registerAdapter(EggProductionAdapter());
//   }
//   if (!Hive.isAdapterRegistered(4)) {
//     Hive.registerAdapter(EggSaleAdapter());
//   }
//   if (!Hive.isAdapterRegistered(5)) {
//     Hive.registerAdapter(BrokenEggAdapter());
//   }
//   if (!Hive.isAdapterRegistered(6)) {
//     Hive.registerAdapter(LargeEggAdapter());
//   }
//   if (!Hive.isAdapterRegistered(7)) {
//     Hive.registerAdapter(CustomerAdapter());
//   }
//   if (!Hive.isAdapterRegistered(8)) {
//     Hive.registerAdapter(CustomerOrderAdapter());
//   }
//   if (!Hive.isAdapterRegistered(9)) {
//     Hive.registerAdapter(FarmAdapter());
//   }
//   if (!Hive.isAdapterRegistered(10)) {
//     Hive.registerAdapter(DailyRecordAdapter());
//   }
//   if (!Hive.isAdapterRegistered(11)) {
//     Hive.registerAdapter(UserProfileAdapter());
//   }
//   if (!Hive.isAdapterRegistered(12)) {
//     Hive.registerAdapter(SaleAdapter());
//   }
//   if (!Hive.isAdapterRegistered(13)) {
//     Hive.registerAdapter(MonthlySummaryAdapter());
//   }

//   // Open Hive boxes
//   await Hive.openBox<Farm>(AppConstants.farmBoxName);
//   await Hive.openBox(AppConstants.settingsBoxName);

//   // Initialize notification service
//   await NotificationService().initialize();

//   // Initialize WorkManager for background tasks
//   Workmanager().initialize(
//     NotificationService.callbackDispatcher,
//     isInDebugMode: false,
//   );

//   runApp(const FermaApp());
// }

// class FermaApp extends StatelessWidget {
//   const FermaApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProvider()),
//         ChangeNotifierProvider(create: (_) => FarmProvider()),
//       ],
//       child: MaterialApp(
//         title: 'Ferma App',
//         debugShowCheckedModeBanner: false,
//         theme: AppTheme.lightTheme,
//         darkTheme: AppTheme.darkTheme,
//         themeMode: ThemeMode.system,
//         home: const SplashScreen(),
//         routes: {
//           '/login': (context) => const LoginScreen(),
//           '/dashboard': (context) => const MainScreen(),
//         },
//       ),
//     );
//   }
// }
