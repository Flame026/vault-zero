import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:character_collector/core/database/database_provider.dart';
import 'package:character_collector/presentation/databases/controllers/database_list_controller.dart';

void main() {
  late ProviderContainer container;
  late Database db;

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

  test('Database list loads successfully (empty initially)', () async {
    // Wait for initial load
    final state = await container.read(databaseListControllerProvider.future);
    expect(state, isEmpty);
  });

  test('Database creation works and refreshes list', () async {
    final controller = container.read(databaseListControllerProvider.notifier);
    await container.read(databaseListControllerProvider.future); // wait init

    await controller.createDatabase(name: 'Test DB', description: 'Test Desc');

    final state = await container.read(databaseListControllerProvider.future);
    expect(state.length, 1);
    expect(state.first.name, 'Test DB');
    expect(state.first.description, 'Test Desc');
  });

  test('Database editing works', () async {
    final controller = container.read(databaseListControllerProvider.notifier);
    await container.read(databaseListControllerProvider.future);

    await controller.createDatabase(name: 'Test DB');
    var state = await container.read(databaseListControllerProvider.future);
    final dbDef = state.first;

    await controller.updateDatabase(dbDef, name: 'Updated DB', description: 'Updated Desc');
    
    state = await container.read(databaseListControllerProvider.future);
    expect(state.first.name, 'Updated DB');
    expect(state.first.description, 'Updated Desc');
    expect(state.first.id, dbDef.id);
  });

  test('Database deletion works', () async {
    final controller = container.read(databaseListControllerProvider.notifier);
    await container.read(databaseListControllerProvider.future);

    await controller.createDatabase(name: 'Test DB');
    var state = await container.read(databaseListControllerProvider.future);
    final dbId = state.first.id;

    await controller.deleteDatabase(dbId);
    
    state = await container.read(databaseListControllerProvider.future);
    expect(state, isEmpty);
  });
}
