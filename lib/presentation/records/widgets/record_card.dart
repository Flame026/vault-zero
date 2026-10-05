import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../domain/models/field_definition.dart';
import '../../../domain/models/field_value.dart';
import '../../../domain/models/record.dart';
import '../../common/widgets/vault_badge.dart';
import '../../common/widgets/vault_card.dart';
import '../../common/widgets/vault_icon_badge.dart';

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

  IconData _getIconForFieldType(FieldType? type) {
    if (type == null) return Icons.description_outlined;
    switch (type) {
      case FieldType.text:
        return Icons.text_fields_rounded;
      case FieldType.longText:
        return Icons.notes_rounded;
      case FieldType.integer:
        return Icons.numbers_rounded;
      case FieldType.decimal:
        return Icons.tag_rounded;
      case FieldType.boolean:
        return Icons.check_circle_outline_rounded;
      case FieldType.date:
        return Icons.calendar_today_rounded;
      case FieldType.dateTime:
        return Icons.access_time_rounded;
      case FieldType.choice:
        return Icons.list_alt_rounded;
    }
  }

  String _formatFieldValue(FieldValue? fieldValue) {
    if (fieldValue == null || fieldValue.value == null) {
      return '';
    }
    if (fieldValue is BooleanFieldValue) {
      return fieldValue.value ? 'Yes' : 'No';
    }
    if (fieldValue is DateFieldValue) {
      return DateFormat.yMMMd().format(fieldValue.value);
    }
    if (fieldValue is DateTimeFieldValue) {
      return DateFormat.yMd().add_jm().format(fieldValue.value);
    }
    if (fieldValue is DecimalFieldValue) {
      return fieldValue.value.toString().replaceAll(RegExp(r'\.0$'), '');
    }
    return fieldValue.value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String primaryText = 'Untitled Record';
    bool isUntitled = true;
    String? secondaryText;
    String? secondaryFieldName;
    FieldType? primaryFieldType;

    if (fields.isNotEmpty) {
      final primaryField = fields[0];
      primaryFieldType = primaryField.type;
      final primaryValue = record.values[primaryField.id];
      if (primaryValue != null &&
          primaryValue.value != null &&
          primaryValue.value.toString().trim().isNotEmpty) {
        primaryText = _formatFieldValue(primaryValue);
        isUntitled = false;
      }

      if (fields.length > 1) {
        final secondaryField = fields[1];
        final secondaryValue = record.values[secondaryField.id];
        if (secondaryValue != null &&
            secondaryValue.value != null &&
            secondaryValue.value.toString().trim().isNotEmpty) {
          secondaryText = _formatFieldValue(secondaryValue);
          secondaryFieldName = secondaryField.name;
        }
      }
    }

    return VaultCard(
      onTap: onTap,
      semanticsLabel: 'Open record $primaryText',
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic record glyph based on primary field type
          VaultIconBadge(
            icon: _getIconForFieldType(primaryFieldType),
            backgroundColor: colorScheme.surfaceContainerHigh.withValues(
              alpha: 0.65,
            ),
            iconColor: isUntitled
                ? colorScheme.onSurfaceVariant
                : colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          // Record text and metadata
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    fontStyle: isUntitled ? FontStyle.italic : FontStyle.normal,
                    color: isUntitled
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                        : colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (secondaryText != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text.rich(
                    TextSpan(
                      children: [
                        if (secondaryFieldName != null)
                          TextSpan(
                            text: '$secondaryFieldName: ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.75,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        TextSpan(
                          text: secondaryText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                // Record timestamp metadata
                VaultBadge(
                  icon: Icons.schedule_rounded,
                  label: DateFormat.yMMMd().format(record.updatedAt),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Action options
          PopupMenuButton<String>(
            tooltip: 'Record options for $primaryText',
            icon: Icon(
              Icons.more_vert_rounded,
              color: colorScheme.onSurfaceVariant,
              size: AppIconSizes.standard,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusCard,
              side: AppBorders.subtle(colorScheme),
            ),
            onSelected: (value) {
              if (value == 'edit') {
                onTap();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: AppIconSizes.standard),
                    SizedBox(width: AppSpacing.md),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_rounded,
                      size: AppIconSizes.standard,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('Delete', style: TextStyle(color: colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
