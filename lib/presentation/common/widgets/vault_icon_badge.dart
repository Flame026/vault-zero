import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// Standard squircle icon badge for cards, list items, and feature rows.
///
/// Encapsulates consistent 40x40 dimension, 12px corner radius, and
/// calibrated tonal background surfaces.
class VaultIconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final BorderRadius? borderRadius;
  final BoxBorder? border;

  const VaultIconBadge({
    super.key,
    required this.icon,
    this.size = AppControlSizes.iconBadge,
    this.iconSize = AppIconSizes.standard,
    this.backgroundColor,
    this.iconColor,
    this.borderRadius,
    this.border,
  });

  /// Factory for a compact 32x32 icon badge.
  const VaultIconBadge.small({
    super.key,
    required this.icon,
    this.size = AppControlSizes.iconBadgeSm,
    this.iconSize = AppIconSizes.sm,
    this.backgroundColor,
    this.iconColor,
    this.borderRadius = AppRadius.radiusSm,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedBg =
        backgroundColor ?? colorScheme.primaryContainer.withValues(alpha: 0.65);
    final resolvedIconColor = iconColor ?? colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: borderRadius ?? AppRadius.radiusMd,
        border: border,
      ),
      child: Center(
        child: Icon(icon, size: iconSize, color: resolvedIconColor),
      ),
    );
  }
}
