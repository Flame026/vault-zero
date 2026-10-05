import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// Standard, recoverable error view for Vault Zero screens.
///
/// Fully responsive across short and tall viewports without overflowing.
class VaultErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  final Key? scrollKey;

  const VaultErrorView({
    super.key,
    this.title = 'Failed to load',
    required this.message,
    required this.onRetry,
    this.scrollKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      key: scrollKey,
      builder: (context, constraints) {
        final isShort = constraints.maxHeight < 480;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              minWidth: constraints.maxWidth,
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: isShort ? AppSpacing.lg : AppSpacing.xxl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: isShort ? 52 : 64,
                      height: isShort ? 52 : 64,
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(
                          alpha: 0.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: isShort ? 28 : 36,
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                    SizedBox(height: isShort ? AppSpacing.md : AppSpacing.lg),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: isShort ? AppSpacing.lg : AppSpacing.xxl),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
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
