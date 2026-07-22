import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/character.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();

    return await openDatabase(
      join(dbPath, 'characters.db'),
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
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
  }

  Future<int> insertCharacter(Character character) async {
    final db = await instance.database;

    return await db.insert(
      'characters',
      character.toMap(),
    );
  }

  Future<int> updateCharacter(Character character) async {
    if (character.id == null) return 0;

    final db = await instance.database;

    return await db.update(
      'characters',
      character.toMap(),
      where: 'id = ?',
      whereArgs: [character.id],
    );
  }

  Future<int> deleteCharacter(int id) async {
    final db = await instance.database;

    return await db.delete(
      'characters',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getCharacterCount() async {
    final db = await instance.database;

    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM characters');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Character>> getAllCharacters() async {
    final db = await instance.database;

    final result = await db.query(
      'characters',
      orderBy: 'id ASC',
    );

    return result.map((map) => Character.fromMap(map)).toList();
  }

  Future<List<Character>> searchCharacters(String query) async {
    final db = await instance.database;
    final searchQuery = query.trim();

    if (searchQuery.isEmpty) {
      return getAllCharacters();
    }

    final likeQuery = '%$searchQuery%';

    final result = await db.query(
      'characters',
      where: '''
        name LIKE ?
        OR faction LIKE ?
        OR characterClass LIKE ?
        OR title LIKE ?
      ''',
      whereArgs: [
        likeQuery,
        likeQuery,
        likeQuery,
        likeQuery,
      ],
      orderBy: 'id ASC',
    );

    return result.map((map) => Character.fromMap(map)).toList();
  }
}