import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:vault_zero/core/database/database_provider.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/domain/models/field_value.dart';
import 'package:vault_zero/domain/models/record.dart';
import 'package:vault_zero/data/repositories/sqlite_schema_repository.dart';
import 'package:vault_zero/data/repositories/sqlite_record_repository.dart';
import 'package:vault_zero/presentation/records/record_form_screen.dart';
import 'package:vault_zero/presentation/records/widgets/dynamic_field_input.dart';

void main() {
  late Database db;
  late String testDbId;
  late List<FieldDefinition> testFields;

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

    testDbId = const Uuid().v4();
    final repo = SqliteSchemaRepository(db);
    testFields = [
      FieldDefinition(
        id: 'f_name',
        databaseId: testDbId,
        name: 'Item Name',
        type: FieldType.text,
        position: 0,
        isRequired: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      FieldDefinition(
        id: 'f_active',
        databaseId: testDbId,
        name: 'Is Active',
        type: FieldType.boolean,
        position: 1,
        isRequired: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      FieldDefinition(
        id: 'f_tier',
        databaseId: testDbId,
        name: 'Tier',
        type: FieldType.choice,
        position: 2,
        isRequired: false,
        configuration: const ChoiceConfig(
          options: ['Bronze', 'Silver', 'Gold'],
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await repo.createDatabase(
      DatabaseDefinition(
        id: testDbId,
        name: 'Inventory',
        description: '',
        fields: testFields,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestWidget({
    Record? initialRecord,
    List<FieldDefinition>? fields,
  }) {
    return ProviderScope(
      overrides: [databaseProvider.overrideWith((ref) => db)],
      child: MaterialApp(
        home: RecordFormScreen(
          databaseId: testDbId,
          fields: fields ?? testFields,
          initialRecord: initialRecord,
        ),
      ),
    );
  }

  testWidgets(
    'RecordFormScreen renders DynamicFieldInputs for text, boolean, and choice fields',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('New Record'), findsOneWidget);
      expect(find.byType(DynamicFieldInput), findsNWidgets(3));

      // Text field
      expect(find.text('Item Name'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);

      // Boolean field
      expect(find.text('Is Active'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);

      // Choice field
      expect(find.text('Tier'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    },
  );

  testWidgets(
    'RecordFormScreen populates existing record values in edit mode',
    (tester) async {
      final existingRecord = Record(
        id: 'rec_1',
        databaseId: testDbId,
        values: {
          'f_name': TextFieldValue(
            id: 'v1',
            recordId: 'rec_1',
            fieldId: 'f_name',
            value: 'Widget Alpha',
          ),
          'f_active': BooleanFieldValue(
            id: 'v2',
            recordId: 'rec_1',
            fieldId: 'f_active',
            value: true,
          ),
          'f_tier': ChoiceFieldValue(
            id: 'v3',
            recordId: 'rec_1',
            fieldId: 'f_tier',
            value: 'Silver',
          ),
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestWidget(initialRecord: existingRecord));
      await tester.pumpAndSettle();

      expect(find.text('Edit Record'), findsOneWidget);
      expect(find.text('Widget Alpha'), findsOneWidget);

      // Verify boolean switch state is true
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, true);

      // Verify choice dropdown value is 'Silver'
      expect(find.text('Silver'), findsOneWidget);
    },
  );

  testWidgets('RecordFormScreen validates required fields on save', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap Save without entering required Item Name
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsOneWidget);
  });

  testWidgets('RecordFormScreen saves valid record into repository', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Enter required Item Name
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item Name'),
      'Mechanical Keyboard',
    );
    await tester.pumpAndSettle();

    // Toggle Active switch
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final recordRepo = SqliteRecordRepository(db);
    final records = await recordRepo.getRecordsForDatabase(testDbId);
    expect(records.length, 1);
    expect(
      (records.first.values['f_name'] as TextFieldValue).value,
      'Mechanical Keyboard',
    );
    expect((records.first.values['f_active'] as BooleanFieldValue).value, true);
  });

  testWidgets('RecordFormScreen allows clearing an optional date field', (
    tester,
  ) async {
    final dateField = FieldDefinition(
      id: 'f_date',
      databaseId: testDbId,
      name: 'Release Date',
      type: FieldType.date,
      position: 3,
      isRequired: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final recordId = const Uuid().v4();
    final initialDate = DateTime(2025, 5, 20);
    final initialRecord = Record(
      id: recordId,
      databaseId: testDbId,
      values: {
        'f_name': TextFieldValue(
          id: const Uuid().v4(),
          recordId: recordId,
          fieldId: 'f_name',
          value: 'Widget Alpha',
        ),
        'f_date': DateFieldValue(
          id: const Uuid().v4(),
          recordId: recordId,
          fieldId: 'f_date',
          value: initialDate,
        ),
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final schemaRepo = SqliteSchemaRepository(db);
    await schemaRepo.createField(dateField);
    final recordRepo = SqliteRecordRepository(db);
    await recordRepo.saveRecord(initialRecord);

    await tester.pumpWidget(
      buildTestWidget(
        initialRecord: initialRecord,
        fields: [...testFields, dateField],
      ),
    );
    await tester.pumpAndSettle();

    // Verify clear button exists for Release Date
    final clearBtn = find.byTooltip('Clear Release Date');
    expect(clearBtn, findsOneWidget);

    // Tap clear
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    // Clear button should be gone since value is now null
    expect(find.byTooltip('Clear Release Date'), findsNothing);

    // Save
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final saved = await recordRepo.getRecord(recordId);
    expect(saved, isNotNull);
  });

  testWidgets('RecordFormScreen warns before discarding unsaved changes', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Enter some text into Item Name
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item Name'),
      'Unsaved Work',
    );
    await tester.pumpAndSettle();

    // Tap Cancel in AppBar
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    // Discard confirmation dialog should appear
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.text('Keep Editing'), findsOneWidget);

    // Tap Keep Editing
    await tester.tap(find.text('Keep Editing'));
    await tester.pumpAndSettle();

    // Still on form with text preserved
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Unsaved Work'), findsOneWidget);
  });

  testWidgets(
    'RecordFormScreen displays required indicators and prefix icons on fields',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 'Item Name' is required, should have 'Required' helper text and text_fields icon
      expect(find.text('Required'), findsOneWidget);
      expect(find.byIcon(Icons.text_fields_rounded), findsOneWidget);

      // 'Is Active' has toggle icon
      expect(find.byIcon(Icons.toggle_on_outlined), findsOneWidget);

      // 'Tier' has choice list icon
      expect(find.byIcon(Icons.list_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'RecordFormScreen shows quick-clear button when text field has content and clears on tap',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Initially no clear button
      expect(find.byTooltip('Clear Item Name'), findsNothing);

      // Enter text
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Item Name'),
        'Temporary Input',
      );
      await tester.pumpAndSettle();

      // Clear button should now be visible
      expect(find.byTooltip('Clear Item Name'), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byTooltip('Clear Item Name'));
      await tester.pumpAndSettle();

      // Text should be cleared and clear button hidden
      expect(find.text('Temporary Input'), findsNothing);
      expect(find.byTooltip('Clear Item Name'), findsNothing);
    },
  );

  testWidgets(
    'RecordFormScreen does NOT autofocus or focus any field when editing an existing record',
    (tester) async {
      final existingRecord = Record(
        id: 'rec_1',
        databaseId: testDbId,
        values: {
          'f_name': const TextFieldValue(
            id: 'v1',
            recordId: 'rec_1',
            fieldId: 'f_name',
            value: 'Existing Item',
          ),
          'f_active': const BooleanFieldValue(
            id: 'v2',
            recordId: 'rec_1',
            fieldId: 'f_active',
            value: true,
          ),
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestWidget(initialRecord: existingRecord));
      await tester.pumpAndSettle();

      // Verify all dynamic inputs have autofocus set to false
      final dynamicInputs = tester.widgetList<DynamicFieldInput>(
        find.byType(DynamicFieldInput),
      );
      for (final input in dynamicInputs) {
        expect(input.autofocus, isFalse);
      }

      // Verify no text field was forcibly focused
      final focusScope = FocusScope.of(
        tester.element(find.byType(RecordFormScreen)),
      );
      expect(focusScope.focusedChild, isNull);
    },
  );

  testWidgets(
    'RecordFormScreen DOES autofocus the first field when creating a new record',
    (tester) async {
      await tester.pumpWidget(buildTestWidget(initialRecord: null));
      await tester.pumpAndSettle();

      final firstInput = tester.widget<DynamicFieldInput>(
        find.byType(DynamicFieldInput).first,
      );
      expect(firstInput.autofocus, isTrue);
    },
  );
}
