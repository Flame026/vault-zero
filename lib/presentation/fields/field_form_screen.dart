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
  late FieldType _selectedType;
  late bool _isRequired;
  
  // For Choice fields
  final List<String> _choiceOptions = [];
  final _choiceOptionController = TextEditingController();

  bool get _isEditing => widget.initialField != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialField?.name ?? '');
    _selectedType = widget.initialField?.type ?? FieldType.text;
    _isRequired = widget.initialField?.isRequired ?? false;

    if (widget.initialField?.configuration is ChoiceConfig) {
      _choiceOptions.addAll((widget.initialField!.configuration as ChoiceConfig).options);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _choiceOptionController.dispose();
    super.dispose();
  }

  void _addChoiceOption() {
    final option = _choiceOptionController.text.trim();
    if (option.isNotEmpty && !_choiceOptions.contains(option)) {
      setState(() {
        _choiceOptions.add(option);
        _choiceOptionController.clear();
      });
    }
  }

  void _removeChoiceOption(String option) {
    setState(() {
      _choiceOptions.remove(option);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedType == FieldType.choice && _choiceOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choice fields must have at least one option.')),
      );
      return;
    }

    FieldConfig? config;
    if (_selectedType == FieldType.choice) {
      config = ChoiceConfig(options: List.from(_choiceOptions));
    }

    final controller = ref.read(fieldListControllerProvider(widget.databaseId).notifier);

    if (_isEditing) {
      controller.updateField(
        widget.initialField!,
        name: _nameController.text,
        isRequired: _isRequired,
        configuration: config,
      );
    } else {
      controller.createField(
        name: _nameController.text,
        type: _selectedType,
        isRequired: _isRequired,
        configuration: config,
      );
    }

    Navigator.of(context).pop();
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
            onPressed: _submit,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Field Name',
                hintText: 'e.g. Release Year',
              ),
              textCapitalization: TextCapitalization.words,
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
            const SizedBox(height: 16),
            DropdownButtonFormField<FieldType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Data Type',
              ),
              items: FieldType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeLabel(type)),
                );
              }).toList(),
              // Disable changing type in edit mode
              onChanged: _isEditing ? null : (type) {
                if (type != null) {
                  setState(() => _selectedType = type);
                }
              },
              validator: (value) => value == null ? 'Please select a type' : null,
            ),
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  'Field type cannot be changed after creation to prevent data loss.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Required Field'),
              subtitle: const Text('Must be filled out for every record'),
              value: _isRequired,
              onChanged: (val) => setState(() => _isRequired = val),
              contentPadding: EdgeInsets.zero,
            ),
            if (_selectedType == FieldType.choice) ...[
              const Divider(height: 48),
              Text('Choice Options', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _choiceOptionController,
                      decoration: const InputDecoration(
                        hintText: 'Add an option (e.g. Action)',
                      ),
                      onSubmitted: (_) => _addChoiceOption(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _addChoiceOption,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _choiceOptions.map((option) {
                  return Chip(
                    label: Text(option),
                    onDeleted: () => _removeChoiceOption(option),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(FieldType type) {
    switch (type) {
      case FieldType.text: return 'Text';
      case FieldType.longText: return 'Long Text';
      case FieldType.integer: return 'Integer';
      case FieldType.decimal: return 'Decimal';
      case FieldType.boolean: return 'Boolean (Yes/No)';
      case FieldType.date: return 'Date';
      case FieldType.dateTime: return 'Date & Time';
      case FieldType.choice: return 'Choice';
    }
  }
}
