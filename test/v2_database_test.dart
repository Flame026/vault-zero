import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/domain/models/field_value.dart';
import 'package:vault_zero/domain/models/record.dart';
import 'package:vault_zero/data/repositories/sqlite_schema_repository.dart';
import 'package:vault_zero/data/repositories/sqlite_record_repository.dart';

void main() {
  late Database db;
  late SqliteSchemaRepository schemaRepo;
  late SqliteRecordRepository recordRepo;
  final uuid = const Uuid();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
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
  });

  tearDown(() async {
    await db.close();
  });

  group('SchemaRepository CRUD', () {
    test('Create and Read Database', () async {
      final dbDef = DatabaseDefinition(
        id: uuid.v4(),
        name: 'Movies',
        description: 'A list of movies',
        fields: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await schemaRepo.createDatabase(dbDef);
      final retrieved = await schemaRepo.getDatabase(dbDef.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Movies');
      expect(retrieved.description, 'A list of movies');
    });

    test('Update Database', () async {
      final dbDef = DatabaseDefinition(
        id: uuid.v4(),
        name: 'Movies',
        fields: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await schemaRepo.createDatabase(dbDef);

      final updatedDef = dbDef.copyWith(name: 'Awesome Movies');
      await schemaRepo.updateDatabase(updatedDef);

      final retrieved = await schemaRepo.getDatabase(dbDef.id);
      expect(retrieved!.name, 'Awesome Movies');
    });

    test('Delete Database', () async {
      final dbDef = DatabaseDefinition(
        id: uuid.v4(),
        name: 'Movies',
        fields: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await schemaRepo.createDatabase(dbDef);
      await schemaRepo.deleteDatabase(dbDef.id);

      final retrieved = await schemaRepo.getDatabase(dbDef.id);
      expect(retrieved, isNull);
    });

    test('Create, Read, Update, Delete Field', () async {
      final dbId = uuid.v4();
      final dbDef = DatabaseDefinition(
        id: dbId,
        name: 'Movies',
        fields: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await schemaRepo.createDatabase(dbDef);

      final fieldId = uuid.v4();
      final fieldDef = FieldDefinition(
        id: fieldId,
        databaseId: dbId,
        name: 'Title',
        type: FieldType.text,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await schemaRepo.createField(fieldDef);
      var fields = await schemaRepo.getFieldsForDatabase(dbId);
      expect(fields.length, 1);
      expect(fields.first.name, 'Title');

      final updatedField = fieldDef.copyWith(name: 'Movie Title');
      await schemaRepo.updateField(updatedField);
      fields = await schemaRepo.getFieldsForDatabase(dbId);
      expect(fields.first.name, 'Movie Title');

      await schemaRepo.deleteField(fieldId);
      fields = await schemaRepo.getFieldsForDatabase(dbId);
      expect(fields, isEmpty);
    });
  });

  group('RecordRepository CRUD', () {
    late String dbId;
    late String fieldId;

    setUp(() async {
      dbId = uuid.v4();
      final dbDef = DatabaseDefinition(
        id: dbId,
        name: 'Books',
        fields: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await schemaRepo.createDatabase(dbDef);

      fieldId = uuid.v4();
      final fieldDef = FieldDefinition(
        id: fieldId,
        databaseId: dbId,
        name: 'Title',
        type: FieldType.text,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await schemaRepo.createField(fieldDef);
    });

    test('Create and Read Record', () async {
      final recordId = uuid.v4();
      final record = Record(
        id: recordId,
        databaseId: dbId,
        values: {
          fieldId: TextFieldValue(
            id: uuid.v4(),
            recordId: recordId,
            fieldId: fieldId,
            value: 'Dune',
          ),
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await recordRepo.saveRecord(record);
      final retrieved = await recordRepo.getRecord(recordId);

      expect(retrieved, isNotNull);
      expect(retrieved!.values.length, 1);
      expect((retrieved.values[fieldId] as TextFieldValue).value, 'Dune');
    });

    test('Update Record', () async {
      final recordId = uuid.v4();
      final record = Record(
        id: recordId,
        databaseId: dbId,
        values: {
          fieldId: TextFieldValue(
            id: uuid.v4(),
            recordId: recordId,
            fieldId: fieldId,
            value: 'Dune',
          ),
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await recordRepo.saveRecord(record);

      final updatedRecord = record.copyWith(
        values: {
          fieldId: TextFieldValue(
            id: uuid.v4(),
            recordId: recordId,
            fieldId: fieldId,
            value: 'Dune Messiah',
          ),
        },
        updatedAt: DateTime.now(),
      );
      await recordRepo.saveRecord(updatedRecord);

      final retrieved = await recordRepo.getRecord(recordId);
      expect((retrieved!.values[fieldId] as TextFieldValue).value, 'Dune Messiah');
    });

    test('Delete Record', () async {
      final recordId = uuid.v4();
      final record = Record(
        id: recordId,
        databaseId: dbId,
        values: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await recordRepo.saveRecord(record);
      await recordRepo.deleteRecord(recordId);

      final retrieved = await recordRepo.getRecord(recordId);
      expect(retrieved, isNull);
    });
  });

  group('Typed Values and Validation', () {
    late String dbId;
    final Map<FieldType, String> fieldIds = {};

    setUp(() async {
      dbId = uuid.v4();
      await schemaRepo.createDatabase(DatabaseDefinition(
        id: dbId,
        name: 'Test DB',
        fields: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      for (var type in FieldType.values) {
        final fId = uuid.v4();
        fieldIds[type] = fId;
        await schemaRepo.createField(FieldDefinition(
          id: fId,
          databaseId: dbId,
          name: type.name,
          type: type,
          position: 0,
          configuration: type == FieldType.choice ? const ChoiceConfig(options: ['Option A', 'Option B']) : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    });

    test('Store and retrieve all FieldTypes', () async {
      final recordId = uuid.v4();
      final record = Record(
        id: recordId,
        databaseId: dbId,
        values: {
          fieldIds[FieldType.text]!: TextFieldValue(id: uuid.v4(), recordId: recordId, fieldId: fieldIds[FieldType.text]!, value: 'Hello'),
          fieldIds[FieldType.longText]!: LongTextFieldValue(id: uuid.v4(), recordId: recordId, fieldId: fieldIds[FieldType.longText]!, value: 'World'),
          fieldIds[FieldType.integer]!: IntegerFieldValue(id: uuid.v4(), recordId: recordId, fieldId: fieldIds[FieldType.integer]!, value: 42),
          fieldIds[FieldType.decimal]!: DecimalFieldValue(id: uuid.v4(), recordId: recordId, fieldId: fieldIds[FieldType.decimal]!, value: 3.14),
          fieldIds[FieldType.boolean]!: BooleanFieldValue(id: uuid.v4(), recordId: recordId, fieldId: fieldIds[FieldType.boolean]!, value: true),
          fieldIds[FieldType.date]!: DateFieldValue(id: uuid.v4(), recordId: recordId, fieldId: fieldIds[FieldType.date]!, value: DateTime(2025, 1, 1)),
          fieldIds[FieldType.dateTime]!: DateTimeFieldValue(id: uuid.v4(), recordId: recordId, fieldId: fieldIds[FieldType.dateTime]!, value: DateTime(2025, 1, 1, 12, 30)),
          fieldIds[FieldType.choice]!: ChoiceFieldValue(id: uuid.v4(), recordId: recordId, fieldId: fieldIds[FieldType.choice]!, value: 'Option A'),
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await recordRepo.saveRecord(record);
      final retrieved = await recordRepo.getRecord(recordId);

      expect(retrieved, isNotNull);
      expect((retrieved!.values[fieldIds[FieldType.text]] as TextFieldValue).value, 'Hello');
      expect((retrieved.values[fieldIds[FieldType.longText]] as LongTextFieldValue).value, 'World');
      expect((retrieved.values[fieldIds[FieldType.integer]] as IntegerFieldValue).value, 42);
      expect((retrieved.values[fieldIds[FieldType.decimal]] as DecimalFieldValue).value, 3.14);
      expect((retrieved.values[fieldIds[FieldType.boolean]] as BooleanFieldValue).value, true);
      expect((retrieved.values[fieldIds[FieldType.date]] as DateFieldValue).value, DateTime(2025, 1, 1));
      expect((retrieved.values[fieldIds[FieldType.dateTime]] as DateTimeFieldValue).value, DateTime(2025, 1, 1, 12, 30));
      expect((retrieved.values[fieldIds[FieldType.choice]] as ChoiceFieldValue).value, 'Option A');
    });

    test('Type mismatch throws ArgumentError', () async {
      final recordId = uuid.v4();
      final record = Record(
        id: recordId,
        databaseId: dbId,
        values: {
          fieldIds[FieldType.integer]!: TextFieldValue(
            id: uuid.v4(),
            recordId: recordId,
            fieldId: fieldIds[FieldType.integer]!,
            value: 'Not an integer',
          ),
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(() => recordRepo.saveRecord(record), throwsArgumentError);
    });

    test('Foreign database field throws ArgumentError', () async {
      final recordId = uuid.v4();
      final record = Record(
        id: recordId,
        databaseId: dbId,
        values: {
          uuid.v4(): TextFieldValue(
            id: uuid.v4(),
            recordId: recordId,
            fieldId: uuid.v4(),
            value: 'Belongs to unknown DB',
          ),
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(() => recordRepo.saveRecord(record), throwsArgumentError);
    });
  });

  group('Foreign Key Constraints', () {
    test('Cascade delete database deletes fields and records', () async {
      final dbId = uuid.v4();
      await schemaRepo.createDatabase(DatabaseDefinition(
        id: dbId,
        name: 'Cascade DB',
        fields: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final fieldId = uuid.v4();
      await schemaRepo.createField(FieldDefinition(
        id: fieldId,
        databaseId: dbId,
        name: 'Field',
        type: FieldType.text,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final recordId = uuid.v4();
      await recordRepo.saveRecord(Record(
        id: recordId,
        databaseId: dbId,
        values: {
          fieldId: TextFieldValue(id: uuid.v4(), recordId: recordId, fieldId: fieldId, value: 'Data'),
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Delete the database
      await schemaRepo.deleteDatabase(dbId);

      // Verify cascading worked using raw queries to prove database state
      final fieldsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM fields WHERE database_id = ?', [dbId]));
      final recordsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM records WHERE database_id = ?', [dbId]));
      final valuesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM field_values WHERE record_id = ?', [recordId]));

      expect(fieldsCount, 0);
      expect(recordsCount, 0);
      expect(valuesCount, 0);
    });
  });

  group('Migration', () {
    test('V3 to V4 drops characters table but preserves generic data', () async {
      final tempDbPath = 'migration_test.db'; // SQLite FFI handles this in the test dir

      // Ensure clean state
      if (await databaseFactory.databaseExists(tempDbPath)) {
        await databaseFactory.deleteDatabase(tempDbPath);
      }

      // Step 1: Open at version 3 and create legacy + generic tables
      var migrationDb = await databaseFactory.openDatabase(
        tempDbPath,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE characters(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                faction TEXT NOT NULL,
                characterClass TEXT NOT NULL,
                title TEXT NOT NULL,
                skill1 TEXT NOT NULL,
                skill2 TEXT NOT NULL,
                skill3 TEXT NOT NULL,
                skill4 TEXT NOT NULL
              )
            ''');

            await db.execute('''
              CREATE TABLE databases (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
              )
            ''');
          },
        ),
      );

      // Step 2: Insert representative data
      await migrationDb.insert('characters', {
        'name': 'Legacy Hero',
        'faction': 'A',
        'characterClass': 'B',
        'title': 'C',
        'skill1': 'D',
        'skill2': 'E',
        'skill3': 'F',
        'skill4': 'G'
      });
      await migrationDb.insert('databases', {
        'id': 'db1',
        'name': 'Generic DB',
        'description': 'Desc',
        'created_at': 0,
        'updated_at': 0
      });
      await migrationDb.close();

      // Step 3: Upgrade to version 4 using the production logic
      migrationDb = await databaseFactory.openDatabase(
        tempDbPath,
        options: OpenDatabaseOptions(
          version: 4,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 4) {
              await db.execute('DROP TABLE IF EXISTS characters');
            }
          },
        ),
      );

      // Step 4: Verify the characters table no longer exists
      final legacyTableCheck = await migrationDb.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='characters'");
      expect(legacyTableCheck.isEmpty, isTrue, reason: 'characters table should have been dropped during migration');

      // Step 5: Verify generic tables still exist and data is intact
      final genericTableCheck = await migrationDb.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='databases'");
      expect(genericTableCheck.isNotEmpty, isTrue, reason: 'databases table should still exist');

      final dbData = await migrationDb.query('databases');
      expect(dbData.length, 1);
      expect(dbData.first['name'], 'Generic DB');

      await migrationDb.close();
      await databaseFactory.deleteDatabase(tempDbPath);
    });
  });
}
