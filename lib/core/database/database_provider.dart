import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  final dbPath = await getDatabasesPath();

  return openDatabase(
    join(dbPath, 'characters.db'),
    version: 3,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onCreate: (db, version) async {
      // Legacy table required to keep old functionality intact during Phase 0
      await db.execute('''
        CREATE TABLE characters(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          faction TEXT NOT NULL,
          characterClass TEXT NOT NULL,
          title TEXT NOT NULL,
          skill1 TEXT NOT NULL,
          skill2 TEXT NOT NULL,
          skill3 TEXT NOT NULL,
          skill4 TEXT NOT NULL
        )
      ''');
      
      if (version >= 2) {
        await _createV2Tables(db);
      }

      if (version >= 3) {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_records_database_created_id ON records(database_id, created_at, id)');
      }
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await _createV2Tables(db);
      }

      if (oldVersion < 3) {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_records_database_created_id ON records(database_id, created_at, id)');
      }
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
