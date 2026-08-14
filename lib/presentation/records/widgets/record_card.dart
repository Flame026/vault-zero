import 'package:flutter/material.dart';

import '../../../domain/models/field_definition.dart';
import '../../../domain/models/field_value.dart';
import '../../../domain/models/record.dart';

class RecordCard extends StatelessWidget {
  final Record record;
  final List<FieldDefinition> fields;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const RecordCard({
    super.key,
    required this.record,
    required this.fields,
    required this.onTap,
    required this.onDelete,
  });

  String _formatFieldValue(FieldValue? fieldValue) {
    if (fieldValue == null || fieldValue.value == null) return '';
    return fieldValue.value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String primaryText = 'Untitled Record';
    String? secondaryText;

    if (fields.isNotEmpty) {
      final primaryField = fields[0];
      final primaryValue = record.values[primaryField.id];
      if (primaryValue != null && primaryValue.value != null && primaryValue.value.toString().isNotEmpty) {
        primaryText = _formatFieldValue(primaryValue);
      }

      if (fields.length > 1) {
        final secondaryField = fields[1];
        final secondaryValue = record.values[secondaryField.id];
        if (secondaryValue != null && secondaryValue.value != null && secondaryValue.value.toString().isNotEmpty) {
          secondaryText = _formatFieldValue(secondaryValue);
        }
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (secondaryText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        secondaryText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
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
      ),
    );
  }
}
