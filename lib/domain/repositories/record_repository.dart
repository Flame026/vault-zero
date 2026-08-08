import '../models/record.dart';

abstract class RecordRepository {
  Future<void> saveRecord(Record record);
  Future<void> deleteRecord(String id);
  Future<Record?> getRecord(String id);
  Future<List<Record>> getRecordsForDatabase(String databaseId);
}
