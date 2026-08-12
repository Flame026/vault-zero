import '../models/record.dart';

import '../models/record_page.dart';

abstract class RecordRepository {
  Future<void> saveRecord(Record record);
  Future<void> deleteRecord(String id);
  Future<Record?> getRecord(String id);
  Future<List<Record>> getRecordsForDatabase(String databaseId);
  Future<RecordPage> getRecordsPage(
    String databaseId, {
    int limit = 50,
    RecordCursor? after,
  });
}
