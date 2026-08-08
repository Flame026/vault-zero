import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:character_collector/core/database/database_provider.dart';
import 'package:character_collector/domain/models/database_definition.dart';
import 'package:character_collector/domain/models/field_definition.dart';
import 'package:character_collector/data/repositories/sqlite_schema_repository.dart';
import 'package:character_collector/presentation/records/controllers/record_list_controller.dart';

void main() {
  late ProviderContainer container;
  late Database db;
  late String testDbId;
  late FieldDefinition nameField;
  late FieldDefinition ageField;

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

    nameField = FieldDefinition(
      id: const Uuid().v4(),
      databaseId: testDbId,
      name: 'Name',
      type: FieldType.text,
      position: 0,
      isRequired: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ageField = FieldDefinition(
      id: const Uuid().v4(),
      databaseId: testDbId,
      name: 'Age',
      type: FieldType.integer,
      position: 1,
      isRequired: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.createField(nameField);
    await repo.createField(ageField);

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) => db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('Record list loads successfully (empty initially)', () async {
    final state = await container.read(recordListControllerProvider(testDbId).future);
    expect(state, isEmpty);
  });

  test('Record creation and retrieval works', () async {
    final controller = container.read(recordListControllerProvider(testDbId).notifier);
    
    await controller.saveRecord(
      fields: [nameField, ageField],
      rawValues: {
        nameField.id: 'John Doe',
        ageField.id: 30,
      },
    );

    final state = await container.read(recordListControllerProvider(testDbId).future);
    expect(state.length, 1);
    
    final record = state.first;
    expect(record.databaseId, testDbId);
    expect(record.values[nameField.id]?.value, 'John Doe');
    expect(record.values[ageField.id]?.value, 30);
  });

  test('Record deletion works', () async {
    final controller = container.read(recordListControllerProvider(testDbId).notifier);
    
    await controller.saveRecord(
      fields: [nameField],
      rawValues: {nameField.id: 'To Be Deleted'},
    );

    var state = await container.read(recordListControllerProvider(testDbId).future);
    expect(state.length, 1);
    
    final recordId = state.first.id;
    await controller.deleteRecord(recordId);

    state = await container.read(recordListControllerProvider(testDbId).future);
    expect(state, isEmpty);
  });
}
