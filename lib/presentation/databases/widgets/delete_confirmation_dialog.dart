import 'package:flutter/material.dart';

import '../../../domain/models/database_definition.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final DatabaseDefinition database;

  const DeleteConfirmationDialog({super.key, required this.database});

  static Future<bool> show(BuildContext context, {required DatabaseDefinition database}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteConfirmationDialog(database: database),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 48),
      title: const Text('Delete Database?'),
      content: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            const TextSpan(text: 'Are you absolutely sure you want to delete the '),
            TextSpan(
              text: database.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(
              text: ' database?\n\nThis action will permanently erase:\n\n'
                  '• The database schema\n'
                  '• All defined fields\n'
                  '• All records and values\n\n'
                  'This action cannot be undone.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: const Text('Delete Permanently'),
        ),
      ],
    );
  }
}
