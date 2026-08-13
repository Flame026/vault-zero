import 'package:sqflite/sqflite.dart';

import '../../domain/models/field_definition.dart';
import '../../domain/models/field_value.dart';
import '../../domain/models/record.dart';
import '../../domain/models/record_page.dart';
import '../../domain/repositories/record_repository.dart';

class SqliteRecordRepository implements RecordRepository {
  final Database db;

  SqliteRecordRepository(this.db);

  @override
  Future<void> saveRecord(Record record) async {
    await db.transaction((txn) async {
      // Upsert record
      final recordExists = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM records WHERE id = ?', [record.id]))! > 0;
      
      if (recordExists) {
        await txn.update(
          'records',
          {
            'updated_at': record.updatedAt.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [record.id],
        );
      } else {
        await txn.insert('records', {
          'id': record.id,
          'database_id': record.databaseId,
          'created_at': record.createdAt.millisecondsSinceEpoch,
          'updated_at': record.updatedAt.millisecondsSinceEpoch,
        });
      }

      // Fetch fields to validate that field belongs to the correct database
      final fields = await txn.query(
        'fields',
        where: 'database_id = ?',
        whereArgs: [record.databaseId],
      );
      
      final Map<String, FieldType> dbFields = {
        for (var row in fields) row['id'] as String: FieldType.values.firstWhere((e) => e.name == row['type'])
      };

      for (final valueEntry in record.values.entries) {
        final fieldId = valueEntry.key;
        final fieldValue = valueEntry.value;

        // Validation 1: Field belongs to the database
        if (!dbFields.containsKey(fieldId)) {
          throw ArgumentError('Field $fieldId does not belong to database ${record.databaseId}');
        }

        // Validation 2: Field value matches field type
        if (fieldValue.fieldType != dbFields[fieldId]) {
          throw ArgumentError('Type mismatch for field $fieldId. Expected ${dbFields[fieldId]}, got ${fieldValue.fieldType}');
        }

        final Map<String, dynamic> valueRow = {
          'id': fieldValue.id,
          'record_id': record.id,
          'field_id': fieldId,
          'text_value': null,
          'integer_value': null,
          'decimal_value': null,
          'boolean_value': null,
          'date_value': null,
          'date_time_value': null,
          'choice_value': null,
        };

        // Populate exactly ONE value column
        if (fieldValue is TextFieldValue) {
          valueRow['text_value'] = fieldValue.value;
        } else if (fieldValue is LongTextFieldValue) {
          valueRow['text_value'] = fieldValue.value;
        } else if (fieldValue is IntegerFieldValue) {
          valueRow['integer_value'] = fieldValue.value;
        } else if (fieldValue is DecimalFieldValue) {
          valueRow['decimal_value'] = fieldValue.value;
        } else if (fieldValue is BooleanFieldValue) {
          valueRow['boolean_value'] = fieldValue.value ? 1 : 0;
        } else if (fieldValue is DateFieldValue) {
          valueRow['date_value'] = fieldValue.value.millisecondsSinceEpoch;
        } else if (fieldValue is DateTimeFieldValue) {
          valueRow['date_time_value'] = fieldValue.value.millisecondsSinceEpoch;
        } else if (fieldValue is ChoiceFieldValue) {
          valueRow['choice_value'] = fieldValue.value;
        }

        // Using REPLACE for UPSERT behavior (requires all NOT NULL fields, but none are)
        // Since UNIQUE(record_id, field_id) exists, we can use insert with conflict algorithm
        await txn.insert(
          'field_values',
          valueRow,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> saveRecordsBatch(List<Record> records) async {
    if (records.isEmpty) return;

    await db.transaction((txn) async {
      // Group records by databaseId to validate fields efficiently
      final dbIds = records.map((r) => r.databaseId).toSet();
      final Map<String, Map<String, FieldType>> cachedDbFields = {};

      for (final dbId in dbIds) {
        final fields = await txn.query(
          'fields',
          where: 'database_id = ?',
          whereArgs: [dbId],
        );
        cachedDbFields[dbId] = {
          for (var row in fields) row['id'] as String: FieldType.values.firstWhere((e) => e.name == row['type'])
        };
      }

      final batch = txn.batch();

      for (final record in records) {
        batch.insert(
          'records',
          {
            'id': record.id,
            'database_id': record.databaseId,
            'created_at': record.createdAt.millisecondsSinceEpoch,
            'updated_at': record.updatedAt.millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        final dbFields = cachedDbFields[record.databaseId]!;

        for (final valueEntry in record.values.entries) {
          final fieldId = valueEntry.key;
          final fieldValue = valueEntry.value;

          // Validation 1: Field belongs to the database
          if (!dbFields.containsKey(fieldId)) {
            throw ArgumentError('Field $fieldId does not belong to database ${record.databaseId}');
          }

          // Validation 2: Field value matches field type
          if (fieldValue.fieldType != dbFields[fieldId]) {
            throw ArgumentError('Type mismatch for field $fieldId. Expected ${dbFields[fieldId]}, got ${fieldValue.fieldType}');
          }

          final Map<String, dynamic> valueRow = {
            'id': fieldValue.id,
            'record_id': record.id,
            'field_id': fieldId,
            'text_value': null,
            'integer_value': null,
            'decimal_value': null,
            'boolean_value': null,
            'date_value': null,
            'date_time_value': null,
            'choice_value': null,
          };

          // Populate exactly ONE value column
          if (fieldValue is TextFieldValue) {
            valueRow['text_value'] = fieldValue.value;
          } else if (fieldValue is LongTextFieldValue) {
            valueRow['text_value'] = fieldValue.value;
          } else if (fieldValue is IntegerFieldValue) {
            valueRow['integer_value'] = fieldValue.value;
          } else if (fieldValue is DecimalFieldValue) {
            valueRow['decimal_value'] = fieldValue.value;
          } else if (fieldValue is BooleanFieldValue) {
            valueRow['boolean_value'] = fieldValue.value ? 1 : 0;
          } else if (fieldValue is DateFieldValue) {
            valueRow['date_value'] = fieldValue.value.millisecondsSinceEpoch;
          } else if (fieldValue is DateTimeFieldValue) {
            valueRow['date_time_value'] = fieldValue.value.millisecondsSinceEpoch;
          } else if (fieldValue is ChoiceFieldValue) {
            valueRow['choice_value'] = fieldValue.value;
          }

          batch.insert(
            'field_values',
            valueRow,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> deleteRecord(String id) async {
    await db.delete(
      'records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<Record?> getRecord(String id) async {
    final results = await db.query(
      'records',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    final row = results.first;
    final databaseId = row['database_id'] as String;

    final values = await _getValuesForRecord(id, databaseId);

    return Record(
      id: id,
      databaseId: databaseId,
      values: values,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  @override
  Future<List<Record>> getRecordsForDatabase(String databaseId) async {
    final results = await db.query(
      'records',
      where: 'database_id = ?',
      whereArgs: [databaseId],
      orderBy: 'created_at ASC',
    );

    final records = <Record>[];
    for (final row in results) {
      final id = row['id'] as String;
      final values = await _getValuesForRecord(id, databaseId);
      records.add(Record(
        id: id,
        databaseId: databaseId,
        values: values,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      ));
    }

    return records;
  }

  @override
  Future<RecordPage> getRecordsPage(
    String databaseId, {
    int limit = 50,
    RecordCursor? after,
  }) async {
    final whereClauses = ['database_id = ?'];
    final whereArgs = <dynamic>[databaseId];

    if (after != null) {
      whereClauses.add('(created_at > ? OR (created_at = ? AND id > ?))');
      whereArgs.addAll([
        after.createdAt.millisecondsSinceEpoch,
        after.createdAt.millisecondsSinceEpoch,
        after.id,
      ]);
    }

    final results = await db.query(
      'records',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'created_at ASC, id ASC',
      limit: limit + 1,
    );

    final hasMore = results.length > limit;
    final pageResults = hasMore ? results.sublist(0, limit) : results;

    if (pageResults.isEmpty) {
      return const RecordPage(records: [], hasMore: false);
    }

    final fields = await db.query(
      'fields',
      where: 'database_id = ?',
      whereArgs: [databaseId],
    );

    final Map<String, FieldType> dbFields = {
      for (var row in fields) row['id'] as String: FieldType.values.firstWhere((e) => e.name == row['type'])
    };

    final recordIds = pageResults.map((r) => r['id'] as String).toList();
    final placeholders = List.filled(recordIds.length, '?').join(',');

    final valueResults = await db.query(
      'field_values',
      where: 'record_id IN ($placeholders)',
      whereArgs: recordIds,
    );

    final Map<String, Map<String, FieldValue>> groupedValues = {};
    for (final id in recordIds) {
      groupedValues[id] = {};
    }

    for (final row in valueResults) {
      final recordId = row['record_id'] as String;
      final fieldId = row['field_id'] as String;
      final type = dbFields[fieldId];
      if (type == null) continue;

      final id = row['id'] as String;
      groupedValues[recordId]![fieldId] = _mapFieldValue(type, id, recordId, fieldId, row);
    }

    final records = pageResults.map((row) {
      final id = row['id'] as String;
      return Record(
        id: id,
        databaseId: databaseId,
        values: groupedValues[id]!,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      );
    }).toList();

    RecordCursor? nextCursor;
    if (hasMore) {
      final lastRecord = records.last;
      nextCursor = RecordCursor(createdAt: lastRecord.createdAt, id: lastRecord.id);
    }

    return RecordPage(
      records: records,
      nextCursor: nextCursor,
      hasMore: hasMore,
    );
  }

  FieldValue _mapFieldValue(FieldType type, String id, String recordId, String fieldId, Map<String, Object?> row) {
    switch (type) {
      case FieldType.text:
        return TextFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: row['text_value'] as String? ?? '');
      case FieldType.longText:
        return LongTextFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: row['text_value'] as String? ?? '');
      case FieldType.integer:
        return IntegerFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: row['integer_value'] as int? ?? 0);
      case FieldType.decimal:
        return DecimalFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: (row['decimal_value'] as num?)?.toDouble() ?? 0.0);
      case FieldType.boolean:
        return BooleanFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: (row['boolean_value'] as int?) == 1);
      case FieldType.date:
        return DateFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: DateTime.fromMillisecondsSinceEpoch(row['date_value'] as int? ?? 0));
      case FieldType.dateTime:
        return DateTimeFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: DateTime.fromMillisecondsSinceEpoch(row['date_time_value'] as int? ?? 0));
      case FieldType.choice:
        return ChoiceFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: row['choice_value'] as String? ?? '');
    }
  }

  Future<Map<String, FieldValue>> _getValuesForRecord(String recordId, String databaseId) async {
    // Need field types to instantiate correct FieldValue
    final fields = await db.query(
      'fields',
      where: 'database_id = ?',
      whereArgs: [databaseId],
    );

    final Map<String, FieldType> dbFields = {
      for (var row in fields) row['id'] as String: FieldType.values.firstWhere((e) => e.name == row['type'])
    };

    final results = await db.query(
      'field_values',
      where: 'record_id = ?',
      whereArgs: [recordId],
    );

    final Map<String, FieldValue> values = {};

    for (final row in results) {
      final fieldId = row['field_id'] as String;
      final type = dbFields[fieldId];
      if (type == null) continue; // Orphaned value, shouldn't happen with CASCADE

      final id = row['id'] as String;
      values[fieldId] = _mapFieldValue(type, id, recordId, fieldId, row);
    }

    return values;
  }
}
