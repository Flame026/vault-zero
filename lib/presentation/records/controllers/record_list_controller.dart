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
      final String rawString = (rawValues[field.id] as String?) ?? '';
      final valueId = existingRecord?.values[field.id]?.id ?? const Uuid().v4();
      
      FieldValue fieldValue;
      
      try {
        switch (field.type) {
          case FieldType.text:
          case FieldType.longText:
            fieldValue = field.type == FieldType.text 
              ? TextFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: rawString)
              : LongTextFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: rawString);
            break;
            
          case FieldType.integer:
            if (rawString.isEmpty && !field.isRequired) {
              fieldValue = IntegerFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: 0);
              break;
            }
            final parsedInt = int.tryParse(rawString);
            if (parsedInt == null) {
              throw Exception('Invalid integer value for field "${field.name}"');
            }
            fieldValue = IntegerFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: parsedInt);
            break;
            
          case FieldType.decimal:
            if (rawString.isEmpty && !field.isRequired) {
              fieldValue = DecimalFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: 0.0);
              break;
            }
            final parsedDouble = double.tryParse(rawString);
            if (parsedDouble == null) {
              throw Exception('Invalid decimal value for field "${field.name}"');
            }
            fieldValue = DecimalFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: parsedDouble);
            break;
            
          case FieldType.boolean:
            final l = rawString.trim().toLowerCase();
            final boolVal = (l == 'true' || l == 'yes' || l == '1');
            fieldValue = BooleanFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: boolVal);
            break;
            
          case FieldType.date:
          case FieldType.dateTime:
            if (rawString.isEmpty && !field.isRequired) {
              fieldValue = field.type == FieldType.date
                  ? DateFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: DateTime(1970))
                  : DateTimeFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: DateTime(1970));
              break;
            }
            final parsedDate = DateTime.tryParse(rawString);
            if (parsedDate == null) {
              throw Exception('Invalid date format for field "${field.name}". Use YYYY-MM-DD');
            }
            fieldValue = field.type == FieldType.date
                ? DateFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: parsedDate)
                : DateTimeFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: parsedDate);
            break;
            
          case FieldType.choice:
            fieldValue = ChoiceFieldValue(id: valueId, recordId: recordId, fieldId: field.id, value: rawString);
            break;
        }
      } catch (e) {
        if (e is Exception && e.toString().contains('Invalid')) {
          rethrow;
        }
        throw Exception('Failed to save field "${field.name}"');
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
