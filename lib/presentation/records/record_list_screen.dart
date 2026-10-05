import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../domain/models/database_definition.dart';
import '../../../domain/models/field_definition.dart';
import '../../../domain/models/record.dart';
import '../common/widgets/vault_app_bar.dart';
import '../common/widgets/vault_bottom_sheet.dart';
import '../common/widgets/vault_empty_state.dart';
import '../common/widgets/vault_error_view.dart';
import '../common/widgets/vault_icon_badge.dart';
import '../common/widgets/vault_section_header.dart';
import '../common/widgets/vault_snackbar.dart';
import '../common/error_sanitizer.dart';
import '../databases/controllers/database_list_controller.dart';
import '../fields/controllers/field_list_controller.dart';
import '../fields/field_list_screen.dart';
import 'controllers/record_list_controller.dart';
import 'controllers/v2_export_controller.dart';
import 'record_form_screen.dart';
import 'widgets/delete_record_dialog.dart';
import 'widgets/record_card.dart';

enum RecordSortOrder {
  newestFirst,
  oldestFirst,
  primaryAscending,
  primaryDescending,
}

class RecordListScreen extends ConsumerStatefulWidget {
  final DatabaseDefinition database;

  const RecordListScreen({super.key, required this.database});

  @override
  ConsumerState<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends ConsumerState<RecordListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSearching = false;
  RecordSortOrder _sortOrder = RecordSortOrder.newestFirst;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
    _searchFocusNode.unfocus();
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_isSearching) return;
    final notifier = ref.read(
      recordListControllerProvider(widget.database.id).notifier,
    );
    if (notifier.isFetchingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      notifier.loadMore();
    }
  }

  bool _recordMatchesQuery(Record record, String query) {
    if (query.isEmpty) return true;
    for (final val in record.values.values) {
      if (val.value != null) {
        final str = val.value.toString().toLowerCase();
        if (str.contains(query)) return true;
      }
    }
    return false;
  }

  List<Record> _filterAndSortRecords(
    List<Record> records,
    List<FieldDefinition> fields,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? records
        : records.where((r) => _recordMatchesQuery(r, query)).toList();

    if (filtered.isEmpty) return filtered;

    final sorted = List<Record>.from(filtered);
    switch (_sortOrder) {
      case RecordSortOrder.newestFirst:
        sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case RecordSortOrder.oldestFirst:
        sorted.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case RecordSortOrder.primaryAscending:
        if (fields.isNotEmpty) {
          final pId = fields.first.id;
          sorted.sort((a, b) {
            final aVal = a.values[pId]?.value?.toString().toLowerCase() ?? '';
            final bVal = b.values[pId]?.value?.toString().toLowerCase() ?? '';
            return aVal.compareTo(bVal);
          });
        }
        break;
      case RecordSortOrder.primaryDescending:
        if (fields.isNotEmpty) {
          final pId = fields.first.id;
          sorted.sort((a, b) {
            final aVal = a.values[pId]?.value?.toString().toLowerCase() ?? '';
            final bVal = b.values[pId]?.value?.toString().toLowerCase() ?? '';
            return bVal.compareTo(aVal);
          });
        }
        break;
    }
    return sorted;
  }

  void _showCreateScreen(BuildContext context, List<FieldDefinition> fields) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            RecordFormScreen(databaseId: widget.database.id, fields: fields),
      ),
    );
  }

  void _showEditScreen(
    BuildContext context,
    Record record,
    List<FieldDefinition> fields,
  ) {
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

  bool _isDeleting = false;

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Record record, {
    List<FieldDefinition>? fields,
  }) async {
    if (_isDeleting) return;
    _isDeleting = true;
    try {
      String? recordTitle;
      if (fields != null && fields.isNotEmpty) {
        final firstVal = record.values[fields[0].id]?.value;
        if (firstVal != null && firstVal.toString().trim().isNotEmpty) {
          recordTitle = firstVal.toString();
        }
      }
      final confirmed = await DeleteRecordDialog.show(
        context,
        recordTitle: recordTitle,
      );
      if (confirmed && context.mounted) {
        try {
          await ref
              .read(recordListControllerProvider(widget.database.id).notifier)
              .deleteRecord(record.id);
          if (context.mounted) {
            VaultSnackbar.showSuccess(context, 'Record deleted');
          }
        } catch (e) {
          if (context.mounted) {
            VaultSnackbar.showError(
              context,
              'Failed to delete record: ${sanitizeErrorMessage(e)}',
            );
          }
        }
      }
    } finally {
      _isDeleting = false;
    }
  }

  void _openManageFields(BuildContext context, DatabaseDefinition db) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => FieldListScreen(database: db)),
    );
  }

  bool _isExporting = false;

  void _executeExport(
    BuildContext context,
    WidgetRef ref,
    List<FieldDefinition> fields,
    DatabaseDefinition db, {
    required bool isCsv,
  }) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final notifier = ref.read(exportControllerProvider.notifier);
      final file = isCsv
          ? await notifier.exportToCsv(db, fields)
          : await notifier.exportToExcel(db, fields);

      if (file != null) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Vault Zero Export: ${db.name}',
          ),
        );
        if (context.mounted) {
          VaultSnackbar.showSuccess(
            context,
            'Exported ${isCsv ? "CSV" : "Excel"} successfully!',
          );
        }
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final isDismissed =
          msg.contains('canceled') ||
          msg.contains('cancelled') ||
          msg.contains('dismissed');
      if (!isDismissed && context.mounted) {
        VaultSnackbar.showError(
          context,
          'Export Failed: ${sanitizeErrorMessage(e)}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showExportSheet(
    BuildContext context,
    WidgetRef ref,
    List<FieldDefinition> fields,
    DatabaseDefinition db,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    VaultBottomSheet.show(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Database',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Choose a format to export all records from "${db.name}".',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            leading: VaultIconBadge(
              icon: Icons.table_view_outlined,
              backgroundColor: colorScheme.primaryContainer,
              iconColor: colorScheme.primary,
            ),
            title: const Text(
              'Excel Spreadsheet (.xlsx)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Standard workbook format with typed cells'),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
            onTap: _isExporting
                ? null
                : () {
                    Navigator.of(sheetContext).pop();
                    _executeExport(context, ref, fields, db, isCsv: false);
                  },
          ),
          const SizedBox(height: AppSpacing.xs),
          ListTile(
            leading: VaultIconBadge(
              icon: Icons.table_chart_outlined,
              backgroundColor: colorScheme.secondaryContainer,
              iconColor: colorScheme.secondary,
            ),
            title: const Text(
              'CSV Document (.csv)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Universal comma-separated plain text file'),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
            onTap: _isExporting
                ? null
                : () {
                    Navigator.of(sheetContext).pop();
                    _executeExport(context, ref, fields, db, isCsv: true);
                  },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbs = ref.watch(databaseListControllerProvider).valueOrNull;
    final currentDb =
        dbs?.firstWhere(
          (d) => d.id == widget.database.id,
          orElse: () => widget.database,
        ) ??
        widget.database;

    final fieldsState = ref.watch(
      fieldListControllerProvider(widget.database.id),
    );
    final recordsState = ref.watch(
      recordListControllerProvider(widget.database.id),
    );
    final isFetchingMore = ref.watch(
      isFetchingMoreProvider(widget.database.id),
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final query = _searchController.text.trim().toLowerCase();

    String? subtitleText;
    if (_isSearching && recordsState.hasValue) {
      final count = recordsState.requireValue
          .where((r) => _recordMatchesQuery(r, query))
          .length;
      subtitleText = '$count found';
    } else if (fieldsState.valueOrNull?.isNotEmpty == true &&
        recordsState.hasValue) {
      final count = recordsState.requireValue.length;
      subtitleText = '$count ${count == 1 ? 'record' : 'records'}';
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
          title: currentDb.name,
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
                            hintText: 'Search records...',
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
              if (recordsState.valueOrNull?.isNotEmpty == true) ...[
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  tooltip: 'Search records',
                  onPressed: _startSearch,
                ),
                PopupMenuButton<RecordSortOrder>(
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'Sort records',
                  initialValue: _sortOrder,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusCard,
                    side: AppBorders.subtle(colorScheme),
                  ),
                  onSelected: (sort) {
                    setState(() {
                      _sortOrder = sort;
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: RecordSortOrder.newestFirst,
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 20),
                          const SizedBox(width: AppSpacing.md),
                          const Expanded(child: Text('Newest first')),
                          if (_sortOrder == RecordSortOrder.newestFirst)
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: RecordSortOrder.oldestFirst,
                      child: Row(
                        children: [
                          const Icon(Icons.history_rounded, size: 20),
                          const SizedBox(width: AppSpacing.md),
                          const Expanded(child: Text('Oldest first')),
                          if (_sortOrder == RecordSortOrder.oldestFirst)
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: RecordSortOrder.primaryAscending,
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_downward_rounded, size: 20),
                          const SizedBox(width: AppSpacing.md),
                          const Expanded(child: Text('Title (A–Z)')),
                          if (_sortOrder == RecordSortOrder.primaryAscending)
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: RecordSortOrder.primaryDescending,
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_upward_rounded, size: 20),
                          const SizedBox(width: AppSpacing.md),
                          const Expanded(child: Text('Title (Z–A)')),
                          if (_sortOrder == RecordSortOrder.primaryDescending)
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              IconButton(
                icon: const Icon(Icons.schema_outlined),
                tooltip: 'Manage Fields',
                onPressed: () => _openManageFields(context, currentDb),
              ),
              fieldsState.maybeWhen(
                data: (fields) => IconButton(
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_download_outlined),
                  tooltip: 'Export Data',
                  onPressed: _isExporting
                      ? null
                      : () => _showExportSheet(context, ref, fields, currentDb),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ],
        ),
        body: AnimatedSwitcher(
          duration: AppDurations.normal,
          child: fieldsState.when(
            data: (fields) {
              if (fields.isEmpty) {
                return VaultEmptyState(
                  scrollKey: const ValueKey('no_fields'),
                  icon: Icons.schema_rounded,
                  title: 'No Fields Defined',
                  message:
                      'Please define at least one field before adding records.',
                  actionLabel: 'Manage Fields',
                  actionIcon: Icons.schema_rounded,
                  onAction: () => _openManageFields(context, currentDb),
                );
              }

              return AnimatedSwitcher(
                duration: AppDurations.normal,
                child: recordsState.when(
                  data: (records) {
                    if (records.isEmpty) {
                      return VaultEmptyState(
                        scrollKey: const ValueKey('no_records'),
                        icon: Icons.description_rounded,
                        title: 'No Records',
                        message:
                            'No records found. Tap + or Add Record below to create your first record.',
                        actionLabel: 'Add Record',
                        actionIcon: Icons.add_rounded,
                        onAction: () => _showCreateScreen(context, fields),
                        secondaryActionLabel: 'Manage Fields',
                        secondaryActionIcon: Icons.schema_outlined,
                        onSecondaryAction: () =>
                            _openManageFields(context, currentDb),
                      );
                    }

                    final displayRecords = _filterAndSortRecords(
                      records,
                      fields,
                    );

                    if (displayRecords.isEmpty) {
                      return VaultEmptyState(
                        scrollKey: const ValueKey('no_record_search_results'),
                        icon: Icons.search_off_rounded,
                        title: 'No Records Found',
                        message:
                            'No records match "$query".\nTry searching for different terms or clear the filter.',
                        actionLabel: 'Clear Search',
                        actionIcon: Icons.clear_rounded,
                        onAction: () => _searchController.clear(),
                      );
                    }

                    return RefreshIndicator(
                      key: const ValueKey('data'),
                      onRefresh: () async {
                        ref.invalidate(
                          recordListControllerProvider(widget.database.id),
                        );
                      },
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final isWide = width >= 600;
                          final isLarge = width >= 900;

                          final horizontalPadding = isWide
                              ? (isLarge ? AppSpacing.xxl : AppSpacing.xl)
                              : AppSpacing.lg;

                          String sortLabel;
                          switch (_sortOrder) {
                            case RecordSortOrder.newestFirst:
                              sortLabel = 'Newest';
                              break;
                            case RecordSortOrder.oldestFirst:
                              sortLabel = 'Oldest';
                              break;
                            case RecordSortOrder.primaryAscending:
                              sortLabel = 'A–Z';
                              break;
                            case RecordSortOrder.primaryDescending:
                              sortLabel = 'Z–A';
                              break;
                          }

                          final sectionTitle = _isSearching
                              ? 'Search Results'
                              : 'All Records';
                          final trailingText = _isSearching
                              ? 'Filtered'
                              : 'Sort: $sortLabel';

                          final showPaginationItem =
                              !_isSearching &&
                              (isFetchingMore ||
                                  (recordsState.hasError && !isFetchingMore));

                          Widget buildPaginationFooter() {
                            if (recordsState.hasError && !isFetchingMore) {
                              return SafeArea(
                                top: false,
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Center(
                                    child: FilledButton.tonalIcon(
                                      onPressed: () => ref
                                          .read(
                                            recordListControllerProvider(
                                              widget.database.id,
                                            ).notifier,
                                          )
                                          .loadMore(),
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Failed to load more. Retry',
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return SafeArea(
                              top: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xl,
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          final textScaler = MediaQuery.textScalerOf(context);
                          final textScale = textScaler.scale(1.0);
                          final cardHeight =
                              (136.0 +
                                      (textScale > 1.0
                                          ? (textScale - 1.0) * 100.0
                                          : 0.0))
                                  .ceilToDouble();

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
                                  title: sectionTitle,
                                  padding: EdgeInsets.zero,
                                  trailing: Text(
                                    trailingText,
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
                                        key: PageStorageKey(
                                          'record_list_grid_${widget.database.id}',
                                        ),
                                        controller: _scrollController,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        keyboardDismissBehavior:
                                            ScrollViewKeyboardDismissBehavior
                                                .onDrag,
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
                                        itemCount:
                                            displayRecords.length +
                                            (showPaginationItem ? 1 : 0),
                                        itemBuilder: (context, index) {
                                          if (index == displayRecords.length) {
                                            return buildPaginationFooter();
                                          }
                                          final record = displayRecords[index];
                                          return RecordCard(
                                            key: ValueKey(record.id),
                                            record: record,
                                            fields: fields,
                                            onTap: () => _showEditScreen(
                                              context,
                                              record,
                                              fields,
                                            ),
                                            onDelete: () => _showDeleteDialog(
                                              context,
                                              ref,
                                              record,
                                              fields: fields,
                                            ),
                                          );
                                        },
                                      )
                                    : ListView.separated(
                                        key: PageStorageKey(
                                          'record_list_list_${widget.database.id}',
                                        ),
                                        controller: _scrollController,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        keyboardDismissBehavior:
                                            ScrollViewKeyboardDismissBehavior
                                                .onDrag,
                                        padding: EdgeInsets.fromLTRB(
                                          horizontalPadding,
                                          AppSpacing.xs,
                                          horizontalPadding,
                                          AppSpacing.xxxl * 2,
                                        ),
                                        itemCount:
                                            displayRecords.length +
                                            (showPaginationItem ? 1 : 0),
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(
                                              height: AppSpacing.md,
                                            ),
                                        itemBuilder: (context, index) {
                                          if (index == displayRecords.length) {
                                            return buildPaginationFooter();
                                          }
                                          final record = displayRecords[index];
                                          return RecordCard(
                                            key: ValueKey(record.id),
                                            record: record,
                                            fields: fields,
                                            onTap: () => _showEditScreen(
                                              context,
                                              record,
                                              fields,
                                            ),
                                            onDelete: () => _showDeleteDialog(
                                              context,
                                              ref,
                                              record,
                                              fields: fields,
                                            ),
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
                  loading: () => Center(
                    key: const ValueKey('loading_records'),
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  error: (err, st) => VaultErrorView(
                    scrollKey: const ValueKey('error'),
                    title: 'Failed to load',
                    message: err.toString(),
                    onRetry: () {
                      ref.invalidate(
                        fieldListControllerProvider(widget.database.id),
                      );
                      ref.invalidate(
                        recordListControllerProvider(widget.database.id),
                      );
                    },
                  ),
                  skipError: true,
                ),
              );
            },
            loading: () => Center(
              key: const ValueKey('loading_fields'),
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colorScheme.primary,
                ),
              ),
            ),
            error: (err, st) => VaultErrorView(
              scrollKey: const ValueKey('error'),
              title: 'Failed to load',
              message: err.toString(),
              onRetry: () {
                ref.invalidate(fieldListControllerProvider(widget.database.id));
                ref.invalidate(
                  recordListControllerProvider(widget.database.id),
                );
              },
            ),
          ),
        ),
        floatingActionButton: fieldsState.maybeWhen(
          data: (fields) => (fields.isNotEmpty && !_isSearching)
              ? FloatingActionButton.extended(
                  tooltip: 'Create new record',
                  elevation: 2,
                  focusElevation: 4,
                  hoverElevation: 4,
                  highlightElevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusCard,
                  ),
                  onPressed: () => _showCreateScreen(context, fields),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New Record'),
                )
              : null,
          orElse: () => null,
        ),
      ),
    );
  }
}
