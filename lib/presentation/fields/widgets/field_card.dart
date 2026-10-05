import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../domain/models/field_definition.dart';
import '../../common/widgets/vault_badge.dart';
import '../../common/widgets/vault_card.dart';
import '../../common/widgets/vault_icon_badge.dart';

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
        return Icons.tag_rounded;
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

  Color _getTypeBackgroundColor(ColorScheme colorScheme, FieldType type) {
    switch (type) {
      case FieldType.text:
      case FieldType.longText:
        return colorScheme.primaryContainer.withValues(alpha: 0.7);
      case FieldType.integer:
      case FieldType.decimal:
        return colorScheme.tertiaryContainer.withValues(alpha: 0.7);
      case FieldType.boolean:
        return colorScheme.secondaryContainer.withValues(alpha: 0.7);
      case FieldType.date:
      case FieldType.dateTime:
        return colorScheme.surfaceContainerHighest;
      case FieldType.choice:
        return colorScheme.primaryContainer.withValues(alpha: 0.5);
    }
  }

  Color _getTypeForegroundColor(ColorScheme colorScheme, FieldType type) {
    switch (type) {
      case FieldType.text:
      case FieldType.longText:
        return colorScheme.onPrimaryContainer;
      case FieldType.integer:
      case FieldType.decimal:
        return colorScheme.onTertiaryContainer;
      case FieldType.boolean:
        return colorScheme.onSecondaryContainer;
      case FieldType.date:
      case FieldType.dateTime:
        return colorScheme.primary;
      case FieldType.choice:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return VaultCard(
      key: ValueKey(field.id),
      onTap: onEdit,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Reorder drag affordance
          Semantics(
            label: 'Reorder ${field.name}',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Icon(
                Icons.drag_indicator_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Field type icon container
          VaultIconBadge(
            icon: _getIconForType(field.type),
            backgroundColor: _getTypeBackgroundColor(colorScheme, field.type),
            iconColor: _getTypeForegroundColor(colorScheme, field.type),
          ),
          const SizedBox(width: AppSpacing.md),
          // Field name and attributes
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
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (field.isRequired) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Flexible(child: VaultBadge.required()),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _getTypeLabel(field.type),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Popup action menu
          PopupMenuButton<String>(
            tooltip: 'Field options for ${field.name}',
            icon: Icon(
              Icons.more_vert_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusCard,
              side: AppBorders.subtle(colorScheme),
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
                      size: 20,
                      color: colorScheme.error,
                    ),
                    SizedBox(width: AppSpacing.md),
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
