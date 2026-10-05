import 'dart:io';

import 'package:excel/excel.dart' hide Border, TextSpan;

import 'tabular_data_source.dart';

class ExcelDataSource implements TabularDataSource {
  final File file;
  final String? sheetName;
  Excel? _cachedExcel;

  ExcelDataSource(this.file, {this.sheetName});

  Future<Excel> _decodeWorkbook() async {
    if (_cachedExcel != null) {
      return _cachedExcel!;
    }

    if (!await file.exists()) {
      throw const FormatException('Excel file does not exist.');
    }

    final List<int> bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      throw FormatException('Could not read Excel file: $e');
    }

    if (bytes.isEmpty) {
      throw const FormatException('Excel file is empty.');
    }

    final Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (e) {
      if (e is FormatException) rethrow;
      throw const FormatException(
        'Failed to parse Excel file. The file may be corrupt or not a valid Excel workbook.',
      );
    }

    if (excel.tables.isEmpty) {
      throw const FormatException('Workbook contains no sheets.');
    }

    _cachedExcel = excel;
    return excel;
  }

  /// Clears the cached decoded workbook from memory to free heap resources.
  void clearCache() {
    _cachedExcel = null;
  }

  /// Decodes and returns all available sheet names in the workbook.
  Future<List<String>> getSheetNames() async {
    final excel = await _decodeWorkbook();
    final sheets = excel.tables.keys.toList();
    if (sheets.isEmpty) {
      throw const FormatException('Workbook contains no sheets.');
    }

    return sheets;
  }

  Sheet _resolveSheet(Excel excel) {
    final targetSheetName = sheetName ?? excel.tables.keys.first;
    final sheet = excel.tables[targetSheetName];
    if (sheet == null) {
      throw FormatException(
        'Worksheet "$targetSheetName" not found in workbook.',
      );
    }
    return sheet;
  }

  static String _cellValueToString(Data? data) {
    if (data == null || data.value == null) {
      return '';
    }

    final cell = data.value!;
    if (cell is TextCellValue) {
      final text = cell.value.text;
      if (text == null) {
        return '';
      }
      return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    } else if (cell is IntCellValue) {
      return cell.value.toString();
    } else if (cell is DoubleCellValue) {
      return cell.value.toString();
    } else if (cell is BoolCellValue) {
      return cell.value ? 'true' : 'false';
    } else if (cell is DateCellValue) {
      final y = cell.year.toString().padLeft(4, '0');
      final m = cell.month.toString().padLeft(2, '0');
      final d = cell.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    } else if (cell is DateTimeCellValue) {
      final y = cell.year.toString().padLeft(4, '0');
      final m = cell.month.toString().padLeft(2, '0');
      final d = cell.day.toString().padLeft(2, '0');
      final h = cell.hour.toString().padLeft(2, '0');
      final min = cell.minute.toString().padLeft(2, '0');
      final s = cell.second.toString().padLeft(2, '0');
      return '$y-$m-$d $h:$min:$s';
    } else if (cell is TimeCellValue) {
      final h = cell.hour.toString().padLeft(2, '0');
      final min = cell.minute.toString().padLeft(2, '0');
      final s = cell.second.toString().padLeft(2, '0');
      return '$h:$min:$s';
    } else if (cell is FormulaCellValue) {
      return cell.formula;
    }

    return cell.toString();
  }

  @override
  Future<List<String>> getHeaders() async {
    final excel = await _decodeWorkbook();
    final sheet = _resolveSheet(excel);

    if (sheet.rows.isEmpty) {
      throw const FormatException('Selected worksheet is empty.');
    }

    final headerRow = sheet.rows.first;
    final headers = headerRow.map(_cellValueToString).toList();

    while (headers.isNotEmpty && headers.last.trim().isEmpty) {
      headers.removeLast();
    }

    if (headers.isEmpty || headers.every((h) => h.trim().isEmpty)) {
      throw const FormatException(
        'Selected worksheet has no valid header row.',
      );
    }

    return headers;
  }

  @override
  Stream<List<dynamic>> getRows() async* {
    final excel = await _decodeWorkbook();
    final sheet = _resolveSheet(excel);

    if (sheet.rows.length <= 1) {
      return;
    }

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      yield row.map(_cellValueToString).toList();
    }
  }
}
