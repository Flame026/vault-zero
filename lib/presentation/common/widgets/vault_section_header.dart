import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// Standard section header with uppercase tracked typography and consistent margins.
class VaultSectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Widget? trailing;

  const VaultSectionHeader({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.xs,
      AppSpacing.md,
      AppSpacing.xs,
      AppSpacing.sm,
    ),
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedColor = color ?? colorScheme.primary;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: resolvedColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
