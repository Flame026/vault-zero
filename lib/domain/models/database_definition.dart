class DatabaseDefinition {
  final String id;
  final String name;
  final List<FieldDefinition> fields;

  const DatabaseDefinition({
    required this.id,
    required this.name,
    required this.fields,
  });
}
