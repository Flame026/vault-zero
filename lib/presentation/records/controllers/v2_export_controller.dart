import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/providers.dart';
import '../../../core/storage/temp_storage_service.dart';
import '../../../domain/models/database_definition.dart';
import '../../../domain/models/field_definition.dart';
import '../../../domain/models/field_value.dart';
import '../../../domain/models/record_page.dart';

final exportControllerProvider = AsyncNotifierProvider<ExportController, void>(
  () {
    return ExportController();
  },
);

// Backward compatibility alias
final v2ExportControllerProvider = exportControllerProvider;

typedef V2ExportController = ExportController;

class ExportController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  CellValue _formatCellValue(FieldValue? fieldValue) {
    if (fieldValue == null || fieldValue.value == null) {
      return TextCellValue('');
    }

    if (fieldValue is IntegerFieldValue) {
      return IntCellValue(fieldValue.value);
    } else if (fieldValue is DecimalFieldValue) {
      return DoubleCellValue(fieldValue.value);
    } else if (fieldValue is BooleanFieldValue) {
      return BoolCellValue(fieldValue.value);
    } else if (fieldValue is DateFieldValue) {
      final dt = fieldValue.value;
      return DateCellValue(year: dt.year, month: dt.month, day: dt.day);
    } else if (fieldValue is DateTimeFieldValue) {
      final dt = fieldValue.value;
      return DateTimeCellValue(
        year: dt.year,
        month: dt.month,
        day: dt.day,
        hour: dt.hour,
        minute: dt.minute,
        second: dt.second,
      );
    }

