import 'dart:io';

import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../domain/models/database_definition.dart';
import '../../../domain/models/field_definition.dart';
import '../../../domain/models/record_page.dart';
import '../../../core/providers.dart';

final v2ExportControllerProvider = AsyncNotifierProvider<V2ExportController, void>(() {
  return V2ExportController();
});

class V2ExportController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<File?> exportToExcel(DatabaseDefinition database, List<FieldDefinition> fields) async {
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
      
      // Sanitize sheet name (max 31 chars, no invalid chars)
      var sheetName = database.name.replaceAll(RegExp(r'[\\/?*\[\]:]'), '_');
      if (sheetName.length > 31) {
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
            if (fieldValue != null && fieldValue.value != null) {
              rowCells.add(TextCellValue(fieldValue.value.toString()));
            } else {
              rowCells.add(TextCellValue(''));
            }
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

      excel.delete('Sheet1');
      final bytes = excel.save();

      if (bytes == null) {
        throw StateError('Excel package returned no file data.');
      }

      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      
      // Sanitize file name
      final safeDbName = database.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = 'vault_zero_${safeDbName}_${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}_${_twoDigits(now.hour)}-${_twoDigits(now.minute)}-${_twoDigits(now.second)}.xlsx';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(bytes, flush: true);
      generatedFile = file;
    });
    
    return generatedFile;
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
