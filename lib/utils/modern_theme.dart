import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernTheme {
  // === COLOR PALETTE ===
  // Primary Colors - Nature inspired greens
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF1B5E20);
  
  // Background Colors - Clean and minimal
  static const Color backgroundColor = Color(0xFFF8FFFE);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  
  // Neutral Colors - Soft grays
  static const Color lightGray = Color(0xFFF5F7FA);
  static const Color mediumGray = Color(0xFFE4E7EB);
  static const Color darkGray = Color(0xFF9AA0A6);
  static const Color textGray = Color(0xFF5F6368);
  
  // Accent Colors
  static const Color accentYellow = Color(0xFFFFC107);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentBlue = Color(0xFF2196F3);
  
  // Status Colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // === SHADOWS ===
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get largeShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  // === BORDER RADIUS ===
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 20.0;

  // === SPACING ===
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // === TYPOGRAPHY ===
  static TextTheme get textTheme => TextTheme(
    // Headlines
    headlineLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      height: 1.25,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      height: 1.3,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      height: 1.4,
    ),
    
    // Titles
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      height: 1.4,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: textPrimary,
      height: 1.5,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textSecondary,
      height: 1.4,
    ),
    
    // Body
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: textPrimary,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: textSecondary,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: textTertiary,
      height: 1.4,
    ),
    
    // Labels
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textPrimary,
      height: 1.4,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: textSecondary,
      height: 1.3,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: textTertiary,
      height: 1.2,
    ),
  );

  // === THEME DATA ===
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      primaryContainer: lightGreen,
      secondary: accentYellow,
      secondaryContainer: accentOrange,
      tertiary: accentBlue,
      surface: surfaceColor,
      surfaceContainerHighest: cardColor,
      background: backgroundColor,
      error: errorColor,
      onPrimary: textOnPrimary,
      onSecondary: textPrimary,
      onSurface: textPrimary,
      onBackground: textPrimary,
      onError: textOnPrimary,
      outline: mediumGray,
      outlineVariant: lightGray,
    ),

    // Scaffold
    scaffoldBackgroundColor: backgroundColor,
    
    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textPrimary,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.05),
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: spaceMD,
        vertical: spaceSM,
      ),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: textOnPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceLG,
          vertical: spaceMD,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceSM,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryGreen,
        side: const BorderSide(color: mediumGray, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceLG,
          vertical: spaceMD,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spaceMD,
        vertical: spaceMD,
      ),
      hintStyle: GoogleFonts.inter(
        color: textTertiary,
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.inter(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryGreen,
      unselectedItemColor: textTertiary,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Typography
    textTheme: textTheme,

    // Icon Theme
    iconTheme: const IconThemeData(
      color: textSecondary,
      size: 24,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: lightGray,
      thickness: 1,
      space: 1,
    ),

    // Tab Bar
    tabBarTheme: TabBarThemeData(
      labelColor: primaryGreen,
      unselectedLabelColor: textTertiary,
      indicatorColor: primaryGreen,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: textOnPrimary,
      elevation: 4,
      shape: CircleBorder(),
    ),

    // Snack Bar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimary,
      contentTextStyle: GoogleFonts.inter(
        color: textOnPrimary,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 8,
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceColor,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        color: textSecondary,
      ),
    ),
  );

  // === COMPONENT STYLES ===
  
  // Modern Card Decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: softShadow,
  );

  // Success Card
  static BoxDecoration get successCardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: softShadow,
    border: Border.all(color: successColor.withOpacity(0.2), width: 1),
  );

  // Warning Card
  static BoxDecoration get warningCardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: softShadow,
    border: Border.all(color: warningColor.withOpacity(0.2), width: 1),
  );

  // Error Card
  static BoxDecoration get errorCardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: softShadow,
    border: Border.all(color: errorColor.withOpacity(0.2), width: 1),
  );

  // Gradient Decorations
  static BoxDecoration get primaryGradientDecoration => BoxDecoration(
    gradient: LinearGradient(
      colors: [primaryGreen, lightGreen],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: [
      BoxShadow(
        color: primaryGreen.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get accentGradientDecoration => BoxDecoration(
    gradient: LinearGradient(
      colors: [accentYellow, accentOrange],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: [
      BoxShadow(
        color: accentYellow.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}