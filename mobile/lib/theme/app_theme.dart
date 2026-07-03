import 'package:flutter/material.dart';

class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFF0D0D0D);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color surfaceCard = Color(0xFF222226);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFF3A3A3C);
  static const Color red = Color(0xFFFF3B30);
  static const Color accentRed = Color(0xFFE53935);

  static const Color mint = Color(0xFFA8E6CF);
  static const Color paleYellow = Color(0xFFFFE8A1);
  static const Color lightBlue = Color(0xFFB8D4E3);
  static const Color lavender = Color(0xFFD4C5F9);
}

class AppTheme {
  static const double cardRadius = 22.0;
  static const double sheetRadius = 24.0;
  static const double pillRadius = 999.0;
  static const double chipRadius = 16.0;

  static ThemeData get dark => ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.white,
      onPrimary: AppColors.black,
      secondary: AppColors.grey,
      surface: AppColors.surfaceDark,
    ),
    fontFamily: 'Helvetica',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.white,
      ),
      displayMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.white,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.grey,
      ),
    ),
    useMaterial3: true,
  );

  static ThemeData get voiceOverlay => ThemeData(
    scaffoldBackgroundColor: AppColors.black,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.white,
      onPrimary: AppColors.black,
      secondary: AppColors.grey,
      surface: AppColors.surfaceDark,
    ),
    fontFamily: 'Helvetica',
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.grey,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.grey,
      ),
    ),
    useMaterial3: true,
  );
}
