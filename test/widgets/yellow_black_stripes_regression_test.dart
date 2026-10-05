import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault_zero/core/theme/app_theme.dart';
import 'package:vault_zero/core/theme/theme_preset.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/domain/models/field_value.dart';
import 'package:vault_zero/domain/models/record.dart';
import 'package:vault_zero/presentation/databases/controllers/database_list_controller.dart';
import 'package:vault_zero/presentation/databases/database_list_screen.dart';
import 'package:vault_zero/presentation/databases/widgets/database_card.dart';
import 'package:vault_zero/presentation/databases/widgets/database_form_dialog.dart';
import 'package:vault_zero/presentation/databases/widgets/delete_confirmation_dialog.dart';
import 'package:vault_zero/presentation/fields/widgets/delete_field_dialog.dart';
import 'package:vault_zero/presentation/records/widgets/delete_record_dialog.dart';
import 'package:vault_zero/presentation/records/widgets/record_card.dart';

class MockDbController extends DatabaseListController {
  final List<DatabaseDefinition> dbs;
  MockDbController(this.dbs);
  @override
  Future<List<DatabaseDefinition>> build() async => dbs;
}

void main() {
  final now = DateTime.now();
  final testDb = DatabaseDefinition(
    id: 'db-1',
    name:
        'Vault Inventory with a Very Long Name That Could Cause Layout Overflow',
    description: 'Detailed description of sensitive assets and records',
    fields: [],
    createdAt: now,
    updatedAt: now,
  );

  final testField = FieldDefinition(
    id: 'field-1',
    databaseId: 'db-1',
    name: 'Extended Field Name For Asset Tracking Category',
    type: FieldType.text,
    position: 0,
    isRequired: true,
    createdAt: now,
    updatedAt: now,
  );

  group('Yellow/Black Stripes Rendering Regression Tests', () {
    testWidgets(
      'Theme switching across all presets and modes does not cause overflow stripes',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        for (final preset in ThemePreset.values) {
          for (final mode in [ThemeMode.light, ThemeMode.dark]) {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  databaseListControllerProvider.overrideWith(
                    () => MockDbController([testDb]),
                  ),
                ],
                child: MaterialApp(
                  theme: preset.buildTheme(Brightness.light),
                  darkTheme: preset.buildTheme(Brightness.dark),
                  themeMode: mode,
                  home: const DatabaseListScreen(),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: 'Overflow occurred for preset $preset in $mode mode',
            );
          }
        }
      },
    );

    testWidgets(
      'Orientation rotation portrait to short landscape produces no stripes',
      (tester) async {
        // Start in portrait
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseListControllerProvider.overrideWith(
                () => MockDbController([testDb]),
              ),
            ],
            child: const MaterialApp(home: DatabaseListScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Rotate to short landscape (640x320)
        tester.view.physicalSize = const Size(640, 320);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Navigation and scrolling through screens produces no overflow stripes',
      (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseListControllerProvider.overrideWith(
                () => MockDbController(
                  List.generate(
                    10,
                    (i) => DatabaseDefinition(
                      id: 'db-$i',
                      name: 'Database #$i Extended Title',
                      description: 'Description of Database #$i',
                      fields: [],
                      createdAt: now,
                      updatedAt: now,
                    ),
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: DatabaseListScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Scroll list down and up
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.drag(find.byType(ListView), const Offset(0, 300));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'All dialogs render cleanly in narrow 320px and short 320px landscape',
      (tester) async {
        tester.view.physicalSize = const Size(320, 320);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. DatabaseFormDialog
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () =>
                      DatabaseFormDialog.show(ctx, initialDatabase: testDb),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // 2. DeleteConfirmationDialog
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () =>
                      DeleteConfirmationDialog.show(ctx, database: testDb),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // 3. DeleteFieldDialog
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () =>
                      DeleteFieldDialog.show(ctx, field: testField),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // 4. DeleteRecordDialog
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => DeleteRecordDialog.show(
                    ctx,
                    recordTitle: 'Record Sample',
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'App lifecycle pause and resume does not cause overflow or crash',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseListControllerProvider.overrideWith(
                () => MockDbController([testDb]),
              ),
            ],
            child: const MaterialApp(home: DatabaseListScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Trigger app pause
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        expect(tester.takeException(), isNull);

        // Trigger app resume
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'DatabaseListScreen in portrait and landscape with large text scale (1.5x, 2.0x) produces zero overflows',
      (tester) async {
        final dbs = [
          testDb,
          DatabaseDefinition(
            id: 'db-2',
            name: 'Another Database With Multi-Line Information',
            description:
                'Secondary description that takes multiple lines and exercises typography scaling.',
            fields: [testField],
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final configurations = [
          // (Size, TextScale, Description)
          (const Size(360, 640), 1.0, 'Portrait 1.0x text'),
          (const Size(360, 640), 1.5, 'Portrait 1.5x text'),
          (const Size(360, 640), 2.0, 'Portrait 2.0x text'),
          (const Size(640, 360), 1.0, 'Landscape 1.0x text'),
          (const Size(640, 360), 1.5, 'Landscape 1.5x text (repro scenario)'),
          (const Size(640, 360), 2.0, 'Landscape 2.0x text'),
          (const Size(600, 320), 1.5, 'Narrow landscape 1.5x text'),
        ];

        for (final config in configurations) {
          tester.view.physicalSize = config.$1;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                databaseListControllerProvider.overrideWith(
                  () => MockDbController(dbs),
                ),
              ],
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: config.$1,
                    textScaler: TextScaler.linear(config.$2),
                  ),
                  child: const DatabaseListScreen(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow stripes occurred on ${config.$3}',
          );
        }
      },
    );

    testWidgets(
      'DatabaseCard and RecordCard inside landscape grid cell render without overflow at 1.5x and 2.0x text scale',
      (tester) async {
        final record = Record(
          id: 'rec-1',
          databaseId: 'db-1',
          values: {
            'field-1': const TextFieldValue(
              id: 'v-1',
              recordId: 'rec-1',
              fieldId: 'field-1',
              value: 'A moderately long record value that takes space',
            ),
          },
          createdAt: now,
          updatedAt: now,
        );

        for (final scale in [1.0, 1.5, 2.0]) {
          // Test DatabaseCard
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: SizedBox(
                    width: 300,
                    child: DatabaseCard(
                      database: testDb,
                      onTap: () {},
                      onEdit: () {},
                      onDelete: () {},
                      onManageFields: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'DatabaseCard overflowed at ${scale}x scale',
          );

          // Test RecordCard
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: SizedBox(
                    width: 300,
                    child: RecordCard(
                      record: record,
                      fields: [testField],
                      onTap: () {},
                      onDelete: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'RecordCard overflowed at ${scale}x scale',
          );
        }
      },
    );

    testWidgets(
      'Import Database sheet in portrait is compact and content-sized',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseListControllerProvider.overrideWith(
                () => MockDbController([testDb]),
              ),
            ],
            child: const MaterialApp(home: DatabaseListScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Import Database
        await tester.tap(find.byTooltip('Import Database'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Import Database'), findsOneWidget);
        expect(find.text('CSV Document (.csv)'), findsOneWidget);
        expect(find.text('Excel Spreadsheet (.xlsx)'), findsOneWidget);

        // Verify sheet height is content-sized (~350-420px) and much less than 90% of screen (844 * 0.9 = 759.6)
        final sheetFinder = find.widgetWithText(Column, 'Import Database');
        final sheetSize = tester.getSize(sheetFinder);
        expect(sheetSize.height, lessThan(500));
        expect(sheetSize.height, lessThan(844 * 0.7));
      },
    );

    testWidgets(
      'Import Database sheet in landscape is scrollable and options are tappable',
      (tester) async {
        // Short landscape viewport: 800 x 360
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseListControllerProvider.overrideWith(
                () => MockDbController([testDb]),
              ),
            ],
            child: const MaterialApp(home: DatabaseListScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Import Database
        await tester.tap(find.byTooltip('Import Database'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Import Database'), findsOneWidget);
        expect(find.text('CSV Document (.csv)'), findsOneWidget);
        expect(find.text('Excel Spreadsheet (.xlsx)'), findsOneWidget);

        // Tap CSV Document to ensure it is interactive and tappable without error
        await tester.tap(find.text('CSV Document (.csv)'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
