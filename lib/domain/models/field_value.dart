import 'field_definition.dart';

abstract class FieldValue {
  final String id;
  final String recordId;
  final String fieldId;

  const FieldValue({
    required this.id,
    required this.recordId,
    required this.fieldId,
  });

  /// The raw value object.
  dynamic get value;

  /// Returns the corresponding `FieldType` this value is allowed for.
  FieldType get fieldType;
}

class TextFieldValue extends FieldValue {
  @override
  final String value;

  const TextFieldValue({
    required super.id,
    required super.recordId,
    required super.fieldId,
    required this.value,
  });

  @override
  FieldType get fieldType => FieldType.text;
}

class LongTextFieldValue extends FieldValue {
  @override
  final String value;

  const LongTextFieldValue({
    required super.id,
    required super.recordId,
    required super.fieldId,
    required this.value,
  });

  @override
  FieldType get fieldType => FieldType.longText;
}

class IntegerFieldValue extends FieldValue {
  @override
  final int value;

  const IntegerFieldValue({
    required super.id,
    required super.recordId,
    required super.fieldId,
    required this.value,
  });

  @override
  FieldType get fieldType => FieldType.integer;
}

class DecimalFieldValue extends FieldValue {
  @override
  final double value;

  const DecimalFieldValue({
    required super.id,
    required super.recordId,
    required super.fieldId,
    required this.value,
  });

  @override
  FieldType get fieldType => FieldType.decimal;
}

class BooleanFieldValue extends FieldValue {
  @override
  final bool value;

  const BooleanFieldValue({
    required super.id,
    required super.recordId,
    required super.fieldId,
    required this.value,
  });

  @override
  FieldType get fieldType => FieldType.boolean;
}

class DateFieldValue extends FieldValue {
  @override
  final DateTime value;

  const DateFieldValue({
    required super.id,
    required super.recordId,
    required super.fieldId,
    required this.value,
  });

  @override
  FieldType get fieldType => FieldType.date;
}

class DateTimeFieldValue extends FieldValue {
  @override
  final DateTime value;

  const DateTimeFieldValue({
    required super.id,
    required super.recordId,
    required super.fieldId,
    required this.value,
  });

  @override
  FieldType get fieldType => FieldType.dateTime;
}

class ChoiceFieldValue extends FieldValue {
  @override
  final String value;

  const ChoiceFieldValue({
    required super.id,
    required super.recordId,
    required super.fieldId,
    required this.value,
  });

  @override
  FieldType get fieldType => FieldType.choice;
}
