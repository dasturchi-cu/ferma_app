import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Ferma App';
  static const String appVersion = '1.0.0';

  // Colors
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color secondaryColor = Color(0xFFFF9800);
  static const Color accentColor = Color(0xFF9C27B0);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color infoColor = Color(0xFF2196F3);
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);

  // Font Sizes
  static const double titleFontSize = 24.0;
  static const double subtitleFontSize = 18.0;
  static const double bodyFontSize = 14.0;
  static const double captionFontSize = 12.0;

  // Padding & Margins
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  // Border Radius
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 24.0;

  // Icons
  static const IconData chickenIcon = Icons.pets;
  static const IconData eggIcon = Icons.egg;
  static const IconData customerIcon = Icons.people;
  static const IconData salesIcon = Icons.shopping_cart;
  static const IconData stockIcon = Icons.inventory;
  static const IconData brokenIcon = Icons.broken_image;
  static const IconData largeIcon = Icons.expand;
  static const IconData deliveryIcon = Icons.local_shipping;
  static const IconData statisticsIcon = Icons.analytics;

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: titleFontSize,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: subtitleFontSize,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: bodyFontSize,
    color: textPrimaryColor,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: captionFontSize,
    color: textSecondaryColor,
  );

  // Messages
  static const String loadingMessage = 'Yuklanmoqda...';
  static const String errorMessage = 'Xatolik yuz berdi';
  static const String successMessage = 'Muvaffaqiyatli bajarildi';
  static const String noDataMessage = 'Ma\'lumot mavjud emas';

  // Firebase Collections
  static const String farmsCollection = 'farms';
  static const String chickensCollection = 'chickens';
  static const String eggsCollection = 'eggs';
  static const String customersCollection = 'customers';

  // Hive Box Names
  static const String farmBoxName = 'farm';
  static const String farmBox = 'farm';
  static const String settingsBoxName = 'settings_box';

  // Default Values
  static const int defaultChickenCount = 0;
  static const int defaultEggCount = 0;
  static const double defaultEggPrice = 15000.0;
  static const String defaultCurrency = 'UZS';

  // Time Formats
  static const String dateFormat = 'dd.MM.yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd.MM.yyyy HH:mm';

  // Validation
  static const int minPhoneLength = 9;
  static const int maxNameLength = 50;
  static const int maxAddressLength = 100;

  // Notification IDs
  static const int dailyReportNotificationId = 1001;
  static const int deliveryReminderNotificationId = 1002;
} 