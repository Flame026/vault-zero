abstract class FieldValue {
  const FieldValue();
  
  dynamic get value;
}

class TextFieldValue extends FieldValue {
  @override
  final String value;
  
  const TextFieldValue(this.value);
}

class NumberFieldValue extends FieldValue {
  @override
  final num value;
  
  const NumberFieldValue(this.value);
}
