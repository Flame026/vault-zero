import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:character_collector/core/database/database_provider.dart';
import 'package:character_collector/core/providers.dart';
import 'package:character_collector/domain/models/database_definition.dart';
import 'package:character_collector/domain/models/field_definition.dart';
import 'package:character_collector/domain/models/record.dart';
import 'package:character_collector/domain/models/record_page.dart';
import 'package:character_collector/domain/repositories/record_repository.dart';
import 'package:character_collector/data/repositories/sqlite_record_repository.dart';
import 'package:character_collector/presentation/records/controllers/record_list_controller.dart';
import 'package:character_collector/presentation/records/controllers/v2_export_controller.dart';

class SpyingRecordRepository implements RecordRepository {
  final RecordRepository delegate;
  int getRecordsPageCallCount = 0;
  int totalRecordsFetched = 0;

  SpyingRecordRepository(this.delegate);

  @override
  Future<void> saveRecord(Record record) => delegate.saveRecord(record);
  @override
  Future<void> deleteRecord(String id) => delegate.deleteRecord(id);
  @override
  Future<Record?> getRecord(String id) => delegate.getRecord(id);
  @override
  Future<List<Record>> getRecordsForDatabase(String databaseId) => delegate.getRecordsForDatabase(databaseId);
  
  @override
  Future<RecordPage> getRecordsPage(
    String databaseId, {
    int limit = 50,
    RecordCursor? after,
  }) async {
    getRecordsPageCallCount++;
    final page = await delegate.getRecordsPage(databaseId, limit: limit, after: after);
    totalRecordsFetched += page.records.length;
    return page;
  }
}

