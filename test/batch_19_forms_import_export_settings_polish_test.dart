import 'dart:io';

import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vault_zero/core/theme/app_theme.dart';
import 'package:vault_zero/core/theme/theme_preset.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/presentation/common/widgets/vault_card.dart';
import 'package:vault_zero/presentation/common/widgets/vault_discard_dialog.dart';
import 'package:vault_zero/presentation/common/widgets/vault_icon_badge.dart';
import 'package:vault_zero/presentation/fields/field_form_screen.dart';
import 'package:vault_zero/presentation/import/csv_preview_screen.dart';
import 'package:vault_zero/presentation/import/excel_preview_screen.dart';
import 'package:vault_zero/presentation/records/record_form_screen.dart';
import 'package:vault_zero/presentation/records/widgets/dynamic_field_input.dart';
import 'package:vault_zero/presentation/settings/widgets/theme_picker_sheet.dart';

void main() {
  late Directory tempDir;
  late File sampleCsv;
  late File sampleExcel;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('vault_zero_b19_test');

    sampleCsv = File('${tempDir.path}/test.csv')
      ..writeAsStringSync('Product,Price\nWidget,19.99\nGadget,42.50\n');

    final excel = Excel.createExcel();
    final sheet = excel['Inventory'];
    sheet.appendRow([TextCellValue('SKU'), TextCellValue('Qty')]);
    sheet.appendRow([TextCellValue('SKU001'), TextCellValue('100')]);
    excel.delete('Sheet1');
    final bytes = excel.save();
    sampleExcel = File('${tempDir.path}/test.xlsx')..writeAsBytesSync(bytes!);
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget buildTestApp(Widget child, {ThemeData? theme}) {
    return ProviderScope(
      child: MaterialApp(
        theme: theme ?? ThemePreset.royalPurple.buildTheme(Brightness.light),
        home: child,
      ),
    );
  }

  Future<void> pumpAsyncUntilLoaded(WidgetTester tester) async {
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

  group('Batch 19: Forms, Import/Export & Settings Polish', () {
    testWidgets(
      '1. VaultDiscardDialog displays canonical strings and warning styling',
      (tester) async {
        bool? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await VaultDiscardDialog.show(context);
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Discard changes?'), findsOneWidget);
        expect(
          find.text(
            'You have unsaved changes. Are you sure you want to discard them and exit?',
          ),
          findsOneWidget,
        );
        expect(find.text('Keep Editing'), findsOneWidget);
        expect(find.text('Discard'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

        await tester.tap(find.text('Keep Editing'));
        await tester.pumpAndSettle();
        expect(result, isFalse);

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Discard'));
        await tester.pumpAndSettle();
        expect(result, isTrue);
      },
    );

    testWidgets(
      '2. RecordFormScreen renders VaultCard header with VaultIconBadge',
      (tester) async {
        final field = FieldDefinition(
          id: 'f1',
          databaseId: 'db1',
          name: 'Title',
          type: FieldType.text,
          position: 0,
          isRequired: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          buildTestApp(RecordFormScreen(databaseId: 'db1', fields: [field])),
        );
        await tester.pumpAndSettle();

        expect(find.text('New Record'), findsOneWidget);
        expect(find.text('New Record Entry'), findsOneWidget);
        expect(
          find.text(
            'Complete the fields below. Required fields are clearly marked.',
          ),
          findsOneWidget,
        );
        expect(find.byType(VaultIconBadge), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      },
    );

    testWidgets(
      '3. FieldFormScreen required toggle wrapped in VaultCard with subtitle',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(const FieldFormScreen(databaseId: 'db1')),
        );
        await tester.pumpAndSettle();

        expect(find.text('New Field'), findsOneWidget);
        expect(find.text('New Field Definition'), findsOneWidget);
        expect(find.text('Required Field'), findsOneWidget);
        expect(
          find.text('Must be filled out for every record'),
          findsOneWidget,
        );
        expect(find.byType(Switch), findsOneWidget);
        expect(find.byType(VaultCard), findsWidgets);
      },
    );

    testWidgets(
      '4. DynamicFieldInput uses specialized glyphs and cards for field types',
      (tester) async {
        final decimalField = FieldDefinition(
          id: 'f_dec',
          databaseId: 'db1',
          name: 'Price',
          type: FieldType.decimal,
          position: 0,
          isRequired: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final choiceField = FieldDefinition(
          id: 'f_choice',
          databaseId: 'db1',
          name: 'Category',
          type: FieldType.choice,
          position: 1,
          configuration: const ChoiceConfig(options: ['Food', 'Hardware']),
          isRequired: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final boolField = FieldDefinition(
          id: 'f_bool',
          databaseId: 'db1',
          name: 'In Stock',
          type: FieldType.boolean,
          position: 2,
          isRequired: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          buildTestApp(
            Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    DynamicFieldInput(
                      field: decimalField,
                      initialValue: null,
                      onChanged: (_) {},
                    ),
                    DynamicFieldInput(
                      field: choiceField,
                      initialValue: null,
                      onChanged: (_) {},
                    ),
                    DynamicFieldInput(
                      field: boolField,
                      initialValue: null,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.tag_rounded), findsOneWidget);
        expect(find.byIcon(Icons.list_rounded), findsOneWidget);
        expect(find.byType(VaultCard), findsOneWidget);
        expect(find.text('In Stock'), findsOneWidget);
      },
    );

    testWidgets(
      '5. CsvPreviewScreen renders VaultCard, badges, table, and validate input',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(CsvPreviewScreen(filePath: sampleCsv.path)),
        );
        await pumpAsyncUntilLoaded(tester);

        expect(find.text('Preview CSV Import'), findsOneWidget);
        expect(find.text('test.csv'), findsOneWidget);
        expect(find.text('2 columns'), findsOneWidget);
        expect(find.text('2 sample rows'), findsOneWidget);
        expect(find.text('Import Database'), findsOneWidget);
        expect(find.byType(VaultCard), findsWidgets);
        expect(find.text('Product'), findsWidgets);
        expect(find.text('Price'), findsWidgets);
      },
    );

    testWidgets(
      '6. ExcelPreviewScreen renders sheet badge, headers, table and import action',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(ExcelPreviewScreen(filePath: sampleExcel.path)),
        );
        await pumpAsyncUntilLoaded(tester);

        expect(find.text('Preview Excel Import'), findsOneWidget);
        expect(find.text('test.xlsx'), findsOneWidget);
        expect(find.text('1 sheet'), findsOneWidget);
        expect(find.text('2 columns'), findsOneWidget);
        expect(find.text('Import Database'), findsOneWidget);
        expect(find.text('SKU'), findsWidgets);
        expect(find.text('Qty'), findsWidgets);
      },
    );

    testWidgets('7. ThemePickerSheet displays modal with surfaceContainerLow', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ThemePickerSheet.show(context),
                child: const Text('Pick Theme'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Theme Color'), findsOneWidget);
      expect(find.text('Choose an appearance for Vault Zero'), findsOneWidget);
      expect(find.text('Royal Purple'), findsOneWidget);
      expect(find.text('Ocean Blue'), findsOneWidget);
    });

    testWidgets(
      '8. Form screens render gracefully without overflow at narrow 320px width',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 3.0, 600 * 3.0);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final field = FieldDefinition(
          id: 'f1',
          databaseId: 'db1',
          name: 'Title',
          type: FieldType.text,
          position: 0,
          isRequired: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          buildTestApp(RecordFormScreen(databaseId: 'db1', fields: [field])),
        );
        await tester.pumpAndSettle();

        expect(find.text('New Record'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
