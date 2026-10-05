import 'package:flutter/material.dart';

/// Centralized design tokens for Vault Zero.
///
/// Ensures consistent spacing, corner radii, elevation, and animations
/// across all screens and components.
abstract final class AppSpacing {
  /// 2px — hairline spacing / tiny badge padding
  static const double xxs = 2.0;

  /// 4px — micro spacing between related label and icon
  static const double xs = 4.0;

  /// 8px — tight spacing between related elements inside a container
  static const double sm = 8.0;

  /// 12px — moderate spacing between list items or inside compact cards
  static const double md = 12.0;

  /// 16px — standard padding for screens, cards, and input fields
  static const double lg = 16.0;

  /// 20px — generous padding between form groups or card grids
  static const double xl = 20.0;

  /// 24px — section spacing and dialog padding
  static const double xxl = 24.0;

  /// 32px — large screen margins and empty state spacing
  static const double xxxl = 32.0;

  /// 48px — empty state hero padding
  static const double huge = 48.0;
}

abstract final class AppRadius {
  /// 4px — tiny pill / tag radius
  static const double xs = 4.0;

  /// 8px — small badge / chip radius
  static const double sm = 8.0;

  /// 12px — input fields, inner containers, squircle badges
  static const double md = 12.0;

  /// 16px — cards, dialog action buttons, segmented controls
  static const double card = 16.0;

  /// 24px — dialogs, modal sheets top
  static const double dialog = 24.0;

  /// 28px — bottom sheet top corners
  static const double sheet = 28.0;

  /// 999px — full pill radius
  static const double pill = 999.0;

  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusCard = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius radiusDialog = BorderRadius.all(
    Radius.circular(dialog),
  );
  static const BorderRadius radiusSheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
  static const BorderRadius radiusSheet = radiusSheetTop;
  static const BorderRadius radiusPill = BorderRadius.all(
    Radius.circular(pill),
  );
}

abstract final class AppBorders {
  /// Standard subtle border for cards and containers
  static BorderSide subtle(ColorScheme colorScheme) {
    return BorderSide(
      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
      width: 1.0,
    );
  }

  /// Focused border for active or selected items
  static BorderSide focused(ColorScheme colorScheme) {
    return BorderSide(color: colorScheme.primary, width: 2.0);
  }

  /// Error border
  static BorderSide error(ColorScheme colorScheme) {
    return BorderSide(color: colorScheme.error, width: 1.5);
  }
}

abstract final class AppDurations {
  /// Fast UI transitions (e.g. checkbox, chip toggle, micro-press)
  static const Duration quick = Duration(milliseconds: 150);

  /// Standard screen state switch (e.g. loading -> content)
  static const Duration normal = Duration(milliseconds: 250);

  /// Modal / sheet appearance
  static const Duration modal = Duration(milliseconds: 300);
}

/// Standard responsive breakpoints for phone, tablet, and wide displays.
abstract final class AppBreakpoints {
  /// 600px — Compact phones vs. medium foldables & tablets
  static const double tablet = 600.0;

  /// 900px — Medium tablets vs. expanded landscape tablets & desktop
  static const double desktop = 900.0;

  /// 480px — Short viewport height threshold (e.g. landscape phones)
  static const double shortHeight = 480.0;
}

/// Standard layout width constraints for readability and reach.
abstract final class AppConstraints {
  /// 440px — Max width for modal alert and confirmation dialogs
  static const double maxDialogWidth = 440.0;

  /// 560px — Max width for bottom sheets and format selection sheets
  static const double maxModalWidth = 560.0;

  /// 640px — Max width for centered form layouts and single-column settings
  static const double maxFormWidth = 640.0;

  /// 720px — Max width for import preview and documentation surfaces
  static const double maxContentWidth = 720.0;
}

/// Standard icon sizing tokens across Vault Zero.
abstract final class AppIconSizes {
  /// 14px — micro/metadata icons inside chips, badges, and inline tags
  static const double micro = 14.0;

  /// 16px — compact inline icons (e.g. date pickers, secondary indicators)
  static const double sm = 16.0;

  /// 20px — standard action and list item icons
  static const double standard = 20.0;

  /// 24px — prominent tile and navigation icons
  static const double lg = 24.0;

  /// 32px — dialog header and modal alert icons
  static const double dialog = 32.0;

  /// 48px — hero illustrations and empty state graphics
  static const double hero = 48.0;
}

/// Standard control dimensions for touch targets and component containers.
abstract final class AppControlSizes {
  /// 48px — Minimum accessible touch target (Material 3 standard)
  static const double minTouchTarget = 48.0;

  /// 40px — Standard leading icon badge container width and height
  static const double iconBadge = 40.0;

  /// 32px — Compact icon container width and height
  static const double iconBadgeSm = 32.0;

  /// 24px — Standard metadata chip/badge height
  static const double badgeHeight = 24.0;
}
