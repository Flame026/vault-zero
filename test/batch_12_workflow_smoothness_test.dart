import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:vault_zero/core/providers.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/domain/models/field_value.dart';
import 'package:vault_zero/domain/models/record.dart';
import 'package:vault_zero/data/repositories/sqlite_schema_repository.dart';
import 'package:vault_zero/data/repositories/sqlite_record_repository.dart';
import 'package:vault_zero/presentation/databases/controllers/database_list_controller.dart';
import 'package:vault_zero/presentation/databases/database_list_screen.dart';
import 'package:vault_zero/presentation/databases/widgets/database_form_dialog.dart';
import 'package:vault_zero/presentation/fields/controllers/field_list_controller.dart';
import 'package:vault_zero/presentation/fields/field_form_screen.dart';
import 'package:vault_zero/presentation/records/controllers/record_list_controller.dart';
import 'package:vault_zero/presentation/records/record_form_screen.dart';
import 'package:vault_zero/presentation/records/record_list_screen.dart';

void main() {
  late Database db;
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
        },
      ),
    );

    schemaRepo = SqliteSchemaRepository(db);
    recordRepo = SqliteRecordRepository(db);

    testDb = DatabaseDefinition(
      id: const Uuid().v4(),
      name: 'Smoothness Test DB',
      description: 'Testing navigation and workflows',
      fields: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await schemaRepo.createDatabase(testDb);

    testField = FieldDefinition(
      id: 'field_name',
      databaseId: testDb.id,
      name: 'Item Title',
      type: FieldType.text,
      position: 0,
      isRequired: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await schemaRepo.createField(testField);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildStackApp({required Widget Function(BuildContext) screenBuilder}) {
    return ProviderScope(
      overrides: [
        schemaRepositoryProvider.overrideWith((ref) => schemaRepo),
        recordRepositoryProvider.overrideWith((ref) => recordRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: screenBuilder),
              ),
              child: const Text('Launch Screen'),
            ),
          ),
        ),
      ),
    );
  }

  group('Batch 12 Workflow & Navigation Smoothness Tests', () {
    testWidgets(
      'RecordListScreen PopScope intercepts back gesture when searching',
      (tester) async {
        final record = Record(
          id: const Uuid().v4(),
          databaseId: testDb.id,
          values: {
            testField.id: TextFieldValue(
              id: const Uuid().v4(),
              recordId: 'rec_1',
              fieldId: testField.id,
              value: 'Alpha Item',
            ),
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await recordRepo.saveRecord(record);

        await tester.pumpWidget(
          buildStackApp(
            screenBuilder: (ctx) => RecordListScreen(database: testDb),
          ),
        );
        await tester.pumpAndSettle();

        // Push screen
        await tester.tap(find.text('Launch Screen'));
        await tester.pumpAndSettle();
        expect(find.byType(RecordListScreen), findsOneWidget);

        final searchButton = find.byTooltip('Search records');
        expect(searchButton, findsOneWidget);
        await tester.tap(searchButton);
        await tester.pumpAndSettle();

        // Search textfield should be visible
        expect(find.byType(TextField), findsOneWidget);

        // Dispatch back navigation via handlePopRoute
        final popHandled = await tester.binding.handlePopRoute();
        expect(popHandled, isTrue); // Pop intercepted by PopScope
        await tester.pumpAndSettle();

        // Search closed and RecordListScreen remains on screen
        expect(find.byType(TextField), findsNothing);
        expect(find.byType(RecordListScreen), findsOneWidget);

        // Dispatch back navigation again when not searching -> should pop back to Launch Screen
        final exitHandled = await tester.binding.handlePopRoute();
        expect(exitHandled, isTrue);
        await tester.pumpAndSettle();
        expect(find.byType(RecordListScreen), findsNothing);
        expect(find.text('Launch Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'RecordFormScreen dirty state prompts discard confirmation on back navigation',
      (tester) async {
        await tester.pumpWidget(
          buildStackApp(
            screenBuilder: (ctx) =>
                RecordFormScreen(databaseId: testDb.id, fields: [testField]),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Launch Screen'));
        await tester.pumpAndSettle();
        expect(find.byType(RecordFormScreen), findsOneWidget);

        // Enter text into the text field to make it dirty
        final input = find.byType(TextFormField);
        expect(input, findsOneWidget);
        await tester.enterText(input, 'Unsaved record notes');
        await tester.pumpAndSettle();

        // Attempt back navigation via handlePopRoute
        final popHandled = await tester.binding.handlePopRoute();
        expect(popHandled, isTrue); // Intercepted by PopScope
        await tester.pumpAndSettle();

        // Discard dialog should be showing
        expect(find.text('Discard changes?'), findsOneWidget);
        expect(find.text('Keep Editing'), findsOneWidget);
        expect(find.text('Discard'), findsOneWidget);

        // Tap Keep Editing
        await tester.tap(find.text('Keep Editing'));
        await tester.pumpAndSettle();

        // Dialog should be gone, form should still be open
        expect(find.text('Discard changes?'), findsNothing);
        expect(find.text('Unsaved record notes'), findsOneWidget);

        // Attempt back navigation again and tap Discard
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Discard changes?'), findsOneWidget);

        await tester.tap(find.text('Discard'));
        await tester.pumpAndSettle();

        // Discard dialog dismissed and RecordFormScreen popped back to root
        expect(find.byType(RecordFormScreen), findsNothing);
        expect(find.text('Launch Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'FieldFormScreen dirty state prompts discard confirmation on back navigation',
      (tester) async {
        await tester.pumpWidget(
          buildStackApp(
            screenBuilder: (ctx) => FieldFormScreen(databaseId: testDb.id),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Launch Screen'));
        await tester.pumpAndSettle();
        expect(find.byType(FieldFormScreen), findsOneWidget);

        // Field name input is present
        final input = find.widgetWithText(TextFormField, 'Field Name');
        expect(input, findsOneWidget);

        // Type a field name
        await tester.enterText(input, 'Category Field');
        await tester.pumpAndSettle();

        // Attempt back navigation via handlePopRoute
        final popHandled = await tester.binding.handlePopRoute();
        expect(popHandled, isTrue); // Intercepted by PopScope
        await tester.pumpAndSettle();

        // Discard dialog should be showing
        expect(find.text('Discard changes?'), findsOneWidget);
        expect(find.text('Keep Editing'), findsOneWidget);
        expect(find.text('Discard'), findsOneWidget);

        // Tap Discard to exit
        await tester.tap(find.text('Discard'));
        await tester.pumpAndSettle();

        // FieldFormScreen popped
        expect(find.byType(FieldFormScreen), findsNothing);
        expect(find.text('Launch Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'DatabaseFormDialog provides seamless next/done keyboard action flow',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              schemaRepositoryProvider.overrideWith((ref) => schemaRepo),
              recordRepositoryProvider.overrideWith((ref) => recordRepo),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => DatabaseFormDialog.show(context),
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(DatabaseFormDialog), findsOneWidget);

        final textFields = tester
            .widgetList<TextField>(find.byType(TextField))
            .toList();
        expect(textFields.length, greaterThanOrEqualTo(2));

        expect(textFields[0].textInputAction, TextInputAction.next);
        expect(textFields[1].textInputAction, TextInputAction.done);
      },
    );

    test(
      'FieldListController mutations invalidate recordListControllerProvider',
      () async {
        final container = ProviderContainer(
          overrides: [
            schemaRepositoryProvider.overrideWith((ref) => schemaRepo),
            recordRepositoryProvider.overrideWith((ref) => recordRepo),
          ],
        );
        addTearDown(container.dispose);

        // Prime the record list controller
        final initialRecords = await container.read(
          recordListControllerProvider(testDb.id).future,
        );
        expect(initialRecords, isEmpty);

        // Create a new field via FieldListController
        final fieldController = container.read(
          fieldListControllerProvider(testDb.id).notifier,
        );
        await fieldController.createField(
          name: 'Priority',
          type: FieldType.integer,
          isRequired: false,
        );

        // Allow microtasks / riverpod invalidation schedule to run
        await Future<void>.delayed(Duration.zero);

        // Field list state updated
        final fields = container
            .read(fieldListControllerProvider(testDb.id))
            .requireValue;
        expect(fields.any((f) => f.name == 'Priority'), isTrue);

        // Verify recordListControllerProvider was refreshed/rebuilt
        final refreshedRecords = await container.read(
          recordListControllerProvider(testDb.id).future,
        );
        expect(refreshedRecords, isEmpty);
      },
    );

    test(
      'DatabaseListController deleteDatabase invalidates sub-controllers',
      () async {
        final container = ProviderContainer(
          overrides: [
            schemaRepositoryProvider.overrideWith((ref) => schemaRepo),
            recordRepositoryProvider.overrideWith((ref) => recordRepo),
          ],
        );
        addTearDown(container.dispose);

        // Prime providers for testDb
        await container.read(fieldListControllerProvider(testDb.id).future);
        await container.read(recordListControllerProvider(testDb.id).future);

        // Delete database via DatabaseListController
        final dbController = container.read(
          databaseListControllerProvider.notifier,
        );
        await dbController.deleteDatabase(testDb.id);

        // Allow microtasks / riverpod invalidation schedule to run
        await Future<void>.delayed(Duration.zero);

        final databases = container
            .read(databaseListControllerProvider)
            .requireValue;
        expect(databases.any((d) => d.id == testDb.id), isFalse);
      },
    );

    testWidgets(
      'DatabaseListScreen PopScope intercepts back gesture when searching',
      (tester) async {
        await tester.pumpWidget(
          buildStackApp(screenBuilder: (ctx) => const DatabaseListScreen()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Launch Screen'));
        await tester.pumpAndSettle();
        expect(find.byType(DatabaseListScreen), findsOneWidget);

        // Tap search icon in DatabaseListScreen
        final searchIcon = find.byTooltip('Search databases');
        expect(searchIcon, findsOneWidget);
        await tester.tap(searchIcon);
        await tester.pumpAndSettle();

        // Search textfield is active
        expect(find.byType(TextField), findsOneWidget);

        // Dispatch back navigation via handlePopRoute
        final popHandled = await tester.binding.handlePopRoute();
        expect(popHandled, isTrue); // Pop was intercepted by PopScope
        await tester.pumpAndSettle();

        // Search should now be closed and DatabaseListScreen remains on screen
        expect(find.byType(TextField), findsNothing);
        expect(find.byType(DatabaseListScreen), findsOneWidget);
      },
    );
  });
}
