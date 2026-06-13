import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppTheme {
  // Global Configurations
  static const String appName = 'RNC Pvt Ltd';
  static const IconData appIcon = LucideIcons.indianRupee;
  static const String appLogo = 'assets/logo/logo.png';

  // Brand Colors
  static const Color background = Color(0xFFF8F9FF);
  static const Color primary = Color(0xFF00328A);
  static const Color primaryContainer = Color(0xFF0047BB);
  static const Color onPrimaryContainer = Color(0xFFAFC1FF);
  static const Color secondary = Color(0xFF5C5F61);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF434653);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFF737685);
  static const Color outlineVariant = Color(0xFFC3C6D6);
  static const Color textSecondary = onSurfaceVariant;
  static const Color textTertiary = outline;
  static const Color border = outlineVariant;

  // Status Alerts
  static const Color success = Color(0xFF1B5E20);
  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningContainer = Color(0xFFFFF3E0);

  // Borders
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 10.0;
  static const double radiusLarge = 16.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        background: background,
        onBackground: onSurface,
        surface: surface,
        onSurface: onSurface,
        surfaceVariant: surfaceContainerHighest,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 34 / 28,
            letterSpacing: -0.56,
            color: onSurface,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 28 / 22,
            letterSpacing: -0.22,
            color: onSurface,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 24 / 18,
            color: onSurface,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            height: 24 / 16,
            color: onSurface,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            height: 20 / 14,
            color: onSurfaceVariant,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            height: 16 / 12,
            color: onSurfaceVariant,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 20 / 14,
            letterSpacing: 0.7,
            color: onSurface,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 16 / 12,
            color: secondary,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 12 / 10,
            color: secondary,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceContainerLowest,
        foregroundColor: primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceContainerLowest,
        indicatorColor: primaryContainer.withOpacity(0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        labelStyle: const TextStyle(color: secondary, fontSize: 14),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
