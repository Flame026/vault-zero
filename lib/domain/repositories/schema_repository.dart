import '../models/database_definition.dart';
import '../models/field_definition.dart';

abstract class SchemaRepository {
  Future<void> createDatabase(DatabaseDefinition database);
  Future<void> updateDatabase(DatabaseDefinition database);
  Future<void> deleteDatabase(String id);
  Future<DatabaseDefinition?> getDatabase(String id);
  Future<List<DatabaseDefinition>> getAllDatabases();

  Future<void> createField(FieldDefinition field);
  Future<void> updateField(FieldDefinition field);
  Future<void> deleteField(String id);
  Future<List<FieldDefinition>> getFieldsForDatabase(String databaseId);
}
