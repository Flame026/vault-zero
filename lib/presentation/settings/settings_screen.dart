import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../../core/theme/theme_preset.dart';
import '../../core/theme/theme_provider.dart';
import '../../domain/models/vault_backup.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Theme Color'),
          children: ThemePreset.values.map((preset) {
            return SimpleDialogOption(
              onPressed: () {
                ref.read(themeProvider.notifier).changePreset(preset);
                Navigator.of(context).pop();
              },
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: preset.seedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(preset.name),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _handleBackup() async {
    setState(() => _isLoading = true);
    try {
      final service = await ref.read(backupRestoreServiceProvider.future);
      final jsonContent = await service.exportVault();
      
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final filename = 'vault_backup_$dateStr.vzbackup';

      // We use XFile to share the content as a file
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
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error),
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

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text('APPEARANCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              ),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Theme Color'),
                subtitle: Text(themeState.preset.name),
                onTap: () => _showThemePicker(context, ref),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                value: themeState.mode == ThemeMode.dark,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).changeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text('DATA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              ),
              const ListTile(
                title: Text('Data Management', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Backup Vault'),
                subtitle: const Text('Export a copy of your V2 database'),
                onTap: _handleBackup,
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore Vault'),
                subtitle: const Text('Replace current data with a backup'),
                onTap: _handleRestore,
              ),
            ],
          ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
