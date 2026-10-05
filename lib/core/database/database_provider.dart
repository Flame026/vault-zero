import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_storage_service.dart';

final databaseStorageServiceProvider = Provider<DatabaseStorageService?>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return dbAsync.when(
    data: (db) => DatabaseStorageService(db),
    loading: () => null,
    error: (_, _) => null,
  );
});

final databaseProvider = FutureProvider<Database>((ref) async {
  final dbPath = await getDatabasesPath();

  return openDatabase(
    join(dbPath, 'characters.db'),
    version: 4,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onOpen: (db) async {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_fields_database_id ON fields(database_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_field_values_field_id ON field_values(field_id)',
      );
    },
    onCreate: (db, version) async {
      if (version >= 2) {
        await _createV2Tables(db);
      }

      if (version >= 3) {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_records_database_created_id ON records(database_id, created_at, id)',
        );
      }

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_fields_database_id ON fields(database_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_field_values_field_id ON field_values(field_id)',
      );
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await _createV2Tables(db);
      }

      if (oldVersion < 3) {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_records_database_created_id ON records(database_id, created_at, id)',
        );
      }

      if (oldVersion < 4) {
        await db.execute('DROP TABLE IF EXISTS characters');
      }

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_fields_database_id ON fields(database_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_field_values_field_id ON field_values(field_id)',
      );
    },
  );
});

Future<void> _createV2Tables(Database db) async {
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
}
