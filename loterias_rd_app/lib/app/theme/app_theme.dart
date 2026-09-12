import 'package:flutter/material.dart';

/// Central place to configure the application's theme.
class AppTheme {
  /// Returns a light theme based on the Dominican flag colours.
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: const Color(0xFF003893),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: const Color(0xFF003893),
        secondary: const Color(0xFFD90F2C),
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF003893),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      useMaterial3: true,
    );
  }
}