import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class TempStorageService {
  final Future<Directory> Function() _getTempDir;

  TempStorageService({Future<Directory> Function()? getTempDir})
    : _getTempDir = getTempDir ?? getTemporaryDirectory;

  /// Deletes a specific temporary file safely if it exists.
  Future<void> deleteTempFile(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Prunes stale export and cache files older than [maxAge]
  /// or when total temp storage exceeds [maxBytesBudget].
  ///
  /// Strictly targets only Vault Zero generated temporary files:
  /// - `vault_zero_*.xlsx`
  /// - `vault_zero_*.csv`
  /// - `*.tmp`
  /// Never touches databases, preferences, or user documents.
  Future<int> pruneStaleExportFiles({
    Duration maxAge = const Duration(hours: 24),
    int maxBytesBudget = 50 * 1024 * 1024, // 50 MB
  }) async {
    int bytesReclaimed = 0;
    try {
      final tempDir = await _getTempDir();
      if (!await tempDir.exists()) return 0;

      final now = DateTime.now();
      final entities = await tempDir.list().toList();

      final exportFiles = <File>[];
      for (final entity in entities) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;

        final isVaultZeroExport =
            name.startsWith('vault_zero_') &&
            (name.endsWith('.xlsx') || name.endsWith('.csv'));
        final isTempFile = name.endsWith('.tmp');

        if (isVaultZeroExport || isTempFile) {
          exportFiles.add(entity);
        }
      }

      // Sort oldest first
      final fileStats = <File, FileStat>{};
      for (final file in exportFiles) {
        try {
          fileStats[file] = await file.stat();
        } catch (_) {}
      }

      exportFiles.sort((a, b) {
        final aTime =
            fileStats[a]?.modified ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            fileStats[b]?.modified ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });

      int currentTotalBytes = 0;
      for (final file in exportFiles) {
        currentTotalBytes += fileStats[file]?.size ?? 0;
      }

      for (final file in exportFiles) {
        final stat = fileStats[file];
        if (stat == null) continue;

        final isExpired = now.difference(stat.modified) > maxAge;
        final isOverBudget = currentTotalBytes > maxBytesBudget;

        if (isExpired || isOverBudget) {
          try {
            final size = stat.size;
            await file.delete();
            bytesReclaimed += size;
            currentTotalBytes -= size;
          } catch (_) {}
        }
      }
    } catch (_) {}

    return bytesReclaimed;
  }

  /// Calculates total size of Vault Zero temporary export/cache files in bytes.
  Future<int> getTempStorageFootprintBytes() async {
    int totalBytes = 0;
    try {
      final tempDir = await _getTempDir();
      if (!await tempDir.exists()) return 0;

      await for (final entity in tempDir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        final isVaultZeroExport =
            name.startsWith('vault_zero_') &&
            (name.endsWith('.xlsx') || name.endsWith('.csv'));
        final isTempFile = name.endsWith('.tmp');

        if (isVaultZeroExport || isTempFile) {
          try {
            totalBytes += await entity.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return totalBytes;
  }
}

final tempStorageServiceProvider = Provider<TempStorageService>((ref) {
  return TempStorageService();
});
