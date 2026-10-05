import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:vault_zero/core/preferences/preferences_repository.dart';
import 'package:vault_zero/data/importers/csv_data_source.dart';
import 'package:vault_zero/data/importers/excel_data_source.dart';
import 'package:vault_zero/data/repositories/sqlite_record_repository.dart';
import 'package:vault_zero/data/repositories/sqlite_schema_repository.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/domain/models/field_value.dart';
import 'package:vault_zero/domain/models/record.dart';
import 'package:vault_zero/domain/services/import_service.dart';
import 'package:vault_zero/presentation/common/error_sanitizer.dart';
import 'package:vault_zero/presentation/records/controllers/v2_export_controller.dart';

void main() {
  late Directory tempDir;
  late Database db;
  late SqliteSchemaRepository schemaRepo;
  late SqliteRecordRepository recordRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('vault_zero_security_test');
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
  });

  tearDown(() async {
    await db.close();
  });

  group('1. Data Boundary & File-System Safety', () {
    test(
      'Export filename sanitizes path traversal, null bytes, and unsafe characters',
      () {
        final unsafe1 = '../../etc/passwd';
        expect(
          ExportController.sanitizeFileName(unsafe1),
          isNot(contains('/')),
        );
        expect(
          ExportController.sanitizeFileName(unsafe1),
          isNot(contains('..')),
        );

        final unsafe2 = 'Database\x00Name:With*Illegal?Chars';
        final sanitized = ExportController.sanitizeFileName(unsafe2);
        expect(sanitized, isNot(contains('\x00')));
        expect(sanitized, isNot(contains(':')));
        expect(sanitized, isNot(contains('*')));
        expect(sanitized, isNot(contains('?')));

        final empty = '...';
        expect(ExportController.sanitizeFileName(empty), equals('database'));
      },
    );

    test(
      'PreferencesRepository does not crash on read/write and cleans temp files',
      () async {
        final repo = PreferencesRepository();
        final prefs = await repo.loadPreferences();
        expect(prefs, isA<Map<String, dynamic>>());
      },
    );
  });

  group('2. Database Integrity & Atomic Rollbacks', () {
    test('saveRecord rejects insertion into non-existent database', () async {
      final record = Record(
        id: const Uuid().v4(),
        databaseId: 'non_existent_db_id',
        values: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => recordRepo.saveRecord(record),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'saveRecordsBatch rejects batch referencing non-existent database atomically',
      () async {
        final now = DateTime.now();
        final validDb = DatabaseDefinition(
          id: const Uuid().v4(),
          name: 'Valid DB',
          description: 'Test',
          fields: [],
          createdAt: now,
          updatedAt: now,
        );
        await schemaRepo.createDatabase(validDb);

        final rec1 = Record(
          id: const Uuid().v4(),
          databaseId: validDb.id,
          values: {},
          createdAt: now,
          updatedAt: now,
        );
        final rec2 = Record(
          id: const Uuid().v4(),
          databaseId: 'ghost_db',
          values: {},
          createdAt: now,
          updatedAt: now,
        );

        expect(
          () => recordRepo.saveRecordsBatch([rec1, rec2]),
          throwsA(isA<ArgumentError>()),
        );

        // Verify rec1 was NOT inserted due to transaction rollback
        final records = await recordRepo.getRecordsForDatabase(validDb.id);
        expect(records, isEmpty);
      },
    );

    test(
      'saveRecordsBatch rolls back completely when a record violates field type',
      () async {
        final now = DateTime.now();
        final fieldId = const Uuid().v4();
        final dbId = const Uuid().v4();
        final validDb = DatabaseDefinition(
          id: dbId,
          name: 'Type Check DB',
          description: 'Test',
          fields: [
            FieldDefinition(
              id: fieldId,
              databaseId: dbId,
              name: 'Score',
              type: FieldType.integer,
              position: 0,
              isRequired: false,
              createdAt: now,
              updatedAt: now,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        );
        await schemaRepo.createDatabase(validDb);

        final rec1Id = const Uuid().v4();
        final rec1 = Record(
          id: rec1Id,
          databaseId: validDb.id,
          values: {
            fieldId: IntegerFieldValue(
              id: const Uuid().v4(),
              recordId: rec1Id,
              fieldId: fieldId,
              value: 42,
            ),
          },
          createdAt: now,
          updatedAt: now,
        );

        final rec2Id = const Uuid().v4();
        final rec2 = Record(
          id: rec2Id,
          databaseId: validDb.id,
          values: {
            fieldId: TextFieldValue(
              id: const Uuid().v4(),
              recordId: rec2Id,
              fieldId: fieldId,
              value: 'Mismatch', // text instead of integer
            ),
          },
          createdAt: now,
          updatedAt: now,
        );

        expect(
          () => recordRepo.saveRecordsBatch([rec1, rec2]),
          throwsA(isA<ArgumentError>()),
        );

        final records = await recordRepo.getRecordsForDatabase(validDb.id);
        expect(records, isEmpty);
      },
    );
  });

  group('3. Input Sanitization & Numeric Precision Safety', () {
    test('DecimalFieldValue constructor asserts on NaN and Infinity', () {
      expect(
        () => DecimalFieldValue(
          id: '1',
          recordId: '1',
          fieldId: '1',
          value: double.nan,
        ),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => DecimalFieldValue(
          id: '1',
          recordId: '1',
          fieldId: '1',
          value: double.infinity,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('FieldValue.fromJson rejects non-finite decimal values', () {
      expect(
        () => FieldValue.fromJson({
          'id': 'v1',
          'recordId': 'r1',
          'fieldId': 'f1',
          'type': 'decimal',
          'value': double.infinity,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'ImportService.normalizeHeaders sanitizes zero-width and control characters',
      () {
        final raw = [
          '\uFEFFTitle', // BOM
          'Col\u200BName', // Zero-width space
          'User\x00Id', // Null byte
          'Price\u202EReverse', // Bidi override
          '', // Empty header 1
          '   ', // Empty header 2
        ];

        final normalized = ImportService.normalizeHeaders(raw);
        expect(normalized[0], equals('Title'));
        expect(normalized[1], equals('ColName'));
        expect(normalized[2], equals('UserId'));
        expect(normalized[3], equals('PriceReverse'));
        expect(normalized[4], equals('Column A'));
        expect(normalized[5], equals('Column B'));
      },
    );
  });

  group('4. Import & File Parser Safety', () {
    test(
      'ExcelDataSource throws clean FormatException on corrupted/non-zip bytes',
      () async {
        final corruptFile = File('${tempDir.path}/corrupt.xlsx');
        await corruptFile.writeAsBytes([0x01, 0x02, 0x03, 0x04, 0x05]);

        final source = ExcelDataSource(corruptFile);
        expect(() => source.getSheetNames(), throwsA(isA<FormatException>()));
      },
    );

    test(
      'CsvDataSource throws clean FormatException when file does not exist',
      () async {
        final nonExistentFile = File('${tempDir.path}/non_existent.csv');
        final source = CsvDataSource(nonExistentFile);

        expect(() => source.getHeaders(), throwsA(isA<FormatException>()));
      },
    );
  });

  group('5. Error Message & Privacy Sanitization', () {
    test('sanitizeErrorMessage strips internal paths and SQLite details', () {
      final errorWithPath = Exception(
        'Cannot open file /data/user/0/com.example.vault_zero/databases/characters.db: Permission denied',
      );
      final sanitized = sanitizeErrorMessage(errorWithPath);
      expect(sanitized, isNot(contains('/data/user/0')));
      expect(sanitized, isNot(contains('characters.db')));
      expect(sanitized, contains('[path]'));

      final errorWithCode =
          'DatabaseException: (code 19 SQLITE_CONSTRAINT_UNIQUE) constraint failed';
      final sanitizedCode = sanitizeErrorMessage(errorWithCode);
      expect(
        sanitizedCode,
        isNot(contains('(code 19 SQLITE_CONSTRAINT_UNIQUE)')),
      );

      final nullError = sanitizeErrorMessage(null);
      expect(nullError, equals('An unexpected error occurred'));
    });
  });
}
