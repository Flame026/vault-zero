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
import 'package:vault_zero/presentation/records/record_list_screen.dart';

void main() {
  late Database db;
  late String testDbId;
  late SqliteSchemaRepository schemaRepo;

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
    schemaRepo = SqliteSchemaRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestWidget(DatabaseDefinition database) {
    return ProviderScope(
      overrides: [databaseProvider.overrideWith((ref) => db)],
      child: MaterialApp(home: RecordListScreen(database: database)),
    );
  }

  testWidgets(
    'RecordListScreen displays No Fields state when database has no fields',
    (tester) async {
      final database = DatabaseDefinition(
        id: testDbId,
        name: 'Empty Inventory',
        description: '',
        fields: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await schemaRepo.createDatabase(database);

      await tester.pumpWidget(buildTestWidget(database));
      await tester.pumpAndSettle();

      expect(find.text('Empty Inventory'), findsOneWidget);
      expect(find.text('No Fields Defined'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Manage Fields'),
        findsOneWidget,
      );
      expect(find.text('0 records'), findsNothing);
    },
  );

  testWidgets(
    'RecordListScreen displays actionable No Records state when fields exist but no records',
    (tester) async {
      final field = FieldDefinition(
        id: 'f1',
        databaseId: testDbId,
        name: 'Item Title',
        type: FieldType.text,
        position: 0,
        isRequired: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final database = DatabaseDefinition(
        id: testDbId,
        name: 'Catalog',
        description: '',
        fields: [field],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await schemaRepo.createDatabase(database);

      await tester.pumpWidget(buildTestWidget(database));
      await tester.pumpAndSettle();

      expect(find.text('No Records'), findsOneWidget);
      expect(find.text('0 records'), findsOneWidget);
      expect(
        find.text(
          'No records found. Tap + or Add Record below to create your first record.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Add Record'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    },
  );

  testWidgets('Record search and sort controls work correctly', (tester) async {
    final field = FieldDefinition(
      id: 'f1',
      databaseId: testDbId,
      name: 'Title',
      type: FieldType.text,
      position: 0,
      isRequired: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final database = DatabaseDefinition(
      id: testDbId,
      name: 'Library',
      description: '',
      fields: [field],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await schemaRepo.createDatabase(database);

    final recordRepo = SqliteRecordRepository(db);
    final record1 = Record(
      id: 'r1',
      databaseId: testDbId,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      values: {
        'f1': const TextFieldValue(
          id: 'v1',
          recordId: 'r1',
          fieldId: 'f1',
          value: 'Apple',
        ),
      },
    );
    final record2 = Record(
      id: 'r2',
      databaseId: testDbId,
      createdAt: DateTime(2025, 1, 2),
      updatedAt: DateTime(2025, 1, 2),
      values: {
        'f1': const TextFieldValue(
          id: 'v2',
          recordId: 'r2',
          fieldId: 'f1',
          value: 'Banana',
        ),
      },
    );
    await recordRepo.saveRecord(record1);
    await recordRepo.saveRecord(record2);

    await tester.pumpWidget(buildTestWidget(database));
    await tester.pumpAndSettle();

    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('2 records'), findsOneWidget);

    // Tap search icon
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    // Enter query
    await tester.enterText(find.byType(TextField), 'app');
    await tester.pumpAndSettle();

    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Banana'), findsNothing);

    // Search no match
    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pumpAndSettle();

    expect(find.text('No Records Found'), findsOneWidget);
    expect(find.text('Clear Search'), findsOneWidget);

    // Clear search
    await tester.tap(find.text('Clear Search'));
    await tester.pumpAndSettle();

    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);

    // Close search
    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();

    // Verify sort button is present
    expect(find.byTooltip('Sort records'), findsOneWidget);
    await tester.tap(find.byTooltip('Sort records'));
    await tester.pumpAndSettle();

    expect(find.text('Newest first'), findsOneWidget);
    expect(find.text('Oldest first'), findsOneWidget);
    expect(find.text('Title (A–Z)'), findsOneWidget);
    expect(find.text('Title (Z–A)'), findsOneWidget);
  });
}
