import 'dart:io';

import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/domain/models/field_value.dart';
import 'package:vault_zero/data/repositories/sqlite_schema_repository.dart';
import 'package:vault_zero/data/repositories/sqlite_record_repository.dart';
import 'package:vault_zero/domain/services/import_service.dart';
import 'package:vault_zero/data/importers/excel_data_source.dart';
import 'package:vault_zero/data/importers/tabular_data_source.dart';

// A mock failing data source that throws an error after 505 rows
class FailingExcelDataSource implements TabularDataSource {
  final TabularDataSource _delegate;
  int rowsRead = 0;

  FailingExcelDataSource(this._delegate);

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
    tempDir = Directory.systemTemp.createTempSync('vault_zero_excel_test');
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

  File createTempExcel(String fileName, void Function(Excel excel) builder) {
    final excel = Excel.createExcel();
    builder(excel);
    final bytes = excel.save()!;
    final file = File('${tempDir.path}/$fileName');
    file.writeAsBytesSync(bytes, flush: true);
    return file;
  }

  group('ExcelDataSource - Workbook & Worksheets', () {
    test('Enumerates single sheet and defaults to it', () async {
      final file = createTempExcel('single_sheet.xlsx', (excel) {
        final sheet = excel['Sheet1'];
        sheet.appendRow([TextCellValue('Col1'), TextCellValue('Col2')]);
        sheet.appendRow([TextCellValue('Val1'), TextCellValue('Val2')]);
      });

      final source = ExcelDataSource(file);
      final sheets = await source.getSheetNames();
      expect(sheets, ['Sheet1']);

      final headers = await source.getHeaders();
      expect(headers, ['Col1', 'Col2']);

      final rows = await source.getRows().toList();
      expect(rows.length, 1);
      expect(rows[0], ['Val1', 'Val2']);
    });

    test('Enumerates multiple sheets and imports chosen sheet', () async {
      final file = createTempExcel('multi_sheet.xlsx', (excel) {
        final sheetA = excel['Customers'];
        sheetA.appendRow([TextCellValue('CustID'), TextCellValue('Name')]);
        sheetA.appendRow([TextCellValue('C1'), TextCellValue('Alice')]);

        final sheetB = excel['Orders'];
        sheetB.appendRow([TextCellValue('OrderID'), TextCellValue('Amount')]);
        sheetB.appendRow([TextCellValue('O100'), IntCellValue(250)]);

        excel.delete('Sheet1');
      });

      final source = ExcelDataSource(file);
      final sheets = await source.getSheetNames();
      expect(sheets, containsAll(['Customers', 'Orders']));

      // Test Customers sheet
      final custSource = ExcelDataSource(file, sheetName: 'Customers');
      expect(await custSource.getHeaders(), ['CustID', 'Name']);
      final custRows = await custSource.getRows().toList();
      expect(custRows.length, 1);
      expect(custRows[0], ['C1', 'Alice']);

      // Test Orders sheet
      final orderSource = ExcelDataSource(file, sheetName: 'Orders');
      expect(await orderSource.getHeaders(), ['OrderID', 'Amount']);
      final orderRows = await orderSource.getRows().toList();
      expect(orderRows.length, 1);
      expect(orderRows[0], ['O100', '250']);
    });

    test('Throws on empty file or empty worksheet', () async {
      final emptyFile = File('${tempDir.path}/empty.xlsx');
      emptyFile.writeAsBytesSync([]);

      final emptySource = ExcelDataSource(emptyFile);
      expect(() => emptySource.getSheetNames(), throwsA(isA<FormatException>()));

      final emptySheetFile = createTempExcel('empty_sheet.xlsx', (excel) {
        excel['EmptySheet'];
        excel.delete('Sheet1');
      });

      final emptySheetSource = ExcelDataSource(emptySheetFile, sheetName: 'EmptySheet');
      expect(() => emptySheetSource.getHeaders(), throwsA(isA<FormatException>()));
    });
  });

  group('ExcelDataSource - Cell Types & Value Conversions', () {
    test('Faithfully converts text, int, double (preserving decimal precision), bool, dates, time, formula, multiline', () async {
      final file = createTempExcel('cell_types.xlsx', (excel) {
        final sheet = excel['Sheet1'];
        sheet.appendRow([
          TextCellValue('TextCol'),
          TextCellValue('IntCol'),
          TextCellValue('DoubleCol'),
          TextCellValue('DoubleDecimalCol'),
          TextCellValue('BoolCol'),
          TextCellValue('DateCol'),
          TextCellValue('DateTimeCol'),
          TextCellValue('TimeCol'),
          TextCellValue('FormulaCol'),
          TextCellValue('MultilineCol'),
          TextCellValue('EmptyCol'),
        ]);

        sheet.appendRow([
          TextCellValue('Hello'),
          IntCellValue(42),
          DoubleCellValue(3.1415),
          DoubleCellValue(42.75),
          BoolCellValue(true),
          DateCellValue(year: 2026, month: 8, day: 14),
          DateTimeCellValue(year: 2026, month: 8, day: 14, hour: 10, minute: 30, second: 0),
          TimeCellValue(hour: 14, minute: 45, second: 10),
          FormulaCellValue('=SUM(A1:B1)'),
          TextCellValue('Line 1\r\nLine 2\rLine 3\nLine 4'),
          null,
        ]);
      });

      final source = ExcelDataSource(file);
      final headers = await source.getHeaders();
      expect(headers.length, 11);

      final rows = await source.getRows().toList();
      expect(rows.length, 1);

      final row = rows[0];
      expect(row[0], 'Hello');
      expect(row[1], '42');
      expect(row[2], '3.1415');
      expect(row[3], '42.75'); // Preserves numeric decimal representation without truncation
      expect(row[4], 'true');
      expect(row[5], '2026-08-14');
      expect(row[6], '2026-08-14 10:30:00');
      expect(row[7], '14:45:10');
      expect(row[8], '=SUM(A1:B1)');
      expect(row[9], 'Line 1\nLine 2\nLine 3\nLine 4');
      expect(row[10], ''); // Null / empty cell becomes empty string
    });

    test('Preview read does not interfere with actual import read', () async {
      final file = createTempExcel('preview_test.xlsx', (excel) {
        final sheet = excel['Sheet1'];
        sheet.appendRow([TextCellValue('A'), TextCellValue('B')]);
        sheet.appendRow([TextCellValue('1'), TextCellValue('2')]);
      });

      final source = ExcelDataSource(file);

      // Preview read
      final previewHeaders = await source.getHeaders();
      final previewRows = await source.getRows().take(5).toList();
      expect(previewHeaders, ['A', 'B']);
      expect(previewRows.length, 1);

      // Subsequent import read
      final importHeaders = await source.getHeaders();
      final importRows = await source.getRows().toList();
      expect(importHeaders, ['A', 'B']);
      expect(importRows.length, 1);
    });
  });

