import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../data/importers/tabular_data_source.dart';
import '../../../domain/models/database_definition.dart';
import '../../fields/controllers/field_list_controller.dart';
import '../../records/controllers/record_list_controller.dart';

class DatabaseListController extends AsyncNotifier<List<DatabaseDefinition>> {
  @override
  Future<List<DatabaseDefinition>> build() async {
    final repository = await ref.watch(schemaRepositoryProvider.future);
    return repository.getAllDatabases();
  }

  Future<void> createDatabase({
    required String name,
    String description = '',
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Database name cannot be empty.');
    }

    state = const AsyncValue.loading();
    try {
      final repository = await ref.read(schemaRepositoryProvider.future);

      final db = DatabaseDefinition(
        id: const Uuid().v4(),
        name: trimmedName,
        description: description.trim(),
        fields: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createDatabase(db);
      final databases = await repository.getAllDatabases();
      state = AsyncValue.data(databases);
    } catch (e, st) {
      state = AsyncError<List<DatabaseDefinition>>(e, st);
      rethrow;
    }
  }

  Future<void> updateDatabase(
    DatabaseDefinition database, {
    required String name,
    String description = '',
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Database name cannot be empty.');
    }

    state = const AsyncValue.loading();
    try {
      final repository = await ref.read(schemaRepositoryProvider.future);

      final updatedDb = database.copyWith(
        name: trimmedName,
        description: description.trim(),
        updatedAt: DateTime.now(),
      );

      await repository.updateDatabase(updatedDb);
      final databases = await repository.getAllDatabases();
      state = AsyncValue.data(databases);
    } catch (e, st) {
      state = AsyncError<List<DatabaseDefinition>>(e, st);
      rethrow;
    }
  }

  Future<void> deleteDatabase(String id) async {
    state = const AsyncValue.loading();
    try {
      final repository = await ref.read(schemaRepositoryProvider.future);
      await repository.deleteDatabase(id);
      ref.invalidate(fieldListControllerProvider(id));
      ref.invalidate(recordListControllerProvider(id));
      final databases = await repository.getAllDatabases();
      state = AsyncValue.data(databases);
    } catch (e, st) {
      state = AsyncError<List<DatabaseDefinition>>(e, st);
      rethrow;
    }
  }

  Future<void> importDatabase({
    required String name,
    required TabularDataSource source,
  }) async {
    state = const AsyncValue.loading();
    try {
      final importService = await ref.read(importServiceProvider.future);
      await importService.importDatabase(name, source);
      final repository = await ref.read(schemaRepositoryProvider.future);
      final databases = await repository.getAllDatabases();
      state = AsyncValue.data(databases);
    } catch (e, st) {
      state = AsyncError<List<DatabaseDefinition>>(e, st);
      rethrow;
    }
  }
}

final databaseListControllerProvider =
    AsyncNotifierProvider<DatabaseListController, List<DatabaseDefinition>>(() {
      return DatabaseListController();
    });
