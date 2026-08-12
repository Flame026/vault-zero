import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../legacy/presentation/screens/character_entry_screen.dart';
import '../fields/field_list_screen.dart';
import '../records/record_list_screen.dart';
import '../settings/settings_screen.dart';
import 'controllers/database_list_controller.dart';
import 'widgets/database_card.dart';
import 'widgets/database_form_dialog.dart';
import 'widgets/delete_confirmation_dialog.dart';

class DatabaseListScreen extends ConsumerWidget {
  const DatabaseListScreen({super.key});

  void _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await DatabaseFormDialog.show(context);
    if (result != null) {
      ref.read(databaseListControllerProvider.notifier).createDatabase(
            name: result['name']!,
            description: result['description']!,
          );
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, database) async {
    final result = await DatabaseFormDialog.show(context, initialDatabase: database);
    if (result != null) {
      ref.read(databaseListControllerProvider.notifier).updateDatabase(
            database,
            name: result['name']!,
            description: result['description']!,
          );
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, database) async {
    final confirmed = await DeleteConfirmationDialog.show(context, database: database);
    if (confirmed) {
      ref.read(databaseListControllerProvider.notifier).deleteDatabase(database.id);
    }
  }

  void _navigateToLegacy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CharacterEntryScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(databaseListControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Zero'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Legacy Archive',
            onPressed: () => _navigateToLegacy(context),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: state.when(
          data: (databases) {
            if (databases.isEmpty) {
              return _buildEmptyState(context, ref);
            }
            return RefreshIndicator(
              key: const ValueKey('data'),
              onRefresh: () async {
                // AsyncValue.guard handles loading, but RefreshIndicator expects a Future
                ref.invalidate(databaseListControllerProvider);
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: databases.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final db = databases[index];
                  return DatabaseCard(
                    database: db,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => RecordListScreen(database: db),
                        ),
                      );
                    },
                    onManageFields: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FieldListScreen(database: db),
                        ),
                      );
                    },
                    onEdit: () => _showEditDialog(context, ref, db),
                    onDelete: () => _showDeleteDialog(context, ref, db),
                  );
                },
              ),
            );
          },
          loading: () => const Center(key: ValueKey('loading'), child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            key: const ValueKey('error'),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load databases',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(databaseListControllerProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Database'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      key: const ValueKey('empty'),
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
                Icons.storage_rounded,
                size: 72,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Databases',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You haven't created any databases yet.\nCreate a database to get started.",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Create Database'),
            ),
          ],
        ),
      ),
    );
  }
}
