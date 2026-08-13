import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/domain/models/record.dart';
import 'package:vault_zero/domain/models/field_value.dart';
import 'package:vault_zero/data/repositories/sqlite_schema_repository.dart';
import 'package:vault_zero/data/repositories/sqlite_record_repository.dart';
import 'package:vault_zero/domain/services/import_service.dart';
import 'package:vault_zero/data/importers/csv_data_source.dart';
import 'package:vault_zero/data/importers/tabular_data_source.dart';

// A mock failing data source that throws an error after parsing headers
class FailingDataSource implements TabularDataSource {
  final TabularDataSource _delegate;
  int rowsRead = 0;

  FailingDataSource(this._delegate);

  @override
  Future<List<String>> getHeaders() => _delegate.getHeaders();

  @override
  Stream<List<dynamic>> getRows() async* {
    await for (final row in _delegate.getRows()) {
      rowsRead++;
      if (rowsRead > 505) {
        throw const FormatException('Simulated parser failure');
      }
      yield row;
    }
  }
}

void main() {
  late Database db;
  late SqliteSchemaRepository schemaRepo;
  late SqliteRecordRepository recordRepo;
  late ImportService importService;
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('vault_zero_test');
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 4,
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

    schemaRepo = SqliteSchemaRepository(db);
    recordRepo = SqliteRecordRepository(db);
    importService = ImportService(
      schemaRepository: schemaRepo,
      recordRepository: recordRepo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  File createTempCsv(String fileName, String content) {
    final file = File('${tempDir.path}/$fileName');
    // Ensure all test fixtures use proper CRLF as expected by the default CSV parser
    final normalizedContent = content.replaceAll('\r\n', '\n').replaceAll('\n', '\r\n');
    file.writeAsStringSync(normalizedContent, encoding: utf8);
    return file;
  }

  group('CsvDataSource (Parser)', () {
    test('Correctly parses headers and rows including multiline and escaped quotes', () async {
      final file = createTempCsv('basic.csv', '''
Name, Age, "", Name, Description
John Doe, 30, x, Jane Doe,"A person
with a multiline
description"
"Escaped ""quotes""", 25, y,, 
''');
      
      final source = CsvDataSource(file);
      final headers = await source.getHeaders();
      expect(headers, ['Name', ' Age', ' ""', ' Name', ' Description']); // Note: csv package strips quotes but leaves space without trim unless configured.

      final rows = await source.getRows().toList();
      expect(rows.length, 2);
      expect(rows[0][0], 'John Doe');
      expect(rows[0][4], 'A person\r\nwith a multiline\r\ndescription');
      expect(rows[1][0], 'Escaped "quotes"');
      expect(rows[1][3], ''); // Empty CSV cell represented as empty string
    });

    test('Preview parsing does not prevent import reading', () async {
      final file = createTempCsv('preview.csv', 'A,B\n1,2');
      final source = CsvDataSource(file);
      
      final previewHeaders = await source.getHeaders();
      final previewRows = await source.getRows().take(5).toList();
      expect(previewHeaders, ['A', 'B']);
      expect(previewRows.length, 1);

      // Second read should still work because it opens a new file stream
      final importHeaders = await source.getHeaders();
      final importRows = await source.getRows().toList();
      expect(importHeaders, ['A', 'B']);
      expect(importRows.length, 1);
    });
  });

  group('ImportService', () {
    test('Imports clean database with normalized headers and text fields', () async {
      final file = createTempCsv('import.csv', '''
  Name  , Name, , 
John, Smith, a, b
Jane, Doe, c, d
,,,,,
Jane, Doe, c
''');
      
      final source = CsvDataSource(file);
      await importService.importDatabase('Test DB', source);

      final databases = await schemaRepo.getAllDatabases();
      expect(databases.length, 1);
      final dbDef = databases.first;
      expect(dbDef.name, 'Test DB');
      expect(dbDef.fields.length, 4);
      
      expect(dbDef.fields[0].name, 'Name');
      expect(dbDef.fields[1].name, 'Name (1)');
      expect(dbDef.fields[2].name, 'Column A');
      expect(dbDef.fields[3].name, 'Column B');

      for (var f in dbDef.fields) {
        expect(f.type, FieldType.text);
        expect(f.isRequired, isFalse);
      }

      final records = await recordRepo.getRecordsForDatabase(dbDef.id);
      expect(records.length, 3); // 1 blank row skipped, last row missing cell padded

      expect((records[0].values[dbDef.fields[0].id] as TextFieldValue).value, 'John');
      expect((records[2].values[dbDef.fields[3].id] as TextFieldValue).value, ''); // Padded missing cell
    });

    test('Rollback on failure during import', () async {
      final sb = StringBuffer();
      sb.writeln('A, B');
      for (var i = 0; i < 600; i++) {
        sb.writeln('1, 2');
      }
      final file = createTempCsv('fail.csv', sb.toString());
      final source = CsvDataSource(file);
      final failingSource = FailingDataSource(source);

      expect(
        () => importService.importDatabase('Fail DB', failingSource),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Changes reverted'))),
      );

      final databases = await schemaRepo.getAllDatabases();
      expect(databases, isEmpty, reason: 'Database should have been rolled back and deleted');
    });

    test('Large import with batching', () async {
      final sb = StringBuffer();
      sb.writeln('Col1,Col2,Col3');
      for (var i = 0; i < 1200; i++) {
        sb.writeln('Row${i}_1,Row${i}_2,Row${i}_3');
      }
      final file = createTempCsv('large.csv', sb.toString());
      final source = CsvDataSource(file);

      await importService.importDatabase('Large DB', source);

      final databases = await schemaRepo.getAllDatabases();
      expect(databases.length, 1);
      
      final records = await recordRepo.getRecordsForDatabase(databases.first.id);
      expect(records.length, 1200);
      expect((records[1199].values[databases.first.fields[0].id] as TextFieldValue).value, 'Row1199_1');
    });
  });

  group('Repository Bulk Write', () {
    test('saveRecordsBatch saves multiple records in one pass', () async {
      final dbDef = DatabaseDefinition(
        id: 'test_db',
        name: 'Bulk DB',
        fields: [
          FieldDefinition(
            id: 'f1',
            databaseId: 'test_db',
            name: 'Text Field',
            type: FieldType.text,
            position: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await schemaRepo.createDatabase(dbDef);

      final records = List.generate(50, (i) => Record(
        id: 'r$i',
        databaseId: 'test_db',
        values: {
          'f1': TextFieldValue(id: 'v$i', recordId: 'r$i', fieldId: 'f1', value: 'Val$i'),
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await recordRepo.saveRecordsBatch(records);

      final saved = await recordRepo.getRecordsForDatabase('test_db');
      expect(saved.length, 50);
      expect((saved.last.values['f1'] as TextFieldValue).value, 'Val49');
    });
  });
}
