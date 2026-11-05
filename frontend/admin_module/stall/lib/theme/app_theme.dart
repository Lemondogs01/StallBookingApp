import 'package:flutter/material.dart';

/// Palette taken from the "MFUgrowtogether" Figma design.
class AppColors {
  static const green = Color(0xFF214F3E);
  static const greenSoft = Color(0xFFD5E3D3);
  static const onGreenMuted = Color(0xFFCBD9CF);
  static const cream = Color(0xFFF4F1E8);
  static const card = Color(0xFFFBFAF5);
  static const beige = Color(0xFFE9E5DA);
  static const border = Color(0xFFE0DCCF);
  static const ink = Color(0xFF1B2B24);
  static const muted = Color(0xFF6B7068);
  static const danger = Color(0xFFA33A2F);
  static const dangerSoft = Color(0xFFF2D9D3);
  static const amberSoft = Color(0xFFF3E6C4);
  static const amberInk = Color(0xFF6B4E0A);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.green,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.green,
    onPrimary: AppColors.cream,
    primaryContainer: AppColors.greenSoft,
    onPrimaryContainer: AppColors.green,
    surface: AppColors.cream,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.muted,
    surfaceContainerLow: AppColors.card,
    surfaceContainerHigh: AppColors.cream,
    surfaceContainerHighest: AppColors.beige,
    outlineVariant: AppColors.border,
    error: AppColors.danger,
    errorContainer: AppColors.dangerSoft,
    onErrorContainer: AppColors.danger,
  );

  OutlineInputBorder outline(Color c, [double w = 0]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w),
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.beige,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: outline(AppColors.beige),
      enabledBorder: outline(AppColors.beige),
      focusedBorder: outline(AppColors.green, 1.5),
      errorBorder: outline(AppColors.danger, 1),
      focusedErrorBorder: outline(AppColors.danger, 1.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.cream,
        minimumSize: const Size(64, 52),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.green),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.card,
      selectedColor: AppColors.greenSoft,
      side: BorderSide(color: AppColors.border),
      shape: StadiumBorder(),
      checkmarkColor: AppColors.green,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.greenSoft,
        selectedForegroundColor: AppColors.green,
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.cream,
      indicatorColor: Color(0xFFD2D7CB),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.green,
      foregroundColor: AppColors.cream,
      shape: StadiumBorder(),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.green,
      contentTextStyle: const TextStyle(color: AppColors.cream),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