    return TextCellValue(fieldValue.value.toString());
  }

  dynamic _formatCsvValue(FieldValue? fieldValue) {
    if (fieldValue == null || fieldValue.value == null) {
      return '';
    }

    if (fieldValue is IntegerFieldValue) {
      return fieldValue.value;
    } else if (fieldValue is DecimalFieldValue) {
      return fieldValue.value;
    } else if (fieldValue is BooleanFieldValue) {
      return fieldValue.value ? 'true' : 'false';
    } else if (fieldValue is DateFieldValue) {
      final dt = fieldValue.value;
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    } else if (fieldValue is DateTimeFieldValue) {
      final dt = fieldValue.value;
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      final s = dt.second.toString().padLeft(2, '0');
      return '$y-$m-$d $h:$min:$s';
    }

    return fieldValue.value.toString();
  }

  Future<File?> exportToExcel(
    DatabaseDefinition database,
    List<FieldDefinition> fields, {
    Directory? outputDirectory,
  }) async {
    final repository = await ref.read(recordRepositoryProvider.future);

    // Explicitly check for records before starting export to maintain the exact pre-V2.5-B contract.
    // We fetch 100 records so we can immediately start processing if not empty.
    final firstPage = await repository.getRecordsPage(database.id, limit: 100);
    if (firstPage.records.isEmpty) {
      throw StateError('Cannot export a database with no records.');
    }

    state = const AsyncValue.loading();
    File? generatedFile;

    state = await AsyncValue.guard(() async {
      final excel = Excel.createExcel();

      // Sanitize sheet name (max 31 chars, no invalid chars, non-empty)
      var sheetName = database.name
          .replaceAll(RegExp(r'[\\/?*\[\]:]'), '_')
          .trim();
      if (sheetName.isEmpty) {
        sheetName = 'Database';
      } else if (sheetName.length > 31) {
        sheetName = sheetName.substring(0, 31);
      }
      final sheet = excel[sheetName];

      // Sort fields by position to determine column order
      final sortedFields = List<FieldDefinition>.from(fields)
        ..sort((a, b) => a.position.compareTo(b.position));

      // Append header row
      final headers = sortedFields.map((f) => TextCellValue(f.name)).toList();
      sheet.appendRow(headers);

      RecordPage currentPage = firstPage;
      bool hasMore = true;

      while (hasMore) {
        // Append data rows
        for (final record in currentPage.records) {
          final rowCells = <CellValue>[];
          for (final field in sortedFields) {
            final fieldValue = record.values[field.id];
            rowCells.add(_formatCellValue(fieldValue));
          }
          sheet.appendRow(rowCells);
        }

        hasMore = currentPage.hasMore;
        if (hasMore) {
          currentPage = await repository.getRecordsPage(
            database.id,
            limit: 100,
            after: currentPage.nextCursor,
          );
        }
      }

      // Only delete the default 'Sheet1' if it is not our target sheet
      if (sheetName != 'Sheet1') {
        excel.delete('Sheet1');
      }
      final bytes = excel.save();

      if (bytes == null) {
        throw StateError('Excel package returned no file data.');
      }

      final directory = await _resolveExportDirectory(outputDirectory);
      await _pruneTempExportsIfDefault(outputDirectory);
      final now = DateTime.now();

      final safeDbName = sanitizeFileName(database.name);
      final fileName =
          'vault_zero_${safeDbName}_${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}_${_twoDigits(now.hour)}-${_twoDigits(now.minute)}-${_twoDigits(now.second)}.xlsx';
      final file = File('${directory.path}/$fileName');

      try {
        await file.writeAsBytes(bytes, flush: true);
        generatedFile = file;
      } catch (e) {
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
        rethrow;
      }
    });

    return generatedFile;
  }

  Future<File?> exportToCsv(
    DatabaseDefinition database,
    List<FieldDefinition> fields, {
    Directory? outputDirectory,
  }) async {
    final repository = await ref.read(recordRepositoryProvider.future);

    final firstPage = await repository.getRecordsPage(database.id, limit: 100);
    if (firstPage.records.isEmpty) {
      throw StateError('Cannot export a database with no records.');
    }

    state = const AsyncValue.loading();
    File? generatedFile;

    state = await AsyncValue.guard(() async {
      final sortedFields = List<FieldDefinition>.from(fields)
        ..sort((a, b) => a.position.compareTo(b.position));

      final directory = await _resolveExportDirectory(outputDirectory);
      await _pruneTempExportsIfDefault(outputDirectory);
      final now = DateTime.now();

      final safeDbName = sanitizeFileName(database.name);
      final fileName =
          'vault_zero_${safeDbName}_${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}_${_twoDigits(now.hour)}-${_twoDigits(now.minute)}-${_twoDigits(now.second)}.csv';
      final file = File('${directory.path}/$fileName');
      IOSink? sink;

      try {
        sink = file.openWrite(mode: FileMode.write, encoding: utf8);

        const converter = CsvEncoder();
        // Write header row
        sink.writeln(
          converter.convert([sortedFields.map((f) => f.name).toList()]),
        );

        RecordPage currentPage = firstPage;
        bool hasMore = true;

        while (hasMore) {
          for (final record in currentPage.records) {
            final row = sortedFields
                .map((f) => _formatCsvValue(record.values[f.id]))
                .toList();
            sink.writeln(converter.convert([row]));
          }

          hasMore = currentPage.hasMore;
          if (hasMore) {
            currentPage = await repository.getRecordsPage(
              database.id,
              limit: 100,
              after: currentPage.nextCursor,
            );
          }
        }

        await sink.flush();
        await sink.close();
        sink = null;
        generatedFile = file;
      } catch (e) {
        if (sink != null) {
          try {
            await sink.close();
          } catch (_) {}
        }
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
        rethrow;
      }
    });

    return generatedFile;
  }

  Future<Directory> _resolveExportDirectory(Directory? outputDirectory) async {
    if (outputDirectory != null) return outputDirectory;
    try {
      return await getTemporaryDirectory();
    } catch (_) {
      try {
        return await getApplicationDocumentsDirectory();
      } catch (_) {
        return Directory.systemTemp;
      }
    }
  }

  Future<void> _pruneTempExportsIfDefault(Directory? outputDirectory) async {
    if (outputDirectory == null) {
      try {
        await ref.read(tempStorageServiceProvider).pruneStaleExportFiles();
      } catch (_) {}
    }
  }

  static String sanitizeFileName(String databaseName) {
    var safe = databaseName
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '')
        .trim();
    if (safe.isEmpty) {
      safe = 'database';
    }
    if (safe.length > 50) {
      safe = safe.substring(0, 50);
    }
    return safe;
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
