import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:vault_zero/core/database/database_provider.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/data/repositories/sqlite_schema_repository.dart';
import 'package:vault_zero/presentation/fields/controllers/field_list_controller.dart';

void main() {
  late ProviderContainer container;
  late Database db;
  late String testDbId;

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

  test('Field list loads successfully (empty initially)', () async {
    final state = await container.read(fieldListControllerProvider(testDbId).future);
    expect(state, isEmpty);
  });

  test('Field creation works and enforces position', () async {
    final controller = container.read(fieldListControllerProvider(testDbId).notifier);
    await container.read(fieldListControllerProvider(testDbId).future);

    await controller.createField(
      name: 'Field 1',
      type: FieldType.text,
      isRequired: true,
    );

    var state = await container.read(fieldListControllerProvider(testDbId).future);
    expect(state.length, 1);
    expect(state.first.name, 'Field 1');
    expect(state.first.position, 0);

    await controller.createField(
      name: 'Field 2',
      type: FieldType.integer,
      isRequired: false,
    );

    state = await container.read(fieldListControllerProvider(testDbId).future);
    expect(state.length, 2);
    expect(state[1].name, 'Field 2');
    expect(state[1].position, 1);
  });

  test('Field uniqueness validation', () async {
    final controller = container.read(fieldListControllerProvider(testDbId).notifier);
    await container.read(fieldListControllerProvider(testDbId).future);

    await controller.createField(name: 'Duplicate Me', type: FieldType.text, isRequired: false);

    expect(controller.isNameUnique('Duplicate Me'), false);
    expect(controller.isNameUnique('duplicate me '), false); // Checks case insensitivity and trim
    expect(controller.isNameUnique('New Field'), true);
  });

  test('Field reordering works comprehensively', () async {
    final controller = container.read(fieldListControllerProvider(testDbId).notifier);
    await container.read(fieldListControllerProvider(testDbId).future);

    await controller.createField(name: 'A', type: FieldType.text, isRequired: false);
    await controller.createField(name: 'B', type: FieldType.text, isRequired: false);
    await controller.createField(name: 'C', type: FieldType.text, isRequired: false);
    await controller.createField(name: 'D', type: FieldType.text, isRequired: false);
    await controller.createField(name: 'E', type: FieldType.text, isRequired: false);

    // Initial: A=0, B=1, C=2, D=3, E=4

    // 1. Moving an item downward: Move B(1) below C(2). ReorderableListView gives newIndex=3
    await controller.reorderFields(1, 3);
    await Future.delayed(Duration.zero);
    var state = await container.read(fieldListControllerProvider(testDbId).future);
    expect(state.map((e) => e.name).toList(), ['A', 'C', 'B', 'D', 'E']);
    for (int i = 0; i < state.length; i++) {
      expect(state[i].position, i);
    }

    // 2. Moving an item upward: Move D(3) above C(1). ReorderableListView gives newIndex=1
    await controller.reorderFields(3, 1);
    await Future.delayed(Duration.zero);
    state = await container.read(fieldListControllerProvider(testDbId).future);
    expect(state.map((e) => e.name).toList(), ['A', 'D', 'C', 'B', 'E']);
    for (int i = 0; i < state.length; i++) {
      expect(state[i].position, i);
    }

    // 3. Moving first -> last: Move A(0) below E(4). ReorderableListView gives newIndex=5
    await controller.reorderFields(0, 5);
    await Future.delayed(Duration.zero);
    state = await container.read(fieldListControllerProvider(testDbId).future);
    expect(state.map((e) => e.name).toList(), ['D', 'C', 'B', 'E', 'A']);
    for (int i = 0; i < state.length; i++) {
      expect(state[i].position, i);
    }

    // 4. Moving last -> first: Move A(4) above D(0). ReorderableListView gives newIndex=0
    await controller.reorderFields(4, 0);
    await Future.delayed(Duration.zero);
    state = await container.read(fieldListControllerProvider(testDbId).future);
    expect(state.map((e) => e.name).toList(), ['A', 'D', 'C', 'B', 'E']);
    for (int i = 0; i < state.length; i++) {
      expect(state[i].position, i);
    }
  });
}
