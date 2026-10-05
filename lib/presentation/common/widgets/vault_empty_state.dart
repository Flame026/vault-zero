import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// Reusable empty state view for Vault Zero.
///
/// Communicates clearly what is empty, why it is empty, and what action
/// the user can take to proceed. Fully adaptive for short screen heights
/// (e.g. landscape phones).
class VaultEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData actionIcon;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final IconData? secondaryActionIcon;
  final Key? scrollKey;

  const VaultEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon = Icons.add_rounded,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.secondaryActionIcon,
    this.scrollKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isShort = constraints.maxHeight < 480;

        return SingleChildScrollView(
          key: scrollKey,
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              minWidth: constraints.maxWidth,
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxxl,
                  vertical: isShort ? AppSpacing.lg : AppSpacing.xxxl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Layered tonal icon badge
                    Container(
                      width: isShort ? 60 : 80,
                      height: isShort ? 60 : 80,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(isShort ? 18 : 24),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          size: isShort ? 30 : 40,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: isShort ? AppSpacing.md : AppSpacing.xl),
                    // Title
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Supportive description
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: isShort ? AppSpacing.lg : AppSpacing.xxl),
                    // Primary call-to-action
                    FilledButton.icon(
                      onPressed: onAction,
                      icon: Icon(actionIcon, size: AppIconSizes.standard),
                      label: Text(actionLabel),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl,
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                    if (secondaryActionLabel != null &&
                        onSecondaryAction != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: onSecondaryAction,
                        icon: Icon(
                          secondaryActionIcon ?? Icons.file_upload_outlined,
                          size: AppIconSizes.standard,
                        ),
                        label: Text(secondaryActionLabel!),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl,
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
