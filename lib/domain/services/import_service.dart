import 'dart:async';

import 'package:uuid/uuid.dart';

import '../models/database_definition.dart';
import '../models/field_definition.dart';
import '../models/field_value.dart';
import '../models/record.dart';
import '../repositories/record_repository.dart';
import '../repositories/schema_repository.dart';
import '../../data/importers/tabular_data_source.dart';

class ImportService {
  final SchemaRepository schemaRepository;
  final RecordRepository recordRepository;
  final _uuid = const Uuid();

  ImportService({
    required this.schemaRepository,
    required this.recordRepository,
  });

  /// Normalizes a list of headers.
  /// Trims whitespace, replaces empty headers with "Column A", "Column B", etc.
  /// Deduplicates by appending "(1)", "(2)", etc.
  List<String> _normalizeHeaders(List<String> rawHeaders) {
    final normalized = <String>[];
    final counts = <String, int>{};
    var emptyCount = 0;

    for (var header in rawHeaders) {
      header = header.trim();
      if (header.isEmpty) {
        final char = String.fromCharCode('A'.codeUnitAt(0) + emptyCount);
        header = 'Column $char';
        emptyCount++;
      }

      if (counts.containsKey(header)) {
        final count = counts[header]! + 1;
        counts[header] = count;
        normalized.add('$header ($count)');
      } else {
        counts[header] = 0;
        normalized.add(header);
      }
    }
    return normalized;
  }

  /// Imports a data source into a new Database with the given [databaseName].
  Future<void> importDatabase(String databaseName, TabularDataSource source) async {
    final rawHeaders = await source.getHeaders();
    if (rawHeaders.isEmpty) {
      throw const FormatException('Data source has no headers or is empty.');
    }

    final headers = _normalizeHeaders(rawHeaders);
    final databaseId = _uuid.v4();
    final now = DateTime.now();

    final fields = <FieldDefinition>[];
    for (var i = 0; i < headers.length; i++) {
      fields.add(FieldDefinition(
        id: _uuid.v4(),
        databaseId: databaseId,
        name: headers[i],
        type: FieldType.text,
        position: i,
        isRequired: false,
        createdAt: now,
        updatedAt: now,
      ));
    }

    final databaseDef = DatabaseDefinition(
      id: databaseId,
      name: databaseName,
      description: 'Imported Database',
      fields: fields,
      createdAt: now,
      updatedAt: now,
    );

    // 1. Create database + fields
    await schemaRepository.createDatabase(databaseDef);

    try {
      // 2. Stream rows and batch import
      final rowsStream = source.getRows();
      final batch = <Record>[];
      const batchSize = 500;

      await for (final row in rowsStream) {
        // Skip completely blank rows
        final isBlank = row.every((cell) => cell == null || cell.toString().trim().isEmpty);
        if (isBlank) {
          continue;
        }

        final values = <String, FieldValue>{};
        final recordId = _uuid.v4();

        for (var i = 0; i < fields.length; i++) {
          final field = fields[i];
          final String rawValue;
          
          if (i < row.length) {
            rawValue = row[i]?.toString() ?? '';
          } else {
            rawValue = ''; // Pad missing cells
          }

          // Normalize newlines to LF for generic database consistency
          final cellValue = rawValue.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

          values[field.id] = TextFieldValue(
            id: _uuid.v4(),
            recordId: recordId,
            fieldId: field.id,
            value: cellValue,
          );
        }

        batch.add(Record(
          id: recordId,
          databaseId: databaseId,
          values: values,
          createdAt: now,
          updatedAt: now,
        ));

        if (batch.length >= batchSize) {
          await recordRepository.saveRecordsBatch(batch);
          batch.clear();
        }
      }

      // Insert any remaining records
      if (batch.isNotEmpty) {
        await recordRepository.saveRecordsBatch(batch);
      }
    } catch (e) {
      // Fatal parser/database error. Cleanup.
      try {
        await schemaRepository.deleteDatabase(databaseId);
        throw Exception('Import failed. Changes reverted.\nError: $e');
      } catch (cleanupError) {
        throw Exception('Import failed and partial database cleanup failed. You may need to manually delete the partial database "$databaseName".\nOriginal Error: $e\nCleanup Error: $cleanupError');
      }
    }
  }
}
