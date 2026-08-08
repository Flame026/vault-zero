import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/field_definition.dart';

class DynamicFieldInput extends StatefulWidget {
  final FieldDefinition field;
  final dynamic initialValue;
  final ValueChanged<dynamic> onChanged;

  const DynamicFieldInput({
    super.key,
    required this.field,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<DynamicFieldInput> createState() => _DynamicFieldInputState();
}

class _DynamicFieldInputState extends State<DynamicFieldInput> {
  late dynamic _currentValue;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;

    if (widget.field.type == FieldType.text || 
        widget.field.type == FieldType.longText ||
        widget.field.type == FieldType.integer ||
        widget.field.type == FieldType.decimal) {
      if (_currentValue != null && _currentValue.toString().isNotEmpty) {
        // Format decimal nicely without trailing zeros if possible
        if (widget.field.type == FieldType.decimal && _currentValue is double) {
          _textController.text = _currentValue.toString().replaceAll(RegExp(r'\.0$'), '');
        } else {
          _textController.text = _currentValue.toString();
        }
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String? _validateRequired(dynamic value) {
    if (!widget.field.isRequired) return null;

    if (value == null) return 'This field is required';
    if (value is String && value.trim().isEmpty) return 'This field is required';
    return null;
  }

  Widget _buildText(bool isLong) {
    return TextFormField(
      controller: _textController,
      decoration: InputDecoration(
        labelText: widget.field.name,
        alignLabelWithHint: isLong,
      ),
      maxLines: isLong ? 5 : 1,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (val) {
        _currentValue = val;
        widget.onChanged(val);
      },
      validator: _validateRequired,
    );
  }

  Widget _buildNumber(bool isDecimal) {
    return TextFormField(
      controller: _textController,
      decoration: InputDecoration(
        labelText: widget.field.name,
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      inputFormatters: [
        if (!isDecimal) FilteringTextInputFormatter.digitsOnly,
        if (isDecimal) FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (val) {
        if (val.isEmpty) {
          _currentValue = null;
          widget.onChanged(null);
          return;
        }
        if (isDecimal) {
          final doubleVal = double.tryParse(val);
          _currentValue = doubleVal;
          widget.onChanged(doubleVal);
        } else {
          final intVal = int.tryParse(val);
          _currentValue = intVal;
          widget.onChanged(intVal);
        }
      },
      validator: (val) {
        final req = _validateRequired(val);
        if (req != null) return req;
        if (val != null && val.isNotEmpty) {
          if (isDecimal && double.tryParse(val) == null) return 'Invalid decimal';
          if (!isDecimal && int.tryParse(val) == null) return 'Invalid integer';
        }
        return null;
      },
    );
  }

  Widget _buildBoolean() {
    return SwitchListTile(
      title: Text(widget.field.name),
      value: (_currentValue as bool?) ?? false,
      onChanged: (val) {
        setState(() {
          _currentValue = val;
        });
        widget.onChanged(val);
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _pickDate(bool includeTime) async {
    final now = DateTime.now();
    final initialDate = (_currentValue as DateTime?) ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    if (!includeTime) {
      setState(() {
        _currentValue = pickedDate;
      });
      widget.onChanged(pickedDate);
      return;
    }

    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null) return;

    final finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _currentValue = finalDateTime;
    });
    widget.onChanged(finalDateTime);
  }

  Widget _buildDateTime(bool includeTime) {
    final String displayValue;
    if (_currentValue is DateTime && (_currentValue as DateTime).year > 1970) {
      if (includeTime) {
        displayValue = DateFormat.yMd().add_jm().format(_currentValue as DateTime);
      } else {
        displayValue = DateFormat.yMMMd().format(_currentValue as DateTime);
      }
    } else {
      displayValue = '';
    }

    return InkWell(
      onTap: () => _pickDate(includeTime),
      child: IgnorePointer(
        child: TextFormField(
          key: ValueKey(displayValue), // Force rebuild when text changes without controller
          initialValue: displayValue,
          decoration: InputDecoration(
            labelText: widget.field.name,
            suffixIcon: Icon(includeTime ? Icons.access_time : Icons.calendar_today),
          ),
          validator: (val) {
            if (widget.field.isRequired && (_currentValue == null || (_currentValue as DateTime).year <= 1970)) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildChoice() {
    final config = widget.field.configuration as ChoiceConfig?;
    final options = config?.options ?? [];

    final String? safeValue = options.contains(_currentValue) ? _currentValue as String : null;

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: widget.field.name,
      ),
      initialValue: safeValue,
      items: [
        if (!widget.field.isRequired)
          const DropdownMenuItem<String>(
            value: null,
            child: Text('None'),
          ),
        ...options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }),
      ],
      onChanged: (val) {
        setState(() {
          _currentValue = val;
        });
        widget.onChanged(val);
      },
      validator: _validateRequired,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.field.type) {
      case FieldType.text:
        return _buildText(false);
      case FieldType.longText:
        return _buildText(true);
      case FieldType.integer:
        return _buildNumber(false);
      case FieldType.decimal:
        return _buildNumber(true);
      case FieldType.boolean:
        return _buildBoolean();
      case FieldType.date:
        return _buildDateTime(false);
      case FieldType.dateTime:
        return _buildDateTime(true);
      case FieldType.choice:
        return _buildChoice();
    }
  }
}
