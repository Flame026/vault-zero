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
    databaseFactory = databaseFactoryFfi;
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
        configuration: const ChoiceConfig(options: ['Bronze', 'Silver', 'Gold']),
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

  Widget buildTestWidget({Record? initialRecord}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) => db),
      ],
      child: MaterialApp(
        home: RecordFormScreen(
          databaseId: testDbId,
          fields: testFields,
          initialRecord: initialRecord,
        ),
      ),
    );
  }

  testWidgets('RecordFormScreen renders DynamicFieldInputs for text, boolean, and choice fields', (tester) async {
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
  });

  testWidgets('RecordFormScreen populates existing record values in edit mode', (tester) async {
    final existingRecord = Record(
      id: 'rec_1',
      databaseId: testDbId,
      values: {
        'f_name': TextFieldValue(id: 'v1', recordId: 'rec_1', fieldId: 'f_name', value: 'Widget Alpha'),
        'f_active': BooleanFieldValue(id: 'v2', recordId: 'rec_1', fieldId: 'f_active', value: true),
        'f_tier': ChoiceFieldValue(id: 'v3', recordId: 'rec_1', fieldId: 'f_tier', value: 'Silver'),
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
  });

  testWidgets('RecordFormScreen validates required fields on save', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap Save without entering required Item Name
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsOneWidget);
  });

  testWidgets('RecordFormScreen saves valid record into repository', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Enter required Item Name
    await tester.enterText(find.widgetWithText(TextFormField, 'Item Name'), 'Mechanical Keyboard');
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
    expect((records.first.values['f_name'] as TextFieldValue).value, 'Mechanical Keyboard');
    expect((records.first.values['f_active'] as BooleanFieldValue).value, true);
  });
}
