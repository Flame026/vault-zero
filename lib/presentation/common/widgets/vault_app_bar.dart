import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// Standard production-grade AppBar for Vault Zero screens.
///
/// Features clean title/subtitle hierarchy, left-aligned titles (native Android style),
/// standardized 48x48 touch targets for action icons, and subtle elevation behavior.
class VaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;

  const VaultAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.titleWidget,
    this.actions,
    this.leading,
    this.bottom,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight +
        (subtitle != null && titleWidget == null ? 8.0 : 0.0) +
        (bottom?.preferredSize.height ?? 0.0),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      centerTitle: false,
      titleSpacing: leading == null && !automaticallyImplyLeading
          ? AppSpacing.lg
          : null,
      title:
          titleWidget ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
      actions: actions != null
          ? [...actions!, const SizedBox(width: AppSpacing.xs)]
          : null,
      bottom: bottom,
    );
  }
}
