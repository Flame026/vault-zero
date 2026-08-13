import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vault_zero/data/repositories/json_backup_restore_service.dart';

void main() {
  late Database db;
  late JsonBackupRestoreService service;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
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
        },
      ),
    );
    service = JsonBackupRestoreService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Valid backup creation and exact UUID/Timestamp preservation', () async {
    final nowRaw = DateTime.now().toUtc();
    final now = DateTime.fromMillisecondsSinceEpoch(nowRaw.millisecondsSinceEpoch, isUtc: true);
    
    // Insert some test data directly
    await db.insert('databases', {
      'id': 'db-1',
      'name': 'Test DB',
      'description': 'Desc',
      'created_at': now.millisecondsSinceEpoch,
      'updated_at': now.millisecondsSinceEpoch,
    });
    
    await db.insert('fields', {
      'id': 'field-1',
      'database_id': 'db-1',
      'name': 'Name',
      'type': 'text',
      'position': 0,
      'is_required': 1,
      'configuration': null,
      'created_at': now.millisecondsSinceEpoch,
      'updated_at': now.millisecondsSinceEpoch,
    });

    await db.insert('records', {
      'id': 'record-1',
      'database_id': 'db-1',
      'created_at': now.millisecondsSinceEpoch,
      'updated_at': now.millisecondsSinceEpoch,
    });

    await db.insert('field_values', {
      'id': 'val-1',
      'record_id': 'record-1',
      'field_id': 'field-1',
      'text_value': 'John Doe',
    });

    final jsonContent = await service.exportVault();
    final decoded = jsonDecode(jsonContent);

    expect(decoded['backupFormatVersion'], 1);
    expect(decoded['databases'].length, 1);
    expect(decoded['fields'].length, 1);
    expect(decoded['records'].length, 1);

    expect(decoded['databases'][0]['id'], 'db-1');
    expect(decoded['databases'][0]['createdAt'], now.toIso8601String());

    // Test restoring it to a clean DB
    await db.execute('DELETE FROM databases');
    
    await service.restoreVault(jsonContent);

    // Verify
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM records'));
    expect(count, 1);
    final valRow = await db.query('field_values');
    expect(valRow.first['text_value'], 'John Doe');
  });

  test('Empty vault backup and restore', () async {
    final jsonContent = await service.exportVault();
    await service.restoreVault(jsonContent);
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM databases'));
    expect(count, 0);
  });

  test('Malformed JSON rejection', () async {
    expect(() => service.restoreVault('not json'), throwsFormatException);
  });

  test('Unsupported backup version rejection', () async {
    final badJson = '{"backupFormatVersion": 99, "databases": [], "fields": [], "records": []}';
    expect(() => service.restoreVault(badJson), throwsFormatException);
  });

  test('Missing structures rejection', () async {
    final badJson = '{"backupFormatVersion": 1, "databases": []}'; // missing fields and records
    expect(() => service.restoreVault(badJson), throwsFormatException);
  });

  test('Orphaned foreign-key references validation', () async {
    final orphanJson = '''{
      "backupFormatVersion": 1,
      "exportDate": "2026-08-12T00:00:00.000Z",
      "databases": [],
      "fields": [],
      "records": [
        {
          "id": "rec-1",
          "databaseId": "missing-db",
          "values": {},
          "createdAt": "2026-08-12T00:00:00.000Z",
          "updatedAt": "2026-08-12T00:00:00.000Z"
        }
      ]
    }''';
    expect(() => service.restoreVault(orphanJson), throwsFormatException);
  });

  test('Failed restore with transaction rollback', () async {
    // 1. Insert existing data
    await db.insert('databases', {
      'id': 'existing-db',
      'name': 'Existing',
      'description': 'Desc',
      'created_at': 0,
      'updated_at': 0,
    });

    final badDateJson = '''{
      "backupFormatVersion": 1,
      "exportDate": "2026-08-12T00:00:00.000Z",
      "databases": [
        {
          "id": "new-db",
          "name": "New",
          "description": "",
          "createdAt": "BAD-DATE",
          "updatedAt": "BAD-DATE",
          "fields": []
        }
      ],
      "fields": [],
      "records": []
    }''';

    expect(() => service.restoreVault(badDateJson), throwsFormatException);

    // Assert existing data remains intact
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM databases'));
    expect(count, 1);
  });
}
