import 'package:flutter/material.dart';

class AppTheme {
  // Late Fall / Burnt Orange & Amber Palette
  static const Color fallPrimary = Color(0xFFC05621);
  static const Color fallPrimaryDark = Color(0xFF7B341E);
  static const Color fallAccent = Color(0xFFDD6B20);
  static const Color fallBackground = Color(0xFFFDF8F5);
  static const Color fallSurface = Color(0xFFFFFFFF);
  static const Color fallCardBg = Color(0xFFFFF9F5);

  // First Frost Theme
  static const Color frostPrimary = Color(0xFF2B6CB0);
  static const Color frostAccent = Color(0xFF319795);
  static const Color frostBackground = Color(0xFFF7FAFC);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: fallPrimary,
        primary: fallPrimary,
        secondary: fallAccent,
        surface: fallSurface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: fallBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: fallPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: fallCardBg,
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: fallPrimary.withValues(alpha: 0.15)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: fallPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fallPrimary,
          side: const BorderSide(color: fallPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: fallPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
