import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/field_definition.dart';
import 'controllers/field_list_controller.dart';

class FieldFormScreen extends ConsumerStatefulWidget {
  final String databaseId;
  final FieldDefinition? initialField;

  const FieldFormScreen({
    super.key,
    required this.databaseId,
    this.initialField,
  });

  @override
  ConsumerState<FieldFormScreen> createState() => _FieldFormScreenState();
}

class _FieldFormScreenState extends ConsumerState<FieldFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _optionController;
  late bool _isRequired;
  late FieldType _selectedType;
  late final List<String> _choiceOptions;
  String? _choiceError;
  String? _optionError;
  bool _isSaving = false;
  
  bool get _isEditing => widget.initialField != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialField?.name ?? '');
    _optionController = TextEditingController();
    _isRequired = widget.initialField?.isRequired ?? false;
    _selectedType = widget.initialField?.type ?? FieldType.text;

    if (widget.initialField?.configuration is ChoiceConfig) {
      _choiceOptions = List<String>.from((widget.initialField!.configuration as ChoiceConfig).options);
    } else {
      _choiceOptions = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _optionController.dispose();
    super.dispose();
  }

  void _addOption() {
    final opt = _optionController.text.trim();
    if (opt.isEmpty) return;
    if (_choiceOptions.any((existing) => existing.toLowerCase() == opt.toLowerCase())) {
      setState(() {
        _optionError = 'Option already added';
      });
      return;
    }
    setState(() {
      _choiceOptions.add(opt);
      _optionController.clear();
      _optionError = null;
      _choiceError = null;
    });
  }

  void _submit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == FieldType.choice && _choiceOptions.isEmpty) {
      setState(() {
        _choiceError = 'Please add at least one choice option';
      });
      return;
    }

    final controller = ref.read(fieldListControllerProvider(widget.databaseId).notifier);
    final FieldConfig? config = _selectedType == FieldType.choice
        ? ChoiceConfig(options: List.unmodifiable(_choiceOptions))
        : null;

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await controller.updateField(
          widget.initialField!,
          name: _nameController.text,
          isRequired: _isRequired,
          configuration: config,
        );
      } else {
        await controller.createField(
          name: _nameController.text,
          type: _selectedType,
          isRequired: _isRequired,
          configuration: config,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save field: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  IconData _getTypeIcon(FieldType type) {
    switch (type) {
      case FieldType.text:
        return Icons.text_fields_rounded;
      case FieldType.longText:
        return Icons.notes_rounded;
      case FieldType.integer:
        return Icons.numbers_rounded;
      case FieldType.decimal:
        return Icons.attach_money_rounded;
      case FieldType.boolean:
        return Icons.check_box_outlined;
      case FieldType.date:
        return Icons.calendar_today_rounded;
      case FieldType.dateTime:
        return Icons.access_time_rounded;
      case FieldType.choice:
        return Icons.list_alt_rounded;
    }
  }

  String _getTypeLabel(FieldType type) {
    switch (type) {
      case FieldType.text:
        return 'Text';
      case FieldType.longText:
        return 'Long Text';
      case FieldType.integer:
        return 'Integer';
      case FieldType.decimal:
        return 'Decimal';
      case FieldType.boolean:
        return 'Boolean (Yes/No)';
      case FieldType.date:
        return 'Date';
      case FieldType.dateTime:
        return 'Date & Time';
      case FieldType.choice:
        return 'Choice';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Field' : 'New Field'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Field Name',
                    hintText: 'e.g. Status',
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a field name';
                    }
                    if (value.trim().length > 60) {
                      return 'Name must be 60 characters or less';
                    }
                    final controller = ref.read(fieldListControllerProvider(widget.databaseId).notifier);
                    if (!controller.isNameUnique(value, excludeFieldId: widget.initialField?.id)) {
                      return 'A field with this name already exists';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_isEditing)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Field Type',
                      helperText: 'Field type cannot be changed after creation',
                    ),
                    child: Row(
                      children: [
                        Icon(_getTypeIcon(_selectedType), size: 20, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(_getTypeLabel(_selectedType), style: theme.textTheme.bodyLarge),
                        const Spacer(),
                        Icon(Icons.lock_outline_rounded, size: 18, color: colorScheme.onSurfaceVariant),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Field Type',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<FieldType>(
                          segments: const [
                            ButtonSegment(
                              value: FieldType.text,
                              label: Text('Text'),
                              icon: Icon(Icons.text_fields_rounded),
                            ),
                            ButtonSegment(
                              value: FieldType.boolean,
                              label: Text('Yes/No'),
                              icon: Icon(Icons.check_box_outlined),
                            ),
                            ButtonSegment(
                              value: FieldType.choice,
                              label: Text('Choice'),
                              icon: Icon(Icons.list_alt_rounded),
                            ),
                          ],
                          selected: {_selectedType},
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _selectedType = newSelection.first;
                              _choiceError = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                if (_selectedType == FieldType.choice) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Choice Options',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _optionController,
                          decoration: InputDecoration(
                            labelText: 'New Option',
                            hintText: 'e.g. In Stock',
                            errorText: _optionError,
                          ),
                          textCapitalization: TextCapitalization.words,
                          onSubmitted: (_) => _addOption(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addOption,
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'Add Option',
                      ),
                    ],
                  ),
                  if (_choiceError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _choiceError!,
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (_choiceOptions.isEmpty)
                    Text(
                      'No options added yet. Add at least one option above.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _choiceOptions.map((opt) {
                        return InputChip(
                          label: Text(opt),
                          onDeleted: () {
                            setState(() {
                              _choiceOptions.remove(opt);
                              if (_choiceOptions.isEmpty) {
                                _choiceError = 'Please add at least one choice option';
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                ],
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Required Field'),
                  subtitle: const Text('Must be filled out for every record'),
                  value: _isRequired,
                  onChanged: (val) => setState(() => _isRequired = val),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
