import 'package:flutter/material.dart';

import '../../../domain/models/field_definition.dart';
import '../../common/widgets/vault_destructive_dialog.dart';

class DeleteFieldDialog extends StatelessWidget {
  final FieldDefinition field;

  const DeleteFieldDialog({super.key, required this.field});

  static Future<bool> show(
    BuildContext context, {
    required FieldDefinition field,
  }) async {
    return VaultDestructiveDialog.show(
      context,
      title: 'Delete Field?',
      confirmText: 'Delete Permanently',
      cancelText: 'Cancel',
      content: _buildContent(context, field),
    );
  }

  static Widget _buildContent(BuildContext context, FieldDefinition field) {
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
            text: field.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' field?\n\n'),
          const TextSpan(
            text:
                'This action will permanently erase all data stored in this field across ALL existing records in the database.',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VaultDestructiveDialog(
      title: 'Delete Field?',
      confirmText: 'Delete Permanently',
      cancelText: 'Cancel',
      content: _buildContent(context, field),
    );
  }
}
