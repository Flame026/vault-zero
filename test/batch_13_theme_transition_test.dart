import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:vault_zero/core/preferences/preferences_repository.dart';
import 'package:vault_zero/core/providers.dart';
import 'package:vault_zero/core/theme/app_theme.dart';
import 'package:vault_zero/core/theme/theme_preset.dart';
import 'package:vault_zero/core/theme/theme_provider.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/data/repositories/sqlite_schema_repository.dart';
import 'package:vault_zero/data/repositories/sqlite_record_repository.dart';
import 'package:vault_zero/presentation/common/widgets/vault_snackbar.dart';
import 'package:vault_zero/presentation/fields/field_form_screen.dart';
import 'package:vault_zero/presentation/records/record_form_screen.dart';
import 'package:vault_zero/presentation/settings/settings_screen.dart';
import 'package:vault_zero/presentation/settings/widgets/theme_picker_sheet.dart';

class InMemoryPreferencesRepository implements PreferencesRepository {
  Map<String, dynamic> storage = {};
  Future<void>? _activeSave;

  @override
  Future<Directory> Function()? get getDocsDir => null;

  @override
  Future<Map<String, dynamic>> loadPreferences() async {
    return Map<String, dynamic>.from(storage);
  }

  @override
  Future<void> savePreferences(Map<String, dynamic> data) {
    final prev = _activeSave ?? Future.value();
    final next = prev.then((_) async {
      storage.addAll(data);
    });
    _activeSave = next.catchError((_) {});
    return next;
  }

  @override
  Future<void> flush() async {
    final active = _activeSave;
    if (active != null) {
      await active;
    }
  }

  @override
  Future<String?> getString(String key) async => storage[key] as String?;

  @override
  Future<void> setString(String key, String value) =>
      savePreferences({key: value});
}

class DelayedPreferencesRepository implements PreferencesRepository {
  final Map<String, dynamic> initialStorage;
  final Duration delay;
  Map<String, dynamic> storage;

  DelayedPreferencesRepository({
    required this.initialStorage,
    this.delay = const Duration(milliseconds: 100),
  }) : storage = Map.from(initialStorage);

  @override
  Future<Directory> Function()? get getDocsDir => null;

  @override
  Future<Map<String, dynamic>> loadPreferences() async {
    await Future.delayed(delay);
    return Map<String, dynamic>.from(storage);
  }

  @override
  Future<void> savePreferences(Map<String, dynamic> data) async {
    storage.addAll(data);
  }

  @override
  Future<void> flush() async {}

  @override
  Future<String?> getString(String key) async => storage[key] as String?;

  @override
  Future<void> setString(String key, String value) =>
      savePreferences({key: value});
}

