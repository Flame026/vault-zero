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
  late final Map<String, dynamic> _values;
  late final List<FocusNode> _focusNodes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _values = {};
    for (final field in widget.fields) {
      final fieldValue = widget.initialRecord?.values[field.id];
      _values[field.id] = fieldValue?.value;
    }
    _focusNodes = List.generate(widget.fields.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onSave() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = ref.read(recordListControllerProvider(widget.databaseId).notifier);

    setState(() => _isSaving = true);
    try {
      await controller.saveRecord(
        existingRecord: widget.initialRecord,
        fields: widget.fields,
        rawValues: _values,
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
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: _isSaving ? null : _onSave,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
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
                child: DynamicFieldInput(
                  field: field,
                  initialValue: _values[field.id],
                  focusNode: _focusNodes[index],
                  autofocus: index == 0,
                  textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
                  onFieldSubmitted: (_) {
                    if (isLast) {
                      _onSave();
                    } else {
                      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                    }
                  },
                  onChanged: (val) {
                    _values[field.id] = val;
                  },
                ),
              );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
