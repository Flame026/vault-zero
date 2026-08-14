import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../../core/theme/theme_provider.dart';
import '../../domain/models/vault_backup.dart';
import '../import/csv_preview_screen.dart';
import '../import/excel_preview_screen.dart';
import 'widgets/theme_picker_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;
  int _selectedCategory = 0; // 0: Appearance, 1: Data Management

  Future<void> _handleBackup() async {
    setState(() => _isLoading = true);
    try {
      final service = await ref.read(backupRestoreServiceProvider.future);
      final jsonContent = await service.exportVault();

      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final filename = 'vault_backup_$dateStr.vzbackup';

      final file = XFile.fromData(
        utf8.encode(jsonContent),
        name: filename,
        mimeType: 'application/json',
      );
      await SharePlus.instance.share(ShareParams(files: [file], text: 'Vault Zero Backup'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.any,
      );
    } catch (e) {
      // Ignored
    }

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      VaultBackup? backup;
      try {
        backup = VaultBackup.fromJson(jsonDecode(content) as Map<String, dynamic>);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid backup file: $e')),
        );
        return;
      }

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Vault?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Backup Created On: ${DateFormat.yMMMd().format(backup!.exportDate)}'),
              Text('Databases: ${backup.databases.length}'),
              Text('Records: ${backup.records.length}'),
              const SizedBox(height: 16),
              Text(
                'WARNING: Restoring will permanently replace your current Vault. This action cannot be undone.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onError,
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        setState(() => _isLoading = true);
        try {
          final service = await ref.read(backupRestoreServiceProvider.future);
          await service.restoreVault(content);

          // Refresh UI
          ref.invalidate(schemaRepositoryProvider);
          ref.invalidate(recordRepositoryProvider);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vault restored successfully.')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Restore failed: $e')),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _handleImportCsv() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
    } catch (e) {
      // Ignored
    }
    if (result != null && result.files.single.path != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CsvPreviewScreen(
            filePath: result!.files.single.path!,
          ),
        ),
      );
    }
  }

  Future<void> _handleImportExcel() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
    } catch (e) {
      // Ignored
    }
    if (result != null && result.files.single.path != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ExcelPreviewScreen(
            filePath: result!.files.single.path!,
          ),
        ),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 20,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildAppearanceGroup() {
    final themeState = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: _buildIconContainer(Icons.palette_rounded),
            title: const Text('Theme Color', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(themeState.preset.label),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: themeState.preset.seedColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
              ],
            ),
            onTap: () => ThemePickerSheet.show(context),
          ),
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          SwitchListTile(
            secondary: _buildIconContainer(Icons.dark_mode_rounded),
            title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Toggle dark/light appearance'),
            value: themeState.mode == ThemeMode.dark,
            onChanged: (value) {
              ref.read(themeProvider.notifier).changeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataGroup() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: _buildIconContainer(Icons.backup_rounded),
            title: const Text('Backup Vault', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Export a copy of your vault data'),
            trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
            onTap: _handleBackup,
          ),
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          ListTile(
            leading: _buildIconContainer(Icons.restore_rounded),
            title: const Text('Restore Vault', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Replace current data with a backup'),
            trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
            onTap: _handleRestore,
          ),
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          ListTile(
            leading: _buildIconContainer(Icons.table_view_rounded),
            title: const Text('Import CSV', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Import a CSV file into a new database'),
            trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
            onTap: _handleImportCsv,
          ),
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          ListTile(
            leading: _buildIconContainer(Icons.description_rounded),
            title: const Text('Import Excel', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Import an Excel (.xlsx) file into a new database'),
            trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
            onTap: _handleImportExcel,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              // Breakpoint >= 900: Two-pane master-detail layout
              if (width >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left navigation master pane (~320px)
                    SizedBox(
                      width: 320,
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          _buildSectionHeader('Categories'),
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
                            child: Column(
                              children: [
                                ListTile(
                                  selected: _selectedCategory == 0,
                                  selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
                                  leading: _buildIconContainer(Icons.palette_rounded),
                                  title: const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: const Text('Theme & Dark Mode'),
                                  trailing: Icon(
                                    Icons.chevron_right_rounded,
                                    color: _selectedCategory == 0
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  onTap: () => setState(() => _selectedCategory = 0),
                                ),
                                Divider(
                                  height: 1,
                                  indent: 56,
                                  endIndent: 16,
                                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                ),
                                ListTile(
                                  selected: _selectedCategory == 1,
                                  selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
                                  leading: _buildIconContainer(Icons.storage_rounded),
                                  title: const Text('Data Management', style: TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: const Text('Backup, Restore & Import'),
                                  trailing: Icon(
                                    Icons.chevron_right_rounded,
                                    color: _selectedCategory == 1
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  onTap: () => setState(() => _selectedCategory = 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    // Right content pane
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          if (_selectedCategory == 0) ...[
                            _buildSectionHeader('Appearance'),
                            _buildAppearanceGroup(),
                          ] else ...[
                            _buildSectionHeader('Data Management'),
                            _buildDataGroup(),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Breakpoint 720-899: Centered constrained single-column layout
              if (width >= 720) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildSectionHeader('Appearance'),
                        _buildAppearanceGroup(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Data Management'),
                        _buildDataGroup(),
                      ],
                    ),
                  ),
                );
              }

              // Breakpoint < 720: Single-column grouped settings (phone)
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  _buildSectionHeader('Appearance'),
                  _buildAppearanceGroup(),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Data Management'),
                  _buildDataGroup(),
                ],
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
