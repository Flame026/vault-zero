import 'package:flutter/material.dart';

import 'theme_preset.dart';

extension AppThemeExtension on ThemePreset {
  ThemeData buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    // 1. Build deliberate ColorScheme
    final ColorScheme colorScheme = _buildColorScheme(brightness);

    // 2. Define consistent background colors
    final scaffoldColor = colorScheme.surface;

    // 3. Construct ThemeData with component themes
    return ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldColor,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: scaffoldColor,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(isDark ? 50 : 80),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(isDark ? 40 : 100)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
        ),
      ),
    );
  }

  ColorScheme _buildColorScheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    switch (this) {
      case ThemePreset.royalPurple:
        return isDark
            ? ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
              ).copyWith(
                primary: const Color(0xFF9D65FF),
                surface: const Color(0xFF14101A),
                surfaceContainer: const Color(0xFF1D1726),
              )
            : ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              ).copyWith(
                primary: const Color(0xFF6F35D3),
                surface: const Color(0xFFFBF9FF),
                surfaceContainer: const Color(0xFFF3EDFD),
              );

      case ThemePreset.oceanBlue:
        return isDark
            ? ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
              ).copyWith(
                primary: const Color(0xFF4DA8FF),
                surface: const Color(0xFF0C121A),
                surfaceContainer: const Color(0xFF141E2B),
              )
            : ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              ).copyWith(
                primary: const Color(0xFF1769AA),
                surface: const Color(0xFFF6FAFF),
                surfaceContainer: const Color(0xFFE8F2FC),
              );

      case ThemePreset.emeraldGreen:
        return isDark
            ? ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
              ).copyWith(
                primary: const Color(0xFF45C492),
                surface: const Color(0xFF0E1713),
                surfaceContainer: const Color(0xFF16261E),
              )
            : ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              ).copyWith(
                primary: const Color(0xFF16835B),
                surface: const Color(0xFFF5FCF8),
                surfaceContainer: const Color(0xFFE5F5ED),
              );

      case ThemePreset.sunsetOrange:
        return isDark
            ? ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
              ).copyWith(
                primary: const Color(0xFFFF8A5C),
                surface: const Color(0xFF1A120E),
                surfaceContainer: const Color(0xFF291B14),
              )
            : ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              ).copyWith(
                primary: const Color(0xFFD85B24),
                surface: const Color(0xFFFFFAF7),
                surfaceContainer: const Color(0xFFFDF0E8),
              );

      case ThemePreset.rosePink:
        return isDark
            ? ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
              ).copyWith(
                primary: const Color(0xFFFF72AD),
                surface: const Color(0xFF1A1014),
                surfaceContainer: const Color(0xFF2B1920),
              )
            : ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              ).copyWith(
                primary: const Color(0xFFC13D75),
                surface: const Color(0xFFFFF7FA),
                surfaceContainer: const Color(0xFFFCE8F0),
              );
    }
  }
}
