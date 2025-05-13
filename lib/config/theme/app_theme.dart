import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
      useMaterial3: true,
      // We can add more theme customizations here later
      // e.g., appBarTheme, textTheme, buttonTheme, inputDecorationTheme
    );
  }
} 