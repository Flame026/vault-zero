import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/providers.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/importers/csv_data_source.dart';
import '../common/widgets/vault_app_bar.dart';
import '../common/widgets/vault_card.dart';
import '../common/widgets/vault_error_view.dart';
import '../common/widgets/vault_icon_badge.dart';
import '../common/widgets/vault_snackbar.dart';
import '../common/error_sanitizer.dart';
import '../databases/controllers/database_list_controller.dart';

class CsvPreviewScreen extends ConsumerStatefulWidget {
  final String filePath;

  const CsvPreviewScreen({super.key, required this.filePath});

  @override
  ConsumerState<CsvPreviewScreen> createState() => _CsvPreviewScreenState();
}

class _CsvPreviewScreenState extends ConsumerState<CsvPreviewScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isImporting = false;
  String? _error;
  int? _fileSizeBytes;
  List<String> _headers = [];
  List<List<dynamic>> _sampleRows = [];
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final defaultName = p.basenameWithoutExtension(widget.filePath);
    _nameController = TextEditingController(text: defaultName);
    _loadPreview();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _loadPreview() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final file = File(widget.filePath);
      if (await file.exists()) {
        _fileSizeBytes = await file.length();
      }

      final source = CsvDataSource(file);
      final rawHeaders = await source.getHeaders();
      if (rawHeaders.isEmpty) {
        throw const FormatException('CSV file has no columns or is empty.');
      }

      // Load max 5 rows for sample
      final rows = await source.getRows().take(5).toList();

      if (mounted) {
        setState(() {
          _headers = rawHeaders;
          _sampleRows = rows;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = sanitizeErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleImport() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    final dbName = _nameController.text.trim();
    if (dbName.isEmpty) {
      VaultSnackbar.showError(context, 'Database name cannot be empty');
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final importService = await ref.read(importServiceProvider.future);
      final source = CsvDataSource(File(widget.filePath));

      await importService.importDatabase(dbName, source);

      // Refresh the root database list
      ref.invalidate(schemaRepositoryProvider);
      ref.invalidate(recordRepositoryProvider);
      ref.invalidate(databaseListControllerProvider);

      if (mounted) {
        VaultSnackbar.showSuccess(context, 'CSV imported successfully!');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) {
            final colorScheme = Theme.of(dialogContext).colorScheme;
            return AlertDialog(
              backgroundColor: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusDialog,
              ),
              icon: Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: colorScheme.error,
              ),
              title: const Text('Import Failed'),
              content: Text(
                sanitizeErrorMessage(e),
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !_isImporting,
      child: Scaffold(
        appBar: const VaultAppBar(
          title: 'Preview CSV Import',
          subtitle: 'Review Columns & Sample Rows',
        ),
        body: Stack(
          children: [
            if (_isLoading)
              const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              )
            else if (_error != null)
              VaultErrorView(
                title: 'Could not load CSV',
                message: _error!,
                onRetry: _loadPreview,
              )
            else
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          children: [
                            // Source File Card
                            VaultCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Row(
                                children: [
                                  VaultIconBadge(
                                    icon: Icons.table_view_rounded,
                                    iconColor: colorScheme.primary,
                                    backgroundColor: colorScheme
                                        .primaryContainer
                                        .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: AppSpacing.lg),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SOURCE FILE',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                letterSpacing: 0.8,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: AppSpacing.xxs),
                                        Text(
                                          p.basename(widget.filePath),
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onSurface,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.sm,
                                                    vertical: AppSpacing.xxs,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .surfaceContainer,
                                                borderRadius:
                                                    AppRadius.radiusSm,
                                              ),
                                              child: Text(
                                                '${_headers.length} ${_headers.length == 1 ? 'column' : 'columns'}',
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.sm,
                                                    vertical: AppSpacing.xxs,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .surfaceContainer,
                                                borderRadius:
                                                    AppRadius.radiusSm,
                                              ),
                                              child: Text(
                                                '${_sampleRows.length} sample ${_sampleRows.length == 1 ? 'row' : 'rows'}',
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                            if (_fileSizeBytes != null) ...[
                                              const SizedBox(
                                                width: AppSpacing.sm,
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: AppSpacing.sm,
                                                      vertical: AppSpacing.xxs,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme
                                                      .surfaceContainer,
                                                  borderRadius:
                                                      AppRadius.radiusSm,
                                                ),
                                                child: Text(
                                                  _formatFileSize(
                                                    _fileSizeBytes!,
                                                  ),
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            // Target database name with validation
                            Form(
                              key: _formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Target Database Name',
                                  hintText: 'Enter database name',
                                  prefixIcon: Icon(
                                    Icons.storage_rounded,
                                    size: 20,
                                  ),
                                ),
                                validator: (value) {
                                  final trimmed = value?.trim() ?? '';
                                  if (trimmed.isEmpty) {
                                    return 'Database name cannot be empty';
                                  }
                                  if (trimmed.length > 60) {
                                    return 'Database name cannot exceed 60 characters';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            // Detected Headers
                            Text(
                              'Detected Headers (${_headers.length}):',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: _headers
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) => Chip(
                                      avatar: CircleAvatar(
                                        backgroundColor:
                                            colorScheme.primaryContainer,
                                        radius: 10,
                                        child: Text(
                                          '${e.key + 1}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                      label: Text(e.value),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppRadius.radiusSm,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            // Sample Data Table
                            Text(
                              'Sample Data (First ${_sampleRows.length} rows):',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (_sampleRows.isEmpty)
                              VaultCard(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        'This file contains headers but no record rows.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              VaultCard(
                                padding: EdgeInsets.zero,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      colorScheme.surfaceContainerHigh
                                          .withValues(alpha: 0.5),
                                    ),
                                    columns: _headers
                                        .map(
                                          (h) => DataColumn(
                                            label: Text(
                                              h,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    rows: _sampleRows.map((row) {
                                      return DataRow(
                                        cells: List.generate(_headers.length, (
                                          index,
                                        ) {
                                          final cellText = index < row.length
                                              ? row[index]?.toString() ?? ''
                                              : '';
                                          return DataCell(
                                            cellText.trim().isEmpty
                                                ? Text(
                                                    '(empty)',
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          color: colorScheme
                                                              .outline,
                                                        ),
                                                  )
                                                : Text(
                                                    cellText.length > 30
                                                        ? '${cellText.substring(0, 27)}...'
                                                        : cellText,
                                                  ),
                                          );
                                        }),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical:
                                MediaQuery.sizeOf(context).height <
                                    AppBreakpoints.shortHeight
                                ? AppSpacing.sm
                                : AppSpacing.lg,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isImporting ? null : _handleImport,
                              icon: _isImporting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.download_rounded,
                                      size: 20,
                                    ),
                              label: Text(
                                _isImporting
                                    ? 'Importing...'
                                    : 'Import Database',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isImporting)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusDialog,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxxl,
                        vertical: AppSpacing.xxl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Importing Database...',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Writing records safely to offline storage',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
