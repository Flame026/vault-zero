import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:vault_zero/core/database/database_provider.dart';
import 'package:vault_zero/data/repositories/sqlite_schema_repository.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/domain/models/record.dart';
import 'package:vault_zero/domain/models/field_value.dart';
import 'package:vault_zero/presentation/databases/controllers/database_list_controller.dart';
import 'package:vault_zero/presentation/databases/widgets/database_card.dart';
import 'package:vault_zero/presentation/fields/field_form_screen.dart';
import 'package:vault_zero/presentation/fields/field_list_screen.dart';
import 'package:vault_zero/presentation/records/controllers/record_list_controller.dart';
import 'package:vault_zero/presentation/records/controllers/v2_export_controller.dart';
import 'package:vault_zero/presentation/records/record_list_screen.dart';
import 'package:vault_zero/presentation/records/widgets/record_card.dart';

void main() {
  late Database db;
  late String testDbId;
  late SqliteSchemaRepository schemaRepo;
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

    testDbId = const Uuid().v4();
    final now = DateTime.now();
    testDb = DatabaseDefinition(
      id: testDbId,
      name: 'Initial DB Name',
      description: 'Test database description',
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
  });

  tearDown(() async {
    await db.close();
  });

  group('Batch 15: Phase 2 Final QA & Regression Suite', () {
    testWidgets(
      '1. Dynamic Database Name Propagation in RecordListScreen when renamed',
      (tester) async {
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWith((ref) => db)],
        );
        addTearDown(container.dispose);

        // Load databases into state
        await container.read(databaseListControllerProvider.future);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(home: RecordListScreen(database: testDb)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Initial DB Name'), findsOneWidget);

        // Update database name via controller
        await container
            .read(databaseListControllerProvider.notifier)
            .updateDatabase(testDb, name: 'Renamed Vault Database');

        await tester.pumpAndSettle();

        // RecordListScreen should now display 'Renamed Vault Database'
        expect(find.text('Renamed Vault Database'), findsOneWidget);
        expect(find.text('Initial DB Name'), findsNothing);
      },
    );

    testWidgets(
      '2. Dynamic Database Name Propagation in FieldListScreen when renamed',
      (tester) async {
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWith((ref) => db)],
        );
        addTearDown(container.dispose);

        await container.read(databaseListControllerProvider.future);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(home: FieldListScreen(database: testDb)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Initial DB Name Fields'), findsOneWidget);

        await container
            .read(databaseListControllerProvider.notifier)
            .updateDatabase(testDb, name: 'Warehouse Assets');

        await tester.pumpAndSettle();

        expect(find.text('Warehouse Assets Fields'), findsOneWidget);
        expect(find.text('Initial DB Name Fields'), findsNothing);
      },
    );

    test(
      '3. Record Prepend Order matches Keyset Pagination (newest at index 0)',
      () async {
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWith((ref) => db)],
        );
        addTearDown(container.dispose);

        final controller = container.read(
          recordListControllerProvider(testDbId).notifier,
        );

        // Create first record
        await controller.saveRecord(
          fields: [testField],
          rawValues: {testField.id: 'First Record'},
        );

        var records = await container.read(
          recordListControllerProvider(testDbId).future,
        );
        expect(records.length, 1);
        expect(records[0].values[testField.id]?.value, 'First Record');

        // Create second record
        await controller.saveRecord(
          fields: [testField],
          rawValues: {testField.id: 'Second Record'},
        );

        records = await container.read(
          recordListControllerProvider(testDbId).future,
        );
        expect(records.length, 2);
        // Second record must be at index 0 (prepended)
        expect(records[0].values[testField.id]?.value, 'Second Record');
        expect(records[1].values[testField.id]?.value, 'First Record');
      },
    );

    testWidgets(
      '4. RecordListScreen Search Dismissal closes search and resets focus',
      (tester) async {
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWith((ref) => db)],
        );
        addTearDown(container.dispose);

        // Prepopulate a record so search icon is visible
        final controller = container.read(
          recordListControllerProvider(testDbId).notifier,
        );
        await controller.saveRecord(
          fields: [testField],
          rawValues: {testField.id: 'Sample Entry'},
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(home: RecordListScreen(database: testDb)),
          ),
        );
        await tester.pumpAndSettle();

        // Tap search button
        final searchBtn = find.byTooltip('Search records');
        expect(searchBtn, findsOneWidget);
        await tester.tap(searchBtn);
        await tester.pumpAndSettle();

        // Search text field should be present
        expect(find.byType(TextField), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Sample');
        await tester.pumpAndSettle();

        // Close search
        final closeSearchBtn = find.byTooltip('Close search');
        expect(closeSearchBtn, findsOneWidget);
        await tester.tap(closeSearchBtn);
        await tester.pumpAndSettle();

        // Search text field should no longer be present
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Initial DB Name'), findsOneWidget);
      },
    );

    test(
      '5. ExportController handles empty database with graceful StateError',
      () async {
        final emptyDb = DatabaseDefinition(
          id: const Uuid().v4(),
          name: 'Empty Vault',
          description: '',
          fields: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await schemaRepo.createDatabase(emptyDb);

        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWith((ref) => db)],
        );
        addTearDown(container.dispose);

        final exportCtrl = container.read(exportControllerProvider.notifier);

        expect(
          () => exportCtrl.exportToCsv(emptyDb, [testField]),
          throwsA(isA<StateError>()),
        );
        expect(
          () => exportCtrl.exportToExcel(emptyDb, [testField]),
          throwsA(isA<StateError>()),
        );
      },
    );

    testWidgets(
      '6. Ultra-narrow 300px viewport renders cards cleanly without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(300, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final longNameDb = DatabaseDefinition(
          id: 'long-db-id',
          name:
              'Super Long Database Title That Exceeds Normal Constraints And Should Wrap Gracefully',
          description:
              'A very detailed and lengthy description of this database to test typography wrapping and card behavior.',
          fields: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  DatabaseCard(
                    database: longNameDb,
                    onTap: () {},
                    onEdit: () {},
                    onDelete: () {},
                    onManageFields: () {},
                  ),
                  RecordCard(
                    record: Record(
                      id: 'rec-1',
                      databaseId: 'long-db-id',
                      values: {
                        'title': TextFieldValue(
                          id: 'v1',
                          recordId: 'rec-1',
                          fieldId: 'title',
                          value:
                              'An Exceptionally Long Record Title That Must Not Cause Horizontal Overflow Under Narrow Bounds',
                        ),
                      },
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                    fields: [
                      FieldDefinition(
                        id: 'title',
                        databaseId: 'long-db-id',
                        name: 'Title',
                        type: FieldType.text,
                        position: 0,
                        isRequired: true,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    ],
                    onTap: () {},
                    onDelete: () {},
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verification: No exception thrown, widgets render properly
        expect(tester.takeException(), isNull);
        expect(find.byType(DatabaseCard), findsOneWidget);
        expect(find.byType(RecordCard), findsOneWidget);
      },
    );

    test('7. DatabaseListController rejects whitespace-only names', () async {
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWith((ref) => db)],
      );
      addTearDown(container.dispose);

      final ctrl = container.read(databaseListControllerProvider.notifier);

      expect(
        () => ctrl.createDatabase(name: '   '),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => ctrl.updateDatabase(testDb, name: '\t\n   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    testWidgets(
      '8. Choice Field Option Deduplication & Inline Error Clearing on Typing',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: FieldFormScreen(databaseId: testDbId)),
          ),
        );
        await tester.pumpAndSettle();

        // Select 'Choice' type via SegmentedButton
        await tester.tap(find.text('Choice'));
        await tester.pumpAndSettle();

        // Add an option: "Active"
        final optionInput = find.widgetWithText(TextField, 'New Option');
        expect(optionInput, findsOneWidget);
        await tester.enterText(optionInput, 'Active');
        await tester.pumpAndSettle();

        final addOptionBtn = find.byTooltip('Add Option');
        await tester.tap(addOptionBtn);
        await tester.pumpAndSettle();

        // Option "Active" should now be added as chip
        expect(find.text('Active'), findsOneWidget);

        // Try adding "active" (case-insensitive duplicate)
        await tester.enterText(optionInput, 'active');
        await tester.pumpAndSettle();
        await tester.tap(addOptionBtn);
        await tester.pumpAndSettle();

        // Should display duplicate error
        expect(find.text('Option already added'), findsOneWidget);

        // Now type in the input: error should clear
        await tester.enterText(optionInput, 'Inactive');
        await tester.pumpAndSettle();

        expect(find.text('Option already added'), findsNothing);
      },
    );

    test(
      '9. Optional Integer and Decimal Fallback Parsing in Record Controller',
      () async {
        final intField = FieldDefinition(
          id: const Uuid().v4(),
          databaseId: testDbId,
          name: 'Optional Count',
          type: FieldType.integer,
          position: 1,
          isRequired: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final decField = FieldDefinition(
          id: const Uuid().v4(),
          databaseId: testDbId,
          name: 'Optional Price',
          type: FieldType.decimal,
          position: 2,
          isRequired: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await schemaRepo.createField(intField);
        await schemaRepo.createField(decField);

        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWith((ref) => db)],
        );
        addTearDown(container.dispose);

        final ctrl = container.read(
          recordListControllerProvider(testDbId).notifier,
        );

        // Save with empty/null optional numeric fields
        await ctrl.saveRecord(
          fields: [testField, intField, decField],
          rawValues: {
            testField.id: 'Product A',
            intField.id: '',
            decField.id: '',
          },
        );

        final records = await container.read(
          recordListControllerProvider(testDbId).future,
        );
        expect(records.length, 1);
        expect(records.first.values[intField.id]?.value, 0);
        expect(records.first.values[decField.id]?.value, 0.0);
      },
    );

    test(
      '10. ExportController sanitizeFileName handles symbols and length',
      () {
        expect(
          ExportController.sanitizeFileName('My Database / 2026 : Final!'),
          equals('My_Database_2026_Final'),
        );
        expect(ExportController.sanitizeFileName(''), equals('database'));
        expect(ExportController.sanitizeFileName('___'), equals('database'));
        final veryLong = 'A' * 100;
        expect(ExportController.sanitizeFileName(veryLong).length, equals(50));
      },
    );
  });
}
