import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/database_provider.dart';
import '../models/character.dart';

abstract class LegacyCharacterRepository {
  Future<int> insertCharacter(Character character);
  Future<int> updateCharacter(Character character);
  Future<int> deleteCharacter(int id);
  Future<int> getCharacterCount();
  Future<List<Character>> getAllCharacters();
  Future<List<Character>> searchCharacters(String query);
}

class SqliteLegacyCharacterRepository implements LegacyCharacterRepository {
  final Database db;

  SqliteLegacyCharacterRepository(this.db);

  @override
  Future<int> insertCharacter(Character character) async {
    return await db.insert(
      'characters',
      character.toMap(),
    );
  }

  @override
  Future<int> updateCharacter(Character character) async {
    if (character.id == null) return 0;

    return await db.update(
      'characters',
      character.toMap(),
      where: 'id = ?',
      whereArgs: [character.id],
    );
  }

  @override
  Future<int> deleteCharacter(int id) async {
    return await db.delete(
      'characters',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> getCharacterCount() async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM characters');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<List<Character>> getAllCharacters() async {
    final result = await db.query(
      'characters',
      orderBy: 'id ASC',
    );
    return result.map((map) => Character.fromMap(map)).toList();
  }

  @override
  Future<List<Character>> searchCharacters(String query) async {
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

final legacyCharacterRepositoryProvider = FutureProvider<LegacyCharacterRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return SqliteLegacyCharacterRepository(db);
});
