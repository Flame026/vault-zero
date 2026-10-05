import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

enum VaultBadgeVariant { tonal, error, success, warning, neutral }

/// Standard compact metadata badge / tag for cards, items, and status indicators.
///
/// Encapsulates consistent 24px height, 8px radius, 14px optical icon size,
/// and responsive text truncation.
class VaultBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VaultBadgeVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  const VaultBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = VaultBadgeVariant.tonal,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  /// Factory constructor for a 'Required' attribute badge.
  const VaultBadge.required({super.key, this.label = 'Required', this.icon})
    : variant = VaultBadgeVariant.error,
      backgroundColor = null,
      foregroundColor = null,
      borderColor = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color resolvedBg;
    final Color resolvedFg;
    final Color resolvedBorder;

    switch (variant) {
      case VaultBadgeVariant.tonal:
        resolvedBg = backgroundColor ?? colorScheme.surfaceContainer;
        resolvedFg = foregroundColor ?? colorScheme.onSurfaceVariant;
        resolvedBorder =
            borderColor ?? colorScheme.outlineVariant.withValues(alpha: 0.4);
        break;
      case VaultBadgeVariant.error:
        resolvedBg =
            backgroundColor ??
            colorScheme.errorContainer.withValues(alpha: 0.6);
        resolvedFg = foregroundColor ?? colorScheme.onErrorContainer;
        resolvedBorder =
            borderColor ?? colorScheme.error.withValues(alpha: 0.3);
        break;
      case VaultBadgeVariant.success:
        resolvedBg =
            backgroundColor ??
            colorScheme.secondaryContainer.withValues(alpha: 0.6);
        resolvedFg = foregroundColor ?? colorScheme.onSecondaryContainer;
        resolvedBorder =
            borderColor ?? colorScheme.secondary.withValues(alpha: 0.3);
        break;
      case VaultBadgeVariant.warning:
        resolvedBg =
            backgroundColor ??
            colorScheme.tertiaryContainer.withValues(alpha: 0.6);
        resolvedFg = foregroundColor ?? colorScheme.onTertiaryContainer;
        resolvedBorder =
            borderColor ?? colorScheme.tertiary.withValues(alpha: 0.3);
        break;
      case VaultBadgeVariant.neutral:
        resolvedBg = backgroundColor ?? colorScheme.surfaceContainerHigh;
        resolvedFg = foregroundColor ?? colorScheme.onSurfaceVariant;
        resolvedBorder =
            borderColor ?? colorScheme.outlineVariant.withValues(alpha: 0.3);
        break;
    }

    return Container(
      constraints: const BoxConstraints(minHeight: AppControlSizes.badgeHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: AppRadius.radiusSm,
        border: Border.all(color: resolvedBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIconSizes.micro, color: resolvedFg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: resolvedFg,
                fontWeight: variant == VaultBadgeVariant.error
                    ? FontWeight.w700
                    : FontWeight.w500,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
