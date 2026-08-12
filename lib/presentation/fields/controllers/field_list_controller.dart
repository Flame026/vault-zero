import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../domain/models/field_definition.dart';

class FieldListController extends FamilyAsyncNotifier<List<FieldDefinition>, String> {
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
    final repository = await ref.read(schemaRepositoryProvider.future);
    
    // We don't want to use state.guard here because it wipes out the UI on error.
    // Instead we grab current state, do mutation, and refresh.
    final currentFields = state.valueOrNull ?? [];
    
    final newField = FieldDefinition(
      id: const Uuid().v4(),
      databaseId: arg, // `arg` is the databaseId
      name: name.trim(),
      type: type,
      position: currentFields.length,
      isRequired: isRequired,
      configuration: configuration,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.createField(newField);
      final fields = await repository.getFieldsForDatabase(arg);
      fields.sort((a, b) => a.position.compareTo(b.position));
      return fields;
    });
  }

  Future<void> updateField(
    FieldDefinition field, {
    required String name,
    required bool isRequired,
    FieldConfig? configuration,
  }) async {
    final repository = await ref.read(schemaRepositoryProvider.future);
    
    final updatedField = field.copyWith(
      name: name.trim(),
      isRequired: isRequired,
      configuration: configuration,
      updatedAt: DateTime.now(),
    );

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateField(updatedField);
      final fields = await repository.getFieldsForDatabase(arg);
      fields.sort((a, b) => a.position.compareTo(b.position));
      return fields;
    });
  }

  Future<void> deleteField(String id) async {
    final repository = await ref.read(schemaRepositoryProvider.future);
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteField(id);
      
      // Fix positions of remaining fields
      final fields = await repository.getFieldsForDatabase(arg);
      fields.sort((a, b) => a.position.compareTo(b.position));
      
      for (int i = 0; i < fields.length; i++) {
        fields[i] = fields[i].copyWith(position: i);
      }
      await repository.updateFields(fields);
      
      return fields;
    });
  }

  Future<void> reorderFields(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final currentFields = state.valueOrNull?.toList();
    if (currentFields == null) return;

    final item = currentFields.removeAt(oldIndex);
    currentFields.insert(newIndex, item);

    // Update positions locally
    for (int i = 0; i < currentFields.length; i++) {
      currentFields[i] = currentFields[i].copyWith(position: i, updatedAt: DateTime.now());
    }

    // Optimistic update
    state = AsyncValue.data(currentFields);

    // Background sync
    try {
      final repository = await ref.read(schemaRepositoryProvider.future);
      await repository.updateFields(currentFields);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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

final fieldListControllerProvider = AsyncNotifierProviderFamily<FieldListController, List<FieldDefinition>, String>(() {
  return FieldListController();
});
