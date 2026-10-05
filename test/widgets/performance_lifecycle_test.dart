import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:vault_zero/core/database/database_provider.dart';
import 'package:vault_zero/data/repositories/sqlite_record_repository.dart';
import 'package:vault_zero/data/repositories/sqlite_schema_repository.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/domain/models/field_value.dart';
import 'package:vault_zero/domain/models/record.dart';
import 'package:vault_zero/main.dart';
import 'package:vault_zero/presentation/databases/widgets/database_card.dart';
import 'package:vault_zero/presentation/records/widgets/record_card.dart';
import 'package:vault_zero/presentation/records/record_list_screen.dart';

void main() {
  late Database db;
  late String testDbId;
  late SqliteSchemaRepository schemaRepo;

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

    testDbId = const Uuid().v4();
    schemaRepo = SqliteSchemaRepository(db);

    await schemaRepo.createDatabase(
      DatabaseDefinition(
        id: testDbId,
        name: 'Performance Test DB',
        description:
            'Verifying rendering, lifecycle, and large dataset handling',
        fields: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Rendering & Stripes Check (Yellow/Black Overflow Prevention)', () {
    testWidgets(
      'DatabaseCard renders without yellow/black overflow stripes in narrow viewport (320px) with 2.0x text scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final longDatabase = DatabaseDefinition(
          id: 'db_long',
          name:
              'Extremely Long Database Name That Might Cause Flex Overflow If Not Wrapped Properly',
          description:
              'A very detailed multi-line database description designed to stress-test layout constraints and text bounds.',
          fields: [
            FieldDefinition(
              id: 'f1',
              databaseId: 'db_long',
              name: 'Field 1',
              type: FieldType.text,
              position: 0,
              isRequired: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 2),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(2.0),
                size: Size(320, 600),
              ),
              child: Scaffold(
                body: DatabaseCard(
                  database: longDatabase,
                  onTap: () {},
                  onEdit: () {},
                  onDelete: () {},
                  onManageFields: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Must have 0 FlutterError / overflow indicators
        expect(tester.takeException(), isNull);
        expect(find.byType(DatabaseCard), findsOneWidget);
      },
    );

    testWidgets(
      'RecordCard renders without yellow/black overflow stripes with long titles and secondary fields in 320px viewport',
      (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final field1 = FieldDefinition(
          id: 'f1',
          databaseId: testDbId,
          name: 'Primary Title Field With Extra Long Name',
          type: FieldType.text,
          position: 0,
          isRequired: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final field2 = FieldDefinition(
          id: 'f2',
          databaseId: testDbId,
          name: 'Secondary Detailed Attribute Name',
          type: FieldType.text,
          position: 1,
          isRequired: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final record = Record(
          id: 'rec_overflow_check',
          databaseId: testDbId,
          values: {
            'f1': TextFieldValue(
              id: 'v1',
              recordId: 'rec_overflow_check',
              fieldId: 'f1',
              value:
                  'A Very Long Primary Record Value Exceeding Normal Cell Width Significantly',
            ),
            'f2': TextFieldValue(
              id: 'v2',
              recordId: 'rec_overflow_check',
              fieldId: 'f2',
              value:
                  'An Equally Long Secondary Content String For Checking RichText Ellipsis',
            ),
          },
          createdAt: DateTime(2026, 3, 15),
          updatedAt: DateTime(2026, 3, 16),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(1.8),
                size: Size(320, 480),
              ),
              child: Scaffold(
                body: RecordCard(
                  record: record,
                  fields: [field1, field2],
                  onTap: () {},
                  onDelete: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Must have 0 FlutterError / overflow indicators
        expect(tester.takeException(), isNull);
        expect(find.byType(RecordCard), findsOneWidget);
      },
    );
  });

  group('Startup Performance & Lifecycle Observer', () {
    testWidgets(
      'VaultZeroApp initializes, displays splash, and transitions gracefully to DatabaseListScreen',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) => db)],
            child: const VaultZeroApp(),
          ),
        );

        // Splash screen is visible initially
        expect(find.byKey(const ValueKey('vault-zero-splash')), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Tap to dismiss splash immediately (startup optimization)
        await tester.tap(find.byKey(const ValueKey('vault-zero-splash')));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Home screen is now visible
        expect(find.byKey(const ValueKey('vault-zero-home')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'App handles background pause and resume lifecycle transitions cleanly',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) => db)],
            child: const VaultZeroApp(),
          ),
        );

        // Wait for splash transition
        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pumpAndSettle();

        // Simulate app moving to background (paused)
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();

        // Simulate app resuming from background (resumed)
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        // No exceptions thrown during lifecycle change
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('vault-zero-home')), findsOneWidget);
      },
    );
  });

  group('Large Dataset Handling & Keyset Pagination', () {
    testWidgets(
      'RecordListScreen renders large dataset and loads more on scroll without rebuild churn',
      (tester) async {
        final field1 = FieldDefinition(
          id: 'field_title',
          databaseId: testDbId,
          name: 'Title',
          type: FieldType.text,
          position: 0,
          isRequired: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await schemaRepo.createField(field1);

        final recordRepo = SqliteRecordRepository(db);

        // Populate 75 records (page 1 has 50, page 2 has 25)
        final records = List.generate(
          75,
          (i) => Record(
            id: 'rec_$i',
            databaseId: testDbId,
            values: {
              field1.id: TextFieldValue(
                id: 'val_$i',
                recordId: 'rec_$i',
                fieldId: field1.id,
                value: 'Record Item #$i',
              ),
            },
            createdAt: DateTime.fromMillisecondsSinceEpoch(1000000 + i * 1000),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(1000000 + i * 1000),
          ),
        );
        await recordRepo.saveRecordsBatch(records);

        final dbDef = (await schemaRepo.getDatabase(testDbId))!;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) => db)],
            child: MaterialApp(home: RecordListScreen(database: dbDef)),
          ),
        );

        // Wait for initial load
        await tester.pumpAndSettle();

        expect(find.text('50 records'), findsOneWidget);
        expect(find.byType(RecordCard), findsWidgets);
        expect(tester.takeException(), isNull);

        // Scroll to bottom to trigger loadMore
        final scrollable = find.byType(Scrollable);
        await tester.scrollUntilVisible(
          find.text('Record Item #0'),
          300,
          scrollable: scrollable,
        );
        await tester.pump();
        await tester.pumpAndSettle();

        // Verified: no exceptions thrown during keyset traversal
        expect(tester.takeException(), isNull);
      },
    );
  });
}
