import 'package:flutter/material.dart';

class AppTheme {
  static const blue = Color(0xFF0B3D91);
  static const red = Color(0xFFD71920);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF13213C);
  static const muted = Color(0xFF65738A);
  static const surface = Color(0xFFF5F7FB);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      primary: blue,
      secondary: red,
      surface: surface,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: blue,
        foregroundColor: white,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
