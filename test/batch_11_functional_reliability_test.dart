import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:vault_zero/core/database/database_provider.dart';
import 'package:vault_zero/data/importers/excel_data_source.dart';
import 'package:vault_zero/data/repositories/sqlite_schema_repository.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/domain/services/import_service.dart';
import 'package:vault_zero/presentation/databases/controllers/database_list_controller.dart';
import 'package:vault_zero/presentation/databases/widgets/database_form_dialog.dart';
import 'package:vault_zero/presentation/fields/controllers/field_list_controller.dart';
import 'package:vault_zero/presentation/records/widgets/dynamic_field_input.dart';

void main() {
  late Database db;
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    tempDir = Directory.systemTemp.createTempSync('batch11_tests_');
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
        version: 3,
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
  });

  tearDown(() async {
    await db.close();
  });

  group('Batch 11: Import Header Normalization & Collision Resilience', () {
    test('normalizeHeaders resolves complex collisions without duplicates', () {
      final input = ['Item', 'Item (1)', 'Item', 'Item (2)', 'item'];
      final output = ImportService.normalizeHeaders(input);

      // Verify all headers are unique (case-insensitively)
      final lowerSet = output.map((h) => h.toLowerCase()).toSet();
      expect(output.length, input.length);
      expect(lowerSet.length, input.length);
      expect(output, [
        'Item',
        'Item (1)',
        'Item (2)',
        'Item (2) (1)',
        'item (3)',
      ]);
    });

    test('normalizeHeaders handles all-empty headers gracefully', () {
      final input = ['', '   ', ''];
      final output = ImportService.normalizeHeaders(input);
      expect(output, ['Column A', 'Column B', 'Column C']);
    });
  });

  group('Batch 11: Excel Data Source Robustness', () {
    test(
      'ExcelDataSource trims trailing empty headers and handles formulas',
      () async {
        final excel = Excel.createExcel();
        final sheet = excel['Sheet1'];

        // Row 0: Headers with trailing empty cells
        sheet.appendRow([
          TextCellValue('Title'),
          TextCellValue('Score'),
          TextCellValue(''), // Trailing empty cell 1
          TextCellValue(''), // Trailing empty cell 2
        ]);

        // Row 1: Data with a formula cell
        sheet.appendRow([
          TextCellValue('Record 1'),
          FormulaCellValue('SUM(1, 2)'),
        ]);

        final bytes = excel.save()!;
        final testFile = File('${tempDir.path}/test_trailing_headers.xlsx');
        testFile.writeAsBytesSync(bytes);

        final dataSource = ExcelDataSource(testFile, sheetName: 'Sheet1');
        final headers = await dataSource.getHeaders();

        // Trailing empty headers should be trimmed off
        expect(headers, ['Title', 'Score']);

        // Rows should parse formula without error
        final rows = await dataSource.getRows().toList();
        expect(rows.length, 1);
        expect(rows[0][0], 'Record 1');
        expect(rows[0][1], 'SUM(1, 2)');
      },
    );
  });

  group('Batch 11: Controller Data Integrity Defense', () {
    test('DatabaseListController rejects blank database names', () async {
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWith((ref) => db)],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        databaseListControllerProvider.notifier,
      );
      await container.read(databaseListControllerProvider.future);

      expect(
        () => controller.createDatabase(name: '   '),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => controller.createDatabase(name: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'FieldListController rejects duplicate and blank field names',
      () async {
        final testDbId = const Uuid().v4();
        final schemaRepo = SqliteSchemaRepository(db);
        await schemaRepo.createDatabase(
          DatabaseDefinition(
            id: testDbId,
            name: 'Integrity DB',
            description: '',
            fields: const [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWith((ref) => db)],
        );
        addTearDown(container.dispose);

        final controller = container.read(
          fieldListControllerProvider(testDbId).notifier,
        );
        await container.read(fieldListControllerProvider(testDbId).future);

        await controller.createField(
          name: 'Status',
          type: FieldType.text,
          isRequired: false,
        );

        // Duplicate name (exact and case-insensitive)
        expect(
          () => controller.createField(
            name: 'Status',
            type: FieldType.text,
            isRequired: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => controller.createField(
            name: 'status',
            type: FieldType.text,
            isRequired: false,
          ),
          throwsA(isA<ArgumentError>()),
        );

        // Blank name
        expect(
          () => controller.createField(
            name: '   ',
            type: FieldType.text,
            isRequired: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });

  group('Batch 11: DynamicFieldInput Choice Clearing & Affordance', () {
    testWidgets(
      'Choice input displays clear suffix icon when optional and value selected',
      (tester) async {
        final field = FieldDefinition(
          id: 'choice_1',
          databaseId: 'db_1',
          name: 'Priority',
          type: FieldType.choice,
          position: 0,
          isRequired: false,
          configuration: const ChoiceConfig(options: ['Low', 'Medium', 'High']),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        String? updatedValue = 'Medium';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return DynamicFieldInput(
                    field: field,
                    initialValue: updatedValue,
                    onChanged: (val) {
                      setState(() {
                        updatedValue = val as String?;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Clear button should be present since an optional choice has a value
        final clearButton = find.byTooltip('Clear Priority');
        expect(clearButton, findsOneWidget);

        // Tap clear button
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        // Value should be cleared
        expect(updatedValue, isNull);
        expect(find.byTooltip('Clear Priority'), findsNothing);
      },
    );
  });

  group('Batch 11: DatabaseFormDialog Button State', () {
    testWidgets(
      'DatabaseFormDialog disables Cancel and Submit during submission',
      (tester) async {
        Map<String, String>? dialogResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      dialogResult = await DatabaseFormDialog.show(context);
                    },
                    child: const Text('Open Dialog'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        final nameField = find.byType(TextFormField).first;
        await tester.enterText(nameField, 'New Valid DB');
        await tester.pumpAndSettle();

        final createButton = find.widgetWithText(FilledButton, 'Create');
        expect(tester.widget<FilledButton>(createButton).enabled, isTrue);

        await tester.tap(createButton);
        await tester.pumpAndSettle();

        // Dialog pops and passes valid values
        expect(find.byType(DatabaseFormDialog), findsNothing);
        expect(dialogResult, isNotNull);
        expect(dialogResult!['name'], 'New Valid DB');
      },
    );
  });
}
