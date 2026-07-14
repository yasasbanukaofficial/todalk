import 'package:flutter/material.dart';

class AppColors {
  static const Color black = Color(0xFF0A0A0C);
  static const Color white = Color(0xFFF5F5F7);
  static const Color surface = Color(0xFF16161A);
  static const Color surfaceRaised = Color(0xFF1E1E22);
  static const Color hairline = Color(0xFF2A2A2E);
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF6E6E76);
  static const Color textTertiary = Color(0xFF3F3F45);
  static const Color priorityHigh = Color(0xFFFF453A);
  static const Color priorityMedium = Color(0xFFFFD60A);
  static const Color priorityLow = Color(0xFF30D158);
}

class AppTheme {
  static const double cardRadius = 28.0;
  static const double sheetRadius = 28.0;
  static const double pillRadius = 999.0;
  static const double smallRadius = 2.0;

  static ThemeData get dark => ThemeData(
    scaffoldBackgroundColor: AppColors.black,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.white,
      onPrimary: AppColors.black,
      secondary: AppColors.textSecondary,
      surface: AppColors.surface,
    ),
    fontFamily: 'Helvetica',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w300,
        color: AppColors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w300,
        color: AppColors.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w300,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        letterSpacing: 4,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.hairline,
      thickness: 1,
      space: 0,
    ),
    useMaterial3: true,
  );

  static ThemeData get voiceOverlay => ThemeData(
    scaffoldBackgroundColor: AppColors.black,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.white,
      onPrimary: AppColors.black,
      secondary: AppColors.textSecondary,
      surface: AppColors.surface,
    ),
    fontFamily: 'Helvetica',
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
    ),
    useMaterial3: true,
  );
}
