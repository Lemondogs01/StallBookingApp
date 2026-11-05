import 'package:flutter/material.dart';

class AppTheme {
  // สีหลักของระบบ
  static const Color bgColor = Color(0xFFF8F7F2);
  static const Color darkGreen = Color(0xFF2C5E43);
  static const Color lightGreen = Color(0xFFE5ECD9);

  // สีที่มีความใส (ใช้ .withValues แทน .withOpacity เพื่อรองรับ Flutter เวอร์ชั่นใหม่)
  static Color darkGreenOpacity80 = darkGreen.withValues(alpha: 0.8);

  // ตั้งค่า ThemeData กลางสำหรับแอป
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: bgColor,
      primaryColor: darkGreen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkGreen,
        primary: darkGreen,
        surface: bgColor,
      ),
      useMaterial3: true,
    );
  }
}
