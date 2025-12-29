import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color darkGrey = Color(0xFF1E1E1E);

  static final ThemeData darkRedTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFD32F2F), // Red 700
      onPrimary: Colors.white,
      secondary: Color(0xFFE53935), // Red 600
      onSecondary: Colors.white,
      surface: Color(0xFF121212), // Dark Grey/Black
      onSurface: Colors.white,
      error: Color(0xFFCF6679),
    ),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.redAccent,
      elevation: 0,
      centerTitle: true,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFD32F2F),
      foregroundColor: Colors.white,
    ),
    // cardTheme: CardTheme(
    //   color: const Color(0xFF1E1E1E),
    //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    // ),
    // dialogTheme: DialogTheme(
    //   backgroundColor: const Color(0xFF1E1E1E),
    //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    // ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD32F2F)),
      ),
    ),
  );
}
