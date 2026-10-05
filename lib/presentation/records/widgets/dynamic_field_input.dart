import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../domain/models/field_definition.dart';
import '../../common/widgets/vault_card.dart';

class DynamicFieldInput extends StatefulWidget {
  final FieldDefinition field;
  final dynamic initialValue;
  final ValueChanged<dynamic> onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final bool autofocus;

  const DynamicFieldInput({
    super.key,
    required this.field,
    required this.initialValue,
    required this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofocus = false,
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
        if (widget.field.type == FieldType.decimal && _currentValue is double) {
          _textController.text = _currentValue.toString().replaceAll(
            RegExp(r'\.0$'),
            '',
          );
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
    if (value is String && value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  Widget _buildText(bool isLong) {
    return TextFormField(
      controller: _textController,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      scrollPadding: const EdgeInsets.all(AppSpacing.xxl),
      textInputAction: isLong
          ? TextInputAction.newline
          : widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.field.name,
        alignLabelWithHint: isLong,
        errorMaxLines: 2,
        prefixIcon: Icon(
          isLong ? Icons.notes_rounded : Icons.text_fields_rounded,
          size: 20,
        ),
        helperText: widget.field.isRequired ? 'Required' : null,
        suffixIcon: (!isLong && _textController.text.isNotEmpty)
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                tooltip: 'Clear ${widget.field.name}',
                onPressed: () {
                  _textController.clear();
                  _currentValue = '';
                  widget.onChanged('');
                  setState(() {});
                },
              )
            : null,
      ),
      minLines: isLong ? 3 : 1,
      maxLines: isLong ? 6 : 1,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (val) {
        _currentValue = val;
        widget.onChanged(val);
        setState(() {});
      },
      validator: _validateRequired,
    );
  }

  Widget _buildNumber(bool isDecimal) {
    return TextFormField(
      controller: _textController,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      scrollPadding: const EdgeInsets.all(AppSpacing.xxl),
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.field.name,
        errorMaxLines: 2,
        prefixIcon: Icon(
          isDecimal ? Icons.tag_rounded : Icons.numbers_rounded,
          size: 20,
        ),
        helperText: widget.field.isRequired ? 'Required' : null,
        suffixIcon: _textController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                tooltip: 'Clear ${widget.field.name}',
                onPressed: () {
                  _textController.clear();
                  _currentValue = null;
                  widget.onChanged(null);
                  setState(() {});
                },
              )
            : null,
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
          setState(() {});
          return;
        }
        if (isDecimal) {
          final doubleVal = double.tryParse(val);
          if (doubleVal != null && doubleVal.isFinite) {
            _currentValue = doubleVal;
            widget.onChanged(doubleVal);
          } else {
            _currentValue = null;
            widget.onChanged(null);
          }
        } else {
          final intVal = int.tryParse(val);
          _currentValue = intVal;
          widget.onChanged(intVal);
        }
        setState(() {});
      },
      validator: (val) {
        final req = _validateRequired(val);
        if (req != null) {
          return req;
        }
        if (val != null && val.isNotEmpty) {
          if (isDecimal) {
            final parsed = double.tryParse(val);
            if (parsed == null || !parsed.isFinite) {
              return 'Invalid decimal';
            }
          }
          if (!isDecimal && int.tryParse(val) == null) {
            return 'Invalid integer';
          }
        }
        return null;
      },
    );
  }

  Widget _buildBoolean() {
    final colorScheme = Theme.of(context).colorScheme;
    final isChecked = (_currentValue as bool?) ?? false;

    return VaultCard(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        secondary: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isChecked
                ? colorScheme.primaryContainer.withValues(alpha: 0.6)
                : colorScheme.surfaceContainer,
            borderRadius: AppRadius.radiusSm,
          ),
          child: Icon(
            Icons.toggle_on_outlined,
            size: 20,
            color: isChecked
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          widget.field.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: widget.field.isRequired ? const Text('Required') : null,
        value: isChecked,
        onChanged: (val) {
          setState(() {
            _currentValue = val;
          });
          widget.onChanged(val);
        },
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
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

    if (pickedDate == null || !mounted) {
      return;
    }

    if (!includeTime) {
      setState(() {
        _currentValue = pickedDate;
      });
      widget.onChanged(pickedDate);
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null || !mounted) {
      return;
    }

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
    if (_currentValue is DateTime) {
      final dt = _currentValue as DateTime;
      displayValue = includeTime
          ? DateFormat.yMd().add_jm().format(dt)
          : DateFormat.yMMMd().format(dt);
    } else {
      displayValue = '';
    }

    return FormField<DateTime>(
      initialValue: _currentValue as DateTime?,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: _validateRequired,
      builder: (state) {
        return Semantics(
          button: true,
          label:
              'Select ${includeTime ? "date and time" : "date"} for ${widget.field.name}',
          child: InkWell(
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            onTap: () => _pickDate(includeTime),
            borderRadius: AppRadius.radiusMd,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: widget.field.name,
                errorMaxLines: 2,
                prefixIcon: Icon(
                  includeTime
                      ? Icons.access_time_rounded
                      : Icons.calendar_today_rounded,
                  size: 20,
                ),
                helperText: widget.field.isRequired ? 'Required' : null,
                errorText: state.errorText,
                suffixIcon: displayValue.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        tooltip: 'Clear ${widget.field.name}',
                        onPressed: () {
                          setState(() {
                            _currentValue = null;
                          });
                          state.didChange(null);
                          widget.onChanged(null);
                        },
                      )
                    : null,
              ),
              child: Text(
                displayValue.isEmpty ? 'Select date' : displayValue,
                style: TextStyle(
                  color: displayValue.isEmpty
                      ? Theme.of(context).hintColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChoice() {
    final config = widget.field.configuration;
    List<String> options = [];
    if (config is ChoiceConfig) {
      options = config.options;
    }

    final selectedValue = options.contains(_currentValue)
        ? _currentValue as String?
        : null;

    return DropdownButtonFormField<String>(
      key: ValueKey('dropdown_${widget.field.id}_$selectedValue'),
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      initialValue: selectedValue,
      borderRadius: AppRadius.radiusMd,
      decoration: InputDecoration(
        labelText: widget.field.name,
        errorMaxLines: 2,
        prefixIcon: const Icon(Icons.list_rounded, size: 20),
        helperText: widget.field.isRequired ? 'Required' : null,
        suffixIcon: (!widget.field.isRequired && selectedValue != null)
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                tooltip: 'Clear ${widget.field.name}',
                onPressed: () {
                  setState(() {
                    _currentValue = null;
                  });
                  widget.onChanged(null);
                },
              )
            : null,
      ),
      items: [
        if (!widget.field.isRequired)
          const DropdownMenuItem<String>(
            value: null,
            child: Text('None', style: TextStyle(fontStyle: FontStyle.italic)),
          ),
        ...options.map((opt) {
          return DropdownMenuItem<String>(
            value: opt,
            child: Text(opt, overflow: TextOverflow.ellipsis),
          );
        }),
      ],
      onChanged: (val) {
        setState(() {
          _currentValue = val;
        });
        widget.onChanged(val);
      },
      validator: (val) {
        if (widget.field.isRequired && (val == null || val.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
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
