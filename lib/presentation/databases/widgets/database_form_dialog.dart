import 'package:flutter/material.dart';

import '../../../domain/models/database_definition.dart';

class DatabaseFormDialog extends StatefulWidget {
  final DatabaseDefinition? initialDatabase;

  const DatabaseFormDialog({super.key, this.initialDatabase});

  static Future<Map<String, String>?> show(
    BuildContext context, {
    DatabaseDefinition? initialDatabase,
  }) {
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DatabaseFormDialog(initialDatabase: initialDatabase),
    );
  }

  @override
  State<DatabaseFormDialog> createState() => _DatabaseFormDialogState();
}

class _DatabaseFormDialogState extends State<DatabaseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialDatabase?.name ?? '');
    _descriptionController = TextEditingController(text: widget.initialDatabase?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialDatabase != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Database' : 'Create Database'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Movies',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                if (value.trim().length > 60) {
                  return 'Name must be 60 characters or less';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g. My favorite films',
              ),
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value != null && value.trim().length > 255) {
                  return 'Description must be 255 characters or less';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save Changes' : 'Create'),
        ),
      ],
    );
  }
}
