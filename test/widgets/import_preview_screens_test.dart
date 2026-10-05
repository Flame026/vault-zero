import 'dart:io';

import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vault_zero/presentation/common/widgets/vault_error_view.dart';
import 'package:vault_zero/presentation/import/csv_preview_screen.dart';
import 'package:vault_zero/presentation/import/excel_preview_screen.dart';

void main() {
  late Directory tempDir;
  late File csvFile;
  late File headersOnlyCsv;
  late File emptyCsv;
  late File excelFile;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('vault_zero_preview_test');

    csvFile = File(
      '${tempDir.path}/sample.csv',
    )..writeAsStringSync('Name,Age,City\nAlice,30,Wonderland\nBob,25,Atlantis');

    headersOnlyCsv = File('${tempDir.path}/headers_only.csv')
      ..writeAsStringSync('Col1,Col2\n');

    emptyCsv = File('${tempDir.path}/empty.csv')..writeAsStringSync('');

    // Create a multi-sheet Excel workbook
    final excel = Excel.createExcel();
    final sheet1 = excel['Employees'];
    sheet1.appendRow([TextCellValue('Name'), TextCellValue('Role')]);
    sheet1.appendRow([TextCellValue('Alice'), TextCellValue('Engineer')]);
    final sheet2 = excel['Projects'];
    sheet2.appendRow([TextCellValue('Project'), TextCellValue('Status')]);
    sheet2.appendRow([TextCellValue('VaultZero'), TextCellValue('Active')]);
    excel.delete('Sheet1');

    final excelBytes = excel.save();
    excelFile = File('${tempDir.path}/sample.xlsx')
      ..writeAsBytesSync(excelBytes!);
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget createCsvPreviewWidget(String path) {
    return ProviderScope(
      child: MaterialApp(home: CsvPreviewScreen(filePath: path)),
    );
  }

  Widget createExcelPreviewWidget(String path) {
    return ProviderScope(
      child: MaterialApp(home: ExcelPreviewScreen(filePath: path)),
    );
  }

  Future<void> pumpUntilLoaded(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      if (!tester.any(find.byType(CircularProgressIndicator))) {
        break;
      }
    }
    await tester.pump();
  }

  group('CsvPreviewScreen Widget Tests', () {
    testWidgets('renders source file details, headers chips, and sample rows', (
      tester,
    ) async {
      await tester.pumpWidget(createCsvPreviewWidget(csvFile.path));
      await pumpUntilLoaded(tester);

      expect(find.text('Preview CSV Import'), findsOneWidget);
      expect(find.text('sample.csv'), findsOneWidget);
      expect(find.text('3 columns'), findsOneWidget);
      expect(find.text('2 sample rows'), findsOneWidget);

      // Detected headers
      expect(find.text('Name'), findsWidgets);
      expect(find.text('Age'), findsWidgets);
      expect(find.text('City'), findsWidgets);

      // Sample data
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Wonderland'), findsOneWidget);

      // Import button
      expect(find.text('Import Database'), findsOneWidget);
    });

    testWidgets('displays empty rows card when CSV contains only headers', (
      tester,
    ) async {
      await tester.pumpWidget(createCsvPreviewWidget(headersOnlyCsv.path));
      await pumpUntilLoaded(tester);

      expect(find.text('headers_only.csv'), findsOneWidget);
      expect(
        find.text('This file contains headers but no record rows.'),
        findsOneWidget,
      );
    });

    testWidgets('displays recoverable VaultErrorView when CSV is empty', (
      tester,
    ) async {
      await tester.pumpWidget(createCsvPreviewWidget(emptyCsv.path));
      await pumpUntilLoaded(tester);

      expect(find.byType(VaultErrorView), findsOneWidget);
      expect(find.text('Could not load CSV'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('validates database name input on empty value', (tester) async {
      await tester.pumpWidget(createCsvPreviewWidget(csvFile.path));
      await pumpUntilLoaded(tester);

      // Clear the target database name
      final nameField = find.widgetWithText(
        TextFormField,
        'Target Database Name',
      );
      await tester.enterText(nameField, '');
      await tester.pump();

      // Tap import
      await tester.tap(find.text('Import Database'));
      await tester.pump();

      expect(find.text('Database name cannot be empty'), findsOneWidget);
    });
  });

  group('ExcelPreviewScreen Widget Tests', () {
    testWidgets(
      'renders multi-sheet dropdown, switches sheets, and displays sample data',
      (tester) async {
        await tester.pumpWidget(createExcelPreviewWidget(excelFile.path));
        await pumpUntilLoaded(tester);

        expect(find.text('Preview Excel Import'), findsOneWidget);
        expect(find.text('sample.xlsx'), findsOneWidget);
        expect(find.text('2 sheets'), findsOneWidget);

        // Initial sheet (Employees)
        expect(find.text('Name'), findsWidgets);
        expect(find.text('Role'), findsWidgets);
        expect(find.text('Alice'), findsOneWidget);
        expect(find.text('Engineer'), findsOneWidget);

        // Worksheet selection dropdown should be present
        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

        // Switch to Projects sheet
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Projects').last);
        await pumpUntilLoaded(tester);

        // Should now display Projects columns
        expect(find.text('Project'), findsWidgets);
        expect(find.text('Status'), findsWidgets);
        expect(find.text('VaultZero'), findsOneWidget);
        expect(find.text('Active'), findsOneWidget);
      },
    );

    testWidgets(
      'displays recoverable VaultErrorView when Excel file is invalid',
      (tester) async {
        final invalidFile = File('${tempDir.path}/corrupt.xlsx')
          ..writeAsStringSync('not an excel file');

        await tester.pumpWidget(createExcelPreviewWidget(invalidFile.path));
        await pumpUntilLoaded(tester);

        expect(find.byType(VaultErrorView), findsOneWidget);
        expect(find.text('Could not load Excel'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      },
    );

    testWidgets(
      'validates database name input on empty value in ExcelPreview',
      (tester) async {
        await tester.pumpWidget(createExcelPreviewWidget(excelFile.path));
        await pumpUntilLoaded(tester);

        final nameField = find.widgetWithText(
          TextFormField,
          'Target Database Name',
        );
        await tester.enterText(nameField, '');
        await tester.pump();

        await tester.tap(find.text('Import Database'));
        await tester.pump();

        expect(find.text('Database name cannot be empty'), findsOneWidget);
      },
    );
  });
}
