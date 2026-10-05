import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:file_picker/file_picker.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../domain/models/database_definition.dart';
import '../common/widgets/vault_app_bar.dart';
import '../common/widgets/vault_bottom_sheet.dart';
import '../common/widgets/vault_empty_state.dart';
import '../common/widgets/vault_error_view.dart';
import '../common/widgets/vault_icon_badge.dart';
import '../common/widgets/vault_section_header.dart';
import '../common/widgets/vault_snackbar.dart';
import '../common/error_sanitizer.dart';
import '../fields/field_list_screen.dart';
import '../import/csv_preview_screen.dart';
import '../import/excel_preview_screen.dart';
import '../records/record_list_screen.dart';
import '../settings/settings_screen.dart';
import 'controllers/database_list_controller.dart';
import 'widgets/database_card.dart';
import 'widgets/database_form_dialog.dart';
import 'widgets/delete_confirmation_dialog.dart';

class DatabaseListScreen extends ConsumerStatefulWidget {
  const DatabaseListScreen({super.key});

  @override
  ConsumerState<DatabaseListScreen> createState() => _DatabaseListScreenState();
}

class _DatabaseListScreenState extends ConsumerState<DatabaseListScreen> {
  bool _isSearching = false;
  bool _isPickingFile = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    _searchFocusNode.requestFocus();
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
  }

  bool _isActionInProgress = false;

  void _showCreateDialog(BuildContext context) async {
    if (_isActionInProgress) return;
    _isActionInProgress = true;
    try {
      final result = await DatabaseFormDialog.show(context);
      if (result != null && context.mounted) {
        try {
          await ref
              .read(databaseListControllerProvider.notifier)
              .createDatabase(
                name: result['name']!,
                description: result['description']!,
              );
          if (context.mounted) {
            VaultSnackbar.showSuccess(context, 'Database created');
          }
        } catch (e) {
          if (context.mounted) {
            VaultSnackbar.showError(
              context,
              'Failed to create database: ${sanitizeErrorMessage(e)}',
            );
          }
        }
      }
    } finally {
      _isActionInProgress = false;
    }
  }

  void _showEditDialog(
    BuildContext context,
    DatabaseDefinition database,
  ) async {
    if (_isActionInProgress) return;
    _isActionInProgress = true;
    try {
      final result = await DatabaseFormDialog.show(
        context,
        initialDatabase: database,
      );
      if (result != null && context.mounted) {
        try {
          await ref
              .read(databaseListControllerProvider.notifier)
              .updateDatabase(
                database,
                name: result['name']!,
                description: result['description']!,
              );
          if (context.mounted) {
            VaultSnackbar.showSuccess(context, 'Database updated');
          }
        } catch (e) {
          if (context.mounted) {
            VaultSnackbar.showError(
              context,
              'Failed to update database: ${sanitizeErrorMessage(e)}',
            );
          }
        }
      }
    } finally {
      _isActionInProgress = false;
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    DatabaseDefinition database,
  ) async {
    if (_isActionInProgress) return;
    _isActionInProgress = true;
    try {
      final confirmed = await DeleteConfirmationDialog.show(
        context,
        database: database,
      );
      if (confirmed && context.mounted) {
        try {
          await ref
              .read(databaseListControllerProvider.notifier)
              .deleteDatabase(database.id);
          if (context.mounted) {
            VaultSnackbar.showSuccess(context, 'Deleted "${database.name}"');
          }
        } catch (e) {
          if (context.mounted) {
            VaultSnackbar.showError(
              context,
              'Failed to delete database: ${sanitizeErrorMessage(e)}',
            );
          }
        }
      }
    } finally {
      _isActionInProgress = false;
    }
  }

  Future<void> _handleImportCsv() async {
    if (_isPickingFile) return;
    _isPickingFile = true;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result != null && result.files.single.path != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                CsvPreviewScreen(filePath: result.files.single.path!),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        VaultSnackbar.showError(
          context,
          'Could not select CSV file: ${sanitizeErrorMessage(e)}',
        );
      }
    } finally {
      _isPickingFile = false;
    }
  }

  Future<void> _handleImportExcel() async {
    if (_isPickingFile) return;
    _isPickingFile = true;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result != null && result.files.single.path != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                ExcelPreviewScreen(filePath: result.files.single.path!),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        VaultSnackbar.showError(
          context,
          'Could not select Excel file: ${sanitizeErrorMessage(e)}',
        );
      }
    } finally {
      _isPickingFile = false;
    }
  }

  void _showImportSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    VaultBottomSheet.show(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import Database',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Choose a file format to import into a new database.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            leading: VaultIconBadge(
              icon: Icons.table_chart_outlined,
              backgroundColor: colorScheme.primaryContainer,
              iconColor: colorScheme.primary,
            ),
            title: const Text(
              'CSV Document (.csv)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Comma-separated values with auto-detected headers',
            ),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
            onTap: _isPickingFile
                ? null
                : () {
                    Navigator.of(sheetContext).pop();
                    _handleImportCsv();
                  },
          ),
          const SizedBox(height: AppSpacing.xs),
          ListTile(
            leading: VaultIconBadge(
              icon: Icons.table_view_outlined,
              backgroundColor: colorScheme.secondaryContainer,
              iconColor: colorScheme.secondary,
            ),
            title: const Text(
              'Excel Spreadsheet (.xlsx)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Worksheet with typed columns and multiple sheets support',
            ),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
            onTap: _isPickingFile
                ? null
                : () {
                    Navigator.of(sheetContext).pop();
                    _handleImportExcel();
                  },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(databaseListControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final query = _searchController.text.trim().toLowerCase();

    String? subtitleText;
    if (_isSearching && state.hasValue) {
      final total = state.requireValue.length;
      final matchCount = query.isEmpty
          ? total
          : state.requireValue.where((db) {
              return db.name.toLowerCase().contains(query) ||
                  db.description.toLowerCase().contains(query);
            }).length;
      subtitleText = '$matchCount found';
    } else if (state.hasValue && state.requireValue.isNotEmpty) {
      final count = state.requireValue.length;
      subtitleText = '$count ${count == 1 ? 'database' : 'databases'}';
    }

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSearching) {
          _stopSearch();
        }
      },
      child: Scaffold(
        appBar: VaultAppBar(
          automaticallyImplyLeading: !_isSearching,
          leading: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Close search',
                  onPressed: _stopSearch,
                )
              : null,
          title: 'Vault Zero',
          subtitle: subtitleText,
          titleWidget: _isSearching
              ? Container(
                  height: 40,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: AppRadius.radiusCard,
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          autofocus: true,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Search databases...',
                            hintStyle: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.65,
                              ),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
          actions: [
            if (_isSearching) ...[
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  tooltip: 'Clear search',
                  onPressed: () => _searchController.clear(),
                ),
            ] else ...[
              state.maybeWhen(
                data: (databases) => databases.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.search_rounded),
                        tooltip: 'Search databases',
                        onPressed: _startSearch,
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),
              IconButton(
                icon: const Icon(Icons.file_upload_outlined),
                tooltip: 'Import Database',
                onPressed: () => _showImportSheet(context),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
        body: AnimatedSwitcher(
          duration: AppDurations.normal,
          child: state.when(
            data: (databases) {
              if (databases.isEmpty) {
                return VaultEmptyState(
                  scrollKey: const ValueKey('empty'),
                  icon: Icons.storage_rounded,
                  title: 'Your Databases',
                  message:
                      "You haven't created any databases yet.\nCreate a database to get started.",
                  actionLabel: 'Create Database',
                  actionIcon: Icons.add_rounded,
                  onAction: () => _showCreateDialog(context),
                  secondaryActionLabel: 'Import Spreadsheet',
                  secondaryActionIcon: Icons.file_upload_outlined,
                  onSecondaryAction: () => _showImportSheet(context),
                );
              }

              final filteredDatabases = query.isEmpty
                  ? databases
                  : databases.where((db) {
                      return db.name.toLowerCase().contains(query) ||
                          db.description.toLowerCase().contains(query);
                    }).toList();

              if (filteredDatabases.isEmpty) {
                return VaultEmptyState(
                  scrollKey: const ValueKey('no_database_search_results'),
                  icon: Icons.search_off_rounded,
                  title: 'No Databases Found',
                  message:
                      'No databases match "$query".\nCheck for typos or try a different keyword.',
                  actionLabel: 'Clear Search',
                  actionIcon: Icons.clear_rounded,
                  onAction: () => _searchController.clear(),
                );
              }

              return RefreshIndicator(
                key: const ValueKey('data'),
                onRefresh: () async {
                  ref.invalidate(databaseListControllerProvider);
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isWide = width >= 600;
                    final isLarge = width >= 900;
                    final totalCount = databases.length;
                    final matchCount = filteredDatabases.length;

                    final textScaler = MediaQuery.textScalerOf(context);
                    final textScale = textScaler.scale(1.0);
                    final cardHeight =
                        (156.0 +
                                (textScale > 1.0
                                    ? (textScale - 1.0) * 120.0
                                    : 0.0))
                            .ceilToDouble();

                    final horizontalPadding = isWide
                        ? (isLarge ? AppSpacing.xxl : AppSpacing.xl)
                        : AppSpacing.lg;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            AppSpacing.sm,
                            horizontalPadding,
                            AppSpacing.xs,
                          ),
                          child: VaultSectionHeader(
                            title: _isSearching
                                ? 'Search Results'
                                : 'All Databases',
                            padding: EdgeInsets.zero,
                            trailing: Text(
                              _isSearching
                                  ? '$matchCount ${matchCount == 1 ? 'match' : 'matches'}'
                                  : '$totalCount ${totalCount == 1 ? 'database' : 'databases'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: isWide
                              ? GridView.builder(
                                  key: const PageStorageKey(
                                    'database_list_grid',
                                  ),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  padding: EdgeInsets.fromLTRB(
                                    horizontalPadding,
                                    AppSpacing.xs,
                                    horizontalPadding,
                                    AppSpacing.xxxl * 2,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 440,
                                        mainAxisExtent: cardHeight,
                                        crossAxisSpacing: isLarge
                                            ? AppSpacing.xl
                                            : AppSpacing.lg,
                                        mainAxisSpacing: isLarge
                                            ? AppSpacing.xl
                                            : AppSpacing.lg,
                                      ),
                                  itemCount: filteredDatabases.length,
                                  itemBuilder: (context, index) {
                                    final db = filteredDatabases[index];
                                    return DatabaseCard(
                                      key: ValueKey(db.id),
                                      database: db,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                RecordListScreen(database: db),
                                          ),
                                        );
                                      },
                                      onManageFields: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FieldListScreen(database: db),
                                          ),
                                        );
                                      },
                                      onEdit: () =>
                                          _showEditDialog(context, db),
                                      onDelete: () =>
                                          _showDeleteDialog(context, db),
                                    );
                                  },
                                )
                              : ListView.separated(
                                  key: const PageStorageKey(
                                    'database_list_list',
                                  ),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  padding: EdgeInsets.fromLTRB(
                                    horizontalPadding,
                                    AppSpacing.xs,
                                    horizontalPadding,
                                    AppSpacing.xxxl * 2,
                                  ),
                                  itemCount: filteredDatabases.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: AppSpacing.md),
                                  itemBuilder: (context, index) {
                                    final db = filteredDatabases[index];
                                    return DatabaseCard(
                                      key: ValueKey(db.id),
                                      database: db,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                RecordListScreen(database: db),
                                          ),
                                        );
                                      },
                                      onManageFields: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FieldListScreen(database: db),
                                          ),
                                        );
                                      },
                                      onEdit: () =>
                                          _showEditDialog(context, db),
                                      onDelete: () =>
                                          _showDeleteDialog(context, db),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
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
              title: 'Failed to load databases',
              message: error.toString(),
              onRetry: () => ref.invalidate(databaseListControllerProvider),
            ),
          ),
        ),
        floatingActionButton: state.maybeWhen(
          data: (databases) => (databases.isNotEmpty && !_isSearching)
              ? FloatingActionButton.extended(
                  tooltip: 'Create new database',
                  elevation: 2,
                  focusElevation: 4,
                  hoverElevation: 4,
                  highlightElevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusCard,
                  ),
                  onPressed: () => _showCreateDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New Database'),
                )
              : null,
          orElse: () => null,
        ),
      ),
    );
  }
}
