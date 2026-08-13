import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

import 'tabular_data_source.dart';

class CsvDataSource implements TabularDataSource {
  final File file;

  CsvDataSource(this.file);

  @override
  Future<List<String>> getHeaders() async {
    final stream = file.openRead();
    final firstRow = await stream
        .transform(utf8.decoder)
        .transform(csv.decoder)
        .first;

    return firstRow.map((e) => e.toString()).toList();
  }

  @override
  Stream<List<dynamic>> getRows() {
    return file
        .openRead()
        .transform(utf8.decoder)
        .transform(csv.decoder)
        .skip(1); // Skip the header row
  }
}
