import 'package:sqflite/sqflite.dart';

import '../../domain/models/field_definition.dart';
import '../../domain/models/field_value.dart';
import '../../domain/models/record.dart';
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

      FieldValue fieldValue;
      switch (type) {
        case FieldType.text:
          fieldValue = TextFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: row['text_value'] as String? ?? '');
          break;
        case FieldType.longText:
          fieldValue = LongTextFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: row['text_value'] as String? ?? '');
          break;
        case FieldType.integer:
          fieldValue = IntegerFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: row['integer_value'] as int? ?? 0);
          break;
        case FieldType.decimal:
          fieldValue = DecimalFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: (row['decimal_value'] as num?)?.toDouble() ?? 0.0);
          break;
        case FieldType.boolean:
          fieldValue = BooleanFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: (row['boolean_value'] as int?) == 1);
          break;
        case FieldType.date:
          fieldValue = DateFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: DateTime.fromMillisecondsSinceEpoch(row['date_value'] as int? ?? 0));
          break;
        case FieldType.dateTime:
          fieldValue = DateTimeFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: DateTime.fromMillisecondsSinceEpoch(row['date_time_value'] as int? ?? 0));
          break;
        case FieldType.choice:
          fieldValue = ChoiceFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: row['choice_value'] as String? ?? '');
          break;
      }
      values[fieldId] = fieldValue;
    }

    return values;
  }
}
