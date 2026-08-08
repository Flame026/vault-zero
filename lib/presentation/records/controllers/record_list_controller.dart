import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../domain/models/field_definition.dart';
import '../../../domain/models/field_value.dart';
import '../../../domain/models/record.dart';

class RecordListController extends FamilyAsyncNotifier<List<Record>, String> {
  @override
  Future<List<Record>> build(String arg) async {
    final repository = await ref.watch(recordRepositoryProvider.future);
    return repository.getRecordsForDatabase(arg);
  }

  Future<void> saveRecord({
    Record? existingRecord,
    required List<FieldDefinition> fields,
    required Map<String, dynamic> rawValues,
  }) async {
    final repository = await ref.read(recordRepositoryProvider.future);
    
    final recordId = existingRecord?.id ?? const Uuid().v4();
    final now = DateTime.now();
    
    final Map<String, FieldValue> fieldValues = {};
    
    for (final field in fields) {
      final rawValue = rawValues[field.id];
      // Keep existing FieldValue ID if editing, otherwise generate new one
      final valueId = existingRecord?.values[field.id]?.id ?? const Uuid().v4();
      
      FieldValue fieldValue;
      switch (field.type) {
        case FieldType.text:
          fieldValue = TextFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: (rawValue as String?) ?? '');
          break;
        case FieldType.longText:
          fieldValue = LongTextFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: (rawValue as String?) ?? '');
          break;
        case FieldType.integer:
          fieldValue = IntegerFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: (rawValue as int?) ?? 0);
          break;
        case FieldType.decimal:
          fieldValue = DecimalFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: (rawValue as double?) ?? 0.0);
          break;
        case FieldType.boolean:
          fieldValue = BooleanFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: (rawValue as bool?) ?? false);
          break;
        case FieldType.date:
          fieldValue = DateFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: (rawValue as DateTime?) ?? DateTime(1970));
          break;
        case FieldType.dateTime:
          fieldValue = DateTimeFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: (rawValue as DateTime?) ?? DateTime(1970));
          break;
        case FieldType.choice:
          fieldValue = ChoiceFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: (rawValue as String?) ?? '');
          break;
      }
      fieldValues[field.id] = fieldValue;
    }

    final newRecord = Record(
      id: recordId,
      databaseId: arg,
      values: fieldValues,
      createdAt: existingRecord?.createdAt ?? now,
      updatedAt: now,
    );

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.saveRecord(newRecord);
      return repository.getRecordsForDatabase(arg);
    });
  }

  Future<void> deleteRecord(String id) async {
    final repository = await ref.read(recordRepositoryProvider.future);
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteRecord(id);
      return repository.getRecordsForDatabase(arg);
    });
  }
}

final recordListControllerProvider = AsyncNotifierProviderFamily<RecordListController, List<Record>, String>(() {
  return RecordListController();
});
