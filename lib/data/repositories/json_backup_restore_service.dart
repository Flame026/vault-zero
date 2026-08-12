import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../domain/models/database_definition.dart';
import '../../domain/models/field_definition.dart';
import '../../domain/models/record.dart';
import '../../domain/models/field_value.dart';
import '../../domain/models/vault_backup.dart';
import '../../domain/repositories/backup_restore_service.dart';

class JsonBackupRestoreService implements BackupRestoreService {
  final Database _db;

  JsonBackupRestoreService(this._db);

  @override
  Future<String> exportVault() async {
    // 1. Fetch Databases
    final dbRows = await _db.query('databases');
    final databases = dbRows.map((row) => DatabaseDefinition(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String,
      fields: const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int, isUtc: true),
    )).toList();

    // 2. Fetch Fields
    final fieldRows = await _db.query('fields');
    final fields = fieldRows.map((row) {
      FieldConfig? config;
      final configStr = row['configuration'] as String?;
      if (configStr != null) {
        final configJson = jsonDecode(configStr) as Map<String, dynamic>;
        if (configJson['type'] == 'choice') {
          config = ChoiceConfig(options: (configJson['options'] as List).cast<String>());
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
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int, isUtc: true),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int, isUtc: true),
      );
    }).toList();

    // 3. Fetch Records
    final recordRows = await _db.query('records');
    final recordsData = recordRows.map((row) => {
      'id': row['id'] as String,
      'databaseId': row['database_id'] as String,
      'createdAt': DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int, isUtc: true),
      'updatedAt': DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int, isUtc: true),
    }).toList();

    // 4. Fetch Field Values
    final valueRows = await _db.query('field_values');
    final Map<String, Map<String, FieldValue>> recordValues = {};
    for (final row in valueRows) {
      final recordId = row['record_id'] as String;
      final fieldId = row['field_id'] as String;
      
      final fieldDef = fields.where((f) => f.id == fieldId).firstOrNull;
      if (fieldDef == null) continue;
      
      FieldValue? fv;
      final id = row['id'] as String;
      switch (fieldDef.type) {
        case FieldType.text:
          fv = TextFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: row['text_value'] as String? ?? '');
          break;
        case FieldType.longText:
          fv = LongTextFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: row['text_value'] as String? ?? '');
          break;
        case FieldType.integer:
          fv = IntegerFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: row['integer_value'] as int? ?? 0);
          break;
        case FieldType.decimal:
          fv = DecimalFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: (row['decimal_value'] as num?)?.toDouble() ?? 0.0);
          break;
        case FieldType.boolean:
          fv = BooleanFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: (row['boolean_value'] as int?) == 1);
          break;
        case FieldType.date:
          fv = DateFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: DateTime.fromMillisecondsSinceEpoch(row['date_value'] as int? ?? 0, isUtc: true));
          break;
        case FieldType.dateTime:
          fv = DateTimeFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: DateTime.fromMillisecondsSinceEpoch(row['date_time_value'] as int? ?? 0, isUtc: true));
          break;
        case FieldType.choice:
          fv = ChoiceFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: row['choice_value'] as String? ?? '');
          break;
      }
      
      recordValues.putIfAbsent(recordId, () => {})[fieldId] = fv;
    }

    final records = recordsData.map((data) => Record(
      id: data['id'] as String,
      databaseId: data['databaseId'] as String,
      values: recordValues[data['id'] as String] ?? {},
      createdAt: data['createdAt'] as DateTime,
      updatedAt: data['updatedAt'] as DateTime,
    )).toList();

    final backup = VaultBackup(
      backupFormatVersion: VaultBackup.currentFormatVersion,
      appVersion: 'V2.5',
      exportDate: DateTime.now().toUtc(),
      databases: databases,
      fields: fields,
      records: records,
    );

    return jsonEncode(backup.toJson());
  }

  @override
  Future<void> restoreVault(String jsonContent) async {
    Map<String, dynamic> jsonMap;
    try {
      jsonMap = jsonDecode(jsonContent) as Map<String, dynamic>;
    } catch (e) {
      throw const FormatException('Invalid backup file: Not valid JSON.');
    }

    final backup = VaultBackup.fromJson(jsonMap);

    await _db.transaction((txn) async {
      // Clear V2 tables
      await txn.delete('field_values');
      await txn.delete('records');
      await txn.delete('fields');
      await txn.delete('databases');

      // 1. Insert Databases
      final dbBatch = txn.batch();
      for (final db in backup.databases) {
        dbBatch.insert('databases', {
          'id': db.id,
          'name': db.name,
          'description': db.description,
          'created_at': db.createdAt.millisecondsSinceEpoch,
          'updated_at': db.updatedAt.millisecondsSinceEpoch,
        });
      }
      await dbBatch.commit(noResult: true);

      // 2. Insert Fields
      final fieldBatch = txn.batch();
      for (final field in backup.fields) {
        String? configStr;
        if (field.configuration is ChoiceConfig) {
          configStr = jsonEncode({
            'type': 'choice',
            'options': (field.configuration as ChoiceConfig).options,
          });
        }
        fieldBatch.insert('fields', {
          'id': field.id,
          'database_id': field.databaseId,
          'name': field.name,
          'type': field.type.name,
          'position': field.position,
          'is_required': field.isRequired ? 1 : 0,
          'configuration': configStr,
          'created_at': field.createdAt.millisecondsSinceEpoch,
          'updated_at': field.updatedAt.millisecondsSinceEpoch,
        });
      }
      await fieldBatch.commit(noResult: true);

      // 3. Insert Records
      final recordBatch = txn.batch();
      final valueBatch = txn.batch();
      for (final record in backup.records) {
        recordBatch.insert('records', {
          'id': record.id,
          'database_id': record.databaseId,
          'created_at': record.createdAt.millisecondsSinceEpoch,
          'updated_at': record.updatedAt.millisecondsSinceEpoch,
        });

        // Insert Field Values for this record
        for (final value in record.values.values) {
          final Map<String, Object?> row = {
            'id': value.id,
            'record_id': value.recordId,
            'field_id': value.fieldId,
          };
          switch (value.fieldType) {
            case FieldType.text:
            case FieldType.longText:
              row['text_value'] = value.value as String;
              break;
            case FieldType.integer:
              row['integer_value'] = value.value as int;
              break;
            case FieldType.decimal:
              row['decimal_value'] = value.value as double;
              break;
            case FieldType.boolean:
              row['boolean_value'] = (value.value as bool) ? 1 : 0;
              break;
            case FieldType.date:
              row['date_value'] = (value.value as DateTime).millisecondsSinceEpoch;
              break;
            case FieldType.dateTime:
              row['date_time_value'] = (value.value as DateTime).millisecondsSinceEpoch;
              break;
            case FieldType.choice:
              row['choice_value'] = value.value as String;
              break;
          }
          valueBatch.insert('field_values', row);
        }
      }
      await recordBatch.commit(noResult: true);
      await valueBatch.commit(noResult: true);
    });
  }
}
