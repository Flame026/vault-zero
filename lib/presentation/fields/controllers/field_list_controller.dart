import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../domain/models/field_definition.dart';
import '../../records/controllers/record_list_controller.dart';

class FieldListController
    extends FamilyAsyncNotifier<List<FieldDefinition>, String> {
  @override
  Future<List<FieldDefinition>> build(String arg) async {
    final repository = await ref.watch(schemaRepositoryProvider.future);
    final fields = await repository.getFieldsForDatabase(arg);
    // Ensure fields are sorted by position
    fields.sort((a, b) => a.position.compareTo(b.position));
    return fields;
  }

  Future<void> createField({
    required String name,
    required FieldType type,
    required bool isRequired,
    FieldConfig? configuration,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Field name cannot be empty.');
    }
    if (!isNameUnique(trimmedName)) {
      throw ArgumentError(
        'A field with the name "$trimmedName" already exists.',
      );
    }

    final repository = await ref.read(schemaRepositoryProvider.future);

    // We don't want to use state.guard here because it wipes out the UI on error.
    // Instead we grab current state, do mutation, and refresh.
    final currentFields = state.valueOrNull ?? [];

    final newField = FieldDefinition(
      id: const Uuid().v4(),
      databaseId: arg, // `arg` is the databaseId
      name: trimmedName,
      type: type,
      position: currentFields.length,
      isRequired: isRequired,
      configuration: configuration,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = const AsyncValue.loading();
    try {
      await repository.createField(newField);
      final fields = await repository.getFieldsForDatabase(arg);
      fields.sort((a, b) => a.position.compareTo(b.position));
      state = AsyncValue.data(fields);
      ref.invalidate(recordListControllerProvider(arg));
    } catch (e, st) {
      state = AsyncError<List<FieldDefinition>>(e, st);
      rethrow;
    }
  }

  Future<void> updateField(
    FieldDefinition field, {
    required String name,
    required bool isRequired,
    FieldConfig? configuration,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Field name cannot be empty.');
    }
    if (!isNameUnique(trimmedName, excludeFieldId: field.id)) {
      throw ArgumentError(
        'A field with the name "$trimmedName" already exists.',
      );
    }

    final repository = await ref.read(schemaRepositoryProvider.future);

    final updatedField = field.copyWith(
      name: trimmedName,
      isRequired: isRequired,
      configuration: configuration,
      updatedAt: DateTime.now(),
    );

    state = const AsyncValue.loading();
    try {
      await repository.updateField(updatedField);
      final fields = await repository.getFieldsForDatabase(arg);
      fields.sort((a, b) => a.position.compareTo(b.position));
      state = AsyncValue.data(fields);
      ref.invalidate(recordListControllerProvider(arg));
    } catch (e, st) {
      state = AsyncError<List<FieldDefinition>>(e, st);
      rethrow;
    }
  }

  Future<void> deleteField(String id) async {
    final repository = await ref.read(schemaRepositoryProvider.future);

    state = const AsyncValue.loading();
    try {
      await repository.deleteField(id);

      // Fix positions of remaining fields
      final fields = await repository.getFieldsForDatabase(arg);
      fields.sort((a, b) => a.position.compareTo(b.position));

      for (int i = 0; i < fields.length; i++) {
        fields[i] = fields[i].copyWith(position: i);
      }
      await repository.updateFields(fields);
      state = AsyncValue.data(fields);
      ref.invalidate(recordListControllerProvider(arg));
    } catch (e, st) {
      state = AsyncError<List<FieldDefinition>>(e, st);
      rethrow;
    }
  }

  Future<void> moveField(int oldIndex, int targetIndex) async {
    if (oldIndex == targetIndex) return;

    final currentFields = state.valueOrNull?.toList();
    if (currentFields == null) return;
    if (oldIndex < 0 || oldIndex >= currentFields.length) return;
    if (targetIndex < 0 || targetIndex >= currentFields.length) return;

    final item = currentFields.removeAt(oldIndex);
    currentFields.insert(targetIndex, item);

    // Update positions locally
    for (int i = 0; i < currentFields.length; i++) {
      currentFields[i] = currentFields[i].copyWith(
        position: i,
        updatedAt: DateTime.now(),
      );
    }

    // Optimistic update
    state = AsyncValue.data(currentFields);

    // Background sync
    try {
      final repository = await ref.read(schemaRepositoryProvider.future);
      await repository.updateFields(currentFields);
      ref.invalidate(recordListControllerProvider(arg));
    } catch (e, st) {
      state = AsyncError<List<FieldDefinition>>(e, st);
      rethrow;
    }
  }

  Future<void> reorderFields(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    return moveField(oldIndex, newIndex);
  }

  bool isNameUnique(String name, {String? excludeFieldId}) {
    final currentFields = state.valueOrNull ?? [];
    final trimmedName = name.trim().toLowerCase();

    return !currentFields.any((f) {
      if (excludeFieldId != null && f.id == excludeFieldId) return false;
      return f.name.toLowerCase() == trimmedName;
    });
  }
}

final fieldListControllerProvider =
    AsyncNotifierProviderFamily<
      FieldListController,
      List<FieldDefinition>,
      String
    >(() {
      return FieldListController();
    });
