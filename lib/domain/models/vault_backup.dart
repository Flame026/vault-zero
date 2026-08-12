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
    final version = json['backupFormatVersion'] as int?;
    if (version == null) {
      throw const FormatException('Missing backupFormatVersion in backup file.');
    }
    if (version > currentFormatVersion) {
      throw FormatException('Unsupported backup version: $version. Please update your app.');
    }

    final dbsJson = json['databases'] as List?;
    final fieldsJson = json['fields'] as List?;
    final recordsJson = json['records'] as List?;

    if (dbsJson == null || fieldsJson == null || recordsJson == null) {
      throw const FormatException('Backup file is missing required structures.');
    }

    final databases = dbsJson.map((d) => DatabaseDefinition.fromJson(d as Map<String, dynamic>)).toList();
    final fields = fieldsJson.map((f) => FieldDefinition.fromJson(f as Map<String, dynamic>)).toList();
    final records = recordsJson.map((r) => Record.fromJson(r as Map<String, dynamic>)).toList();

    // In-memory Foreign Key Validation
    final dbIds = databases.map((d) => d.id).toSet();
    final fieldIds = fields.map((f) => f.id).toSet();

    for (final field in fields) {
      if (!dbIds.contains(field.databaseId)) {
        throw FormatException('Invalid backup: Field ${field.name} references missing database.');
      }
    }

    for (final record in records) {
      if (!dbIds.contains(record.databaseId)) {
        throw const FormatException('Invalid backup: A record references a missing database.');
      }
      for (final value in record.values.values) {
        if (!fieldIds.contains(value.fieldId)) {
          throw const FormatException('Invalid backup: A record value references a missing field.');
        }
      }
    }

    return VaultBackup(
      backupFormatVersion: version,
      appVersion: json['appVersion'] as String? ?? 'Unknown',
      exportDate: DateTime.parse(json['exportDate'] as String),
      databases: databases,
      fields: fields,
      records: records,
    );
  }
}
