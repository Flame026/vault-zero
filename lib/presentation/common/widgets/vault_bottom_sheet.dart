import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// Standard adaptive bottom sheet helper for Vault Zero.
///
/// Fixes bottom overflows on landscape viewports and short screens by setting
/// [isScrollControlled] to true, constraining maximum width on wide displays,
/// and wrapping sheet content in a [SingleChildScrollView].
abstract final class VaultBottomSheet {
  /// Displays a modal bottom sheet that adapts safely to landscape and short viewports.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
    bool showDragHandle = true,
    double maxWidth = AppConstraints.maxModalWidth,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      0,
      AppSpacing.xl,
      AppSpacing.xl,
    ),
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.radiusSheetTop,
      ),
      builder: (sheetContext) {
        final screenHeight = MediaQuery.sizeOf(sheetContext).height;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: screenHeight * 0.85,
            ),
            child: SingleChildScrollView(
              padding: contentPadding,
              child: builder(sheetContext),
            ),
          ),
        );
      },
    );
  }
}
