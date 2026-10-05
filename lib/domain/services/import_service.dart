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
  /// Enforces maximum 60 characters for Vault Zero field name limits.
  static List<String> normalizeHeaders(List<String> rawHeaders) {
    final normalized = <String>[];
    final seenLower = <String>{};
    final counts = <String, int>{};
    var emptyCount = 0;

    for (var raw in rawHeaders) {
      var header = raw
          // Strip BOM and invisible zero-width characters
          .replaceAll(RegExp(r'[\uFEFF\u200B-\u200D\u2060\uFE0E\uFE0F]'), '')
          // Strip bidirectional control overrides
          .replaceAll(RegExp(r'[\u202A-\u202E\u2066-\u2069]'), '')
          // Strip ASCII control characters
          .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
          .trim();

      if (header.isEmpty) {
        if (emptyCount < 26) {
          final char = String.fromCharCode('A'.codeUnitAt(0) + emptyCount);
          header = 'Column $char';
        } else {
          header = 'Column ${emptyCount + 1}';
        }
        emptyCount++;
      }

      if (header.length > 60) {
        header = header.substring(0, 60);
      }

      var candidate = header;
      final key = header.toLowerCase();
      var count = counts[key] ?? 0;

      while (seenLower.contains(candidate.toLowerCase())) {
        count++;
        final suffix = ' ($count)';
        final base = header.length + suffix.length > 60
            ? header.substring(0, 60 - suffix.length)
            : header;
        candidate = '$base$suffix';
      }

      counts[key] = count;
      seenLower.add(candidate.toLowerCase());
      normalized.add(candidate);
    }
    return normalized;
  }

  /// Imports a data source into a new Database with the given [databaseName].
  Future<void> importDatabase(
    String databaseName,
    TabularDataSource source,
  ) async {
    final rawHeaders = await source.getHeaders();
    if (rawHeaders.isEmpty) {
      throw const FormatException('Data source has no headers or is empty.');
    }

    final headers = normalizeHeaders(rawHeaders);
    final databaseId = _uuid.v4();
    final now = DateTime.now();

    final fields = <FieldDefinition>[];
    for (var i = 0; i < headers.length; i++) {
      fields.add(
        FieldDefinition(
          id: _uuid.v4(),
          databaseId: databaseId,
          name: headers[i],
          type: FieldType.text,
          position: i,
          isRequired: false,
          createdAt: now,
          updatedAt: now,
        ),
      );
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
      var rowIndex = 0;

      await for (final row in rowsStream) {
        // Skip completely blank rows
        final isBlank = row.every(
          (cell) => cell == null || cell.toString().trim().isEmpty,
        );
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
          final cellValue = rawValue
              .replaceAll('\r\n', '\n')
              .replaceAll('\r', '\n');

          values[field.id] = TextFieldValue(
            id: _uuid.v4(),
            recordId: recordId,
            fieldId: field.id,
            value: cellValue,
          );
        }

        final recordCreatedAt = now.add(Duration(milliseconds: rowIndex++));
        batch.add(
          Record(
            id: recordId,
            databaseId: databaseId,
            values: values,
            createdAt: recordCreatedAt,
            updatedAt: recordCreatedAt,
          ),
        );

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
      var cleanupFailed = false;
      Object? cleanupError;
      try {
        await schemaRepository.deleteDatabase(databaseId);
      } catch (err) {
        cleanupFailed = true;
        cleanupError = err;
      }

      if (cleanupFailed) {
        throw Exception(
          'Import failed and partial database cleanup failed. You may need to manually delete the partial database "$databaseName".\nOriginal Error: $e\nCleanup Error: $cleanupError',
        );
      } else {
        throw Exception('Import failed. Changes reverted.\nError: $e');
      }
    }
  }
}
