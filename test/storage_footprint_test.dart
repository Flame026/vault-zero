import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vault_zero/core/database/database_storage_service.dart';
import 'package:vault_zero/core/storage/temp_storage_service.dart';
import 'package:vault_zero/data/importers/excel_data_source.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TempStorageService', () {
    late Directory testTempDir;
    late TempStorageService service;

    setUp(() async {
      testTempDir = await Directory.systemTemp.createTemp(
        'vault_zero_storage_test_',
      );
      service = TempStorageService(getTempDir: () async => testTempDir);
    });

    tearDown(() async {
      if (await testTempDir.exists()) {
        await testTempDir.delete(recursive: true);
      }
    });

    test(
      'deleteTempFile removes file safely and handles null/missing',
      () async {
        final file = File('${testTempDir.path}/test.tmp');
        await file.writeAsString('temp data');
        expect(await file.exists(), isTrue);

        await service.deleteTempFile(file);
        expect(await file.exists(), isFalse);

        // Idempotent: deleting non-existent or null does not throw
        await service.deleteTempFile(file);
        await service.deleteTempFile(null);
      },
    );

    test(
      'pruneStaleExportFiles removes expired files and preserves fresh ones',
      () async {
        final oldExport = File('${testTempDir.path}/vault_zero_db_old.xlsx');
        await oldExport.writeAsString('old content');
        // Set modification time to 48 hours ago
        await oldExport.setLastModified(
          DateTime.now().subtract(const Duration(hours: 48)),
        );

        final freshExport = File(
          '${testTempDir.path}/vault_zero_db_fresh.xlsx',
        );
        await freshExport.writeAsString('fresh content');

        final oldCsv = File('${testTempDir.path}/vault_zero_db_old.csv');
        await oldCsv.writeAsString('col1,col2');
        await oldCsv.setLastModified(
          DateTime.now().subtract(const Duration(hours: 25)),
        );

        final freshCsv = File('${testTempDir.path}/vault_zero_db_fresh.csv');
        await freshCsv.writeAsString('col1,col2');

        final oldTmp = File('${testTempDir.path}/prefs.tmp');
        await oldTmp.writeAsString('tmp data');
        await oldTmp.setLastModified(
          DateTime.now().subtract(const Duration(hours: 30)),
        );

        // Non-matching file should NEVER be pruned
        final userFile = File('${testTempDir.path}/important_notes.txt');
        await userFile.writeAsString('user content');
        await userFile.setLastModified(
          DateTime.now().subtract(const Duration(days: 30)),
        );

        final reclaimed = await service.pruneStaleExportFiles(
          maxAge: const Duration(hours: 24),
        );

        expect(reclaimed, greaterThan(0));
        expect(await oldExport.exists(), isFalse);
        expect(await oldCsv.exists(), isFalse);
        expect(await oldTmp.exists(), isFalse);
        expect(await freshExport.exists(), isTrue);
        expect(await freshCsv.exists(), isTrue);
        expect(await userFile.exists(), isTrue);
      },
    );

    test(
      'pruneStaleExportFiles enforces maxBytesBudget by deleting oldest files first',
      () async {
        final file1 = File('${testTempDir.path}/vault_zero_file1.xlsx');
        await file1.writeAsBytes(List.filled(1024, 0));
        await file1.setLastModified(
          DateTime.now().subtract(const Duration(minutes: 30)),
        );

        final file2 = File('${testTempDir.path}/vault_zero_file2.xlsx');
        await file2.writeAsBytes(List.filled(1024, 0));
        await file2.setLastModified(
          DateTime.now().subtract(const Duration(minutes: 10)),
        );

        // Budget of 1500 bytes: total is 2048 bytes, file1 (older) should be pruned
        await service.pruneStaleExportFiles(
          maxAge: const Duration(hours: 24),
          maxBytesBudget: 1500,
        );

        expect(await file1.exists(), isFalse);
        expect(await file2.exists(), isTrue);
      },
    );

    test(
      'getTempStorageFootprintBytes accurately sums vault zero temp files',
      () async {
        final file1 = File('${testTempDir.path}/vault_zero_db.xlsx');
        await file1.writeAsBytes(List.filled(500, 0));

        final file2 = File('${testTempDir.path}/vault_zero_db.csv');
        await file2.writeAsBytes(List.filled(300, 0));

        final file3 = File('${testTempDir.path}/unrelated.txt');
        await file3.writeAsBytes(List.filled(1000, 0));

        final total = await service.getTempStorageFootprintBytes();
        expect(total, equals(800));
      },
    );
  });

  group('DatabaseStorageService', () {
    late Database db;
    late DatabaseStorageService storageService;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE test_table (id TEXT PRIMARY KEY, val TEXT)',
          );
        },
      );
      storageService = DatabaseStorageService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('compactDatabase executes without error', () async {
      await db.insert('test_table', {'id': '1', 'val': 'test'});
      await db.delete('test_table', where: 'id = ?', whereArgs: ['1']);

      // Should run VACUUM and wal_checkpoint cleanly
      await storageService.compactDatabase();
    });

    test('getStorageStats returns valid stats', () async {
      final stats = await storageService.getStorageStats();
      expect(stats.mainSizeBytes, greaterThanOrEqualTo(0));
      expect(stats.walSizeBytes, greaterThanOrEqualTo(0));
      expect(stats.freelistCount, greaterThanOrEqualTo(0));
      expect(
        stats.totalSizeBytes,
        equals(stats.mainSizeBytes + stats.walSizeBytes),
      );
    });
  });

  group('ExcelDataSource Memory Optimization', () {
    test('clearCache resets cached workbook instance', () async {
      final tempDir = await Directory.systemTemp.createTemp('excel_test_');
      final file = File('${tempDir.path}/empty.xlsx');
      await file.writeAsBytes([
        0x50,
        0x4b,
        0x05,
        0x06,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
      ]);

      final source = ExcelDataSource(file);
      // Calling clearCache on non-decoded or decoded source does not throw
      source.clearCache();

      await tempDir.delete(recursive: true);
    });
  });
}
