import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/sqlite_schema_repository.dart';
import '../domain/repositories/schema_repository.dart';
import 'database/database_provider.dart';

final schemaRepositoryProvider = FutureProvider<SchemaRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return SqliteSchemaRepository(db);
});
