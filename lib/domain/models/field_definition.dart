enum FieldType {
  text,
  number,
  boolean,
  date,
  // More to be added in Phase 2
}

class FieldDefinition {
  final String id;
  final String name;
  final FieldType type;
  final bool isRequired;

  const FieldDefinition({
    required this.id,
    required this.name,
    required this.type,
    this.isRequired = false,
  });
}
