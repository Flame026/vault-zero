import 'package:flutter/material.dart';

import '../../../domain/models/database_definition.dart';
import '../../common/widgets/vault_destructive_dialog.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final DatabaseDefinition database;

  const DeleteConfirmationDialog({super.key, required this.database});

  static Future<bool> show(
    BuildContext context, {
    required DatabaseDefinition database,
  }) async {
    return VaultDestructiveDialog.show(
      context,
      title: 'Delete Database?',
      confirmText: 'Delete Permanently',
      cancelText: 'Cancel',
      content: _buildContent(context, database),
    );
  }

  static Widget _buildContent(
    BuildContext context,
    DatabaseDefinition database,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text.rich(
      TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          height: 1.45,
        ),
        children: [
          const TextSpan(
            text: 'Are you absolutely sure you want to delete the ',
          ),
          TextSpan(
            text: database.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(
            text:
                ' database?\n\nThis action will permanently erase:\n\n'
                '• The database schema\n'
                '• All defined fields\n'
                '• All records and values',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VaultDestructiveDialog(
      title: 'Delete Database?',
      confirmText: 'Delete Permanently',
      cancelText: 'Cancel',
      content: _buildContent(context, database),
    );
  }
}
