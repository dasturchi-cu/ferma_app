import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Enhanced Colors with Modern Vivid Tones
  static const Color primaryColor = Color(0xFF0063C4);      // Bright Indigo
  static const Color secondaryColor = Color(0xFFFF6B35);    // Vibrant Orange
  static const Color accentColor = Color(0xFF0976FF);       // Bright Teal
  static const Color tertiaryColor = Color(0xFFFFE066);     // Golden Yellow

  static const Color backgroundColor = Color(0xFFF8FAFC);   // Cool White
  static const Color surfaceColor = Color(0xFFFFFFFF);      // Pure White
  static const Color cardColor = Color(0xFFF1F5F9);         // Light Blue-Gray

  static const Color darkPrimary = Color(0xFF818CF8);       // Light Indigo
  static const Color darkBackground = Color(0xFF0F172A);    // Dark Slate
  static const Color darkSurface = Color(0xFF1E293B);       // Slate 800
  static const Color darkCard = Color(0xFF334155);          // Slate 700
  static const Color darkSecondary = Color(0xFFFF7849);     // Dark Orange
  static const Color darkAccent = Color(0xFF06D6A0);        // Dark Teal

  static const Color success = Color(0xFF10B981);           // Emerald Green
  static const Color warning = Color(0xFFF59E0B);           // Amber
  static const Color error = Color(0xFFEF4444);             // Red
  static const Color info = Color(0xFF3B82F6);              // Blue

  static const Color textPrimary = Color(0xFF0F172A);       // Dark Slate
  static const Color textSecondary = Color(0xFF475569);     // Slate 600
  static const Color textTertiary = Color(0xFF94A3B8);      // Slate 400
  static const Color textOnDark = Color(0xFFF8FAFC);        // Off White

  // ✅ Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        error: error,
        onError: Colors.white,
        background: backgroundColor,
        onBackground: textPrimary,
        surface: surfaceColor,
        onSurface: textPrimary,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 22),
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        color: surfaceColor,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),

      textTheme: GoogleFonts.interTextTheme(),
    );
  }

  // ✅ Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: Colors.black,
        secondary: darkSecondary,
        onSecondary: Colors.black,
        error: error,
        onError: Colors.black,
        background: darkBackground,
        onBackground: textOnDark,
        surface: darkSurface,
        onSurface: textOnDark,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: darkSurface,
        foregroundColor: textOnDark,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textOnDark,
        ),
        iconTheme: const IconThemeData(color: textOnDark, size: 22),
      ),

      cardTheme: CardThemeData(
        elevation: 3,
        color: darkSurface,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF475569), width: 1),
        ),
      ),

      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textOnDark,
        displayColor: textOnDark,
      ),
    );
  }
}
