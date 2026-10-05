import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../domain/models/vault_backup.dart';
import '../common/widgets/vault_app_bar.dart';
import '../common/widgets/vault_card.dart';
import '../common/widgets/vault_icon_badge.dart';
import '../common/widgets/vault_section_header.dart';
import '../common/widgets/vault_snackbar.dart';
import '../common/error_sanitizer.dart';
import '../databases/controllers/database_list_controller.dart';
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
    if (_isLoading) return;
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
      await SharePlus.instance.share(
        ShareParams(files: [file], text: 'Vault Zero Backup'),
      );
    } catch (e) {
      if (mounted) {
        VaultSnackbar.showError(
          context,
          'Backup failed: ${sanitizeErrorMessage(e)}',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    if (_isLoading) return;
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(type: FileType.any);
    } catch (_) {
      // Ignored
    }

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final String content;
      try {
        content = await file.readAsString();
      } catch (e) {
        if (!mounted) return;
        VaultSnackbar.showError(
          context,
          'Could not read backup file: ${sanitizeErrorMessage(e)}',
        );
        return;
      }

      VaultBackup? backup;
      try {
        backup = VaultBackup.fromJson(
          jsonDecode(content) as Map<String, dynamic>,
        );
      } catch (e) {
        if (!mounted) return;
        VaultSnackbar.showError(
          context,
          'Invalid backup file: ${sanitizeErrorMessage(e)}',
        );
        return;
      }

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          return AlertDialog(
            backgroundColor: colorScheme.surfaceContainerLow,
            scrollable: true,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusDialog),
            icon: Icon(
              Icons.warning_amber_rounded,
              size: 32,
              color: colorScheme.error,
            ),
            title: const Text('Restore Vault?'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstraints.maxDialogWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: AppRadius.radiusMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Backup Date: ${DateFormat.yMMMd().format(backup!.exportDate)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.storage_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                '${backup.databases.length} Databases, ${backup.records.length} Records',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.5),
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Restoring will permanently replace your current Vault. This action cannot be undone.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  foregroundColor: colorScheme.onError,
                  backgroundColor: colorScheme.error,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Restore Vault'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        if (!mounted) return;
        setState(() => _isLoading = true);
        try {
          final service = await ref.read(backupRestoreServiceProvider.future);
          await service.restoreVault(content);

          // Refresh UI
          ref.invalidate(schemaRepositoryProvider);
          ref.invalidate(recordRepositoryProvider);
          ref.invalidate(databaseListControllerProvider);

          if (mounted) {
            VaultSnackbar.showSuccess(context, 'Vault restored successfully.');
          }
        } catch (e) {
          if (mounted) {
            VaultSnackbar.showError(
              context,
              'Restore failed: ${sanitizeErrorMessage(e)}',
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _handleImportCsv() async {
    if (_isLoading) return;
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
    }
  }

  Future<void> _handleImportExcel() async {
    if (_isLoading) return;
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
    }
  }

  Widget _buildSectionHeader(String title) {
    return VaultSectionHeader(title: title);
  }

  Widget _buildIconContainer(IconData icon) {
    return VaultIconBadge(icon: icon);
  }

  Widget _buildAppearanceGroup() {
    final themeState = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return VaultCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            leading: _buildIconContainer(Icons.palette_rounded),
            title: const Text(
              'Theme Color',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${themeState.preset.label} — ${themeState.preset.description}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: themeState.preset.seedColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            onTap: () => ThemePickerSheet.show(context),
          ),
          Divider(
            height: 1,
            indent: 64,
            endIndent: AppSpacing.lg,
            color: colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            leading: _buildIconContainer(
              themeState.mode == ThemeMode.dark
                  ? Icons.dark_mode_rounded
                  : (themeState.mode == ThemeMode.light
                        ? Icons.light_mode_rounded
                        : Icons.brightness_auto_rounded),
            ),
            title: const Text(
              'Theme Mode',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(switch (themeState.mode) {
              ThemeMode.system => 'System (Follows device setting)',
              ThemeMode.light => 'Light appearance',
              ThemeMode.dark => 'Dark appearance',
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_rounded),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('System'),
                    ),
                    tooltip: 'Match device system appearance',
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_rounded),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Light'),
                    ),
                    tooltip: 'Always use light theme',
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Dark'),
                    ),
                    tooltip: 'Always use dark theme',
                  ),
                ],
                selected: {themeState.mode},
                onSelectionChanged: (selected) {
                  ref.read(themeProvider.notifier).changeMode(selected.first);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataBackupGroup() {
    final colorScheme = Theme.of(context).colorScheme;

    return VaultCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            leading: _buildIconContainer(Icons.backup_rounded),
            title: const Text(
              'Backup Vault',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Export a copy of your vault data'),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: _handleBackup,
          ),
          Divider(
            height: 1,
            indent: 64,
            endIndent: AppSpacing.lg,
            color: colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            leading: _buildIconContainer(Icons.restore_rounded),
            title: const Text(
              'Restore Vault',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Replace current data with a backup'),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: _handleRestore,
          ),
        ],
      ),
    );
  }

  Widget _buildImportDataGroup() {
    final colorScheme = Theme.of(context).colorScheme;

    return VaultCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            leading: _buildIconContainer(Icons.table_view_rounded),
            title: const Text(
              'Import CSV',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Import a CSV file into a new database'),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: _handleImportCsv,
          ),
          Divider(
            height: 1,
            indent: 64,
            endIndent: AppSpacing.lg,
            color: colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            leading: _buildIconContainer(Icons.description_rounded),
            title: const Text(
              'Import Excel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Import an Excel (.xlsx) file into a new database',
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: _handleImportExcel,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutFooter(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_outlined,
                size: 24,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Vault Zero',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Version 1.0.0 • Offline & Private',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                '100% offline local SQLite storage. Zero telemetry, zero cloud services. Your data never leaves your device.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        appBar: const VaultAppBar(
          title: 'Settings',
          subtitle: 'Appearance & Data Management',
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
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          children: [
                            _buildSectionHeader('Categories'),
                            VaultCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  ListTile(
                                    selected: _selectedCategory == 0,
                                    selectedTileColor: colorScheme
                                        .primaryContainer
                                        .withValues(alpha: 0.35),
                                    leading: _buildIconContainer(
                                      Icons.palette_rounded,
                                    ),
                                    title: const Text(
                                      'Appearance',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'Theme & Appearance Mode',
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right_rounded,
                                      color: _selectedCategory == 0
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    onTap: () =>
                                        setState(() => _selectedCategory = 0),
                                  ),
                                  Divider(
                                    height: 1,
                                    indent: 64,
                                    endIndent: AppSpacing.lg,
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.25),
                                  ),
                                  ListTile(
                                    selected: _selectedCategory == 1,
                                    selectedTileColor: colorScheme
                                        .primaryContainer
                                        .withValues(alpha: 0.35),
                                    leading: _buildIconContainer(
                                      Icons.storage_rounded,
                                    ),
                                    title: const Text(
                                      'Data Management',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'Backup, Restore & Import',
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right_rounded,
                                      color: _selectedCategory == 1
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    onTap: () =>
                                        setState(() => _selectedCategory = 1),
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
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      // Right content pane
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          children: [
                            if (_selectedCategory == 0) ...[
                              _buildSectionHeader('Appearance'),
                              _buildAppearanceGroup(),
                            ] else ...[
                              _buildSectionHeader('Data Safety & Backup'),
                              _buildDataBackupGroup(),
                              const SizedBox(height: AppSpacing.xl),
                              _buildSectionHeader('Import Data'),
                              _buildImportDataGroup(),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            _buildAboutFooter(context),
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
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        children: [
                          _buildSectionHeader('Appearance'),
                          _buildAppearanceGroup(),
                          const SizedBox(height: AppSpacing.xl),
                          _buildSectionHeader('Data Safety & Backup'),
                          _buildDataBackupGroup(),
                          const SizedBox(height: AppSpacing.xl),
                          _buildSectionHeader('Import Data'),
                          _buildImportDataGroup(),
                          _buildAboutFooter(context),
                        ],
                      ),
                    ),
                  );
                }

                // Breakpoint < 720: Single-column grouped settings (phone)
                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  children: [
                    _buildSectionHeader('Appearance'),
                    _buildAppearanceGroup(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Data Safety & Backup'),
                    _buildDataBackupGroup(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Import Data'),
                    _buildImportDataGroup(),
                    _buildAboutFooter(context),
                  ],
                );
              },
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Card(
                      elevation: 6,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                              'Processing...',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
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
