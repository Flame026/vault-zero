import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

import 'tabular_data_source.dart';

class CsvDataSource implements TabularDataSource {
  final File file;

  CsvDataSource(this.file);

  @override
  Future<List<String>> getHeaders() async {
    if (!await file.exists()) {
      throw const FormatException('CSV file does not exist.');
    }

    try {
      final stream = file.openRead();
      final rows = await stream
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(csv.decoder)
          .take(1)
          .toList();

      if (rows.isEmpty || rows.first.isEmpty) {
        return const [];
      }

      final firstRow = rows.first;
      return firstRow.asMap().entries.map((entry) {
        var header = entry.value?.toString() ?? '';
        if (entry.key == 0 && header.startsWith('\uFEFF')) {
          header = header.substring(1);
        }
        return header;
      }).toList();
    } catch (e) {
      if (e is FormatException) rethrow;
      throw FormatException('Failed to read CSV file: $e');
    }
  }

  @override
  Stream<List<dynamic>> getRows() {
    return file
        .openRead()
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(csv.decoder)
        .skip(1); // Skip the header row
  }
}
