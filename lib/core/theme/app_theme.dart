import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Design tokens from design-tokens.md
abstract class AppColors {
  // Background
  static const bg = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const surfaceHigh = Color(0xFF1E1E1E);
  static const surfaceHigher = Color(0xFF282828);

  // Accent — 형광 라임 (VOLT의 L)
  static const accent = Color(0xFFD4FF00);
  static const accentDim = Color(0xFF8FAA00);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF999999);
  static const textTertiary = Color(0xFF555555);

  // Border
  static const border = Color(0xFF2A2A2A);
  static const borderLight = Color(0xFF333333);

  // Status
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFFF5252);

  // Muscle group colors
  static const chest = Color(0xFFFF6B6B);    // 가슴 — 레드
  static const back = Color(0xFF4ECDC4);     // 등 — 틸
  static const shoulder = Color(0xFFFFBE0B); // 어깨 — 옐로
  static const arm = Color(0xFFFF9F1C);      // 팔 — 오렌지
  static const leg = Color(0xFF2EC4B6);      // 하체 — 민트
  static const abs = Color(0xFF8B5CF6);      // 복근 — 퍼플
  static const cardio = Color(0xFF6B7280);   // 유산소 — 그레이

  static Color muscleGroupColor(String group) {
    switch (group) {
      case '가슴': return chest;
      case '등': return back;
      case '어깨': return shoulder;
      case '팔': return arm;
      case '하체': return leg;
      case '복근': return abs;
      case '유산소': return cardio;
      default: return textSecondary;
    }
  }
}

abstract class AppTextStyles {
  // Display — Anton (via GoogleFonts)
  static TextStyle get displayLg => GoogleFonts.anton(fontSize: 48, color: AppColors.textPrimary, letterSpacing: 1);
  static TextStyle get displayMd => GoogleFonts.anton(fontSize: 32, color: AppColors.textPrimary, letterSpacing: 0.5);
  static TextStyle get displaySm => GoogleFonts.anton(fontSize: 24, color: AppColors.textPrimary);

  // Heading — Archivo
  static TextStyle get headingLg => GoogleFonts.archivo(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static TextStyle get headingMd => GoogleFonts.archivo(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle get headingSm => GoogleFonts.archivo(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  // Body — Archivo
  static TextStyle get bodyLg => GoogleFonts.archivo(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle get bodyMd => GoogleFonts.archivo(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle get bodySm => GoogleFonts.archivo(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);

  // Number — JetBrains Mono (bundled)
  static const numLg = TextStyle(fontFamily: 'JetBrainsMono', fontSize: 32, fontWeight: FontWeight.w500, color: AppColors.textPrimary, letterSpacing: -0.5);
  static const numMd = TextStyle(fontFamily: 'JetBrainsMono', fontSize: 20, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static const numSm = TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary);

  // Label — Archivo
  static TextStyle get labelMd => GoogleFonts.archivo(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 0.5);
  static TextStyle get labelSm => GoogleFonts.archivo(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 0.8);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.accent,
      onPrimary: AppColors.bg,
      secondary: AppColors.accentDim,
      onSecondary: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
      outline: AppColors.border,
    ),
    fontFamily: GoogleFonts.archivo().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: AppTextStyles.headingMd,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textTertiary),
      labelStyle: AppTextStyles.labelMd,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bg,
        textStyle: AppTextStyles.headingSm,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(double.infinity, 52),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: AppTextStyles.bodyMd,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceHigh,
      selectedColor: AppColors.accent.withOpacity(0.2),
      labelStyle: AppTextStyles.bodySm,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.bg,
      elevation: 4,
    ),
  );
}
