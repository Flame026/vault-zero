import 'field_definition.dart';

class DatabaseDefinition {
  final String id;
  final String name;
  final String description;
  final List<FieldDefinition> fields;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DatabaseDefinition({
    required this.id,
    required this.name,
    this.description = '',
    required this.fields,
    required this.createdAt,
    required this.updatedAt,
  });

  DatabaseDefinition copyWith({
    String? id,
    String? name,
    String? description,
    List<FieldDefinition>? fields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DatabaseDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      fields: fields ?? this.fields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
