import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  String _formatFieldValue(FieldValue? value, FieldType type) {
    if (value == null) return 'Empty';

    switch (type) {
      case FieldType.date:
        if (value is DateFieldValue) {
          return DateFormat.yMMMd().format(value.value);
        }
        return value.value.toString();
      case FieldType.dateTime:
        if (value is DateTimeFieldValue) {
          return DateFormat.yMd().add_jm().format(value.value);
        }
        return value.value.toString();
      case FieldType.boolean:
        if (value is BooleanFieldValue) {
          return value.value ? 'Yes' : 'No';
        }
        return value.value.toString();
      default:
        return value.value.toString();
    }
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
        primaryText = _formatFieldValue(primaryValue, primaryField.type);
      }

      if (fields.length > 1) {
        final secondaryField = fields[1];
        final secondaryValue = record.values[secondaryField.id];
        if (secondaryValue != null && secondaryValue.value != null && secondaryValue.value.toString().isNotEmpty) {
          secondaryText = _formatFieldValue(secondaryValue, secondaryField.type);
        }
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
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
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
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
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
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
      ),
    );
  }
}
