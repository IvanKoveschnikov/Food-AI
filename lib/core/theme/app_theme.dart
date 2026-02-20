import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF212121),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF212121),
        onSecondary: Color(0xFFFFFFFF),
        error: Color(0xFFFF5252),
        onError: Color(0xFFFFFFFF),
        background: Color(0xFFFFFFFF),
        onBackground: Color(0xFF111111),
        surface: Color(0xFFF5F5F5),
        onSurface: Color(0xFF111111),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111111),
        foregroundColor: Color(0xFFFFFFFF),
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF212121),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFFFFFFFF),
        onPrimary: Color(0xFF111111),
        secondary: Color(0xFF212121),
        onSecondary: Color(0xFFFFFFFF),
        error: Color(0xFFFF5252),
        onError: Color(0xFF111111),
        background: Color(0xFF111111),
        onBackground: Color(0xFFFFFFFF),
        surface: Color(0xFF212121),
        onSurface: Color(0xFFFFFFFF),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111111),
        foregroundColor: Color(0xFFFFFFFF),
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Color(0xFF212121),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF111111),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
