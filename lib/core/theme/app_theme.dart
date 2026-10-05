import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design_tokens.dart';
import 'theme_preset.dart';

extension AppThemeExtension on ThemePreset {
  ThemeData buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = _buildColorScheme(brightness);

    // 1. Deliberate typography hierarchy
    final baseTextTheme = Typography.material2021(
      platform: TargetPlatform.android,
      colorScheme: colorScheme,
    ).englishLike;

    final textTheme = TextTheme(
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
        height: 1.25,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: colorScheme.onSurface,
        height: 1.3,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        height: 1.3,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.35,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        height: 1.4,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        height: 1.4,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurfaceVariant,
        height: 1.45,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        height: 1.35,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
        height: 1.35,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
        height: 1.3,
      ),
    );

    return ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surfaceTint,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        modalBackgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colorScheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.radiusSheetTop,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusDialog),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        focusElevation: 3,
        hoverElevation: 3,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusCard),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusCard,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        thickness: 1,
        space: 1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerLowest,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusCard,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: colorScheme.secondaryContainer,
          selectedForegroundColor: colorScheme.onSecondaryContainer,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        minVerticalPadding: AppSpacing.xs,
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            AppControlSizes.minTouchTarget,
            AppControlSizes.minTouchTarget,
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  ColorScheme _buildColorScheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    switch (this) {
      case ThemePreset.royalPurple:
        return isDark
            ? const ColorScheme(
                brightness: Brightness.dark,
                primary: Color(0xFFA77DFF),
                onPrimary: Color(0xFF260058),
                primaryContainer: Color(0xFF431D80),
                onPrimaryContainer: Color(0xFFEDDEFF),
                secondary: Color(0xFFCCC2DC),
                onSecondary: Color(0xFF332D41),
                secondaryContainer: Color(0xFF4A4458),
                onSecondaryContainer: Color(0xFFE8DEF8),
                tertiary: Color(0xFFEFB8C8),
                onTertiary: Color(0xFF492532),
                error: Color(0xFFFFB4AB),
                onError: Color(0xFF690005),
                errorContainer: Color(0xFF93000A),
                onErrorContainer: Color(0xFFFFDAD6),
                surface: Color(0xFF131318),
                onSurface: Color(0xFFE5E5EB),
                surfaceContainerLowest: Color(0xFF0E0E12),
                surfaceContainerLow: Color(0xFF1A1A22),
                surfaceContainer: Color(0xFF22222C),
                surfaceContainerHigh: Color(0xFF2B2B36),
                surfaceContainerHighest: Color(0xFF353542),
                onSurfaceVariant: Color(0xFFA3A3B2),
                outline: Color(0xFF757585),
                outlineVariant: Color(0xFF383845),
                inverseSurface: Color(0xFFE5E5EB),
                onInverseSurface: Color(0xFF1E1E24),
                inversePrimary: Color(0xFF642EC3),
              )
            : const ColorScheme(
                brightness: Brightness.light,
                primary: Color(0xFF5E2BB8),
                onPrimary: Color(0xFFFFFFFF),
                primaryContainer: Color(0xFFEFE8FC),
                onPrimaryContainer: Color(0xFF250262),
                secondary: Color(0xFF605A6F),
                onSecondary: Color(0xFFFFFFFF),
                secondaryContainer: Color(0xFFE6E0F8),
                onSecondaryContainer: Color(0xFF1D172A),
                tertiary: Color(0xFF7C5263),
                onTertiary: Color(0xFFFFFFFF),
                error: Color(0xFFBA1A1A),
                onError: Color(0xFFFFFFFF),
                errorContainer: Color(0xFFFFDAD6),
                onErrorContainer: Color(0xFF410002),
                surface: Color(0xFFF9F9FC),
                onSurface: Color(0xFF191B21),
                surfaceContainerLowest: Color(0xFFFFFFFF),
                surfaceContainerLow: Color(0xFFF2F2F7),
                surfaceContainer: Color(0xFFEAEAF0),
                surfaceContainerHigh: Color(0xFFE2E2E8),
                surfaceContainerHighest: Color(0xFFDCDCE2),
                onSurfaceVariant: Color(0xFF565863),
                outline: Color(0xFF787985),
                outlineVariant: Color(0xFFD2D3DC),
                inverseSurface: Color(0xFF2E3036),
                onInverseSurface: Color(0xFFF1F1F5),
                inversePrimary: Color(0xFFA77DFF),
              );

      case ThemePreset.oceanBlue:
        return isDark
            ? const ColorScheme(
                brightness: Brightness.dark,
                primary: Color(0xFF58B0FF),
                onPrimary: Color(0xFF003258),
                primaryContainer: Color(0xFF00497D),
                onPrimaryContainer: Color(0xFFD1E4FF),
                secondary: Color(0xFFBBC7DB),
                onSecondary: Color(0xFF253140),
                secondaryContainer: Color(0xFF3B4858),
                onSecondaryContainer: Color(0xFFD7E3F7),
                tertiary: Color(0xFFD6BEE4),
                onTertiary: Color(0xFF3B2948),
                error: Color(0xFFFFB4AB),
                onError: Color(0xFF690005),
                errorContainer: Color(0xFF93000A),
                onErrorContainer: Color(0xFFFFDAD6),
                surface: Color(0xFF111418),
                onSurface: Color(0xFFE1E5EB),
                surfaceContainerLowest: Color(0xFF0B0E12),
                surfaceContainerLow: Color(0xFF171B20),
                surfaceContainer: Color(0xFF1E232A),
                surfaceContainerHigh: Color(0xFF272D35),
                surfaceContainerHighest: Color(0xFF313842),
                onSurfaceVariant: Color(0xFF9EABB8),
                outline: Color(0xFF727E8C),
                outlineVariant: Color(0xFF353C47),
                inverseSurface: Color(0xFFE1E5EB),
                onInverseSurface: Color(0xFF1B2026),
                inversePrimary: Color(0xFF0B63A4),
              )
            : const ColorScheme(
                brightness: Brightness.light,
                primary: Color(0xFF0B63A4),
                onPrimary: Color(0xFFFFFFFF),
                primaryContainer: Color(0xFFE2F0FF),
                onPrimaryContainer: Color(0xFF001D36),
                secondary: Color(0xFF526070),
                onSecondary: Color(0xFFFFFFFF),
                secondaryContainer: Color(0xFFD5E4F7),
                onSecondaryContainer: Color(0xFF0F1D2B),
                tertiary: Color(0xFF6B5778),
                onTertiary: Color(0xFFFFFFFF),
                error: Color(0xFFBA1A1A),
                onError: Color(0xFFFFFFFF),
                errorContainer: Color(0xFFFFDAD6),
                onErrorContainer: Color(0xFF410002),
                surface: Color(0xFFF8FAFC),
                onSurface: Color(0xFF181C20),
                surfaceContainerLowest: Color(0xFFFFFFFF),
                surfaceContainerLow: Color(0xFFF0F3F7),
                surfaceContainer: Color(0xFFE7EBF0),
                surfaceContainerHigh: Color(0xFFDFE4EA),
                surfaceContainerHighest: Color(0xFFD7DCE3),
                onSurfaceVariant: Color(0xFF505763),
                outline: Color(0xFF737A86),
                outlineVariant: Color(0xFFCFD5DF),
                inverseSurface: Color(0xFF2C3036),
                onInverseSurface: Color(0xFFEFF1F6),
                inversePrimary: Color(0xFF58B0FF),
              );

      case ThemePreset.emeraldGreen:
        return isDark
            ? const ColorScheme(
                brightness: Brightness.dark,
                primary: Color(0xFF4FD6A0),
                onPrimary: Color(0xFF003823),
                primaryContainer: Color(0xFF005235),
                onPrimaryContainer: Color(0xFF71F5BC),
                secondary: Color(0xFFB5CCBA),
                onSecondary: Color(0xFF213528),
                secondaryContainer: Color(0xFF374B3E),
                onSecondaryContainer: Color(0xFFD1E8D6),
                tertiary: Color(0xFFA4CDDD),
                onTertiary: Color(0xFF063542),
                error: Color(0xFFFFB4AB),
                onError: Color(0xFF690005),
                errorContainer: Color(0xFF93000A),
                onErrorContainer: Color(0xFFFFDAD6),
                surface: Color(0xFF111513),
                onSurface: Color(0xFFE1E5E2),
                surfaceContainerLowest: Color(0xFF0C100E),
                surfaceContainerLow: Color(0xFF171D1A),
                surfaceContainer: Color(0xFF1E2521),
                surfaceContainerHigh: Color(0xFF27302B),
                surfaceContainerHighest: Color(0xFF313B35),
                onSurfaceVariant: Color(0xFF9EA9A1),
                outline: Color(0xFF737D76),
                outlineVariant: Color(0xFF353D38),
                inverseSurface: Color(0xFFE1E5E2),
                onInverseSurface: Color(0xFF1B221E),
                inversePrimary: Color(0xFF0F7A53),
              )
            : const ColorScheme(
                brightness: Brightness.light,
                primary: Color(0xFF0F7A53),
                onPrimary: Color(0xFFFFFFFF),
                primaryContainer: Color(0xFFE2F8EE),
                onPrimaryContainer: Color(0xFF002113),
                secondary: Color(0xFF4F6355),
                onSecondary: Color(0xFFFFFFFF),
                secondaryContainer: Color(0xFFD2E8D7),
                onSecondaryContainer: Color(0xFF0D1F14),
                tertiary: Color(0xFF3C6473),
                onTertiary: Color(0xFFFFFFFF),
                error: Color(0xFFBA1A1A),
                onError: Color(0xFFFFFFFF),
                errorContainer: Color(0xFFFFDAD6),
                onErrorContainer: Color(0xFF410002),
                surface: Color(0xFFF7FAF8),
                onSurface: Color(0xFF181D1A),
                surfaceContainerLowest: Color(0xFFFFFFFF),
                surfaceContainerLow: Color(0xFFEEF3F0),
                surfaceContainer: Color(0xFFE5ECE8),
                surfaceContainerHigh: Color(0xFFDDE4E0),
                surfaceContainerHighest: Color(0xFFD4DCD8),
                onSurfaceVariant: Color(0xFF4E5851),
                outline: Color(0xFF717C75),
                outlineVariant: Color(0xFFCDD6D0),
                inverseSurface: Color(0xFF2C322E),
                onInverseSurface: Color(0xFFEEF3EE),
                inversePrimary: Color(0xFF4FD6A0),
              );

      case ThemePreset.sunsetOrange:
        return isDark
            ? const ColorScheme(
                brightness: Brightness.dark,
                primary: Color(0xFFFF956B),
                onPrimary: Color(0xFF551C00),
                primaryContainer: Color(0xFF792900),
                onPrimaryContainer: Color(0xFFFFDBCE),
                secondary: Color(0xFFE7BEAF),
                onSecondary: Color(0xFF442B21),
                secondaryContainer: Color(0xFF5D4035),
                onSecondaryContainer: Color(0xFFFFDBCE),
                tertiary: Color(0xFFD6C68E),
                onTertiary: Color(0xFF3A3005),
                error: Color(0xFFFFB4AB),
                onError: Color(0xFF690005),
                errorContainer: Color(0xFF93000A),
                onErrorContainer: Color(0xFFFFDAD6),
                surface: Color(0xFF161311),
                onSurface: Color(0xFFE8E2DF),
                surfaceContainerLowest: Color(0xFF110E0C),
                surfaceContainerLow: Color(0xFF1E1A17),
                surfaceContainer: Color(0xFF26211E),
                surfaceContainerHigh: Color(0xFF312C28),
                surfaceContainerHighest: Color(0xFF3D3732),
                onSurfaceVariant: Color(0xFFAFA29C),
                outline: Color(0xFF837772),
                outlineVariant: Color(0xFF423B36),
                inverseSurface: Color(0xFFE8E2DF),
                onInverseSurface: Color(0xFF221E1C),
                inversePrimary: Color(0xFFB33E0B),
              )
            : const ColorScheme(
                brightness: Brightness.light,
                primary: Color(0xFFB33E0B),
                onPrimary: Color(0xFFFFFFFF),
                primaryContainer: Color(0xFFFFECE5),
                onPrimaryContainer: Color(0xFF3B0F00),
                secondary: Color(0xFF77574B),
                onSecondary: Color(0xFFFFFFFF),
                secondaryContainer: Color(0xFFFFDBCE),
                onSecondaryContainer: Color(0xFF2C160D),
                tertiary: Color(0xFF6B5D2F),
                onTertiary: Color(0xFFFFFFFF),
                error: Color(0xFFBA1A1A),
                onError: Color(0xFFFFFFFF),
                errorContainer: Color(0xFFFFDAD6),
                onErrorContainer: Color(0xFF410002),
                surface: Color(0xFFFCFAF9),
                onSurface: Color(0xFF201B18),
                surfaceContainerLowest: Color(0xFFFFFFFF),
                surfaceContainerLow: Color(0xFFF5F1EF),
                surfaceContainer: Color(0xFFEBE6E3),
                surfaceContainerHigh: Color(0xFFE3DDD9),
                surfaceContainerHighest: Color(0xFFDBD5D1),
                onSurfaceVariant: Color(0xFF5B524D),
                outline: Color(0xFF7E746F),
                outlineVariant: Color(0xFFD7CFCA),
                inverseSurface: Color(0xFF342E2B),
                onInverseSurface: Color(0xFFF7F2EF),
                inversePrimary: Color(0xFFFF956B),
              );

      case ThemePreset.rosePink:
        return isDark
            ? const ColorScheme(
                brightness: Brightness.dark,
                primary: Color(0xFFFF7DB7),
                onPrimary: Color(0xFF580034),
                primaryContainer: Color(0xFF7D004B),
                onPrimaryContainer: Color(0xFFFFD8E7),
                secondary: Color(0xFFE2BDCC),
                onSecondary: Color(0xFF422935),
                secondaryContainer: Color(0xFF5B3F4C),
                onSecondaryContainer: Color(0xFFFFD9E7),
                tertiary: Color(0xFFEBB8B0),
                onTertiary: Color(0xFF462520),
                error: Color(0xFFFFB4AB),
                onError: Color(0xFF690005),
                errorContainer: Color(0xFF93000A),
                onErrorContainer: Color(0xFFFFDAD6),
                surface: Color(0xFF161214),
                onSurface: Color(0xFFE7E1E3),
                surfaceContainerLowest: Color(0xFF110E10),
                surfaceContainerLow: Color(0xFF1E191B),
                surfaceContainer: Color(0xFF262023),
                surfaceContainerHigh: Color(0xFF312A2E),
                surfaceContainerHighest: Color(0xFF3D3439),
                onSurfaceVariant: Color(0xFFAEA1A7),
                outline: Color(0xFF82767C),
                outlineVariant: Color(0xFF42393E),
                inverseSurface: Color(0xFFE7E1E3),
                onInverseSurface: Color(0xFF221E20),
                inversePrimary: Color(0xFFA52467),
              )
            : const ColorScheme(
                brightness: Brightness.light,
                primary: Color(0xFFA52467),
                onPrimary: Color(0xFFFFFFFF),
                primaryContainer: Color(0xFFFFEBF2),
                onPrimaryContainer: Color(0xFF3E0022),
                secondary: Color(0xFF745663),
                onSecondary: Color(0xFFFFFFFF),
                secondaryContainer: Color(0xFFFFD9E7),
                onSecondaryContainer: Color(0xFF2B1520),
                tertiary: Color(0xFF7B524B),
                onTertiary: Color(0xFFFFFFFF),
                error: Color(0xFFBA1A1A),
                onError: Color(0xFFFFFFFF),
                errorContainer: Color(0xFFFFDAD6),
                onErrorContainer: Color(0xFF410002),
                surface: Color(0xFFFCF9FA),
                onSurface: Color(0xFF201B1D),
                surfaceContainerLowest: Color(0xFFFFFFFF),
                surfaceContainerLow: Color(0xFFF5EFF2),
                surfaceContainer: Color(0xFFEBE4E7),
                surfaceContainerHigh: Color(0xFFE3DCE0),
                surfaceContainerHighest: Color(0xFFDBD3D8),
                onSurfaceVariant: Color(0xFF5A5155),
                outline: Color(0xFF7E7378),
                outlineVariant: Color(0xFFD6CED3),
                inverseSurface: Color(0xFF342E31),
                onInverseSurface: Color(0xFFF7F0F3),
                inversePrimary: Color(0xFFFF7DB7),
              );
    }
  }
}
