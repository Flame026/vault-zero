import 'package:flutter/material.dart';

import '../../../domain/models/field_definition.dart';

class DeleteFieldDialog extends StatelessWidget {
  final FieldDefinition field;

  const DeleteFieldDialog({super.key, required this.field});

  static Future<bool> show(BuildContext context, {required FieldDefinition field}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteFieldDialog(field: field),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 48),
      title: const Text('Delete Field?'),
      content: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            const TextSpan(text: 'Are you absolutely sure you want to delete the '),
            TextSpan(
              text: field.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: ' field?\n\n'),
            const TextSpan(
              text: 'This action will instantly and permanently erase all data stored in this field across ALL existing records in the database.\n\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: 'This action cannot be undone.'),
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
