import 'package:flutter/material.dart';

import '../../common/widgets/vault_destructive_dialog.dart';

class DeleteRecordDialog extends StatelessWidget {
  final String? recordTitle;

  const DeleteRecordDialog({super.key, this.recordTitle});

  static Future<bool> show(BuildContext context, {String? recordTitle}) async {
    return VaultDestructiveDialog.show(
      context,
      title: 'Delete Record?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      content: _buildContent(context, recordTitle),
    );
  }

  static Widget _buildContent(BuildContext context, String? recordTitle) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text.rich(
      TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          height: 1.45,
        ),
        children: [
          const TextSpan(text: 'Are you sure you want to delete '),
          TextSpan(
            text: recordTitle != null ? '"$recordTitle"' : 'this record',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: '?'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VaultDestructiveDialog(
      title: 'Delete Record?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      content: _buildContent(context, recordTitle),
    );
  }
}
