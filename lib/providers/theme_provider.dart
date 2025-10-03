import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Light theme colors
  static const Color lightPrimaryColor = Color(0xFF1976D2);
  static const Color lightPrimaryLightColor = Color(0xFF42A5F5);
  static const Color lightPrimaryDarkColor = Color(0xFF0D47A1);
  static const Color lightBackgroundColor = Color(0xFFF8FAFF);
  static const Color lightSurfaceColor = Color(0xFFFFFFFF);
  static const Color lightTextColor = Color(0xFF212121);
  static const Color lightSecondaryTextColor = Color(0xFF757575);

  // Dark theme colors
  static const Color darkPrimaryColor = Color(0xFF64B5F6);
  static const Color darkPrimaryLightColor = Color(0xFF90CAF9);
  static const Color darkPrimaryDarkColor = Color(0xFF1976D2);
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkTextColor = Color(0xFFFFFFFF);
  static const Color darkSecondaryTextColor = Color(0xFFB0B0B0);

  // Get current colors based on theme
  Color get primaryColor => _isDarkMode ? darkPrimaryColor : lightPrimaryColor;
  Color get primaryLightColor =>
      _isDarkMode ? darkPrimaryLightColor : lightPrimaryLightColor;
  Color get primaryDarkColor =>
      _isDarkMode ? darkPrimaryDarkColor : lightPrimaryDarkColor;
  Color get backgroundColor =>
      _isDarkMode ? darkBackgroundColor : lightBackgroundColor;
  Color get surfaceColor => _isDarkMode ? darkSurfaceColor : lightSurfaceColor;
  Color get textColor => _isDarkMode ? darkTextColor : lightTextColor;
  Color get secondaryTextColor =>
      _isDarkMode ? darkSecondaryTextColor : lightSecondaryTextColor;

  // Error, success, warning colors
  static const Color errorColor = Color(0xFFE57373);
  static const Color successColor = Color(0xFF81C784);
  static const Color warningColor = Color(0xFFFFB74D);
  static const Color infoColor = Color(0xFF42A5F5);

  ThemeProvider() {
    _loadTheme();
  }

  // Load saved theme from SharedPreferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  // Save theme to SharedPreferences
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  // Toggle theme
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveTheme();
    notifyListeners();
  }

  // Set specific theme
  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    await _saveTheme();
    notifyListeners();
  }

  // Get theme data for MaterialApp
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: lightPrimaryColor,
      scaffoldBackgroundColor: lightBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: lightPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: lightPrimaryColor.withOpacity(0.3),
      ),
      cardTheme: CardThemeData(
        color: lightSurfaceColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: lightTextColor,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: lightTextColor,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: lightTextColor),
        bodyMedium: TextStyle(color: lightTextColor),
        bodySmall: TextStyle(color: lightSecondaryTextColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lightPrimaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkPrimaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: darkPrimaryColor.withOpacity(0.3),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: darkTextColor,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: darkTextColor,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: darkTextColor),
        bodyMedium: TextStyle(color: darkTextColor),
        bodySmall: TextStyle(color: darkSecondaryTextColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[600]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkPrimaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
