import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import '../../domain/models/database_definition.dart';
import '../../domain/models/field_definition.dart';
import '../../domain/repositories/schema_repository.dart';

class SqliteSchemaRepository implements SchemaRepository {
  final Database db;

  SqliteSchemaRepository(this.db);

  @override
  Future<void> createDatabase(DatabaseDefinition database) async {
    await db.transaction((txn) async {
      await txn.insert('databases', {
        'id': database.id,
        'name': database.name,
        'description': database.description,
        'created_at': database.createdAt.millisecondsSinceEpoch,
        'updated_at': database.updatedAt.millisecondsSinceEpoch,
      });

      for (final field in database.fields) {
        await _insertField(txn, field);
      }
    });
  }

  @override
  Future<void> updateDatabase(DatabaseDefinition database) async {
    await db.update(
      'databases',
      {
        'name': database.name,
        'description': database.description,
        'updated_at': database.updatedAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [database.id],
    );
  }

  @override
  Future<void> deleteDatabase(String id) async {
    await db.delete(
      'databases',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<DatabaseDefinition?> getDatabase(String id) async {
    final results = await db.query(
      'databases',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    final row = results.first;
    final fields = await getFieldsForDatabase(id);

    return DatabaseDefinition(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String,
      fields: fields,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  @override
  Future<List<DatabaseDefinition>> getAllDatabases() async {
    final results = await db.query('databases');
    if (results.isEmpty) return const [];

    final fieldRows = await db.query('fields', orderBy: 'position ASC');
    final Map<String, List<FieldDefinition>> fieldsByDb = {};
    for (final row in fieldRows) {
      final dbId = row['database_id'] as String;
      (fieldsByDb[dbId] ??= []).add(_mapFieldDefinition(row));
    }

    return results.map((row) {
      final id = row['id'] as String;
      return DatabaseDefinition(
        id: id,
        name: row['name'] as String,
        description: row['description'] as String,
        fields: fieldsByDb[id] ?? const [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      );
    }).toList();
  }

  @override
  Future<void> createField(FieldDefinition field) async {
    await _insertField(db, field);
  }

  @override
  Future<void> updateField(FieldDefinition field) async {
    String? configJson;
    if (field.configuration is ChoiceConfig) {
      configJson = jsonEncode({'options': (field.configuration as ChoiceConfig).options});
    }

    await db.update(
      'fields',
      {
        'name': field.name,
        'type': field.type.name,
        'position': field.position,
        'is_required': field.isRequired ? 1 : 0,
        'configuration': configJson,
        'updated_at': field.updatedAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [field.id],
    );
  }

  @override
  Future<void> updateFields(List<FieldDefinition> fields) async {
    await db.transaction((txn) async {
      for (final field in fields) {
        String? configJson;
        if (field.configuration is ChoiceConfig) {
          configJson = jsonEncode({'options': (field.configuration as ChoiceConfig).options});
        }

        await txn.update(
          'fields',
          {
            'name': field.name,
            'type': field.type.name,
            'position': field.position,
            'is_required': field.isRequired ? 1 : 0,
            'configuration': configJson,
            'updated_at': field.updatedAt.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [field.id],
        );
      }
    });
  }

  @override
  Future<void> deleteField(String id) async {
    await db.delete(
      'fields',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<FieldDefinition>> getFieldsForDatabase(String databaseId) async {
    final results = await db.query(
      'fields',
      where: 'database_id = ?',
      whereArgs: [databaseId],
      orderBy: 'position ASC',
    );

    return results.map(_mapFieldDefinition).toList();
  }

  FieldDefinition _mapFieldDefinition(Map<String, Object?> row) {
    final configJson = row['configuration'] as String?;
    FieldConfig? config;
    if (configJson != null) {
      final map = jsonDecode(configJson) as Map<String, dynamic>;
      if (map.containsKey('options')) {
        config = ChoiceConfig(options: List<String>.from(map['options'] as List));
      }
    }

    return FieldDefinition(
      id: row['id'] as String,
      databaseId: row['database_id'] as String,
      name: row['name'] as String,
      type: FieldType.values.firstWhere((e) => e.name == row['type']),
      position: row['position'] as int,
      isRequired: (row['is_required'] as int) == 1,
      configuration: config,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  Future<void> _insertField(DatabaseExecutor executor, FieldDefinition field) async {
    String? configJson;
    if (field.configuration is ChoiceConfig) {
      configJson = jsonEncode({'options': (field.configuration as ChoiceConfig).options});
    }

    await executor.insert('fields', {
      'id': field.id,
      'database_id': field.databaseId,
      'name': field.name,
      'type': field.type.name,
      'position': field.position,
      'is_required': field.isRequired ? 1 : 0,
      'configuration': configJson,
      'created_at': field.createdAt.millisecondsSinceEpoch,
      'updated_at': field.updatedAt.millisecondsSinceEpoch,
    });
  }
}
