import 'dart:io';

import 'package:excel/excel.dart' hide Border, TextSpan;

import 'tabular_data_source.dart';

class ExcelDataSource implements TabularDataSource {
  final File file;
  final String? sheetName;

  ExcelDataSource(this.file, {this.sheetName});

  /// Decodes and returns all available sheet names in the workbook.
  Future<List<String>> getSheetNames() async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('Excel file is empty.');
    }

    final excel = Excel.decodeBytes(bytes);
    final sheets = excel.tables.keys.toList();
    if (sheets.isEmpty) {
      throw const FormatException('Workbook contains no sheets.');
    }

    return sheets;
  }

  Future<Excel> _decodeWorkbook() async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('Excel file is empty.');
    }

    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw const FormatException('Workbook contains no sheets.');
    }

    return excel;
  }

  Sheet _resolveSheet(Excel excel) {
    final targetSheetName = sheetName ?? excel.tables.keys.first;
    final sheet = excel.tables[targetSheetName];
    if (sheet == null) {
      throw FormatException('Worksheet "$targetSheetName" not found in workbook.');
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
      if (text == null) return '';
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
    return headerRow.map(_cellValueToString).toList();
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
