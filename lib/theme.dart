import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF6F3EA);
  static const primary = Color(0xFF1F5340);
  static const primarySoft = Color(0xFFD3E3D0);
  static const primaryTint = Color(0xFFE7EEE1);
  static const accent = Color(0xFFE5B547);
  static const text = Color(0xFF17231D);
  static const textMuted = Color(0xFF6A726C);
  static const border = Color(0xFFDAD9CC);

  static const successBg = Color(0xFFDCEADA);
  static const success = Color(0xFF1F5340);
  static const warningBg = Color(0xFFFFF0BF);
  static const warning = Color(0xFF7A5800);
  static const dangerBg = Color(0xFFFBDADA);
  static const danger = Color(0xFF9B2222);
  static const neutralBg = Color(0xFFE9E7DF);
  static const neutral = Color(0xFF5A5F59);
}

ThemeData appTheme() {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary)
        .copyWith(primary: AppColors.primary, onPrimary: Colors.white),
    scaffoldBackgroundColor: AppColors.background,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.primary),
    ),
  );
}

ButtonStyle primaryButtonStyle() => ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFB7C6BC),
      disabledForegroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );

ButtonStyle softButtonStyle() => ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFCFE0CB),
      foregroundColor: AppColors.primary,
      elevation: 0,
      minimumSize: const Size(170, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
