import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getTheme() {
    // Lakeside Blues & Earthy Browns Palette
    const Color lakeBlue = Color(0xFF0077B6); // Primary Seed
    const Color earthyBrown = Color(0xFFA0522D); // Explicit Secondary
    const Color beige = Color(0xFFF5F5DC); // Accent / Neutral

    final baseTheme = ThemeData.from(colorScheme: ColorScheme.fromSeed(seedColor: lakeBlue, brightness: Brightness.light), useMaterial3: true);

    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: lakeBlue,
        secondary: earthyBrown,
        // You might want to adjust container colors if the defaults aren't quite right
        // primaryContainer: lakeBlue.withOpacity(0.1), // Example adjustment
        // secondaryContainer: earthyBrown.withOpacity(0.1), // Example adjustment
        // surface: beige, // Could be used for general background
        // background: beige, // Could be used for scaffold background
        onPrimary: Colors.white, // Text/icon color on primary color
        onSecondary: Colors.white, // Text/icon color on secondary color
      ),
      // We can add more theme customizations here later
      // e.g., appBarTheme, textTheme, buttonTheme, inputDecorationTheme
      // appBarTheme: baseTheme.appBarTheme.copyWith(
      //   backgroundColor: lakeBlue,
      //   foregroundColor: Colors.white,
      // ),
      // elevatedButtonTheme: ElevatedButtonThemeData(
      //   style: ElevatedButton.styleFrom(
      //     backgroundColor: lakeBlue,
      //     foregroundColor: Colors.white,
      //   ),
      // ),
    );
  }
} 