  group('ImportService - End-to-End Excel Import', () {
    test('Imports Excel worksheet into new database with normalized headers and text fields', () async {
      final file = createTempExcel('full_import.xlsx', (excel) {
        final sheet = excel['Sheet1'];
        sheet.appendRow([
          TextCellValue('  Title  '),
          TextCellValue('Title'),
          TextCellValue(''),
          TextCellValue('Score'),
        ]);

        sheet.appendRow([
          TextCellValue('Inception'),
          TextCellValue('Movie'),
          TextCellValue('Extra'),
          DoubleCellValue(9.5),
        ]);

        sheet.appendRow([
          TextCellValue('Interstellar'),
          TextCellValue('SciFi'),
          TextCellValue(''),
          DoubleCellValue(9.0),
        ]);

        // Blank row
        sheet.appendRow([null, null, null, null]);

        // Row with missing cells (sparse)
        sheet.appendRow([
          TextCellValue('Tenet'),
          TextCellValue('Action'),
        ]);
      });

      final source = ExcelDataSource(file);
      await importService.importDatabase('Movies DB', source);

      final databases = await schemaRepo.getAllDatabases();
      expect(databases.length, 1);

      final dbDef = databases.first;
      expect(dbDef.name, 'Movies DB');
      expect(dbDef.fields.length, 4);

      expect(dbDef.fields[0].name, 'Title');
      expect(dbDef.fields[1].name, 'Title (1)');
      expect(dbDef.fields[2].name, 'Column A');
      expect(dbDef.fields[3].name, 'Score');

      for (final field in dbDef.fields) {
        expect(field.type, FieldType.text);
        expect(field.isRequired, isFalse);
      }

      final records = await recordRepo.getRecordsForDatabase(dbDef.id);
      expect(records.length, 3); // 1 blank row skipped, sparse row padded

      expect((records[0].values[dbDef.fields[0].id] as TextFieldValue).value, 'Inception');
      expect((records[0].values[dbDef.fields[3].id] as TextFieldValue).value, '9.5');

      // Check sparse row padding
      expect((records[2].values[dbDef.fields[0].id] as TextFieldValue).value, 'Tenet');
      expect((records[2].values[dbDef.fields[2].id] as TextFieldValue).value, '');
      expect((records[2].values[dbDef.fields[3].id] as TextFieldValue).value, '');
    });

    test('Rollback cleans up partial database on failure', () async {
      final file = createTempExcel('fail_excel.xlsx', (excel) {
        final sheet = excel['Sheet1'];
        sheet.appendRow([TextCellValue('ColA'), TextCellValue('ColB')]);
        for (var i = 0; i < 600; i++) {
          sheet.appendRow([TextCellValue('ValA_$i'), TextCellValue('ValB_$i')]);
        }
      });

      final source = ExcelDataSource(file);
      final failingSource = FailingExcelDataSource(source);

      expect(
        () => importService.importDatabase('Fail Excel DB', failingSource),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Changes reverted'))),
      );

      final databases = await schemaRepo.getAllDatabases();
      expect(databases, isEmpty, reason: 'Database should have been rolled back and cascade-deleted');
    });

    test('Large workbook import with 1200 rows across multiple batches', () async {
      final file = createTempExcel('large_excel.xlsx', (excel) {
        final sheet = excel['Sheet1'];
        sheet.appendRow([
          TextCellValue('ID'),
          TextCellValue('Name'),
          TextCellValue('Count'),
        ]);

        for (var i = 0; i < 1200; i++) {
          sheet.appendRow([
            TextCellValue('rec_$i'),
            TextCellValue('Item $i'),
            IntCellValue(i),
          ]);
        }
      });

      final source = ExcelDataSource(file);
      await importService.importDatabase('Large Excel DB', source);

      final databases = await schemaRepo.getAllDatabases();
      expect(databases.length, 1);

      final records = await recordRepo.getRecordsForDatabase(databases.first.id);
      expect(records.length, 1200);

      final fields = databases.first.fields;
      expect((records[0].values[fields[0].id] as TextFieldValue).value, 'rec_0');
      expect((records[1199].values[fields[0].id] as TextFieldValue).value, 'rec_1199');
      expect((records[1199].values[fields[2].id] as TextFieldValue).value, '1199');
    });
  });
}
