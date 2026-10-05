import 'dart:io';

import 'package:sqflite/sqflite.dart';

class DatabaseStorageService {
  final Database _db;

  DatabaseStorageService(this._db);

  /// Performs WAL checkpoint and SQLite VACUUM to reclaim storage space
  /// from deleted pages and freelists, preventing database file bloat.
  Future<void> compactDatabase() async {
    try {
      await _db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (_) {}
    try {
      await _db.execute('VACUUM');
    } catch (_) {}
  }

  /// Returns storage metrics for the database file:
  /// - [mainSizeBytes]: size of the .db file on disk
  /// - [walSizeBytes]: size of the .db-wal file on disk (if present)
  /// - [freelistCount]: number of unused pages on SQLite's freelist
  Future<DatabaseStorageStats> getStorageStats() async {
    final dbPath = _db.path;
    var mainSizeBytes = 0;
    var walSizeBytes = 0;

    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      mainSizeBytes = await dbFile.length();
    }

    final walFile = File('$dbPath-wal');
    if (await walFile.exists()) {
      walSizeBytes = await walFile.length();
    }

    var freelistCount = 0;
    try {
      final result = await _db.rawQuery('PRAGMA freelist_count');
      if (result.isNotEmpty && result.first.values.isNotEmpty) {
        freelistCount = (result.first.values.first as num?)?.toInt() ?? 0;
      }
    } catch (_) {}

    return DatabaseStorageStats(
      mainSizeBytes: mainSizeBytes,
      walSizeBytes: walSizeBytes,
      freelistCount: freelistCount,
    );
  }
}

class DatabaseStorageStats {
  final int mainSizeBytes;
  final int walSizeBytes;
  final int freelistCount;

  const DatabaseStorageStats({
    required this.mainSizeBytes,
    required this.walSizeBytes,
    required this.freelistCount,
  });

  int get totalSizeBytes => mainSizeBytes + walSizeBytes;
}
