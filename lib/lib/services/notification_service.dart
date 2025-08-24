import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import '../utils/constants.dart';

// Notification channels
enum NotificationChannelType {
  reminders,
  alerts,
  transactions,
  system,
}

// Notification types
enum NotificationType {
  reminder,
  alert,
  transaction,
  report,
  threshold,
  health,
  system,
}

// Notification actions
enum NotificationAction {
  viewDetails,
  markAsDone,
  remindLater,
  viewReport,
  acknowledge,
  dismiss,
  takeAction,
  viewChart,
  call,
  navigate,
}

// Report types
enum ReportType {
  dailySummary,
  weeklySummary,
  monthlySummary,
  salesReport,
  productionReport,
  healthReport,
}

// Threshold types
enum ThresholdType {
  temperatureHigh,
  temperatureLow,
  humidityHigh,
  humidityLow,
  feedLow,
  waterLow,
  eggProductionLow,
  mortalityHigh,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  late final FlutterLocalNotificationsPlugin _localNotifications;

  // Initialize WorkManager for background tasks
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      try {
        final notificationService = NotificationService();

        switch (task) {
          case 'daily_reminder':
            await notificationService._showDailyReminder();
            break;
          case 'debt_reminder':
            await notificationService._showDebtReminder(
              inputData?['customerName'] ?? 'Mijoz',
              double.tryParse(inputData?['debt'] ?? '0') ?? 0,
              inputData?['phone'] ?? '',
            );
            break;
          case 'delivery_reminder':
            await notificationService._showDeliveryReminder(
              inputData?['customerName'] ?? 'Mijoz',
              inputData?['deliveryDate'] ?? 'bugun',
              int.tryParse(inputData?['trayCount'] ?? '0') ?? 0,
            );
            break;
        }
        return true;
      } catch (e) {
        print('Background task error: $e');
        return false;
      }
    });
  }

  Future<void> initialize() async {
    try {
      // Initialize timezone
      tz_data.initializeTimeZones();

      // Initialize local notifications
      _localNotifications = FlutterLocalNotificationsPlugin();

      // Initialize WorkManager
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );

      // Firebase Cloud Messaging ruxsatlari
      NotificationSettings settings;
      try {
        settings = await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: true,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
      } catch (e) {
        print('FCM permission error: $e');
        return;
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('FCM ruxsati berildi');

        try {
          // FCM token olish va yangilash
          await _setupTokenRefresh();

          // Foreground message handling
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

          // Background message handling
          FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

          // App ochilganda message handling
          FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

          // Get initial message if app was opened from terminated state
          _getInitialMessage();
        } catch (e) {
          print('FCM setup error: $e');
        }
      } else {
        print('FCM ruxsati berilmadi. Status: ${settings.authorizationStatus}');
      }

      // Local notifications sozlash
      try {
        await _initializeLocalNotifications();
      } catch (e) {
        print('Local notifications setup error: $e');
      }
    } catch (e) {
      print('Notification service initialization error: $e');
    }
  }

  Future<void> _setupTokenRefresh() async {
    try {
      // Get initial token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        // TODO: Save token to your backend
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
        // TODO: Update token in your backend
      });
    } catch (e) {
      print('Token refresh error: $e');
    }
  }

  Future<void> _getInitialMessage() async {
    try {
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      print('Error getting initial message: $e');
      rethrow;
    }
  }

  // Initialize local notifications for Android
  Future<void> _initializeLocalNotifications() async {
    try {
      // Initialize timezone
      tz_data.initializeTimeZones();

      // Android notification initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Initialize settings for Android only
      final initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      // Initialize notifications
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _createNotificationChannels();
    } catch (e) {
      print('Error initializing local notifications: $e');
      rethrow;
    }
  }

  // Foreground message handling
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');

    // Local notification ko'rsatish
    _showLocalNotification(
      title: message.notification?.title ?? 'Yangi xabar',
      body: message.notification?.body ?? 'Xabar matni',
      payload: message.data.toString(),
    );
  }

  // Background message handling
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Background message: ${message.notification?.title}');

    // Background'da local notification ko'rsatish
    final notificationService = NotificationService();
    await notificationService._showLocalNotification(
      title: message.notification?.title ?? 'Yangi xabar',
      body: message.notification?.body ?? 'Xabar matni',
      payload: message.data.toString(),
    );
  }

  // App ochilganda message handling
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.notification?.title}');
    // Bu yerda app ichida sahifaga o'tish mumkin
  }

  // Local notification ko'rsatish
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    NotificationType notificationType = NotificationType.alert,
    List<MapEntry<String, String>>? actions,
  }) async {
    // Determine channel based on notification type
    String channelId;
    String channelName;
    String channelDescription;

    switch (notificationType) {
      case NotificationType.reminder:
        channelId = 'reminder_channel';
        channelName = 'Eslatmalar';
        channelDescription = 'Kunlik eslatmalar va bildirishnomalar';
        break;
      case NotificationType.alert:
        channelId = 'alert_channel';
        channelName = 'Ogohlantirishlar';
        channelDescription = 'Muhim ogohlantirishlar va xavf-xatarlar';
        break;
      case NotificationType.transaction:
        channelId = 'transaction_channel';
        channelName = 'Tranzaksiyalar';
        channelDescription = 'Sotuvlar va xaridlar haqida bildirishnomalar';
        break;
      case NotificationType.report:
        channelId = 'report_channel';
        channelName = 'Hisobotlar';
        channelDescription = 'Muntazam hisobotlar va tahlillar';
        break;
      case NotificationType.threshold:
        channelId = 'threshold_channel';
        channelName = 'Chegaraviy qiymatlar';
        channelDescription = 'Chegaraviy qiymatlar haqida ogohlantirishlar';
        break;
      case NotificationType.health:
        channelId = 'health_channel';
        channelName = 'Sog\'liqni saqlash';
        channelDescription = 'Tovuqlar sog\'ligi haqida ogohlantirishlar';
        break;
      case NotificationType.system:
        channelId = 'system_channel';
        channelName = 'Tizim xabarlari';
        channelDescription = 'Tizim va yangilanishlar haqida xabarlar';
        break;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableLights: true,
      enableVibration: true,
      styleInformation: const BigTextStyleInformation(''),
      actions: actions
          ?.map((action) => AndroidNotificationAction(
                action.key,
                action.value,
                showsUserInterface: true,
                cancelNotification: action.key == 'dismiss',
              ))
          .toList(),
    );

    final iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
      attachments: null,
      threadIdentifier: channelId,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    try {
      // Reminders channel
      const AndroidNotificationChannel reminderChannel =
          AndroidNotificationChannel(
        'reminder_channel',
        'Eslatmalar',
        description: 'Kunlik eslatmalar va bildirishnomalar',
        importance: Importance.high,
        playSound: true,
        showBadge: true,
      );

      // Alerts channel
      const AndroidNotificationChannel alertChannel =
          AndroidNotificationChannel(
        'alert_channel',
        'Ogohlantirishlar',
        description: 'Muhim ogohlantirishlar va xavf-xatarlar',
        importance: Importance.high,
        playSound: true,
        showBadge: true,
      );

      // Transactions channel
      const AndroidNotificationChannel transactionChannel =
          AndroidNotificationChannel(
        'transaction_channel',
        'Tranzaksiyalar',
        description: 'Sotuvlar va xaridlar haqida bildirishnomalar',
        importance: Importance.defaultImportance,
        playSound: true,
        showBadge: true,
      );

      // Create channels
      final androidFlutterLocalNotificationsPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidFlutterLocalNotificationsPlugin != null) {
        await androidFlutterLocalNotificationsPlugin
            .createNotificationChannel(reminderChannel);
        await androidFlutterLocalNotificationsPlugin
            .createNotificationChannel(alertChannel);
        await androidFlutterLocalNotificationsPlugin
            .createNotificationChannel(transactionChannel);
      }
    } catch (e) {
      print('Error creating notification channels: $e');
      rethrow;
    }
  }

  // Notification tap handling
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');

    // Parse payload if it exists
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final payload = jsonDecode(response.payload!);
        _handleNotificationAction(
          actionId: response.actionId,
          payload: payload,
        );
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Background notification tap handling
  @pragma('vm:entry-point')
  static Future<void> _onBackgroundNotificationTapped(
      NotificationResponse response) async {
    // Handle background notification tap
    print('Background notification tapped: ${response.payload}');
    try {
      final Map<String, dynamic>? payload = response.payload != null
          ? Map<String, dynamic>.from(jsonDecode(response.payload!))
          : null;
      // Handle the notification tap
      if (payload != null) {
        print('Notification payload: $payload');
        // Handle different notification types here if needed
      }
    } catch (e) {
      print('Error parsing notification payload: $e');
    }

    // Get the instance and handle the notification tap
    final notificationService = NotificationService();
    notificationService._onNotificationTapped(response);
  }

  // Handle notification actions
  void _handleNotificationAction({
    String? actionId,
    dynamic payload,
  }) {
    if (payload is! Map<String, dynamic>) return;

    switch (actionId) {
      case 'mark_done':
        // Handle mark as done
        break;
      case 'remind_later':
        // Handle remind later
        _scheduleReminderLater(payload);
        break;
      default:
        // Handle default tap
        _navigateToScreen(payload);
        break;
    }
  }

  // Navigate to appropriate screen based on payload
  void _navigateToScreen(Map<String, dynamic> payload) {
    final type = payload['type'];
    final id = payload['id'];

    // TODO: Implement navigation logic based on notification type
    // You can use Navigator or any state management solution here
    print('Navigating to $type with id: $id');
  }

  // Schedule a reminder to show later
  void _scheduleReminderLater(Map<String, dynamic> payload) {
    // TODO: Implement logic to reschedule the reminder
    final reminderTime = DateTime.now().add(const Duration(minutes: 30));
    print('Reminder rescheduled for $reminderTime');
  }

  // Show delivery reminder
  Future<void> showDeliveryReminder({
    required String customerName,
    required String deliveryDate,
    required int trayCount,
    DateTime? scheduleTime,
    bool schedule = false,
  }) async {
    final notificationId = 'delivery_${customerName.hashCode}';

    if (schedule && scheduleTime != null) {
      // Schedule delivery reminder
      await _localNotifications.zonedSchedule(
        notificationId.hashCode,
        '🚚 Yetkazib berish eslatmasi',
        '$customerName uchun $trayCount fletka tuxum $deliveryDate kuni yetkazib berilishi kerak',
        tz.TZDateTime.from(scheduleTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Eslatmalar',
            channelDescription: 'Yetkazib berishlar haqida eslatmalar',
            importance: Importance.high,
            priority: Priority.high,
            enableLights: true,
            color: Colors.blue,
            styleInformation: BigTextStyleInformation(''),
            actions: [
              const AndroidNotificationAction(
                'mark_delivered',
                'Yetkazib berildi',
              ),
              const AndroidNotificationAction(
                'reschedule_delivery',
                'Qayta rejalashtirish',
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            categoryIdentifier: 'delivery_reminder',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode({
          'type': 'delivery_reminder',
          'customerName': customerName,
          'deliveryDate': deliveryDate,
          'trayCount': trayCount,
          'scheduledTime': scheduleTime.toIso8601String(),
        }),
      );

      // Schedule with WorkManager for reliability
      // await Workmanager().registerOneOffTask(
      //   'delivery_reminder_${notificationId.hashCode}',
      //   'delivery_reminder',
      //   inputData: {
      //     'customerName': customerName,
      //     'deliveryDate': deliveryDate,
      //     'trayCount': trayCount.toString(),
      //   },
      //   initialDelay: scheduleTime.difference(DateTime.now()),
      //   constraints: Constraints(
      //     networkType: NetworkType.not_required,
      //   ),
      // );
    } else {
      // Show immediate delivery reminder
      await _showLocalNotification(
        title: '🚚 Yetkazib berish eslatmasi',
        body:
            '$customerName uchun $trayCount fletka tuxum $deliveryDate kuni yetkazib berilishi kerak',
        payload: jsonEncode({
          'type': 'delivery_reminder',
          'customerName': customerName,
          'deliveryDate': deliveryDate,
          'trayCount': trayCount,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    }
  }

  // Show delivery reminder (called by WorkManager)
  Future<void> _showDeliveryReminder(
    String customerName,
    String deliveryDate,
    int trayCount,
  ) async {
    await _showLocalNotification(
      title: '🚚 Yetkazib berish eslatmasi',
      body:
          '$customerName uchun $trayCount fletka tuxum $deliveryDate kuni yetkazib berilishi kerak',
      payload: jsonEncode({
        'type': 'delivery_reminder',
        'customerName': customerName,
        'deliveryDate': deliveryDate,
        'trayCount': trayCount,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }

  // Tovuq o'limi eslatmasi
  Future<void> showChickenDeathReminder({
    required int deathCount,
    required String date,
  }) async {
    await _showLocalNotification(
      title: 'Tovuq o\'limi',
      body: '$date kuni $deathCount ta tovuq o\'lgan. Tekshirib ko\'ring!',
      payload: 'chicken_death',
    );
  }

  // Tuxum ishlab chiqarish eslatmasi
  Future<void> showEggProductionReminder({
    required int productionCount,
    required String date,
  }) async {
    await _showLocalNotification(
      title: 'Tuxum ishlab chiqarish',
      body: '$date kuni $productionCount fletka tuxum yig\'ildi',
      payload: 'egg_production',
    );
  }

  // Sotuv eslatmasi
  Future<void> showSaleReminder({
    required int saleCount,
    required double totalAmount,
    required String date,
  }) async {
    await _showLocalNotification(
      title: 'Tuxum sotuvi',
      body:
          '$date kuni $saleCount fletka tuxum sotildi. Jami: ${totalAmount.toStringAsFixed(0)} so\'m',
      payload: 'egg_sale',
    );
  }

  // FCM token olish
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Topic'ga obuna bo'lish
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Topic'dan chiqish
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Schedule daily morning reminder
  Future<void> scheduleMorningReminder() async {
    // Cancel any existing morning reminders
    await _localNotifications.cancel(1001);

    // Schedule new reminder
    await _localNotifications.zonedSchedule(
      1001,
      '🌅 Xayrli tong!',
      'Tovuqlarni tekshirish va tuxum yig\'ish vaqti keldi',
      _nextInstanceOfTime(8, 0), // 8:00 AM
      NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Kunlik eslatma',
          channelDescription: 'Kunlik ferma ishlari uchun eslatmalar',
          importance: Importance.high,
          priority: Priority.high,
          color: Colors.green,
          enableLights: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(''),
          actions: [
            const AndroidNotificationAction(
              'mark_done',
              'Bajarildi',
            ),
            const AndroidNotificationAction(
              'remind_later',
              'Keyinroq',
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'reminder',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({
        'type': 'daily_reminder',
        'time': '08:00',
      }),
    );

    // Schedule with WorkManager for reliability
    // await Workmanager().registerPeriodicTask(
    //   'daily_morning_reminder',
    //   'daily_reminder',
    //   frequency: const Duration(hours: 24),
    //   initialDelay: const Duration(seconds: 10),
    //   constraints: Constraints(
    //     networkType: NetworkType.not_required,
    //     requiresBatteryNotLow: false,
    //     requiresCharging: false,
    //     requiresDeviceIdle: false,
    //     requiresStorageNotLow: false,
    //   ),
    // );
  }

  // Show daily reminder (called by WorkManager)
  Future<void> _showDailyReminder() async {
    await _showLocalNotification(
      title: '🌅 Kun boshlanishi',
      body: 'Bugungi ishlarni rejalashtirish vaqti keldi',
      payload: jsonEncode({
        'type': 'daily_reminder',
        'time': DateTime.now().toIso8601String(),
      }),
    );
  }

  // Smart alert based on data
  Future<void> showSmartAlert({
    required String title,
    required String description,
    String? suggestion,
    NotificationType type = NotificationType.alert,
    Map<String, dynamic>? data,
    List<MapEntry<String, String>>? actions,
  }) async {
    final buffer = StringBuffer(description);
    if (suggestion != null) {
      buffer.write('\n\n💡 Tavsiya: $suggestion');
    }

    await _showLocalNotification(
      title: title,
      body: buffer.toString(),
      payload: jsonEncode({
        'type': type.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'data': data ?? {},
      }),
      notificationType: type,
      actions: actions,
    );
  }

  // Schedule daily report
  Future<void> scheduleDailyReport(TimeOfDay time) async {
    await _scheduleReport(
      type: ReportType.dailySummary,
      time: time,
      title: '📊 Kunlik hisobot',
      body: 'Bugungi ferma faoliyati haqida hisobot tayyor',
    );
  }

  // Schedule weekly report
  Future<void> scheduleWeeklyReport(TimeOfDay time,
      {int dayOfWeek = DateTime.monday}) async {
    await _scheduleReport(
      type: ReportType.weeklySummary,
      time: time,
      title: '📈 Haftalik hisobot',
      body: 'O\'tgan hafta uchun ferma hisoboti tayyor',
      dayOfWeek: dayOfWeek,
    );
  }

  // Generic report scheduling
  Future<void> _scheduleReport({
    required ReportType type,
    required TimeOfDay time,
    required String title,
    required String body,
    int? dayOfWeek,
  }) async {
    final now = DateTime.now();
    var scheduledTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    if (dayOfWeek != null) {
      final daysToAdd = (dayOfWeek - scheduledTime.weekday) % 7;
      scheduledTime = scheduledTime.add(Duration(days: daysToAdd));
    }

    await _localNotifications.zonedSchedule(
      type.index,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      _getNotificationDetails(
        channelId: 'report_channel',
        channelName: 'Hisobotlar',
        channelDescription: 'Muntazam hisobotlar va tahlillar',
        importance: Importance.high,
        actions: [
          const MapEntry('view_report', 'Ko\'rish'),
          const MapEntry('share_report', 'Ulashish'),
        ],
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode({
        'type': 'report',
        'reportType': type.toString(),
        'timestamp': scheduledTime.toIso8601String(),
      }),
      matchDateTimeComponents: dayOfWeek != null
          ? DateTimeComponents.dayOfWeekAndTime
          : DateTimeComponents.time,
    );
  }

  // Check and alert for threshold breaches
  Future<void> checkThresholds({
    required double temperature,
    required double humidity,
    required int feedLevel,
    required int waterLevel,
    required int eggCount,
    required int mortalityCount,
  }) async {
    final Map<ThresholdType, String> thresholdAlerts = {
      if (temperature > 28)
        ThresholdType.temperatureHigh:
            'Harorat juda baland: ${temperature.toStringAsFixed(1)}°C',
      if (temperature < 18)
        ThresholdType.temperatureLow:
            'Harorat juda past: ${temperature.toStringAsFixed(1)}°C',
      if (humidity > 70)
        ThresholdType.humidityHigh:
            'Namlik juda baland: ${humidity.toStringAsFixed(0)}%',
      if (humidity < 40)
        ThresholdType.humidityLow:
            'Namlik juda past: ${humidity.toStringAsFixed(0)}%',
      if (feedLevel < 20)
        ThresholdType.feedLow: 'Yem zaxirasi tugab qolmoqda: $feedLevel%',
      if (waterLevel < 20)
        ThresholdType.waterLow: 'Suv zaxirasi tugab qolmoqda: $waterLevel%',
      if (eggCount < 50)
        ThresholdType.eggProductionLow:
            'Tuxum ishlab chiqarish kamaydi: $eggCount dona',
      if (mortalityCount > 5)
        ThresholdType.mortalityHigh:
            'Tovuq o\'limi ko\'paydi: $mortalityCount ta',
    };

    if (thresholdAlerts.isNotEmpty) {
      await showSmartAlert(
        title: '⚠️ Diqqat!',
        description: thresholdAlerts.values.join('\n'),
        type: NotificationType.threshold,
        data: {
          'alerts': thresholdAlerts.keys.map((e) => e.toString()).toList(),
        },
        actions: [
          const MapEntry('acknowledge', 'Tushunarli'),
          const MapEntry('view_details', 'Batafsil'),
        ],
      );
    }
  }

  // Get notification details with proper channel configuration
  NotificationDetails _getNotificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    required Importance importance,
    List<MapEntry<String, String>>? actions,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: importance,
        priority: Priority.high,
        autoCancel: true,
        enableLights: true,
        enableVibration: true,
        color: Colors.blue,
        styleInformation: const BigTextStyleInformation(''),
        actions: actions
            ?.map((action) => AndroidNotificationAction(
                  action.key,
                  action.value,
                  showsUserInterface: true,
                  cancelNotification: action.key == 'dismiss',
                ))
            .toList(),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // Batch send notifications
  Future<void> sendBatchNotifications(
      List<Map<String, dynamic>> notifications) async {
    for (final notification in notifications) {
      await _showLocalNotification(
        title: notification['title'],
        body: notification['body'],
        payload: jsonEncode(notification['payload'] ?? {}),
        notificationType: notification['type'],
      );
      // Small delay to avoid overwhelming the system
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Health monitoring alert
  Future<void> sendHealthAlert({
    required String title,
    required String description,
    required String severity,
    Map<String, dynamic>? metrics,
  }) async {
    await _showLocalNotification(
      title: '🩺 $title',
      body: description,
      payload: jsonEncode({
        'type': 'health_alert',
        'severity': severity,
        'timestamp': DateTime.now().toIso8601String(),
        'metrics': metrics ?? {},
      }),
      notificationType: NotificationType.health,
      actions: [
        const MapEntry('acknowledge', 'Tushunarli'),
        const MapEntry('view_metrics', 'Ko\'rish'),
      ],
    );
  }

  // Schedule customer debt reminder
  Future<void> scheduleDebtReminder(
    String customerName,
    double debt,
    String phone, {
    Duration delay = const Duration(days: 1),
  }) async {
    final reminderTime = DateTime.now().add(delay);
    final notificationId = customerName.hashCode;

    // Format the debt amount
    final formattedDebt = debt.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]} ',
        );

    // Schedule notification
    await _localNotifications.zonedSchedule(
      notificationId,
      '💰 Qarzdorlik eslatmasi',
      '$customerName ning $formattedDebt so\'m qarzi bor. Qayta to\'lovni so\'rang!',
      tz.TZDateTime.from(reminderTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'alert_channel',
          'Ogohlantirishlar',
          channelDescription: 'Muhim ogohlantirishlar va xavf-xatarlar',
          importance: Importance.high,
          priority: Priority.high,
          autoCancel: true,
          enableLights: true,
          enableVibration: true,
          color: Colors.orange,
          styleInformation: BigTextStyleInformation(''),
          actions: [
            AndroidNotificationAction(
              'call_$notificationId',
              'Qo\'ng\'iroq qilish',
              showsUserInterface: true,
              cancelNotification: false,
            ),
            AndroidNotificationAction(
              'snooze_$notificationId',
              'Keyinroq',
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'debt_reminder',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode({
        'type': 'debt_reminder',
        'customerName': customerName,
        'phone': phone,
        'debt': debt,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );

    // Schedule with WorkManager for reliability
    // await Workmanager().registerOneOffTask(
    //   'debt_reminder_${customerName.hashCode}',
    //   'debt_reminder',
    //   inputData: {
    //     'customerName': customerName,
    //     'phone': phone,
    //     'debt': debt.toString(),
    //   },
    //   initialDelay: delay,
    //   constraints: Constraints(
    //     networkType: NetworkType.not_required,
    //     requiresBatteryNotLow: false,
    //   ),
    // );
  }

  // Show debt reminder (called by WorkManager)
  Future<void> _showDebtReminder(
    String customerName,
    double debt,
    String phone,
  ) async {
    await _showLocalNotification(
      title: '💰 Qarzdorlik eslatmasi',
      body:
          '$customerName ning $debt so\'m qarzi bor. Qayta to\'lovni so\'rang!',
      payload: jsonEncode({
        'type': 'debt_reminder',
        'customerName': customerName,
        'phone': phone,
        'debt': debt,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
