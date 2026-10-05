import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:vault_zero/core/database/database_provider.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/data/repositories/sqlite_schema_repository.dart';
import 'package:vault_zero/presentation/fields/field_form_screen.dart';

void main() {
  late Database db;
  late String testDbId;

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
        },
      ),
    );

    testDbId = const Uuid().v4();
    final repo = SqliteSchemaRepository(db);
    await repo.createDatabase(
      DatabaseDefinition(
        id: testDbId,
        name: 'Test DB',
        description: '',
        fields: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestWidget({FieldDefinition? initialField}) {
    return ProviderScope(
      overrides: [databaseProvider.overrideWith((ref) => db)],
      child: MaterialApp(
        home: FieldFormScreen(databaseId: testDbId, initialField: initialField),
      ),
    );
  }

  testWidgets('FieldFormScreen renders creation mode with 3 field types', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('New Field'), findsOneWidget);
    expect(find.text('Field Name'), findsOneWidget);
    expect(find.text('Required Field'), findsOneWidget);

    // Verify 3 constitutional types are available
    expect(find.text('Text'), findsOneWidget);
    expect(find.text('Yes/No'), findsOneWidget);
    expect(find.text('Choice'), findsOneWidget);

    // Choice options section is NOT shown by default (Text is default)
    expect(find.text('Choice Options'), findsNothing);
  });

  testWidgets(
    'Selecting Choice reveals options manager, allows adding and deleting options',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Choice segment
      await tester.tap(find.text('Choice'));
      await tester.pumpAndSettle();

      // Choice options section is now visible
      expect(find.text('Choice Options'), findsOneWidget);
      expect(
        find.text('No options added yet. Add at least one option above.'),
        findsOneWidget,
      );

      // Add option 1
      final optionField = find.widgetWithText(TextField, 'New Option');
      expect(optionField, findsOneWidget);
      await tester.enterText(optionField, 'High Priority');
      await tester.tap(find.byTooltip('Add Option'));
      await tester.pumpAndSettle();

      expect(find.text('High Priority'), findsOneWidget);
      expect(
        find.text('No options added yet. Add at least one option above.'),
        findsNothing,
      );

      // Add option 2
      await tester.enterText(optionField, 'Low Priority');
      await tester.tap(find.byTooltip('Add Option'));
      await tester.pumpAndSettle();

      expect(find.text('Low Priority'), findsOneWidget);

      // Prevent duplicate option
      await tester.enterText(optionField, 'high priority');
      await tester.tap(find.byTooltip('Add Option'));
      await tester.pumpAndSettle();

      expect(find.text('Option already added'), findsOneWidget);

      // Delete first option
      final deleteChipIcon = find.descendant(
        of: find.widgetWithText(InputChip, 'High Priority'),
        matching: find.byIcon(Icons.clear),
      );
      expect(deleteChipIcon, findsOneWidget);
      await tester.tap(deleteChipIcon);
      await tester.pumpAndSettle();

      expect(find.text('High Priority'), findsNothing);
      expect(find.text('Low Priority'), findsOneWidget);
    },
  );

  testWidgets('FieldFormScreen in edit mode locks field type', (tester) async {
    final existingField = FieldDefinition(
      id: const Uuid().v4(),
      databaseId: testDbId,
      name: 'Status',
      type: FieldType.choice,
      position: 0,
      isRequired: true,
      configuration: const ChoiceConfig(options: ['Open', 'Closed']),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(buildTestWidget(initialField: existingField));
    await tester.pumpAndSettle();

    expect(find.text('Edit Field'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(
      find.text('Field type cannot be changed after creation'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

    // SegmentedButton is not displayed in edit mode
    expect(find.byType(SegmentedButton<FieldType>), findsNothing);

    // Choice options are still editable
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('2 options'), findsOneWidget);
  });

  testWidgets(
    'FieldFormScreen updates option count badge and supports clearing inputs',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Choice
      await tester.tap(find.text('Choice'));
      await tester.pumpAndSettle();

      expect(find.text('0 options'), findsOneWidget);

      final optionField = find.widgetWithText(TextField, 'New Option');
      await tester.enterText(optionField, 'Draft');
      await tester.pumpAndSettle();

      // Clear button appears
      expect(find.byTooltip('Clear option text'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear option text'));
      await tester.pumpAndSettle();

      expect(find.text('Draft'), findsNothing);
      expect(find.byTooltip('Clear option text'), findsNothing);

      // Enter option and add
      await tester.enterText(optionField, 'Published');
      await tester.tap(find.byTooltip('Add Option'));
      await tester.pumpAndSettle();

      expect(find.text('1 option'), findsOneWidget);
    },
  );

  testWidgets('FieldFormScreen warns before discarding unsaved changes', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Enter text into Field Name
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Field Name'),
      'Priority',
    );
    await tester.pumpAndSettle();

    // Tap Cancel in AppBar
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    // Confirmation dialog should appear
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.text('Keep Editing'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);

    // Tap Keep Editing
    await tester.tap(find.text('Keep Editing'));
    await tester.pumpAndSettle();

    // Still on form with input intact
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Priority'), findsOneWidget);
  });
}
