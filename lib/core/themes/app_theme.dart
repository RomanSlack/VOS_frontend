import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      textTheme: _getTextTheme(Brightness.light),
      appBarTheme: _getAppBarTheme(Brightness.light),
      elevatedButtonTheme: _getElevatedButtonTheme(),
      outlinedButtonTheme: _getOutlinedButtonTheme(),
      textButtonTheme: _getTextButtonTheme(),
      inputDecorationTheme: _getInputDecorationTheme(),
      cardTheme: _getCardTheme(),
      chipTheme: _getChipTheme(),
      bottomNavigationBarTheme: _getBottomNavigationBarTheme(),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF212121),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        surface: const Color(0xFF212121),
        background: const Color(0xFF212121),
      ),
      textTheme: _getTextTheme(Brightness.dark),
      appBarTheme: _getAppBarTheme(Brightness.dark),
      elevatedButtonTheme: _getElevatedButtonTheme(),
      outlinedButtonTheme: _getOutlinedButtonTheme(),
      textButtonTheme: _getTextButtonTheme(),
      inputDecorationTheme: _getInputDecorationTheme(),
      cardTheme: _getCardTheme(),
      chipTheme: _getChipTheme(),
      bottomNavigationBarTheme: _getBottomNavigationBarTheme(),
    );
  }

  static TextTheme _getTextTheme(Brightness brightness) {
    final baseTextTheme = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;

    return GoogleFonts.interTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 96,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 60,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w400,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w400,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
      ),
    );
  }

  static AppBarTheme _getAppBarTheme(Brightness brightness) {
    return AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 3,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: brightness == Brightness.light ? Colors.black : Colors.white,
      ),
    );
  }

  static ElevatedButtonThemeData _getElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _getOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static TextButtonThemeData _getTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  static InputDecorationTheme _getInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }

  static CardThemeData _getCardTheme() {
    return CardThemeData(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  static ChipThemeData _getChipTheme() {
    return ChipThemeData(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static BottomNavigationBarThemeData _getBottomNavigationBarTheme() {
    return const BottomNavigationBarThemeData(
      elevation: 8,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    );
  }
}

/// VOS Design System Colors - Unified color palette for consistency
class AppColors {
  AppColors._();

  // Primary accent color - VOS cyan/teal (ONLY blue in the system)
  static const Color primary = Color(0xFF00BCD4);
  static const Color accent = Color(0xFF00BCD4); // Alias for clarity

  // Status colors
  static const Color success = Color(0xFF4CAF50); // Green for open/active states
  static const Color warning = Color(0xFFFF9800); // Orange for minimized/warning states
  static const Color error = Color(0xFFFF5252); // Red for errors/delete
  static const Color info = Color(0xFF00BCD4); // Same as primary

  // Grayscale - Dark theme palette
  static const Color backgroundDark = Color(0xFF212121); // Main background
  static const Color surfaceDark = Color(0xFF303030); // Cards, modals, panels
  static const Color surfaceVariant = Color(0xFF424242); // Hover states, selected items
  static const Color textPrimary = Color(0xFFEDEDED); // Primary text
  static const Color textSecondary = Color(0xFF757575); // Secondary text, hints
  static const Color gridLines = Color(0xFF2F2F2F); // Workspace grid

  // Light theme (less used, but kept for consistency)
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF212121);
  static const Color onSurface = Color(0xFF212121);
  static const Color onBackgroundDark = Color(0xFFEDEDED);
  static const Color onSurfaceDark = Color(0xFFEDEDED);
}

/// VOS Design System Constants - Border radius, shadows, spacing
class VosDesign {
  VosDesign._();

  // Border Radius values
  static const double radiusLarge = 24.0; // AppRail, major containers
  static const double radiusMedium = 16.0; // Modals, cards, dialogs
  static const double radiusSmall = 12.0; // Buttons, small cards
  static const double radiusTiny = 8.0; // Chips, form inputs
  static const double radiusPill = 30.0; // InputBar, pill-shaped elements

  // Standard dual-layer shadow for modals and elevated surfaces
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      offset: const Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  // Light shadow for hover states
  static List<BoxShadow> get hoverShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      offset: const Offset(0, 3),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  // Bevel effect - subtle white border
  static Border get bevel => Border.all(
    color: Colors.white.withOpacity(0.1),
    width: 1,
  );

  // Spacing constants
  static const double spacingTiny = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingXLarge = 24.0;

  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 48.0;
}