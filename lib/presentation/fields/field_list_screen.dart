import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../domain/models/database_definition.dart';
import '../../../domain/models/field_definition.dart';
import '../common/widgets/vault_app_bar.dart';
import '../common/widgets/vault_empty_state.dart';
import '../common/widgets/vault_error_view.dart';
import '../common/widgets/vault_snackbar.dart';
import '../common/error_sanitizer.dart';
import '../databases/controllers/database_list_controller.dart';
import 'controllers/field_list_controller.dart';
import 'field_form_screen.dart';
import 'widgets/delete_field_dialog.dart';
import 'widgets/field_card.dart';

class FieldListScreen extends ConsumerWidget {
  final DatabaseDefinition database;

  const FieldListScreen({super.key, required this.database});

  void _showCreateScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FieldFormScreen(databaseId: database.id),
      ),
    );
  }

  void _showEditScreen(BuildContext context, FieldDefinition field) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            FieldFormScreen(databaseId: database.id, initialField: field),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    FieldDefinition field,
  ) async {
    final confirmed = await DeleteFieldDialog.show(context, field: field);
    if (confirmed && context.mounted) {
      try {
        await ref
            .read(fieldListControllerProvider(database.id).notifier)
            .deleteField(field.id);
        if (context.mounted) {
          VaultSnackbar.showSuccess(context, 'Field "${field.name}" deleted');
        }
      } catch (e) {
        if (context.mounted) {
          VaultSnackbar.showError(
            context,
            'Failed to delete field: ${sanitizeErrorMessage(e)}',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbs = ref.watch(databaseListControllerProvider).valueOrNull;
    final currentDb =
        dbs?.firstWhere((d) => d.id == database.id, orElse: () => database) ??
        database;

    final state = ref.watch(fieldListControllerProvider(database.id));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final subtitleText = state.maybeWhen(
      data: (fields) => fields.isNotEmpty
          ? '${fields.length} ${fields.length == 1 ? 'field' : 'fields'} defined'
          : 'Database Schema Definition',
      orElse: () => 'Database Schema Definition',
    );

    return Scaffold(
      appBar: VaultAppBar(
        title: '${currentDb.name} Fields',
        subtitle: subtitleText,
      ),
      body: AnimatedSwitcher(
        duration: AppDurations.normal,
        child: state.when(
          data: (fields) {
            if (fields.isEmpty) {
              return VaultEmptyState(
                scrollKey: const ValueKey('empty'),
                icon: Icons.schema_rounded,
                title: 'Database Schema',
                message:
                    "This database has no fields.\nAdd fields to define what you want to track.",
                actionLabel: 'Add Field',
                actionIcon: Icons.add_rounded,
                onAction: () => _showCreateScreen(context),
              );
            }
            return RefreshIndicator(
              key: const ValueKey('data'),
              onRefresh: () async {
                ref.invalidate(fieldListControllerProvider(database.id));
              },
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      // Subdued schema guidance bar
                      Container(
                        margin: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.xs,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: AppRadius.radiusMd,
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Drag to reorder. The top field serves as the title in record lists.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ReorderableListView.builder(
                          key: PageStorageKey('field_list_${database.id}'),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: fields.length,
                          onReorderItem: (oldIndex, newIndex) {
                            ref
                                .read(
                                  fieldListControllerProvider(
                                    database.id,
                                  ).notifier,
                                )
                                .reorderFields(oldIndex, newIndex);
                          },
                          itemBuilder: (context, index) {
                            final field = fields[index];
                            return Padding(
                              key: ValueKey(field.id),
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: FieldCard(
                                field: field,
                                onEdit: () => _showEditScreen(context, field),
                                onDelete: () =>
                                    _showDeleteDialog(context, ref, field),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(
            key: ValueKey('loading'),
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
          error: (error, stack) => VaultErrorView(
            scrollKey: const ValueKey('error'),
            title: 'Failed to load fields',
            message: error.toString(),
            onRetry: () =>
                ref.invalidate(fieldListControllerProvider(database.id)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Create new field',
        onPressed: () => _showCreateScreen(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Field'),
      ),
    );
  }
}
