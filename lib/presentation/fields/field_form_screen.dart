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
  late bool _isRequired;
  
  bool get _isEditing => widget.initialField != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialField?.name ?? '');
    _isRequired = widget.initialField?.isRequired ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    final controller = ref.read(fieldListControllerProvider(widget.databaseId).notifier);

    if (_isEditing) {
      controller.updateField(
        widget.initialField!,
        name: _nameController.text,
        isRequired: _isRequired,
      );
    } else {
      controller.createField(
        name: _nameController.text,
        type: FieldType.text,
        isRequired: _isRequired,
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
    );
  }
}
