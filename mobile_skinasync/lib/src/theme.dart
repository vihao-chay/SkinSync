import 'package:flutter/material.dart';

class SkinSyncColors {
  static const espresso = Color(0xFF1A1410);
  static const text = Color(0xFF2A2A2A);
  static const muted = Color(0xFF6B7280);
  static const sand = Color(0xFFC4A882);
  static const cocoa = Color(0xFF8C6E52);
  static const linen = Color(0xFFFAF7F2);
  static const cream = Color(0xFFF5F0E8);
  static const border = Color(0xFFE8D5B7);
  static const field = Color(0xFFFAFAFA);
}

ThemeData buildSkinSyncTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: SkinSyncColors.sand,
    brightness: Brightness.light,
    primary: SkinSyncColors.cocoa,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: SkinSyncColors.linen,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        color: SkinSyncColors.espresso,
        fontSize: 34,
        height: 1.08,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: TextStyle(
        color: SkinSyncColors.espresso,
        fontSize: 28,
        height: 1.16,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: SkinSyncColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: SkinSyncColors.text,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        color: SkinSyncColors.text,
        fontSize: 16,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        color: SkinSyncColors.muted,
        fontSize: 14,
        height: 1.42,
      ),
      labelLarge: TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SkinSyncColors.field,
      hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: SkinSyncColors.sand, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
      ),
    ),
  );
}

class SkinSyncGradients {
  static const brand = LinearGradient(
    colors: [SkinSyncColors.sand, SkinSyncColors.cocoa],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const warmBackground = LinearGradient(
    colors: [SkinSyncColors.linen, SkinSyncColors.cream, Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
