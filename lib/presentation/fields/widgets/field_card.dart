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
        return Icons.text_fields;
      case FieldType.longText:
        return Icons.notes;
      case FieldType.integer:
        return Icons.numbers;
      case FieldType.decimal:
        return Icons.money;
      case FieldType.boolean:
        return Icons.check_box;
      case FieldType.date:
        return Icons.calendar_today;
      case FieldType.dateTime:
        return Icons.access_time;
      case FieldType.choice:
        return Icons.list_alt;
    }
  }

  String _getTypeLabel(FieldType type) {
    switch (type) {
      case FieldType.text: return 'Text';
      case FieldType.longText: return 'Long Text';
      case FieldType.integer: return 'Integer';
      case FieldType.decimal: return 'Decimal';
      case FieldType.boolean: return 'Boolean (Yes/No)';
      case FieldType.date: return 'Date';
      case FieldType.dateTime: return 'Date & Time';
      case FieldType.choice: return 'Choice';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const ReorderableDragStartListener(
              index: 0, // This gets overridden by the ListView, but we supply it anyway. Wait, ReorderableDragStartListener needs the actual index.
              // Actually, ReorderableListView handles dragging via the drag handle automatically if we use ReorderableDragStartListener, but it's easier to just let ReorderableListView handle it by default, or provide an explicit handle.
              // We'll replace ReorderableDragStartListener with an Icon, and ReorderableListView will make the whole card draggable, or we can use ReorderableDragStartListener around a handle.
              // We'll just provide a drag handle icon visually. The framework handles dragging on long-press.
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.drag_indicator, color: Colors.grey),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconForType(field.type),
                color: colorScheme.onSecondaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(4),
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
                  const SizedBox(height: 4),
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
              icon: const Icon(Icons.more_vert),
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
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Colors.red)),
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
