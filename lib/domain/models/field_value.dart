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
    final typeName = json['type'] as String?;
    final type = FieldType.values.where((e) => e.name == typeName).firstOrNull;
    if (type == null) {
      throw FormatException('Unknown field value type: $typeName');
    }
    final id = json['id'];
    final recordId = json['recordId'];
    final fieldId = json['fieldId'];
    if (id is! String || recordId is! String || fieldId is! String) {
      throw const FormatException(
        'FieldValue is missing required string identifiers.',
      );
    }
    final rawValue = json['value'];

    try {
      switch (type) {
        case FieldType.text:
          return TextFieldValue(
            id: id,
            recordId: recordId,
            fieldId: fieldId,
            value: (rawValue as String?) ?? '',
          );
        case FieldType.longText:
          return LongTextFieldValue(
            id: id,
            recordId: recordId,
            fieldId: fieldId,
            value: (rawValue as String?) ?? '',
          );
        case FieldType.integer:
          return IntegerFieldValue(
            id: id,
            recordId: recordId,
            fieldId: fieldId,
            value: (rawValue as num).toInt(),
          );
        case FieldType.decimal:
          final d = (rawValue as num).toDouble();
          if (!d.isFinite) {
            throw const FormatException('Decimal value must be finite.');
          }
          return DecimalFieldValue(
            id: id,
            recordId: recordId,
            fieldId: fieldId,
            value: d,
          );
        case FieldType.boolean:
          return BooleanFieldValue(
            id: id,
            recordId: recordId,
            fieldId: fieldId,
            value: rawValue as bool,
          );
        case FieldType.date:
          return DateFieldValue(
            id: id,
            recordId: recordId,
            fieldId: fieldId,
            value: DateTime.parse(rawValue as String),
          );
        case FieldType.dateTime:
          return DateTimeFieldValue(
            id: id,
            recordId: recordId,
            fieldId: fieldId,
            value: DateTime.parse(rawValue as String),
          );
        case FieldType.choice:
          return ChoiceFieldValue(
            id: id,
            recordId: recordId,
            fieldId: fieldId,
            value: (rawValue as String?) ?? '',
          );
      }
    } catch (e) {
      if (e is FormatException) rethrow;
      throw FormatException(
        'Invalid value "$rawValue" for field type ${type.name}: $e',
      );
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
  }) : assert(
         value >= -1.7976931348623157e+308 && value <= 1.7976931348623157e+308,
         'Decimal value must be finite',
       );

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
