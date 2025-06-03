import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primary = Color(0xFF6750A4);
  static const Color background = Color(0xFFFDF7E9);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFFBCBCBC);
  static const Color textHint = Color(0xFFB0B0B0);
  static const Color error = Color(0xFFFF5252);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color sectionBackground = Color.fromRGBO(87, 179, 230, 0.1);
  
  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
  static const Color accent = Color(0xFF57B3E6);
  
  // Personality Colors
  static const Color warmthHigh = Color(0xFFFF9F40);
  static const Color warmthLow = Color(0xFF4ECDC4);
  static const Color competenceHigh = Color(0xFF6B73FF);
  static const Color competenceLow = Color(0xFF95E1D3);
  static const Color extroversionHigh = Color(0xFFFF6B6B);
  static const Color extroversionLow = Color(0xFFA8E6CF);
  
  static ThemeData get lightTheme => ThemeData(
    primarySwatch: _createMaterialColor(primary),
    scaffoldBackgroundColor: background,
    fontFamily: 'Pretendard',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        minimumSize: const Size(343, 56),
        textStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: textSecondary,
        textStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: textHint,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        fontSize: 26,
        height: 1.5,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        fontSize: 20,
        height: 1.2,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        fontSize: 16,
        height: 1.25,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.4,
        color: textPrimary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        fontSize: 10,
        height: 1.2,
        color: error,
      ),
    ),
  );
  
  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

class AppColors {
  static Color getPersonalityColor(String trait) {
    switch (trait.toLowerCase()) {
      case '따뜻한':
        return AppTheme.warmthHigh;
      case '차분한':
        return AppTheme.warmthLow;
      case '유능한':
        return AppTheme.competenceHigh;
      case '순수한':
        return AppTheme.competenceLow;
      case '활발한':
        return AppTheme.extroversionHigh;
      case '내성적인':
        return AppTheme.extroversionLow;
      default:
        return AppTheme.accent;
    }
  }
} 