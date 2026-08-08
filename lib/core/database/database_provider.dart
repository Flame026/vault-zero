import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  final dbPath = await getDatabasesPath();

  return openDatabase(
    join(dbPath, 'characters.db'),
    version: 1,
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
    },
  );
});
