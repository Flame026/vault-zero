import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vault_zero/core/theme/app_theme.dart';
import 'package:vault_zero/core/theme/design_tokens.dart';
import 'package:vault_zero/core/theme/theme_preset.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/domain/models/field_value.dart';
import 'package:vault_zero/domain/models/record.dart';
import 'package:vault_zero/presentation/common/widgets/vault_card.dart';
import 'package:vault_zero/presentation/databases/widgets/database_card.dart';
import 'package:vault_zero/presentation/fields/widgets/field_card.dart';
import 'package:vault_zero/presentation/records/widgets/record_card.dart';
import 'package:vault_zero/presentation/settings/settings_screen.dart';
import 'package:vault_zero/presentation/settings/widgets/theme_picker_sheet.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Widget buildTestApp(
    Widget child, {
    ThemePreset preset = ThemePreset.royalPurple,
    Brightness brightness = Brightness.light,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: preset.buildTheme(brightness),
        home: Scaffold(body: child),
      ),
    );
  }

  group('Batch 20: Final Product Polish & De-Vibe-Coding', () {
    testWidgets(
      '1. FieldCard, DatabaseCard, and RecordCard share standard horizontal padding and geometry',
      (tester) async {
        final now = DateTime(2026, 1, 1);
        final testDb = DatabaseDefinition(
          id: 'db_1',
          name: 'Inventory',
          description: 'Store inventory',
          createdAt: now,
          updatedAt: now,
          fields: const [],
        );

        final decimalField = FieldDefinition(
          id: 'f_dec',
          databaseId: 'db_1',
          name: 'Price',
          type: FieldType.decimal,
          position: 0,
          isRequired: true,
          createdAt: now,
          updatedAt: now,
        );

        final testRecord = Record(
          id: 'rec_1',
          databaseId: 'db_1',
          values: {
            'f_dec': DecimalFieldValue(
              id: 'v_1',
              recordId: 'rec_1',
              fieldId: 'f_dec',
              value: 19.99,
            ),
          },
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          buildTestApp(
            Column(
              children: [
                DatabaseCard(
                  database: testDb,
                  onTap: () {},
                  onEdit: () {},
                  onDelete: () {},
                  onManageFields: () {},
                ),
                FieldCard(field: decimalField, onEdit: () {}, onDelete: () {}),
                RecordCard(
                  record: testRecord,
                  fields: [decimalField],
                  onTap: () {},
                  onDelete: () {},
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final cards = tester
            .widgetList<VaultCard>(find.byType(VaultCard))
            .toList();
        expect(cards.length, 3);

        for (final card in cards) {
          expect(
            card.padding,
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          );
        }
      },
    );

    testWidgets(
      '2. FieldCard and RecordCard both render Icons.tag_rounded for FieldType.decimal',
      (tester) async {
        final now = DateTime(2026, 1, 1);
        final decimalField = FieldDefinition(
          id: 'f_dec',
          databaseId: 'db_1',
          name: 'Weight',
          type: FieldType.decimal,
          position: 0,
          isRequired: false,
          createdAt: now,
          updatedAt: now,
        );

        final testRecord = Record(
          id: 'rec_1',
          databaseId: 'db_1',
          values: {
            'f_dec': DecimalFieldValue(
              id: 'v_2',
              recordId: 'rec_1',
              fieldId: 'f_dec',
              value: 42.5,
            ),
          },
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          buildTestApp(
            Column(
              children: [
                FieldCard(field: decimalField, onEdit: () {}, onDelete: () {}),
                RecordCard(
                  record: testRecord,
                  fields: [decimalField],
                  onTap: () {},
                  onDelete: () {},
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.tag_rounded), findsNWidgets(2));
        expect(find.byIcon(Icons.attach_money_rounded), findsNothing);
      },
    );

    testWidgets(
      '3. SettingsScreen and ThemePickerSheet do NOT contain arbitrary BoxShadow glows',
      (tester) async {
        await tester.pumpWidget(buildTestApp(const SettingsScreen()));
        await tester.pumpAndSettle();

        final decoratedBoxes = tester.widgetList<DecoratedBox>(
          find.byType(DecoratedBox),
        );
        for (final box in decoratedBoxes) {
          final decoration = box.decoration;
          if (decoration is BoxDecoration) {
            expect(
              decoration.boxShadow,
              isNull,
              reason: 'Arbitrary BoxShadow detected in SettingsScreen',
            );
          }
        }

        await tester.tap(find.text('Theme Color'));
        await tester.pumpAndSettle();

        expect(find.byType(ThemePickerSheet), findsOneWidget);
        final sheetDecoratedBoxes = tester.widgetList<DecoratedBox>(
          find.byType(DecoratedBox),
        );
        for (final box in sheetDecoratedBoxes) {
          final decoration = box.decoration;
          if (decoration is BoxDecoration) {
            expect(
              decoration.boxShadow,
              isNull,
              reason: 'Arbitrary BoxShadow detected in ThemePickerSheet',
            );
          }
        }
      },
    );

    test(
      '4. ThemeData configures centralized listTileTheme and iconButtonTheme',
      () {
        final theme = ThemePreset.royalPurple.buildTheme(Brightness.light);

        expect(
          theme.listTileTheme.shape,
          const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        );
        expect(
          theme.listTileTheme.contentPadding,
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
        );
        expect(
          theme.iconButtonTheme.style?.minimumSize?.resolve({}),
          const Size(
            AppControlSizes.minTouchTarget,
            AppControlSizes.minTouchTarget,
          ),
        );
      },
    );

    testWidgets(
      '5. Branded 32x32 loading spinner used across light and dark modes',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
        );
        await tester.pump();

        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.width, 32.0);
        expect(sizedBox.height, 32.0);

        final spinner = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(spinner.strokeWidth, 3.0);
      },
    );

    testWidgets(
      '6. All 5 Theme presets build cleanly in both Light and Dark modes',
      (tester) async {
        for (final preset in ThemePreset.values) {
          final lightTheme = preset.buildTheme(Brightness.light);
          final darkTheme = preset.buildTheme(Brightness.dark);

          expect(lightTheme.brightness, Brightness.light);
          expect(darkTheme.brightness, Brightness.dark);
          expect(lightTheme.useMaterial3, isTrue);
          expect(darkTheme.useMaterial3, isTrue);
          expect(lightTheme.colorScheme.primary, isNotNull);
          expect(darkTheme.colorScheme.primary, isNotNull);
        }
      },
    );

    testWidgets(
      '7. Narrow 320px viewport with 2.0x text scaling renders cards cleanly without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime(2026, 1, 1);
        final testDb = DatabaseDefinition(
          id: 'db_1',
          name: 'Database With Very Long Title For Regression Testing',
          description:
              'Extensive description testing text wrap and touch geometry in narrow viewports.',
          createdAt: now,
          updatedAt: now,
          fields: const [],
        );

        await tester.pumpWidget(
          buildTestApp(
            MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: ListView(
                children: [
                  DatabaseCard(
                    database: testDb,
                    onTap: () {},
                    onEdit: () {},
                    onDelete: () {},
                    onManageFields: () {},
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.text('Database With Very Long Title For Regression Testing'),
          findsOneWidget,
        );
      },
    );
  });
}
