import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/providers.dart';
import '../../data/importers/excel_data_source.dart';

class ExcelPreviewScreen extends ConsumerStatefulWidget {
  final String filePath;

  const ExcelPreviewScreen({super.key, required this.filePath});

  @override
  ConsumerState<ExcelPreviewScreen> createState() => _ExcelPreviewScreenState();
}

class _ExcelPreviewScreenState extends ConsumerState<ExcelPreviewScreen> {
  bool _isLoading = true;
  bool _isImporting = false;
  String? _error;
  List<String> _sheetNames = [];
  String? _selectedSheet;
  List<String> _headers = [];
  List<List<dynamic>> _sampleRows = [];
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final defaultName = p.basenameWithoutExtension(widget.filePath);
    _nameController = TextEditingController(text: defaultName);
    _initializeWorkbook();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initializeWorkbook() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final source = ExcelDataSource(File(widget.filePath));
      final sheets = await source.getSheetNames();

      if (sheets.isEmpty) {
        throw const FormatException('Workbook contains no sheets.');
      }

      final initialSheet = sheets.first;
      _sheetNames = sheets;
      _selectedSheet = initialSheet;

      final baseName = p.basenameWithoutExtension(widget.filePath);
      if (sheets.length > 1) {
        _nameController.text = '$baseName - $initialSheet';
      } else {
        _nameController.text = baseName;
      }

      await _loadSheetPreview(initialSheet);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to read Excel workbook: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSheetPreview(String sheetName) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final source = ExcelDataSource(File(widget.filePath), sheetName: sheetName);
      final headers = await source.getHeaders();
      final rows = await source.getRows().take(5).toList();

      if (mounted) {
        setState(() {
          _headers = headers;
          _sampleRows = rows;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to read worksheet preview: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onSheetChanged(String? newSheet) {
    if (newSheet == null || newSheet == _selectedSheet) return;

    final baseName = p.basenameWithoutExtension(widget.filePath);
    setState(() {
      _selectedSheet = newSheet;
      _nameController.text = '$baseName - $newSheet';
    });

    _loadSheetPreview(newSheet);
  }

  Future<void> _handleImport() async {
    final dbName = _nameController.text.trim();
    if (dbName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database name cannot be empty.')),
      );
      return;
    }

    if (_selectedSheet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a worksheet to import.')),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final importService = await ref.read(importServiceProvider.future);
      final source = ExcelDataSource(File(widget.filePath), sheetName: _selectedSheet);

      await importService.importDatabase(dbName, source);

      // Refresh the root database list
      ref.invalidate(schemaRepositoryProvider);
      ref.invalidate(recordRepositoryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel imported successfully!')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Failed'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Excel Import'),
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(color: colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    if (_sheetNames.length > 1) ...[
                      const SizedBox(height: 16),
                      DropdownButton<String>(
                        value: _selectedSheet,
                        items: _sheetNames.map((sheet) {
                          return DropdownMenuItem(
                            value: sheet,
                            child: Text(sheet),
                          );
                        }).toList(),
                        onChanged: _onSheetChanged,
                      ),
                    ],
                  ],
                ),
              ),
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
                        padding: const EdgeInsets.all(24.0),
                        children: [
                          Card(
                            elevation: 0,
                            color: colorScheme.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.description_rounded,
                                      color: colorScheme.onPrimaryContainer,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Source File',
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          p.basename(widget.filePath),
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_sheetNames.length > 1) ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedSheet,
                              decoration: const InputDecoration(
                                labelText: 'Select Worksheet',
                                border: OutlineInputBorder(),
                              ),
                              items: _sheetNames.map((sheet) {
                                return DropdownMenuItem(
                                  value: sheet,
                                  child: Text(sheet),
                                );
                              }).toList(),
                              onChanged: _onSheetChanged,
                            ),
                          ] else if (_sheetNames.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Worksheet: ${_sheetNames.first}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Target Database Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Detected Headers (${_headers.length}):',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _headers
                                .map((h) => Chip(
                                      label: Text(h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Sample Data (First ${_sampleRows.length} rows):',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 0,
                            color: colorScheme.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: _headers
                                    .map((h) => DataColumn(
                                          label: Text(
                                            h,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ))
                                    .toList(),
                                rows: _sampleRows.map((row) {
                                  return DataRow(
                                    cells: List.generate(_headers.length, (index) {
                                      final cellText = index < row.length ? row[index].toString() : '';
                                      return DataCell(Text(
                                        cellText.length > 30 ? '${cellText.substring(0, 27)}...' : cellText,
                                      ));
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
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isImporting ? null : _handleImport,
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Import Database'),
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
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Importing Database...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
