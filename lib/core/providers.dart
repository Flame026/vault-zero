import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/sqlite_record_repository.dart';
import '../data/repositories/sqlite_schema_repository.dart';
import '../data/repositories/json_backup_restore_service.dart';
import '../domain/repositories/record_repository.dart';
import '../domain/repositories/schema_repository.dart';
import '../domain/repositories/backup_restore_service.dart';
import 'database/database_provider.dart';

final schemaRepositoryProvider = FutureProvider<SchemaRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return SqliteSchemaRepository(db);
});

final recordRepositoryProvider = FutureProvider<RecordRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return SqliteRecordRepository(db);
});

final backupRestoreServiceProvider = FutureProvider<BackupRestoreService>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return JsonBackupRestoreService(db);
});
