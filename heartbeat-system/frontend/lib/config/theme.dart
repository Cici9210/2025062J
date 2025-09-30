
//應用主題 (theme.dart)
//功能: 定義應用程式的視覺主題
//相依: Flutter SDK, ui_constants

import 'package:flutter/material.dart';
import 'ui_constants.dart';

class AppTheme {
  // 使用 UI 常數中的顏色定義
  static const primaryColor = UIConstants.primaryColor;
  static const secondaryColor = UIConstants.secondaryColor;
  static const darkPrimaryColor = UIConstants.primaryVariant;
  static const darkSecondaryColor = UIConstants.secondaryVariant;
    // 淺色主題 (從Figma設計提取)
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: UIConstants.accentColor,
    ),
    fontFamily: 'Noto Sans TC', // 使用Noto Sans TC字體
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      iconTheme: const IconThemeData(size: 24),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: UIConstants.primaryButtonStyle,
    ),
    textButtonTheme: TextButtonThemeData(
      style: UIConstants.textButtonStyle,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: UIConstants.secondaryButtonStyle,
    ),    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor),
      ),
    ),
  );
  
  // 深色主題
  static final ThemeData darkTheme = ThemeData(
    primaryColor: darkPrimaryColor,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.dark(
      primary: darkPrimaryColor,
      secondary: darkSecondaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkSecondaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: darkPrimaryColor),
      ),
    ),
  );
}