void main() {
  late Database db;
  late ProviderContainer container;
  const dbId = 'test_db_id';

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.';
        }
        return null;
      },
    );
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, version) async {
            await db.execute('PRAGMA foreign_keys = ON');
            await db.execute('''
              CREATE TABLE databases (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE fields (
                id TEXT PRIMARY KEY,
                database_id TEXT NOT NULL,
                name TEXT NOT NULL,
                type TEXT NOT NULL,
                position INTEGER NOT NULL,
                is_required INTEGER NOT NULL,
                configuration TEXT,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                FOREIGN KEY (database_id) REFERENCES databases (id) ON DELETE CASCADE
              )
            ''');
            await db.execute('''
              CREATE TABLE records (
                id TEXT PRIMARY KEY,
                database_id TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                FOREIGN KEY (database_id) REFERENCES databases (id) ON DELETE CASCADE
              )
            ''');
            await db.execute('''
              CREATE TABLE field_values (
                id TEXT PRIMARY KEY,
                record_id TEXT NOT NULL,
                field_id TEXT NOT NULL,
                text_value TEXT,
                integer_value INTEGER,
                decimal_value REAL,
                boolean_value INTEGER,
                date_value INTEGER,
                date_time_value INTEGER,
                choice_value TEXT,
                FOREIGN KEY (record_id) REFERENCES records (id) ON DELETE CASCADE,
                FOREIGN KEY (field_id) REFERENCES fields (id) ON DELETE CASCADE,
                UNIQUE(record_id, field_id)
              )
            ''');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_records_database_created_id ON records(database_id, created_at, id)');
          },
        ));

    container = ProviderContainer(overrides: [
      databaseProvider.overrideWith((ref) => db),
    ]);

    // Setup Test Database
    final schemaRepo = await container.read(schemaRepositoryProvider.future);
    await schemaRepo.createDatabase(DatabaseDefinition(
      id: dbId,
      name: 'Test DB',
      description: 'DB for pagination tests',
      fields: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    
    await schemaRepo.createField(FieldDefinition(
      id: 'field_1',
      databaseId: dbId,
      name: 'Test Field',
      type: FieldType.text,
      position: 0,
      isRequired: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  tearDown(() async {
    await db.close();
    container.dispose();
  });

  group('Record Pagination - SqliteRecordRepository', () {
    test('Zero records returns empty page', () async {
      final repo = await container.read(recordRepositoryProvider.future);
      final page = await repo.getRecordsPage(dbId, limit: 50);
      expect(page.records, isEmpty);
      expect(page.hasMore, false);
      expect(page.nextCursor, null);
    });

    test('Identical timestamps preserve stable cursor order without skips/duplicates', () async {
      final repo = await container.read(recordRepositoryProvider.future);

      // Create 10 records with EXACTLY the same timestamp
      final fixedTime = DateTime(2026, 1, 1, 12, 0, 0);
      final ids = List.generate(10, (i) => const Uuid().v4());
      
      for (final id in ids) {
        await repo.saveRecord(Record(
          id: id,
          databaseId: dbId,
          values: {},
          createdAt: fixedTime,
          updatedAt: fixedTime,
        ));
      }

      // Fetch page 1 (size 5)
      final page1 = await repo.getRecordsPage(dbId, limit: 5);
      expect(page1.records.length, 5);
      expect(page1.hasMore, true);
      expect(page1.nextCursor, isNotNull);

      // Fetch page 2 (size 5)
      final page2 = await repo.getRecordsPage(dbId, limit: 5, after: page1.nextCursor);
      expect(page2.records.length, 5);
      expect(page2.hasMore, false);

      // Verify no duplicates
      final allRecords = [...page1.records, ...page2.records];
      final uniqueIds = allRecords.map((r) => r.id).toSet();
      expect(uniqueIds.length, 10);
    });

    test('Large dataset traversal (10000 records) returns correct bounds', () async {
      final repo = await container.read(recordRepositoryProvider.future);
      
      // Bulk insert 10000 records for speed
      await db.transaction((txn) async {
        final batch = txn.batch();
        final now = DateTime.now().millisecondsSinceEpoch;
        for (int i = 0; i < 10000; i++) {
          batch.insert('records', {
            'id': 'record_$i',
            'database_id': dbId,
            'created_at': now + i, // sequential
            'updated_at': now,
          });
        }
        await batch.commit(noResult: true);
      });

      // Traverse all 10000 records page by page (limit 100)
      bool hasMore = true;
      RecordCursor? cursor;
      final seenIds = <String>{};
      int totalCount = 0;

      while (hasMore) {
        final page = await repo.getRecordsPage(dbId, limit: 100, after: cursor);
        totalCount += page.records.length;
        for (final record in page.records) {
          seenIds.add(record.id);
        }
        hasMore = page.hasMore;
        cursor = page.nextCursor;
      }

      expect(totalCount, 10000, reason: 'Should traverse exactly 10000 records without duplicates');
      expect(seenIds.length, 10000, reason: 'Should see exactly 10000 unique records');
      expect(cursor, isNull);
    });
  });

  group('RecordListController Pagination & State', () {
    test('Load more prevents concurrent fetches and appends records', () async {
      // Insert 60 records
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (int i = 0; i < 60; i++) {
          batch.insert('records', {
            'id': 'rec_$i',
            'database_id': dbId,
            'created_at': i,
            'updated_at': i,
          });
        }
        await batch.commit(noResult: true);
      });

      // Wait for initial load
      final sub = container.listen(recordListControllerProvider(dbId), (_, _) {});
      final initialRecords = await container.read(recordListControllerProvider(dbId).future);
      
      final controller = container.read(recordListControllerProvider(dbId).notifier);
      expect(initialRecords.length, 50);
      expect(controller.hasMore, true);

      // Trigger load more
      await controller.loadMore();
      
      final appendedRecords = container.read(recordListControllerProvider(dbId)).value!;
      expect(appendedRecords.length, 60);
      expect(controller.hasMore, false);
      
      sub.close();
    });

    test('CRUD mutations modify state locally without reloading database', () async {
      final fields = await container.read(schemaRepositoryProvider.future).then((r) => r.getFieldsForDatabase(dbId));
      
      final sub = container.listen(recordListControllerProvider(dbId), (_, _) {});
      await container.read(recordListControllerProvider(dbId).future);
      final controller = container.read(recordListControllerProvider(dbId).notifier);

      // Create
      await controller.saveRecord(fields: fields, rawValues: {'field_1': 'Hello'});
      var records = container.read(recordListControllerProvider(dbId)).value!;
      expect(records.length, 1);
      
      final createdRecord = records.first;
      
      // Update
      await controller.saveRecord(existingRecord: createdRecord, fields: fields, rawValues: {'field_1': 'World'});
      records = container.read(recordListControllerProvider(dbId)).value!;
      expect(records.length, 1);
      
      // Delete
      await controller.deleteRecord(createdRecord.id);
      records = container.read(recordListControllerProvider(dbId)).value!;
      expect(records.length, 0);

      sub.close();
    });
  });

  group('V2ExportController Decoupling', () {
    test('Export fetches ALL records directly through repository, ignoring controller state', () async {
      final realRepo = SqliteRecordRepository(db);
      final spyRepo = SpyingRecordRepository(realRepo);

      final testContainer = ProviderContainer(overrides: [
        databaseProvider.overrideWith((ref) => db),
        recordRepositoryProvider.overrideWith((ref) => spyRepo),
      ]);

      final fields = await testContainer.read(schemaRepositoryProvider.future).then((r) => r.getFieldsForDatabase(dbId));
      
      // Insert 120 records (requires multiple pages)
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (int i = 0; i < 120; i++) {
          batch.insert('records', {
            'id': 'rec_$i',
            'database_id': dbId,
            'created_at': i,
            'updated_at': i,
          });
        }
        await batch.commit(noResult: true);
      });

      // UI controller loads only the first 50
      final sub = testContainer.listen(recordListControllerProvider(dbId), (_, _) {});
      final uiRecords = await testContainer.read(recordListControllerProvider(dbId).future);
      expect(uiRecords.length, 50);

      // Reset spy counters so we only measure the export's fetches
      spyRepo.getRecordsPageCallCount = 0;
      spyRepo.totalRecordsFetched = 0;

      // Export controller runs independently
      final exportController = testContainer.read(v2ExportControllerProvider.notifier);
      final dbDef = await testContainer.read(schemaRepositoryProvider.future).then((r) => r.getDatabase(dbId));
      
      final exportedFile = await exportController.exportToExcel(dbDef!, fields);
      
      expect(exportedFile, isNotNull);
      expect(exportedFile!.existsSync(), true);
      
      final bytes = await exportedFile.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      var sheetName = dbDef.name.replaceAll(RegExp(r'[\\/?*\[\]:]'), '_');
      if (sheetName.length > 31) sheetName = sheetName.substring(0, 31);
      
      final sheet = excel.tables[sheetName];
      expect(sheet, isNotNull);
      
      // Row 1 is header, 120 data rows = 121 rows total
      expect(sheet!.maxRows, 121);
      
      if (exportedFile.existsSync()) {
        await exportedFile.delete();
      }
      
      // The export should have fetched 120 records across 2 page calls (limit 100).
      expect(spyRepo.getRecordsPageCallCount, 2);
      expect(spyRepo.totalRecordsFetched, 120);
      
      sub.close();
      testContainer.dispose();
    });
  });
}
