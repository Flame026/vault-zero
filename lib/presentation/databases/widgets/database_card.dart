import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../domain/models/database_definition.dart';
import '../../common/widgets/vault_badge.dart';
import '../../common/widgets/vault_card.dart';
import '../../common/widgets/vault_icon_badge.dart';

class DatabaseCard extends StatelessWidget {
  final DatabaseDefinition database;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageFields;

  const DatabaseCard({
    super.key,
    required this.database,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onManageFields,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fieldCount = database.fields.length;
    final fieldLabel = fieldCount == 0
        ? 'No fields'
        : '$fieldCount ${fieldCount == 1 ? 'field' : 'fields'}';

    return VaultCard(
      onTap: onTap,
      semanticsLabel: 'Open database ${database.name}',
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unified squircle icon badge
          const VaultIconBadge(icon: Icons.storage_rounded),
          const SizedBox(width: AppSpacing.md),
          // Database details
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  database.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (database.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    database.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                // Structured metadata badges
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    VaultBadge(
                      icon: Icons.schema_outlined,
                      label: fieldLabel,
                      variant: fieldCount == 0
                          ? VaultBadgeVariant.warning
                          : VaultBadgeVariant.neutral,
                    ),
                    VaultBadge(
                      icon: Icons.schedule_rounded,
                      label: DateFormat.yMMMd().format(database.updatedAt),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Action menu button with 48x48 touch target
          PopupMenuButton<String>(
            tooltip: 'Database options for ${database.name}',
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
              if (value == 'manage_fields') {
                onManageFields();
              } else if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'manage_fields',
                child: Row(
                  children: [
                    Icon(Icons.schema_rounded, size: AppIconSizes.standard),
                    SizedBox(width: AppSpacing.md),
                    Text('Manage Fields'),
                  ],
                ),
              ),
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
