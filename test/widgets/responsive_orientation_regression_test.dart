import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:vault_zero/core/database/database_provider.dart';
import 'package:vault_zero/data/repositories/sqlite_record_repository.dart';
import 'package:vault_zero/data/repositories/sqlite_schema_repository.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/domain/models/field_value.dart';
import 'package:vault_zero/domain/models/record.dart';
import 'package:vault_zero/presentation/databases/controllers/database_list_controller.dart';
import 'package:vault_zero/presentation/databases/database_list_screen.dart';
import 'package:vault_zero/presentation/fields/field_form_screen.dart';
import 'package:vault_zero/presentation/records/record_form_screen.dart';
import 'package:vault_zero/presentation/records/record_list_screen.dart';
import 'package:vault_zero/presentation/settings/widgets/theme_picker_sheet.dart';

class MockDbController extends DatabaseListController {
  final List<DatabaseDefinition> dbs;
  MockDbController(this.dbs);
  @override
  Future<List<DatabaseDefinition>> build() async => dbs;
}

void main() {
  late Database db;
  late String testDbId;
  late SqliteSchemaRepository schemaRepo;
  late SqliteRecordRepository recordRepo;
  late DatabaseDefinition testDb;
  late FieldDefinition testField;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
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
          await db.execute('''
            CREATE INDEX IF NOT EXISTS idx_records_database_created_id 
            ON records(database_id, created_at, id)
          ''');
        },
      ),
    );

    schemaRepo = SqliteSchemaRepository(db);
    recordRepo = SqliteRecordRepository(db);

    testDbId = const Uuid().v4();
    final now = DateTime.now();
    testDb = DatabaseDefinition(
      id: testDbId,
      name: 'Inventory Vault',
      description: 'Asset tracking and records database',
      fields: [],
      createdAt: now,
      updatedAt: now,
    );
    await schemaRepo.createDatabase(testDb);

    testField = FieldDefinition(
      id: const Uuid().v4(),
      databaseId: testDbId,
      name: 'Item Title',
      type: FieldType.text,
      position: 0,
      isRequired: true,
      createdAt: now,
      updatedAt: now,
    );
    await schemaRepo.createField(testField);

    // Insert 5 test records
    for (int i = 1; i <= 5; i++) {
      final recordId = const Uuid().v4();
      await recordRepo.saveRecord(
        Record(
          id: recordId,
          databaseId: testDbId,
          values: {
            testField.id: TextFieldValue(
              id: const Uuid().v4(),
              recordId: recordId,
              fieldId: testField.id,
              value: 'Record Item #$i',
            ),
          },
          createdAt: now.add(Duration(minutes: i)),
          updatedAt: now.add(Duration(minutes: i)),
        ),
      );
    }
  });

  tearDown(() async {
    await db.close();
  });

  group('Landscape and Constrained Viewport Regression Tests', () {
    testWidgets(
      'Import Database format-selection modal in landscape mode (640x360) produces NO overflow',
      (tester) async {
        // Landscape phone dimensions
        tester.view.physicalSize = const Size(640, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseListControllerProvider.overrideWith(
                () => MockDbController([testDb]),
              ),
            ],
            child: const MaterialApp(home: DatabaseListScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Open Import Database modal
        final importButton = find.byTooltip('Import Database');
        expect(importButton, findsOneWidget);
        await tester.tap(importButton);
        await tester.pumpAndSettle();

        // Must not produce any RenderFlex overflow exception
        expect(tester.takeException(), isNull);

        // Both format options must be visible and present
        expect(find.text('Import Database'), findsOneWidget);
        expect(find.text('CSV Document (.csv)'), findsOneWidget);
        expect(find.text('Excel Spreadsheet (.xlsx)'), findsOneWidget);

        // Dismiss modal
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Import Database modal in short landscape (640x300) is scrollable without overflow',
      (tester) async {
        // Short landscape viewport
        tester.view.physicalSize = const Size(640, 300);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseListControllerProvider.overrideWith(
                () => MockDbController([testDb]),
              ),
            ],
            child: const MaterialApp(home: DatabaseListScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Import Database'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Import Database'), findsOneWidget);
        expect(find.text('CSV Document (.csv)'), findsOneWidget);

        // Scroll within modal
        await tester.drag(
          find.text('CSV Document (.csv)'),
          const Offset(0, -100),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Export Database format-selection modal in landscape mode (640x360) produces NO overflow',
      (tester) async {
        tester.view.physicalSize = const Size(640, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) => db)],
            child: MaterialApp(home: RecordListScreen(database: testDb)),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Open Export Database modal
        final exportButton = find.byTooltip('Export Data');
        expect(exportButton, findsOneWidget);
        await tester.tap(exportButton);
        await tester.pumpAndSettle();

        // Must not produce any RenderFlex overflow
        expect(tester.takeException(), isNull);

        // Verify options are displayed
        expect(find.text('Export Database'), findsOneWidget);
        expect(find.text('Excel Spreadsheet (.xlsx)'), findsOneWidget);
        expect(find.text('CSV Document (.csv)'), findsOneWidget);

        // Dismiss modal
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Export Database modal in short landscape (640x300) is scrollable without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(640, 300);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) => db)],
            child: MaterialApp(home: RecordListScreen(database: testDb)),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Export Data'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Export Database'), findsOneWidget);
        expect(find.text('Excel Spreadsheet (.xlsx)'), findsOneWidget);

        // Scroll within modal
        await tester.drag(
          find.text('Excel Spreadsheet (.xlsx)'),
          const Offset(0, -100),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'ThemePickerSheet in landscape mode renders cleanly without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(640, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () => ThemePickerSheet.show(ctx),
                    child: const Text('Theme'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Theme Color'), findsOneWidget);

        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'RecordFormScreen in landscape mode (640x360) and discard dialog produces NO overflow',
      (tester) async {
        tester.view.physicalSize = const Size(640, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) => db)],
            child: MaterialApp(
              home: RecordFormScreen(databaseId: testDbId, fields: [testField]),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('New Record'), findsOneWidget);

        // Enter some text into field to mark it dirty
        await tester.enterText(find.byType(TextFormField).first, 'Dirty Item');
        await tester.pumpAndSettle();

        // Tap cancel in app bar
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Discard dialog must render cleanly in landscape without overflow
        expect(tester.takeException(), isNull);
        expect(find.text('Discard changes?'), findsOneWidget);

        // Tap Keep Editing
        await tester.tap(find.text('Keep Editing'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'FieldFormScreen in landscape mode (640x360) and discard dialog produces NO overflow',
      (tester) async {
        tester.view.physicalSize = const Size(640, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) => db)],
            child: MaterialApp(home: FieldFormScreen(databaseId: testDbId)),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('New Field'), findsOneWidget);

        // Enter text into field name to make it dirty
        await tester.enterText(
          find.byType(TextFormField).first,
          'Field Name Sample',
        );
        await tester.pumpAndSettle();

        // Tap cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Discard dialog must render cleanly without overflow
        expect(tester.takeException(), isNull);
        expect(find.text('Discard changes?'), findsOneWidget);

        // Keep editing
        await tester.tap(find.text('Keep Editing'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
