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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'fields': fields.map((f) => f.toJson()).toList(),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory DatabaseDefinition.fromJson(Map<String, dynamic> json) {
    return DatabaseDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      fields: (json['fields'] as List)
          .map((f) => FieldDefinition.fromJson(f as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
