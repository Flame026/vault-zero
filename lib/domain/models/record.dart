import 'field_value.dart';

class Record {
  final String id;
  final String databaseId;
  final Map<String, FieldValue> values;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const Record({
    required this.id,
    required this.databaseId,
    required this.values,
    required this.createdAt,
    required this.updatedAt,
  });

  Record copyWith({
    String? id,
    String? databaseId,
    Map<String, FieldValue>? values,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Record(
      id: id ?? this.id,
      databaseId: databaseId ?? this.databaseId,
      values: values ?? this.values,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
