import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/field_definition.dart';
import '../../../domain/models/record.dart';
import 'controllers/record_list_controller.dart';
import 'widgets/dynamic_field_input.dart';

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
  late Map<String, dynamic> _values;

  @override
  void initState() {
    super.initState();
    _values = {};

    if (widget.initialRecord != null) {
      for (final field in widget.fields) {
        final fieldValue = widget.initialRecord!.values[field.id];
        if (fieldValue != null) {
          _values[field.id] = fieldValue.value;
        }
      }
    }
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = ref.read(recordListControllerProvider(widget.databaseId).notifier);

    await controller.saveRecord(
      existingRecord: widget.initialRecord,
      fields: widget.fields,
      rawValues: _values,
    );

    if (mounted) {
      Navigator.of(context).pop();
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
          padding: const EdgeInsets.all(16),
          itemCount: widget.fields.length,
          itemBuilder: (context, index) {
            final field = widget.fields[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: DynamicFieldInput(
                field: field,
                initialValue: _values[field.id],
                onChanged: (val) {
                  _values[field.id] = val;
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
