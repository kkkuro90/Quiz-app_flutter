import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF4361EE);
  static const Color secondary = Color(0xFF3A0CA3);
  static const Color success = Color(0xFF4CC9F0);
  static const Color danger = Color(0xFFF72585);
  static const Color light = Color(0xFFF8F9FA);
  static const Color dark = Color(0xFF212529);

  static ThemeData lightTheme = ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: light,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: primary,
      textTheme: ButtonTextTheme.primary,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: dark,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: dark,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: dark,
    appBarTheme: const AppBarTheme(
      backgroundColor: dark,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
