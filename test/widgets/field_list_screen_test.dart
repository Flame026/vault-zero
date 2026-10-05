import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:vault_zero/core/database/database_provider.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/data/repositories/sqlite_schema_repository.dart';
import 'package:vault_zero/presentation/fields/field_list_screen.dart';
import 'package:vault_zero/presentation/fields/widgets/field_card.dart';

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
      child: MaterialApp(home: FieldListScreen(database: database)),
    );
  }

  testWidgets(
    'FieldListScreen displays empty state when database has no fields',
    (tester) async {
      final database = DatabaseDefinition(
        id: testDbId,
        name: 'Empty DB',
        description: '',
        fields: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await schemaRepo.createDatabase(database);

      await tester.pumpWidget(buildTestWidget(database));
      await tester.pumpAndSettle();

      expect(find.text('Empty DB Fields'), findsOneWidget);
      expect(find.text('Database Schema'), findsOneWidget);
      expect(
        find.text(
          "This database has no fields.\nAdd fields to define what you want to track.",
        ),
        findsOneWidget,
      );
      expect(find.text('Add Field'), findsOneWidget);
      expect(find.text('New Field'), findsOneWidget);
    },
  );

  testWidgets(
    'FieldListScreen renders ReorderableListView with fields and allows deletion',
    (tester) async {
      final fields = [
        FieldDefinition(
          id: 'f1',
          databaseId: testDbId,
          name: 'Field Alpha',
          type: FieldType.text,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        FieldDefinition(
          id: 'f2',
          databaseId: testDbId,
          name: 'Field Beta',
          type: FieldType.boolean,
          position: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final database = DatabaseDefinition(
        id: testDbId,
        name: 'Inventory',
        description: '',
        fields: fields,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await schemaRepo.createDatabase(database);

      await tester.pumpWidget(buildTestWidget(database));
      await tester.pumpAndSettle();

      expect(find.text('Inventory Fields'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.byType(FieldCard), findsNWidgets(2));
      expect(find.text('Field Alpha'), findsOneWidget);
      expect(find.text('Field Beta'), findsOneWidget);

      // Open popup menu on first field card
      final popupFinder = find.byIcon(Icons.more_vert_rounded).first;
      await tester.tap(popupFinder);
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Delete Field?'), findsOneWidget);
      expect(find.text('Delete Permanently'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();

      // Field Alpha is now deleted, Field Beta remains
      expect(find.text('Field Alpha'), findsNothing);
      expect(find.text('Field Beta'), findsOneWidget);
    },
  );
}
