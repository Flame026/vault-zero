import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../domain/models/field_definition.dart';
import '../../../domain/models/field_value.dart';
import '../../../domain/models/record.dart';

import '../../../domain/models/record_page.dart';

class RecordListController extends FamilyAsyncNotifier<List<Record>, String> {
  RecordCursor? _nextCursor;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetchingMore;

  @override
  Future<List<Record>> build(String arg) async {
    _nextCursor = null;
    _hasMore = true;
    _isFetchingMore = false;

    final repository = await ref.watch(recordRepositoryProvider.future);
    final page = await repository.getRecordsPage(arg, limit: 50);

    _nextCursor = page.nextCursor;
    _hasMore = page.hasMore;
    return page.records;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isFetchingMore) return;

    _isFetchingMore = true;
    // Notify listeners so UI can show loading indicator
    state = AsyncValue.data(state.value ?? []);

    try {
      final repository = await ref.read(recordRepositoryProvider.future);
      final page = await repository.getRecordsPage(arg, limit: 50, after: _nextCursor);

      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore;

      final currentRecords = state.value ?? [];
      state = AsyncValue.data([...currentRecords, ...page.records]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isFetchingMore = false;
      // Trigger rebuild to remove loading indicator if no error
      if (!state.hasError) {
        state = AsyncValue.data(state.value ?? []);
      }
    }
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

    // Save through repository
    await repository.saveRecord(newRecord);

    // Update local state without reloading database
    final currentRecords = state.value ?? [];

    if (existingRecord != null) {
      // Edit: Replace matching record
      final index = currentRecords.indexWhere((r) => r.id == newRecord.id);
      if (index != -1) {
        final newRecords = List<Record>.from(currentRecords);
        newRecords[index] = newRecord;
        state = AsyncValue.data(newRecords);
      }
    } else {
      // Create: Records are ordered by created_at ASC.
      // A newly created record goes at the very end of the database.
      if (!_hasMore) {
        // We have loaded the end of the database, so append it visually
        state = AsyncValue.data([...currentRecords, newRecord]);
      } else {
        // We haven't scrolled to the end yet, so don't append it to the current UI list
        // It will be loaded naturally when the user reaches the last page.
      }
    }
  }

  Future<void> deleteRecord(String id) async {
    final repository = await ref.read(recordRepositoryProvider.future);
    
    // Delete through repository
    await repository.deleteRecord(id);

    // Remove locally
    final currentRecords = state.value ?? [];
    final newRecords = currentRecords.where((r) => r.id != id).toList();
    state = AsyncValue.data(newRecords);
  }
}

final recordListControllerProvider = AsyncNotifierProviderFamily<RecordListController, List<Record>, String>(() {
  return RecordListController();
});
