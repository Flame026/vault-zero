import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// Provides consistent, calm, and accessible floating snackbar notifications
/// across Vault Zero.
abstract final class VaultSnackbar {
  /// Shows a success feedback snackbar with a checkmark icon.
  static void showSuccess(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 20,
              color: colorScheme.onInverseSurface,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  /// Shows an error feedback snackbar with an alert icon and error color.
  static void showError(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.error,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        content: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: colorScheme.onError,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onError),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows an informational snackbar.
  static void showInfo(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        content: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: colorScheme.onInverseSurface,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
