import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palet Warna Utama dari Desain Sistem
  static const Color primary = Color(0xFF006B57);
  static const Color primaryContainer = Color(0xFF00B897);
  static const Color onPrimaryContainer = Color(0xFF004234);
  static const Color secondary = Color(0xFF586062);
  static const Color tertiary = Color(0xFF0062A0);
  static const Color tertiaryContainer = Color(0xFF62A8ED);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color outlineVariant = Color(0xFFBBCAC3);
  static const Color textOnSurface = Color(0xFF191C1D);
  static const Color textOnSurfaceVariant = Color(0xFF3C4A45);

  // Shadow lembut untuk Card
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        background: background,
        surface: background,
      ),
      // Tipografi Be Vietnam Pro
      textTheme: GoogleFonts.beVietnamProTextTheme().apply(
        bodyColor: textOnSurface,
        displayColor: textOnSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: primary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textOnSurfaceVariant),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded-lg
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Rounded-2xl
          side: const BorderSide(color: surfaceContainerLow, width: 1),
        ),
      ),
    );
  }
}