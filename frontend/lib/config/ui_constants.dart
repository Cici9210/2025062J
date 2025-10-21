// UI 常數檔案
// 功能: 定義應用程式的UI常數，包括顏色、間距、圓角等
// 相依: Flutter SDK

import 'package:flutter/material.dart';

class UIConstants {  // 主色調 (從Figma設計提取)
  static const Color primaryColor = Color(0xFFFF6B6B);      // 主要色彩
  static const Color primaryVariant = Color(0xFFE53935);    // 主要色彩變體
  static const Color secondaryColor = Color(0xFFFF9A8B);    // 次要色彩
  static const Color secondaryVariant = Color(0xFFFF7043);  // 次要色彩變體
  static const Color accentColor = Color(0xFFFFC6C6);       // 強調色
  static const Color successColor = Color(0xFF4CAF50);      // 成功狀態色
  static const Color warningColor = Color(0xFFFFA000);      // 警告狀態色
  static const Color errorColor = Color(0xFFE53935);        // 錯誤狀態色
  
  // 背景漸層色 (從Figma設計提取)
  static const List<Color> backgroundGradient = [
    Color(0xFFFFC6C6),  // 淺粉紅色 (頂部)
    Color(0xFFFF8A8A)   // 中紅色 (底部)
  ];
    // 心臟顏色 (從Figma設計提取)
  static const Color heartColor = Color(0xFFE53935);        // 心臟紅色
  static const Color pairHeartColor = Color(0xFFFF7043);    // 配對心臟色
  static const Color heartGlowColor = Color(0xFFFFC6C6);    // 心臟發光色

  // 文字顏色
  static const Color textDark = Color(0xFF212121);    // 深色文字
  static const Color textLight = Color(0xFFFAFAFA);   // 淺色文字
  static const Color textMedium = Color(0xFF757575);  // 中等色文字
  // 間距 (從Figma設計提取)
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // 圓角 (從Figma設計提取)
  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;
  static const double radiusXXL = 40.0;

  // 陰影 (從Figma設計提取)
  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      spreadRadius: 1,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  // 按鈕樣式 (從Figma設計提取)
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 4,
    padding: const EdgeInsets.symmetric(horizontal: spaceL, vertical: spaceM),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusL),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: primaryColor,
    elevation: 2,
    padding: const EdgeInsets.symmetric(horizontal: spaceL, vertical: spaceM),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusL),
      side: BorderSide(color: primaryColor, width: 1.5),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: spaceM, vertical: spaceS),
    textStyle: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
  );

  // 卡片樣式 (從Figma設計提取)
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusL),
    boxShadow: shadowMedium,
    border: Border.all(color: Colors.grey.shade100, width: 1),
  );
  // 輸入框裝飾 (從Figma設計提取)
  static InputDecoration inputDecoration(String label, {IconData? prefixIcon, String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: TextStyle(
        color: textMedium,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: textMedium.withOpacity(0.7),
        fontSize: 14,
      ),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: textMedium, size: 20) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: spaceM, vertical: spaceL),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
    );
  }
  
  // 容器樣式 (從Figma設計提取)
  static BoxDecoration containerDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusL),
    boxShadow: shadowSmall,
    border: Border.all(color: Colors.grey.shade100, width: 1),
  );
}
