import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/database_definition.dart';
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

  void _showEditScreen(BuildContext context, field) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FieldFormScreen(
          databaseId: database.id,
          initialField: field,
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, field) async {
    final confirmed = await DeleteFieldDialog.show(context, field: field);
    if (confirmed) {
      ref.read(fieldListControllerProvider(database.id).notifier).deleteField(field.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fieldListControllerProvider(database.id));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${database.name} Fields'),
      ),
      body: state.when(
        data: (fields) {
          if (fields.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(fieldListControllerProvider(database.id));
            },
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: fields.length,
              onReorderItem: (oldIndex, newIndex) {
                ref.read(fieldListControllerProvider(database.id).notifier).reorderFields(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final field = fields[index];
                return Padding(
                  key: ValueKey(field.id),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FieldCard(
                    field: field,
                    onEdit: () => _showEditScreen(context, field),
                    onDelete: () => _showDeleteDialog(context, ref, field),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: 16),
                Text('Failed to load fields', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(fieldListControllerProvider(database.id)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateScreen(context),
        icon: const Icon(Icons.add),
        label: const Text('New Field'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.view_list_rounded,
                size: 72,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Database Schema',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "This database has no fields.\nAdd fields to define what you want to track.",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showCreateScreen(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Field'),
            ),
          ],
        ),
      ),
    );
  }
}
