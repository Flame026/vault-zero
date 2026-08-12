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

  Map<String, dynamic> toJson() {
    dynamic serializedValue = value;
    if (value is DateTime) {
      serializedValue = (value as DateTime).toUtc().toIso8601String();
    }
    return {
      'id': id,
      'recordId': recordId,
      'fieldId': fieldId,
      'type': fieldType.name,
      'value': serializedValue,
    };
  }

  static FieldValue fromJson(Map<String, dynamic> json) {
    final type = FieldType.values.firstWhere((e) => e.name == json['type']);
    final id = json['id'] as String;
    final recordId = json['recordId'] as String;
    final fieldId = json['fieldId'] as String;
    final rawValue = json['value'];

    switch (type) {
      case FieldType.text:
        return TextFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: rawValue as String);
      case FieldType.longText:
        return LongTextFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: rawValue as String);
      case FieldType.integer:
        return IntegerFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: rawValue as int);
      case FieldType.decimal:
        return DecimalFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: (rawValue as num).toDouble());
      case FieldType.boolean:
        return BooleanFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: rawValue as bool);
      case FieldType.date:
        return DateFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: DateTime.parse(rawValue as String));
      case FieldType.dateTime:
        return DateTimeFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: DateTime.parse(rawValue as String));
      case FieldType.choice:
        return ChoiceFieldValue(id: id, recordId: recordId, fieldId: fieldId, value: rawValue as String);
    }
  }
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
