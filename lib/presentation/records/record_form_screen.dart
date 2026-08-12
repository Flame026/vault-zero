import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/field_definition.dart';
import '../../../domain/models/record.dart';
import 'controllers/record_list_controller.dart';

class RecordFormScreen extends ConsumerStatefulWidget {
  final String databaseId;
  final Record? initialRecord;
  final List<FieldDefinition> fields;

  const RecordFormScreen({
    super.key,
    required this.databaseId,
    this.initialRecord,
    required this.fields,
  });

  @override
  ConsumerState<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends ConsumerState<RecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers and FocusNodes for fast entry
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    
    _controllers = List.generate(widget.fields.length, (index) {
      final field = widget.fields[index];
      final fieldValue = widget.initialRecord?.values[field.id];
      // Format decimal safely to remove trailing zero if needed, otherwise just toString()
      String textValue = '';
      if (fieldValue != null && fieldValue.value != null) {
        if (field.type == FieldType.decimal && fieldValue.value is double) {
           textValue = fieldValue.value.toString().replaceAll(RegExp(r'\.0$'), '');
        } else {
           textValue = fieldValue.value.toString();
        }
      }
      return TextEditingController(text: textValue);
    });

    _focusNodes = List.generate(widget.fields.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawValues = <String, dynamic>{};
    for (int i = 0; i < widget.fields.length; i++) {
      rawValues[widget.fields[i].id] = _controllers[i].text.trim();
    }

    final controller = ref.read(recordListControllerProvider(widget.databaseId).notifier);

    try {
      await controller.saveRecord(
        existingRecord: widget.initialRecord,
        fields: widget.fields,
        rawValues: rawValues,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialRecord != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Record' : 'New Record'),
        actions: [
          TextButton(
            onPressed: _onSave,
            child: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          itemCount: widget.fields.length,
          itemBuilder: (context, index) {
            final field = widget.fields[index];
            final isLast = index == widget.fields.length - 1;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                autofocus: index == 0,
                textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: field.name,
                ),
                onFieldSubmitted: (_) {
                  if (isLast) {
                    _onSave();
                  } else {
                    FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                  }
                },
                validator: (val) {
                  if (field.isRequired && (val == null || val.trim().isEmpty)) {
                    return 'This field is required';
                  }
                  return null;
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
