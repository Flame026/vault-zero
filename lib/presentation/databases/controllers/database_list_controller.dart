import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../domain/models/database_definition.dart';

class DatabaseListController extends AsyncNotifier<List<DatabaseDefinition>> {
  @override
  Future<List<DatabaseDefinition>> build() async {
    final repository = await ref.watch(schemaRepositoryProvider.future);
    return repository.getAllDatabases();
  }

  Future<void> createDatabase({required String name, String description = ''}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(schemaRepositoryProvider.future);
      
      final db = DatabaseDefinition(
        id: const Uuid().v4(),
        name: name.trim(),
        description: description.trim(),
        fields: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createDatabase(db);
      return repository.getAllDatabases();
    });
  }

  Future<void> updateDatabase(DatabaseDefinition database, {required String name, String description = ''}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(schemaRepositoryProvider.future);
      
      final updatedDb = database.copyWith(
        name: name.trim(),
        description: description.trim(),
        updatedAt: DateTime.now(),
      );

      await repository.updateDatabase(updatedDb);
      return repository.getAllDatabases();
    });
  }

  Future<void> deleteDatabase(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(schemaRepositoryProvider.future);
      await repository.deleteDatabase(id);
      return repository.getAllDatabases();
    });
  }
}

final databaseListControllerProvider = AsyncNotifierProvider<DatabaseListController, List<DatabaseDefinition>>(() {
  return DatabaseListController();
});
