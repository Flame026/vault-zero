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
import 'package:vault_zero/presentation/common/widgets/vault_icon_badge.dart';
import 'package:vault_zero/presentation/common/widgets/vault_section_header.dart';
import 'package:vault_zero/presentation/fields/field_list_screen.dart';
import 'package:vault_zero/presentation/fields/widgets/field_card.dart';
import 'package:vault_zero/presentation/records/record_list_screen.dart';
import 'package:vault_zero/presentation/records/widgets/record_card.dart';

void main() {
  group('Batch 18: Record Browsing & Information Density Polish', () {
    late Database db;
    late String testDbId;
    late SqliteSchemaRepository schemaRepo;
    late SqliteRecordRepository recordRepo;

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
      recordRepo = SqliteRecordRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Widget buildTestApp(Widget child) {
      return ProviderScope(
        overrides: [databaseProvider.overrideWith((ref) => db)],
        child: MaterialApp(home: child),
      );
    }

    testWidgets(
      '1. RecordCard renders prominent typography and italicized placeholder for untitled records',
      (tester) async {
        final field = FieldDefinition(
          id: 'f_title',
          databaseId: testDbId,
          name: 'Title',
          type: FieldType.text,
          position: 0,
          isRequired: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final untitledRecord = Record(
          id: 'r_empty',
          databaseId: testDbId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          values: const {},
        );

        final populatedRecord = Record(
          id: 'r_pop',
          databaseId: testDbId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          values: {
            'f_title': const TextFieldValue(
              id: 'v1',
              recordId: 'r_pop',
              fieldId: 'f_title',
              value: 'Vault Master Key',
            ),
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  RecordCard(
                    record: untitledRecord,
                    fields: [field],
                    onTap: () {},
                    onDelete: () {},
                  ),
                  RecordCard(
                    record: populatedRecord,
                    fields: [field],
                    onTap: () {},
                    onDelete: () {},
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Untitled record renders italicized styling
        final untitledTextFinder = find.text('Untitled Record');
        expect(untitledTextFinder, findsOneWidget);
        final untitledWidget = tester.widget<Text>(untitledTextFinder);
        expect(untitledWidget.style?.fontStyle, equals(FontStyle.italic));

        // Populated record renders normal font style with semi-bold weight
        final populatedTextFinder = find.text('Vault Master Key');
        expect(populatedTextFinder, findsOneWidget);
        final populatedWidget = tester.widget<Text>(populatedTextFinder);
        expect(populatedWidget.style?.fontStyle, equals(FontStyle.normal));
        expect(populatedWidget.style?.fontWeight, equals(FontWeight.w600));
      },
    );

    testWidgets(
      '2. RecordCard dynamically maps primary field type to appropriate glyph in VaultIconBadge',
      (tester) async {
        final textField = FieldDefinition(
          id: 'f_txt',
          databaseId: testDbId,
          name: 'Notes',
          type: FieldType.longText,
          position: 0,
          isRequired: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final numField = FieldDefinition(
          id: 'f_num',
          databaseId: testDbId,
          name: 'Count',
          type: FieldType.integer,
          position: 0,
          isRequired: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final dateField = FieldDefinition(
          id: 'f_date',
          databaseId: testDbId,
          name: 'Due',
          type: FieldType.date,
          position: 0,
          isRequired: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final recText = Record(
          id: 'r_txt',
          databaseId: testDbId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          values: {
            'f_txt': const LongTextFieldValue(
              id: 'v_txt',
              recordId: 'r_txt',
              fieldId: 'f_txt',
              value: 'Sample text',
            ),
          },
        );

        final recNum = Record(
          id: 'r_num',
          databaseId: testDbId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          values: {
            'f_num': const IntegerFieldValue(
              id: 'v_num',
              recordId: 'r_num',
              fieldId: 'f_num',
              value: 42,
            ),
          },
        );

        final recDate = Record(
          id: 'r_date',
          databaseId: testDbId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          values: {
            'f_date': DateFieldValue(
              id: 'v_date',
              recordId: 'r_date',
              fieldId: 'f_date',
              value: DateTime(2026, 1, 1),
            ),
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  RecordCard(
                    record: recText,
                    fields: [textField],
                    onTap: () {},
                    onDelete: () {},
                  ),
                  RecordCard(
                    record: recNum,
                    fields: [numField],
                    onTap: () {},
                    onDelete: () {},
                  ),
                  RecordCard(
                    record: recDate,
                    fields: [dateField],
                    onTap: () {},
                    onDelete: () {},
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify type-specific glyphs render
        expect(find.byIcon(Icons.notes_rounded), findsOneWidget);
        expect(find.byIcon(Icons.numbers_rounded), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
      },
    );

    testWidgets(
      '3. RecordCard and FieldCard context menus isolate Delete with PopupMenuDivider',
      (tester) async {
        bool tapped = false;
        bool deleted = false;

        final field = FieldDefinition(
          id: 'f1',
          databaseId: testDbId,
          name: 'Field Alpha',
          type: FieldType.text,
          position: 0,
          isRequired: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final record = Record(
          id: 'r1',
          databaseId: testDbId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          values: {
            'f1': const TextFieldValue(
              id: 'v1',
              recordId: 'r1',
              fieldId: 'f1',
              value: 'Record One',
            ),
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  RecordCard(
                    record: record,
                    fields: [field],
                    onTap: () => tapped = true,
                    onDelete: () => deleted = true,
                  ),
                  FieldCard(field: field, onEdit: () {}, onDelete: () {}),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open RecordCard popup menu
        final recordMenuButton = find.byTooltip(
          'Record options for Record One',
        );
        expect(recordMenuButton, findsOneWidget);
        await tester.tap(recordMenuButton);
        await tester.pumpAndSettle();

        // Context menu contains Edit, Divider, and Delete
        expect(find.text('Edit'), findsOneWidget);
        expect(find.byType(PopupMenuDivider), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);

        // Tap Edit in popup menu
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();
        expect(tapped, isTrue);

        // Open FieldCard popup menu
        final fieldMenuButton = find.byTooltip('Field options for Field Alpha');
        expect(fieldMenuButton, findsOneWidget);
        await tester.tap(fieldMenuButton);
        await tester.pumpAndSettle();

        // FieldCard context menu also contains Divider before Delete
        expect(find.byType(PopupMenuDivider), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);

        // Tap Delete in FieldCard popup menu
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Open RecordCard popup menu again and tap Delete
        await tester.tap(recordMenuButton);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(deleted, isTrue);
      },
    );

    testWidgets(
      '4. RecordListScreen sort popup marks the active sort order with checkmark',
      (tester) async {
        final field = FieldDefinition(
          id: 'f1',
          databaseId: testDbId,
          name: 'Title',
          type: FieldType.text,
          position: 0,
          isRequired: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final database = DatabaseDefinition(
          id: testDbId,
          name: 'Sorting Lab',
          description: '',
          fields: [field],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await schemaRepo.createDatabase(database);

        final record1 = Record(
          id: 'r1',
          databaseId: testDbId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          values: {
            'f1': const TextFieldValue(
              id: 'v1',
              recordId: 'r1',
              fieldId: 'f1',
              value: 'A',
            ),
          },
        );
        await recordRepo.saveRecord(record1);

        await tester.pumpWidget(
          buildTestApp(RecordListScreen(database: database)),
        );
        await tester.pumpAndSettle();

        // Tap sort button
        await tester.tap(find.byTooltip('Sort records'));
        await tester.pumpAndSettle();

        // Initially Newest first is selected and has checkmark
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);

        // Switch to Oldest first
        await tester.tap(find.text('Oldest first'));
        await tester.pumpAndSettle();

        // Re-open sort menu
        await tester.tap(find.byTooltip('Sort records'));
        await tester.pumpAndSettle();

        // Active checkmark is still present on the new selection
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      },
    );

    testWidgets(
      '5. RecordListScreen renders VaultSectionHeader and drag-to-dismiss keyboard on scroll',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final field = FieldDefinition(
          id: 'f1',
          databaseId: testDbId,
          name: 'Title',
          type: FieldType.text,
          position: 0,
          isRequired: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final database = DatabaseDefinition(
          id: testDbId,
          name: 'Scroll Lab',
          description: '',
          fields: [field],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await schemaRepo.createDatabase(database);

        final record = Record(
          id: 'r1',
          databaseId: testDbId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          values: {
            'f1': const TextFieldValue(
              id: 'v1',
              recordId: 'r1',
              fieldId: 'f1',
              value: 'Scroll Item',
            ),
          },
        );
        await recordRepo.saveRecord(record);

        await tester.pumpWidget(
          buildTestApp(RecordListScreen(database: database)),
        );
        await tester.pumpAndSettle();

        // VaultSectionHeader displays section title
        expect(find.byType(VaultSectionHeader), findsOneWidget);
        expect(find.text('ALL RECORDS'), findsOneWidget);

        // Verify ListView has onDrag keyboard dismissal
        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(
          listView.keyboardDismissBehavior,
          equals(ScrollViewKeyboardDismissBehavior.onDrag),
        );
      },
    );

    testWidgets(
      '6. RecordListScreen empty records state provides secondary action to Manage Fields',
      (tester) async {
        final field = FieldDefinition(
          id: 'f1',
          databaseId: testDbId,
          name: 'Schema Only Field',
          type: FieldType.text,
          position: 0,
          isRequired: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final database = DatabaseDefinition(
          id: testDbId,
          name: 'Zero Records DB',
          description: '',
          fields: [field],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await schemaRepo.createDatabase(database);

        await tester.pumpWidget(
          buildTestApp(RecordListScreen(database: database)),
        );
        await tester.pumpAndSettle();

        expect(find.text('No Records'), findsOneWidget);
        expect(find.text('Add Record'), findsOneWidget);
        expect(find.text('Manage Fields'), findsOneWidget);

        // Tapping secondary action opens FieldListScreen
        await tester.tap(find.text('Manage Fields'));
        await tester.pumpAndSettle();

        expect(find.byType(FieldListScreen), findsOneWidget);
      },
    );

    testWidgets(
      '7. Export sheet renders VaultIconBadge for Excel and CSV options without overflow',
      (tester) async {
        final field = FieldDefinition(
          id: 'f1',
          databaseId: testDbId,
          name: 'Title',
          type: FieldType.text,
          position: 0,
          isRequired: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final database = DatabaseDefinition(
          id: testDbId,
          name: 'Export Lab',
          description: '',
          fields: [field],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await schemaRepo.createDatabase(database);

        await tester.pumpWidget(
          buildTestApp(RecordListScreen(database: database)),
        );
        await tester.pumpAndSettle();

        // Tap export button
        final exportButton = find.byTooltip('Export Data');
        expect(exportButton, findsOneWidget);
        await tester.tap(exportButton);
        await tester.pumpAndSettle();

        // Export sheet displays formatted options with VaultIconBadge
        expect(find.text('Export Database'), findsOneWidget);
        expect(find.text('Excel Spreadsheet (.xlsx)'), findsOneWidget);
        expect(find.text('CSV Document (.csv)'), findsOneWidget);
        expect(find.byType(VaultIconBadge), findsNWidgets(2));
      },
    );

    testWidgets(
      '8. RecordListScreen in landscape mode (800x360) renders GridView without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final field = FieldDefinition(
          id: 'f1',
          databaseId: testDbId,
          name: 'Title',
          type: FieldType.text,
          position: 0,
          isRequired: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final database = DatabaseDefinition(
          id: testDbId,
          name: 'Landscape Records',
          description: '',
          fields: [field],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await schemaRepo.createDatabase(database);

        final record = Record(
          id: 'r1',
          databaseId: testDbId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          values: {
            'f1': const TextFieldValue(
              id: 'v1',
              recordId: 'r1',
              fieldId: 'f1',
              value: 'Landscape Item',
            ),
          },
        );
        await recordRepo.saveRecord(record);

        await tester.pumpWidget(
          buildTestApp(RecordListScreen(database: database)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(GridView), findsOneWidget);
        expect(find.text('Landscape Item'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );
  });
}
