import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales
  static const Color green400 = Color(0xFF5CB85C);
  static const Color green500 = Color(0xFF075B47);
  static const Color green600 = Color(0xFF1E5F1E);
  static const Color green700 = Color(0xFF174D17);

  static const Color accent = Color(0xFFFFB74D);
  static const Color danger = Color(0xFFE53935);

  static ThemeData theme = ThemeData(
    useMaterial3: true,

    fontFamily: 'Arial',

    colorScheme: ColorScheme.fromSeed(
      seedColor: green500,
      primary: green500,
      secondary: accent,
      error: danger,
      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor: const Color(0xFFFFFEFA),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF7FAF7),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFCADCD4),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: green500,
          width: 2,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: danger,
          width: 1.5,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: danger,
          width: 2,
        ),
      ),

      labelStyle: const TextStyle(
        color: Color(0xFF667066),
      ),

      floatingLabelStyle: const TextStyle(
        color: green500,
        fontWeight: FontWeight.w600,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: green500,
        foregroundColor: Colors.white,

        minimumSize: const Size(
          double.infinity,
          56,
        ),

        elevation: 0,

        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        ),

        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
