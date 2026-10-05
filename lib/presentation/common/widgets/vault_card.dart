import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// The canonical card component for Vault Zero.
///
/// Encapsulates consistent M3 elevation, surfaceContainerLow coloring,
/// subtle hairline borders, standard 16px corner radius, and ink ripple.
class VaultCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final BorderSide? border;
  final double elevation;
  final Clip clipBehavior;
  final String? semanticsLabel;

  const VaultCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.elevation = 0,
    this.clipBehavior = Clip.antiAlias,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedRadius = borderRadius ?? AppRadius.radiusCard;
    final resolvedBorder = border ?? AppBorders.subtle(colorScheme);
    final resolvedBackground =
        backgroundColor ?? colorScheme.surfaceContainerLow;

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: resolvedRadius,
        child: content,
      );
      if (semanticsLabel != null) {
        content = Semantics(
          button: true,
          label: semanticsLabel,
          child: content,
        );
      }
    }

    return Card(
      elevation: elevation,
      margin: margin,
      color: resolvedBackground,
      clipBehavior: clipBehavior,
      shape: RoundedRectangleBorder(
        borderRadius: resolvedRadius,
        side: resolvedBorder,
      ),
      child: content,
    );
  }
}