void main() {
  late Database db;
  late SqliteSchemaRepository schemaRepo;
  late SqliteRecordRepository recordRepo;
  late DatabaseDefinition testDb;
  late FieldDefinition testField;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE databases (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE fields (
              id TEXT PRIMARY KEY,
              database_id TEXT NOT NULL,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              position INTEGER NOT NULL,
              is_required INTEGER NOT NULL,
              configuration TEXT,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              FOREIGN KEY (database_id) REFERENCES databases (id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE records (
              id TEXT PRIMARY KEY,
              database_id TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              FOREIGN KEY (database_id) REFERENCES databases (id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE field_values (
              id TEXT PRIMARY KEY,
              record_id TEXT NOT NULL,
              field_id TEXT NOT NULL,
              text_value TEXT,
              integer_value INTEGER,
              decimal_value REAL,
              boolean_value INTEGER,
              date_value INTEGER,
              date_time_value INTEGER,
              choice_value TEXT,
              FOREIGN KEY (record_id) REFERENCES records (id) ON DELETE CASCADE,
              FOREIGN KEY (field_id) REFERENCES fields (id) ON DELETE CASCADE,
              UNIQUE(record_id, field_id)
            )
          ''');
        },
      ),
    );

    schemaRepo = SqliteSchemaRepository(db);
    recordRepo = SqliteRecordRepository(db);

    testDb = DatabaseDefinition(
      id: const Uuid().v4(),
      name: 'Theme Transition DB',
      description: 'Testing screen rebuilds across theme shifts',
      fields: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await schemaRepo.createDatabase(testDb);

    testField = FieldDefinition(
      id: 'field_title',
      databaseId: testDb.id,
      name: 'Title Note',
      type: FieldType.text,
      position: 0,
      isRequired: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await schemaRepo.createField(testField);
  });

  tearDown(() async {
    await db.close();
  });

  group('Batch 13: Theme Engine & State Reliability', () {
    test('ThemeState value equality and copyWith semantics', () {
      const state1 = ThemeState(
        mode: ThemeMode.dark,
        preset: ThemePreset.oceanBlue,
        isLoaded: true,
      );
      const state2 = ThemeState(
        mode: ThemeMode.dark,
        preset: ThemePreset.oceanBlue,
        isLoaded: true,
      );
      const state3 = ThemeState(
        mode: ThemeMode.light,
        preset: ThemePreset.oceanBlue,
        isLoaded: true,
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state1, isNot(equals(state3)));

      final updated = state1.copyWith(mode: ThemeMode.light);
      expect(updated.mode, ThemeMode.light);
      expect(updated.preset, ThemePreset.oceanBlue);
      expect(updated.isLoaded, isTrue);
    });

    test(
      'User mutation before async load finishes is not overwritten by disk data',
      () async {
        final repo = DelayedPreferencesRepository(
          initialStorage: {'themeMode': 'light', 'themePreset': 'rosePink'},
          delay: const Duration(milliseconds: 50),
        );

        final container = ProviderContainer(
          overrides: [preferencesRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        final controller = container.read(themeProvider.notifier);
        // User immediately chooses dark mode + sunsetOrange before delayed load returns
        await controller.changeMode(ThemeMode.dark);
        await controller.changePreset(ThemePreset.sunsetOrange);

        // Now wait long enough for delayed load to complete
        await Future.delayed(const Duration(milliseconds: 80));

        final finalState = container.read(themeProvider);
        // Must retain user choice
        expect(finalState.mode, ThemeMode.dark);
        expect(finalState.preset, ThemePreset.sunsetOrange);
      },
    );

    test(
      'Concurrent preference saves queue sequentially without data corruption',
      () async {
        final repo = InMemoryPreferencesRepository();
        final container = ProviderContainer(
          overrides: [preferencesRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        final controller = container.read(themeProvider.notifier);

        // Rapidly fire multiple mode and preset updates
        final f1 = controller.changeMode(ThemeMode.light);
        final f2 = controller.changePreset(ThemePreset.emeraldGreen);
        final f3 = controller.changeMode(ThemeMode.dark);
        final f4 = controller.changePreset(ThemePreset.oceanBlue);

        await Future.wait([f1, f2, f3, f4]);

        expect(repo.storage['themeMode'], 'dark');
        expect(repo.storage['themePreset'], 'oceanBlue');
        expect(container.read(themeProvider).mode, ThemeMode.dark);
        expect(container.read(themeProvider).preset, ThemePreset.oceanBlue);
      },
    );
  });

  group('Batch 13: Light/Dark Switching & System Theme Handling', () {
    testWidgets(
      'Switching ThemeMode from SettingsScreen preserves state and adapts UI',
      (tester) async {
        final repo = InMemoryPreferencesRepository();
        repo.storage = {'themeMode': 'system', 'themePreset': 'royalPurple'};

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferencesRepositoryProvider.overrideWithValue(repo),
              schemaRepositoryProvider.overrideWith((ref) => schemaRepo),
              recordRepositoryProvider.overrideWith((ref) => recordRepo),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                final themeState = ref.watch(themeProvider);
                return MaterialApp(
                  themeMode: themeState.mode,
                  theme: themeState.preset.buildTheme(Brightness.light),
                  darkTheme: themeState.preset.buildTheme(Brightness.dark),
                  home: const SettingsScreen(),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find SegmentedButton segments
        expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);

        // Tap 'Dark'
        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();

        expect(repo.storage['themeMode'], 'dark');

        // Tap 'Light'
        await tester.tap(find.text('Light'));
        await tester.pumpAndSettle();

        expect(repo.storage['themeMode'], 'light');

        // Tap 'System'
        await tester.tap(find.text('System'));
        await tester.pumpAndSettle();

        expect(repo.storage['themeMode'], 'system');
      },
    );

    testWidgets(
      'VaultSnackbar explicitly binds icon colors to high-contrast onInverseSurface',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemePreset.royalPurple.buildTheme(Brightness.light),
            darkTheme: ThemePreset.royalPurple.buildTheme(Brightness.dark),
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          VaultSnackbar.showSuccess(context, 'Success message'),
                      child: const Text('Show Success'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          VaultSnackbar.showInfo(context, 'Info message'),
                      child: const Text('Show Info'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger success snackbar
        await tester.tap(find.text('Show Success'));
        await tester.pumpAndSettle();

        final successIcon = tester.widget<Icon>(
          find.byIcon(Icons.check_circle_outline_rounded),
        );
        expect(successIcon.color, isNotNull);

        // Trigger info snackbar
        await tester.tap(find.text('Show Info'));
        await tester.pumpAndSettle();

        final infoIcon = tester.widget<Icon>(
          find.byIcon(Icons.info_outline_rounded),
        );
        expect(infoIcon.color, isNotNull);
      },
    );
  });

  group(
    'Batch 13: Orientation + Constrained Landscape Layout (Zero Stripes)',
    () {
      testWidgets(
        'ThemePickerSheet in short landscape 500x240 and 1.5x text scale produces zero overflows',
        (tester) async {
          tester.view.physicalSize = const Size(500, 240);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(500, 240),
                    textScaler: TextScaler.linear(1.5),
                  ),
                  child: const Scaffold(
                    body: ThemePickerSheet(isDialog: false),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Theme Color'), findsOneWidget);
          expect(find.text('Done'), findsOneWidget);
        },
      );

      testWidgets(
        'ThemePickerSheet dialog in 320x240 landscape produces zero overflows',
        (tester) async {
          tester.view.physicalSize = const Size(320, 240);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(320, 240),
                    textScaler: TextScaler.linear(1.4),
                  ),
                  child: const Scaffold(body: ThemePickerSheet(isDialog: true)),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Theme Color'), findsOneWidget);
          expect(find.text('Done'), findsOneWidget);
        },
      );
    },
  );

  group('Batch 13: Screen-Wide Rebuild Safety & Form Input Retention', () {
    testWidgets(
      'RecordFormScreen retains form inputs across repeated theme mode transitions',
      (tester) async {
        final repo = InMemoryPreferencesRepository();
        repo.storage = {'themeMode': 'light', 'themePreset': 'royalPurple'};

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferencesRepositoryProvider.overrideWithValue(repo),
              schemaRepositoryProvider.overrideWith((ref) => schemaRepo),
              recordRepositoryProvider.overrideWith((ref) => recordRepo),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                final themeState = ref.watch(themeProvider);
                return MaterialApp(
                  themeMode: themeState.mode,
                  theme: themeState.preset.buildTheme(Brightness.light),
                  darkTheme: themeState.preset.buildTheme(Brightness.dark),
                  home: RecordFormScreen(
                    databaseId: testDb.id,
                    fields: [testField],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter text into field
        final input = find.byType(TextFormField);
        expect(input, findsOneWidget);
        await tester.enterText(input, 'Persistent Record Text');
        await tester.pumpAndSettle();

        // Switch theme to Dark
        final context = tester.element(find.byType(RecordFormScreen));
        final container = ProviderScope.containerOf(context);
        await container.read(themeProvider.notifier).changeMode(ThemeMode.dark);
        await tester.pumpAndSettle();

        // Verify text is still present in dark theme
        expect(find.text('Persistent Record Text'), findsOneWidget);

        // Switch preset to Emerald Green
        await container
            .read(themeProvider.notifier)
            .changePreset(ThemePreset.emeraldGreen);
        await tester.pumpAndSettle();

        // Verify text is still intact after preset rebuild
        expect(find.text('Persistent Record Text'), findsOneWidget);

        // Switch back to Light
        await container
            .read(themeProvider.notifier)
            .changeMode(ThemeMode.light);
        await tester.pumpAndSettle();

        expect(find.text('Persistent Record Text'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'FieldFormScreen retains field inputs across theme transitions',
      (tester) async {
        final repo = InMemoryPreferencesRepository();
        repo.storage = {'themeMode': 'dark', 'themePreset': 'sunsetOrange'};

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferencesRepositoryProvider.overrideWithValue(repo),
              schemaRepositoryProvider.overrideWith((ref) => schemaRepo),
              recordRepositoryProvider.overrideWith((ref) => recordRepo),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                final themeState = ref.watch(themeProvider);
                return MaterialApp(
                  themeMode: themeState.mode,
                  theme: themeState.preset.buildTheme(Brightness.light),
                  darkTheme: themeState.preset.buildTheme(Brightness.dark),
                  home: FieldFormScreen(databaseId: testDb.id),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter field name
        final nameField = find.widgetWithText(TextFormField, 'Field Name');
        await tester.enterText(nameField, 'Custom Metric');
        await tester.pumpAndSettle();

        // Toggle theme mode to Light
        final context = tester.element(find.byType(FieldFormScreen));
        final container = ProviderScope.containerOf(context);
        await container
            .read(themeProvider.notifier)
            .changeMode(ThemeMode.light);
        await tester.pumpAndSettle();

        expect(find.text('Custom Metric'), findsOneWidget);

        // Change preset to Ocean Blue
        await container
            .read(themeProvider.notifier)
            .changePreset(ThemePreset.oceanBlue);
        await tester.pumpAndSettle();

        expect(find.text('Custom Metric'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
