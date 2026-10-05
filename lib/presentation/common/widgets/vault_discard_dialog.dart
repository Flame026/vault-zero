import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// Standard confirmation dialog for discarding unsaved changes across Vault Zero.
///
/// Ensures consistent presentation, accessibility semantics, and error styling
/// while preserving established workflow test expectations.
class VaultDiscardDialog extends StatelessWidget {
  const VaultDiscardDialog({super.key});

  /// Displays the discard confirmation dialog and returns `true` if discard is confirmed,
  /// or `false` if the user chooses to keep editing.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const VaultDiscardDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusDialog),
      backgroundColor: colorScheme.surfaceContainerLow,
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.sm,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.sm,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      icon: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: colorScheme.error,
            size: 24,
          ),
        ),
      ),
      title: Text(
        'Discard changes?',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppConstraints.maxDialogWidth,
        ),
        child: Text(
          'You have unsaved changes. Are you sure you want to discard them and exit?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep Editing'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          ),
          child: const Text('Discard'),
        ),
      ],
    );
  }
}
