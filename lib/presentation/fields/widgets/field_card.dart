import 'package:flutter/material.dart';

import '../../../domain/models/field_definition.dart';

class FieldCard extends StatelessWidget {
  final FieldDefinition field;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FieldCard({
    super.key,
    required this.field,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _getIconForType(FieldType type) {
    switch (type) {
      case FieldType.text:
        return Icons.text_fields_rounded;
      case FieldType.longText:
        return Icons.notes_rounded;
      case FieldType.integer:
        return Icons.numbers_rounded;
      case FieldType.decimal:
        return Icons.attach_money_rounded;
      case FieldType.boolean:
        return Icons.check_box_outlined;
      case FieldType.date:
        return Icons.calendar_today_rounded;
      case FieldType.dateTime:
        return Icons.access_time_rounded;
      case FieldType.choice:
        return Icons.list_alt_rounded;
    }
  }

  String _getTypeLabel(FieldType type) {
    switch (type) {
      case FieldType.text:
        return 'Text';
      case FieldType.longText:
        return 'Long Text';
      case FieldType.integer:
        return 'Integer';
      case FieldType.decimal:
        return 'Decimal';
      case FieldType.boolean:
        return 'Boolean (Yes/No)';
      case FieldType.date:
        return 'Date';
      case FieldType.dateTime:
        return 'Date & Time';
      case FieldType.choice:
        return 'Choice';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      key: ValueKey(field.id),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.drag_indicator_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 22,
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconForType(field.type),
                color: colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          field.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (field.isRequired) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Required',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getTypeLabel(field.type),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, size: 20, color: colorScheme.error),
                      const SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: colorScheme.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
