import 'dart:io';

import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:vault_zero/core/database/database_provider.dart';
import 'package:vault_zero/data/importers/csv_data_source.dart';
import 'package:vault_zero/data/repositories/sqlite_record_repository.dart';
import 'package:vault_zero/data/repositories/sqlite_schema_repository.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/domain/models/field_value.dart';
import 'package:vault_zero/domain/services/import_service.dart';
import 'package:vault_zero/presentation/records/controllers/record_list_controller.dart';
import 'package:vault_zero/presentation/records/controllers/v2_export_controller.dart';

void main() {
  late ProviderContainer container;
  late Database db;
  late DatabaseDefinition testDb;
  late FieldDefinition nameField;
  late FieldDefinition ageField;
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('vault_zero_export_test');
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
        version: 2,
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

    final repo = SqliteSchemaRepository(db);
    testDb = DatabaseDefinition(
      id: const Uuid().v4(),
      name: 'Test DB Export',
      description: '',
      fields: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await repo.createDatabase(testDb);

    nameField = FieldDefinition(
      id: const Uuid().v4(),
      databaseId: testDb.id,
      name: 'Name',
      type: FieldType.text,
      position: 0,
      isRequired: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ageField = FieldDefinition(
      id: const Uuid().v4(),
      databaseId: testDb.id,
      name: 'Age',
      type: FieldType.integer,
      position: 1,
      isRequired: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.createField(nameField);
    await repo.createField(ageField);

    container = ProviderContainer(
      overrides: [databaseProvider.overrideWith((ref) => db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test(
    'Export to Excel with outputDirectory generates valid xlsx file and preserves data',
    () async {
      final recordController = container.read(
        recordListControllerProvider(testDb.id).notifier,
      );

      await recordController.saveRecord(
        fields: [nameField, ageField],
        rawValues: {nameField.id: 'Alice', ageField.id: '30'},
      );

      final exportController = container.read(
        v2ExportControllerProvider.notifier,
      );

      final file = await exportController.exportToExcel(testDb, [
        nameField,
        ageField,
      ], outputDirectory: tempDir);

      expect(file, isNotNull);
      expect(file!.existsSync(), isTrue);
      expect(file.path, endsWith('.xlsx'));
      expect(file.path, contains('vault_zero_Test_DB_Export_'));

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      expect(excel.tables.isNotEmpty, isTrue);

      final sheet = excel.tables[excel.tables.keys.first]!;
      expect(sheet.rows.length, greaterThanOrEqualTo(2)); // header + 1 record
      expect(sheet.rows[0][0]?.value.toString(), 'Name');
      expect(sheet.rows[0][1]?.value.toString(), 'Age');
      expect(sheet.rows[1][0]?.value.toString(), 'Alice');
      expect(sheet.rows[1][1]?.value.toString(), '30');

      await file.delete();
    },
  );

  test(
    'Export to CSV with outputDirectory generates valid RFC 4180 file with headers and rows',
    () async {
      final recordController = container.read(
        recordListControllerProvider(testDb.id).notifier,
      );

      await recordController.saveRecord(
        fields: [nameField, ageField],
        rawValues: {nameField.id: 'Bob', ageField.id: '25'},
      );

      final exportController = container.read(
        v2ExportControllerProvider.notifier,
      );

      final file = await exportController.exportToCsv(testDb, [
        nameField,
        ageField,
      ], outputDirectory: tempDir);

      expect(file, isNotNull);
      expect(file!.existsSync(), isTrue);
      expect(file.path, endsWith('.csv'));
      expect(file.path, contains('vault_zero_Test_DB_Export_'));

      final content = await file.readAsString();
      final lines = content.trim().split(RegExp(r'\r?\n'));
      expect(lines[0], 'Name,Age');
      expect(lines[1], 'Bob,25');

      await file.delete();
    },
  );

  test(
    'Export to CSV preserves quotes, commas, and newlines per RFC 4180',
    () async {
      final recordController = container.read(
        recordListControllerProvider(testDb.id).notifier,
      );

      // Record with commas, quotes, and newlines
      await recordController.saveRecord(
        fields: [nameField, ageField],
        rawValues: {
          nameField.id: 'Smith, "The Agent"\nLine 2',
          ageField.id: '99',
        },
      );

      final exportController = container.read(
        v2ExportControllerProvider.notifier,
      );

      final file = await exportController.exportToCsv(testDb, [
        nameField,
        ageField,
      ], outputDirectory: tempDir);

      expect(file, isNotNull);
      expect(file!.existsSync(), isTrue);

      // Read back using CsvDataSource
      final source = CsvDataSource(file);
      final headers = await source.getHeaders();
      expect(headers, ['Name', 'Age']);

      final rows = await source.getRows().toList();
      expect(rows.length, 1);
      expect(rows.first[0], 'Smith, "The Agent"\nLine 2');
      expect(rows.first[1].toString(), '99');

      await file.delete();
    },
  );

  test(
    'Export to CSV throws StateError when database has no records',
    () async {
      final exportController = container.read(
        v2ExportControllerProvider.notifier,
      );

      // Database has no records
      expect(
        () => exportController.exportToCsv(testDb, [
          nameField,
          ageField,
        ], outputDirectory: tempDir),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'Export to Excel throws StateError when database has no records',
    () async {
      final exportController = container.read(
        v2ExportControllerProvider.notifier,
      );

      expect(
        () => exportController.exportToExcel(testDb, [
          nameField,
          ageField,
        ], outputDirectory: tempDir),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'Round-trip: export to CSV then import into new database preserves data',
    () async {
      final recordController = container.read(
        recordListControllerProvider(testDb.id).notifier,
      );

      await recordController.saveRecord(
        fields: [nameField, ageField],
        rawValues: {nameField.id: 'Charlie', ageField.id: '33'},
      );
      await recordController.saveRecord(
        fields: [nameField, ageField],
        rawValues: {nameField.id: 'Dana', ageField.id: '44'},
      );

      final exportController = container.read(
        v2ExportControllerProvider.notifier,
      );

      final csvFile = await exportController.exportToCsv(testDb, [
        nameField,
        ageField,
      ], outputDirectory: tempDir);

      expect(csvFile, isNotNull);

      // Now import it back using ImportService
      final schemaRepo = SqliteSchemaRepository(db);
      final recordRepo = SqliteRecordRepository(db);
      final importService = ImportService(
        schemaRepository: schemaRepo,
        recordRepository: recordRepo,
      );

      await importService.importDatabase(
        'Imported DB',
        CsvDataSource(csvFile!),
      );

      final databases = await schemaRepo.getAllDatabases();
      final importedDb = databases.firstWhere((d) => d.name == 'Imported DB');

      expect(importedDb.name, 'Imported DB');
      expect(importedDb.fields.length, 2);
      expect(importedDb.fields[0].name, 'Name');
      expect(importedDb.fields[1].name, 'Age');

      final importedRecords = await recordRepo.getRecordsForDatabase(
        importedDb.id,
      );
      expect(importedRecords.length, 2);

      final nameFieldId = importedDb.fields[0].id;
      final ageFieldId = importedDb.fields[1].id;
      expect(
        (importedRecords[0].values[nameFieldId] as TextFieldValue).value,
        'Charlie',
      );
      expect(
        (importedRecords[0].values[ageFieldId] as TextFieldValue).value,
        '33',
      );
      expect(
        (importedRecords[1].values[nameFieldId] as TextFieldValue).value,
        'Dana',
      );
      expect(
        (importedRecords[1].values[ageFieldId] as TextFieldValue).value,
        '44',
      );

      await csvFile.delete();
    },
  );

  test('exportControllerProvider alias resolves correctly', () {
    final exportController = container.read(exportControllerProvider.notifier);
    expect(exportController, isNotNull);
  });
}
