import 'database_definition.dart';
import 'field_definition.dart';
import 'record.dart';

class VaultBackup {
  static const int currentFormatVersion = 1;

  final int backupFormatVersion;
  final String appVersion;
  final DateTime exportDate;
  final List<DatabaseDefinition> databases;
  final List<FieldDefinition> fields;
  final List<Record> records;

  const VaultBackup({
    required this.backupFormatVersion,
    required this.appVersion,
    required this.exportDate,
    required this.databases,
    required this.fields,
    required this.records,
  });

  Map<String, dynamic> toJson() {
    return {
      'backupFormatVersion': backupFormatVersion,
      'appVersion': appVersion,
      'exportDate': exportDate.toUtc().toIso8601String(),
      'databases': databases.map((d) => d.toJson()).toList(),
      'fields': fields.map((f) => f.toJson()).toList(),
      'records': records.map((r) => r.toJson()).toList(),
    };
  }

  factory VaultBackup.fromJson(Map<String, dynamic> json) {
    final version = json['backupFormatVersion'];
    if (version == null || version is! int) {
      throw const FormatException(
        'Missing or invalid backupFormatVersion in backup file.',
      );
    }
    if (version > currentFormatVersion) {
      throw FormatException(
        'Unsupported backup version: $version. Please update your app.',
      );
    }

    final exportDateRaw = json['exportDate'];
    if (exportDateRaw == null || exportDateRaw is! String) {
      throw const FormatException(
        'Missing or invalid exportDate in backup file.',
      );
    }
    final DateTime exportDate;
    try {
      exportDate = DateTime.parse(exportDateRaw);
    } catch (_) {
      throw const FormatException('Invalid exportDate format in backup file.');
    }

    final dbsJson = json['databases'];
    final fieldsJson = json['fields'];
    final recordsJson = json['records'];

    if (dbsJson is! List || fieldsJson is! List || recordsJson is! List) {
      throw const FormatException(
        'Backup file is missing required structures.',
      );
    }

    final List<DatabaseDefinition> databases = [];
    final Set<String> dbIds = {};
    for (final d in dbsJson) {
      if (d is! Map<String, dynamic>) {
        throw const FormatException('Invalid database entry in backup file.');
      }
      try {
        final db = DatabaseDefinition.fromJson(d);
        if (!dbIds.add(db.id)) {
          throw FormatException('Duplicate database ID in backup: ${db.id}');
        }
        databases.add(db);
      } catch (e) {
        if (e is FormatException) rethrow;
        throw FormatException('Failed to parse database entry: $e');
      }
    }

    final List<FieldDefinition> fields = [];
    final Map<String, FieldDefinition> fieldMap = {};
    for (final f in fieldsJson) {
      if (f is! Map<String, dynamic>) {
        throw const FormatException('Invalid field entry in backup file.');
      }
      try {
        final field = FieldDefinition.fromJson(f);
        if (fieldMap.containsKey(field.id)) {
          throw FormatException('Duplicate field ID in backup: ${field.id}');
        }
        fieldMap[field.id] = field;
        fields.add(field);
      } catch (e) {
        if (e is FormatException) rethrow;
        throw FormatException('Failed to parse field entry: $e');
      }
    }

    final List<Record> records = [];
    final Set<String> recordIds = {};
    for (final r in recordsJson) {
      if (r is! Map<String, dynamic>) {
        throw const FormatException('Invalid record entry in backup file.');
      }
      try {
        final record = Record.fromJson(r);
        if (!recordIds.add(record.id)) {
          throw FormatException('Duplicate record ID in backup: ${record.id}');
        }
        records.add(record);
      } catch (e) {
        if (e is FormatException) rethrow;
        throw FormatException('Failed to parse record entry: $e');
      }
    }

    // In-memory Foreign Key and Integrity Validation
    for (final field in fields) {
      if (!dbIds.contains(field.databaseId)) {
        throw FormatException(
          'Invalid backup: Field ${field.name} references missing database.',
        );
      }
    }

    for (final record in records) {
      if (!dbIds.contains(record.databaseId)) {
        throw const FormatException(
          'Invalid backup: A record references a missing database.',
        );
      }
      for (final value in record.values.values) {
        final fieldDef = fieldMap[value.fieldId];
        if (fieldDef == null) {
          throw const FormatException(
            'Invalid backup: A record value references a missing field.',
          );
        }
        if (value.recordId != record.id) {
          throw const FormatException(
            'Invalid backup: A record value has mismatched recordId.',
          );
        }
        if (value.fieldType != fieldDef.type) {
          throw FormatException(
            'Invalid backup: Value type ${value.fieldType.name} does not match field type ${fieldDef.type.name} for field ${fieldDef.name}.',
          );
        }
      }
    }

    return VaultBackup(
      backupFormatVersion: version,
      appVersion: json['appVersion'] as String? ?? 'Unknown',
      exportDate: exportDate,
      databases: databases,
      fields: fields,
      records: records,
    );
  }
}
