import 'field_value.dart';

class Record {
  final String id;
  final String databaseId;
  final Map<String, FieldValue> values;
  
  const Record({
    required this.id,
    required this.databaseId,
    required this.values,
  });
}
