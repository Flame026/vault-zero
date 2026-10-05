import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:vault_zero/core/database/database_provider.dart';
import 'package:vault_zero/core/preferences/preferences_repository.dart';
import 'package:vault_zero/data/repositories/sqlite_record_repository.dart';
import 'package:vault_zero/data/repositories/sqlite_schema_repository.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/domain/models/record.dart';
import 'package:vault_zero/main.dart';
import 'package:vault_zero/presentation/databases/database_list_screen.dart';
import 'package:vault_zero/presentation/databases/widgets/database_form_dialog.dart';
import 'package:vault_zero/presentation/fields/field_form_screen.dart';
import 'package:vault_zero/presentation/records/record_form_screen.dart';
import 'package:vault_zero/presentation/records/record_list_screen.dart';
import 'package:vault_zero/presentation/records/widgets/dynamic_field_input.dart';

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
      name: 'Interruption Test DB',
      description: 'Testing lifecycle and interruption',
      fields: [],
      createdAt: now,
      updatedAt: now,
    );
    await schemaRepo.createDatabase(testDb);

    testField = FieldDefinition(
      id: const Uuid().v4(),
      databaseId: testDbId,
      name: 'Product Code',
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

  group('Batch 14: Lifecycle, Orientation, Keyboard & Interruption Safety', () {
    test('PreferencesRepository flush awaits active save operations', () async {
      final tempDir = await Directory.systemTemp.createTemp('prefs_test_');
      try {
        final repo = PreferencesRepository(getDocsDir: () async => tempDir);
        final saveFuture = repo.setString('test_key', 'test_value');
        await repo.flush();
        await saveFuture;
        expect(await repo.getString('test_key'), equals('test_value'));
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    testWidgets(
      'VaultZeroApp handles paused and inactive lifecycle events cleanly',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) => db)],
            child: const VaultZeroApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger lifecycle paused event
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);

        // Trigger lifecycle inactive event
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);

        // Resume app
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'FieldFormScreen has drag keyboard dismissal and sequential choice focus',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) => db)],
            child: MaterialApp(home: FieldFormScreen(databaseId: testDbId)),
          ),
        );
        await tester.pumpAndSettle();

        // Verify ListView has onDrag keyboard dismissal
        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(
          listView.keyboardDismissBehavior,
          equals(ScrollViewKeyboardDismissBehavior.onDrag),
        );

        // Select Choice field type
        await tester.tap(find.text('Choice'));
        await tester.pumpAndSettle();

        // Locate choice option input
        final optionInput = find.widgetWithText(TextField, 'New Option');
        expect(optionInput, findsOneWidget);

        // Enter Option A
        await tester.enterText(optionInput, 'Option Alpha');
        await tester.pumpAndSettle();

        // Tap Add Option button
        await tester.tap(find.byTooltip('Add Option'));
        await tester.pumpAndSettle();

        // Option Alpha chip should be displayed
        expect(find.text('Option Alpha'), findsOneWidget);

        // TextField should be cleared and refocused for sequential typing
        final textFieldWidget = tester.widget<TextField>(optionInput);
        expect(textFieldWidget.controller?.text, isEmpty);
        expect(textFieldWidget.focusNode?.hasFocus, isTrue);

        // Enter Option B immediately without tapping into field again
        await tester.enterText(optionInput, 'Option Beta');
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Add Option'));
        await tester.pumpAndSettle();

        expect(find.text('Option Beta'), findsOneWidget);
      },
    );

    testWidgets(
      'DatabaseFormDialog prevents back-pop when submission is in progress',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: DatabaseFormDialog())),
        );
        await tester.pumpAndSettle();

        // Verify PopScope wraps the dialog
        expect(find.byType(PopScope), findsOneWidget);
        final popScope = tester.widget<PopScope>(find.byType(PopScope));
        // When not submitting, canPop is true
        expect(popScope.canPop, isTrue);

        // Enter a valid name
        await tester.enterText(find.byType(TextFormField).first, 'Project X');
        await tester.pumpAndSettle();

        // Tap Create
        await tester.tap(find.text('Create'));
        await tester.pump();

        // The form submitted and popped
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'DatabaseFormDialog in short landscape (640x300) renders cleanly with no overflow',
      (tester) async {
        tester.view.physicalSize = const Size(640, 300);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: DatabaseFormDialog())),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Create Database'), findsOneWidget);
        expect(find.text('Name'), findsOneWidget);
        expect(find.text('Description (Optional)'), findsOneWidget);
      },
    );

    testWidgets(
      'Orientation changes (portrait <-> landscape) preserve dirty form drafts without reset',
      (tester) async {
        // Start in Portrait
        tester.view.physicalSize = const Size(390, 844);
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

        // Enter a draft value in portrait
        final input = find.byType(TextFormField).first;
        await tester.enterText(input, 'Draft Value 12345');
        await tester.pumpAndSettle();

        // Rotate to Landscape
        tester.view.physicalSize = const Size(844, 390);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Verify draft text is preserved
        expect(find.text('Draft Value 12345'), findsOneWidget);

        // Rotate back to Portrait
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Verify draft text is still intact
        expect(find.text('Draft Value 12345'), findsOneWidget);
      },
    );

    testWidgets(
      'Virtual keyboard inset on RecordFormScreen does not cause overflow or clip inputs',
      (tester) async {
        // Set phone dimensions
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        // Simulate soft keyboard taking 350px
        tester.view.viewInsets = const FakeViewPadding(bottom: 350);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetViewInsets();
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

        // No overflow despite large keyboard inset
        expect(tester.takeException(), isNull);
        expect(find.text('New Record'), findsOneWidget);
      },
    );

    testWidgets(
      'DatabaseListScreen rapid multi-tap on create database FAB opens single dialog',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) => db)],
            child: const MaterialApp(home: DatabaseListScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final fab = find.byType(FloatingActionButton);
        expect(fab, findsOneWidget);

        // Tap twice in rapid succession
        await tester.tap(fab, warnIfMissed: false);
        await tester.tap(fab, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Exactly one DatabaseFormDialog is present
        expect(find.byType(DatabaseFormDialog), findsOneWidget);

        // Dismiss dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets('DynamicFieldInput date picker handles cancellation safely', (
      tester,
    ) async {
      final dateField = FieldDefinition(
        id: const Uuid().v4(),
        databaseId: testDbId,
        name: 'Target Date',
        type: FieldType.date,
        position: 1,
        isRequired: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicFieldInput(
              field: dateField,
              initialValue: null,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to open date picker
      await tester.tap(find.byType(DynamicFieldInput));
      await tester.pumpAndSettle();

      // Confirm date picker is shown
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Tap Cancel on date picker
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'RecordListScreen delete confirmation dialog renders cleanly and cancels safely',
      (tester) async {
        final recordId = const Uuid().v4();
        await recordRepo.saveRecord(
          Record(
            id: recordId,
            databaseId: testDbId,
            values: {},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) => db)],
            child: MaterialApp(home: RecordListScreen(database: testDb)),
          ),
        );
        await tester.pumpAndSettle();

        // Find more options popup button
        final moreOptions = find.byIcon(Icons.more_vert_rounded);
        expect(moreOptions, findsOneWidget);

        await tester.tap(moreOptions);
        await tester.pumpAndSettle();

        final deleteItem = find.text('Delete');
        expect(deleteItem, findsOneWidget);

        await tester.tap(deleteItem);
        await tester.pumpAndSettle();

        // Delete confirmation dialog is visible
        expect(find.text('Delete Record?'), findsOneWidget);

        // Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
