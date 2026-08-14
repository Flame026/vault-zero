import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/models/database_definition.dart';
import '../fields/controllers/field_list_controller.dart';
import '../fields/field_list_screen.dart';
import 'controllers/record_list_controller.dart';
import 'controllers/v2_export_controller.dart';
import 'record_form_screen.dart';
import 'widgets/delete_record_dialog.dart';
import 'widgets/record_card.dart';

class RecordListScreen extends ConsumerStatefulWidget {
  final DatabaseDefinition database;

  const RecordListScreen({super.key, required this.database});

  @override
  ConsumerState<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends ConsumerState<RecordListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(recordListControllerProvider(widget.database.id).notifier).loadMore();
    }
  }

  void _showCreateScreen(BuildContext context, fields) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecordFormScreen(
          databaseId: widget.database.id,
          fields: fields,
        ),
      ),
    );
  }

  void _showEditScreen(BuildContext context, record, fields) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecordFormScreen(
          databaseId: widget.database.id,
          initialRecord: record,
          fields: fields,
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, record) async {
    final confirmed = await DeleteRecordDialog.show(context);
    if (confirmed) {
      ref.read(recordListControllerProvider(widget.database.id).notifier).deleteRecord(record.id);
    }
  }

  void _openManageFields(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FieldListScreen(database: widget.database),
      ),
    );
  }

  void _handleExport(BuildContext context, WidgetRef ref, fields) async {
    try {
      final file = await ref.read(v2ExportControllerProvider.notifier).exportToExcel(widget.database, fields);
      if (file != null) {
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Vault Zero Export: ${widget.database.name}'));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export Complete!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export Failed: ${e.toString().replaceAll('Exception: ', '').replaceAll('Bad state: ', '')}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldsState = ref.watch(fieldListControllerProvider(widget.database.id));
    final recordsState = ref.watch(recordListControllerProvider(widget.database.id));
    final isFetchingMore = ref.watch(recordListControllerProvider(widget.database.id).notifier).isFetchingMore;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.database.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.schema_outlined),
            tooltip: 'Manage Fields',
            onPressed: () => _openManageFields(context),
          ),
          fieldsState.maybeWhen(
            data: (fields) => IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'Export Excel',
              onPressed: () => _handleExport(context, ref, fields),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: fieldsState.when(
          data: (fields) {
            if (fields.isEmpty) {
              return _buildNoFieldsState(context, colorScheme, theme);
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: recordsState.when(
                data: (records) {
                  if (records.isEmpty) {
                    return _buildNoRecordsState(context, colorScheme, theme, fields);
                  }
                  return RefreshIndicator(
                    key: const ValueKey('data'),
                    onRefresh: () async {
                      ref.invalidate(recordListControllerProvider(widget.database.id));
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final isWide = width >= 600;

                        if (isWide) {
                          final isLarge = width >= 900;
                          return GridView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.all(isLarge ? 24 : 20),
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 440,
                              mainAxisExtent: 104,
                              crossAxisSpacing: isLarge ? 20 : 16,
                              mainAxisSpacing: isLarge ? 20 : 16,
                            ),
                            itemCount: records.length + (isFetchingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == records.length) {
                                return const SafeArea(
                                  top: false,
                                  child: Center(
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(strokeWidth: 3),
                                    ),
                                  ),
                                );
                              }
                              final record = records[index];
                              return RecordCard(
                                record: record,
                                fields: fields,
                                onTap: () => _showEditScreen(context, record, fields),
                                onDelete: () => _showDeleteDialog(context, ref, record),
                              );
                            },
                          );
                        }

                        return ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: records.length + (isFetchingMore ? 1 : 0),
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == records.length) {
                              return const SafeArea(
                                top: false,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32),
                                  child: Center(
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(strokeWidth: 3),
                                    ),
                                  ),
                                ),
                              );
                            }
                            final record = records[index];
                            return RecordCard(
                              record: record,
                              fields: fields,
                              onTap: () => _showEditScreen(context, record, fields),
                              onDelete: () => _showDeleteDialog(context, ref, record),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  key: ValueKey('loading_records'),
                  child: CircularProgressIndicator(),
                ),
                error: (err, st) => _buildErrorState(context, ref, err, theme, colorScheme),
              ),
            );
          },
          loading: () => const Center(
            key: ValueKey('loading_fields'),
            child: CircularProgressIndicator(),
          ),
          error: (err, st) => _buildErrorState(context, ref, err, theme, colorScheme),
        ),
      ),
      floatingActionButton: fieldsState.maybeWhen(
        data: (fields) => fields.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _showCreateScreen(context, fields),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Record'),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildNoFieldsState(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Center(
      key: const ValueKey('no_fields'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.schema_rounded,
                size: 44,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Fields Defined',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please define at least one field before adding records.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _openManageFields(context),
              icon: const Icon(Icons.schema_rounded),
              label: const Text('Manage Fields'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRecordsState(BuildContext context, ColorScheme colorScheme, ThemeData theme, fields) {
    return Center(
      key: const ValueKey('no_records'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.description_rounded,
                size: 44,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Records',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No records found. Tap + to create your first record.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(fieldListControllerProvider(widget.database.id));
                ref.invalidate(recordListControllerProvider(widget.database.id));
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
