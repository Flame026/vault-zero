enum FieldType {
  text,
  longText,
  integer,
  decimal,
  boolean,
  date,
  dateTime,
  choice,
}

abstract class FieldConfig {
  const FieldConfig();
}

class ChoiceConfig extends FieldConfig {
  final List<String> options;

  const ChoiceConfig({required this.options});
}

class FieldDefinition {
  final String id;
  final String databaseId;
  final String name;
  final FieldType type;
  final int position;
  final bool isRequired;
  final FieldConfig? configuration;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FieldDefinition({
    required this.id,
    required this.databaseId,
    required this.name,
    required this.type,
    required this.position,
    this.isRequired = false,
    this.configuration,
    required this.createdAt,
    required this.updatedAt,
  });

  FieldDefinition copyWith({
    String? id,
    String? databaseId,
    String? name,
    FieldType? type,
    int? position,
    bool? isRequired,
    FieldConfig? configuration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FieldDefinition(
      id: id ?? this.id,
      databaseId: databaseId ?? this.databaseId,
      name: name ?? this.name,
      type: type ?? this.type,
      position: position ?? this.position,
      isRequired: isRequired ?? this.isRequired,
      configuration: configuration ?? this.configuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
