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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'databaseId': databaseId,
      'values': values.map((k, v) => MapEntry(k, v.toJson())),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Record.fromJson(Map<String, dynamic> json) {
    final valuesMap = (json['values'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, FieldValue.fromJson(v as Map<String, dynamic>)),
    );
    return Record(
      id: json['id'] as String,
      databaseId: json['databaseId'] as String,
      values: valuesMap,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
