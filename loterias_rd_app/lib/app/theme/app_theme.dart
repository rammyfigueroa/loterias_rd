import 'package:flutter/material.dart';

/// Central place to configure the application's theme.
class AppTheme {
  /// Returns a light theme based on the Dominican flag colours.
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'Roboto',
      primaryColor: const Color(0xFF003893),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: const Color(0xFF003893),
        secondary: const Color(0xFFD90F2C),
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F7FB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF003893),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: Colors.white,
        shadowColor: const Color(0x1A0F172A),
        elevation: 2,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        prefixIconColor: Color(0xFF64748B),
        suffixIconColor: Color(0xFF64748B),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFDCEAFE),
        side: const BorderSide(color: Color(0xFFDCE4EF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(
          color: Color(0xFF17345C),
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0648A8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      useMaterial3: true,
    );
  }
}
