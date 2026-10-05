import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
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
      builder: (context) =>
          DatabaseFormDialog(initialDatabase: initialDatabase),
    );
  }

  @override
  State<DatabaseFormDialog> createState() => _DatabaseFormDialogState();
}

class _DatabaseFormDialogState extends State<DatabaseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialDatabase?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialDatabase?.description ?? '',
    );
    _nameController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _submit() {
    if (_isSubmitting) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.initialDatabase != null;

    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusDialog),
        backgroundColor: colorScheme.surfaceContainerLow,
        titlePadding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xxl,
          AppSpacing.xxl,
          AppSpacing.sm,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.sm,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.sm,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        title: Text(
          isEditing ? 'Edit Database' : 'Create Database',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing
                      ? 'Update the database name and description.'
                      : 'Create a new database to organize and manage your records.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _nameController,
                  autofocus: !isEditing,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  maxLength: 60,
                  textInputAction: TextInputAction.next,
                  scrollPadding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Movies',
                    errorMaxLines: 2,
                    prefixIcon: const Icon(Icons.storage_rounded, size: 20),
                    suffixIcon: _nameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            tooltip: 'Clear name',
                            onPressed: () {
                              setState(() {
                                _nameController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  textCapitalization: TextCapitalization.words,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  onChanged: (_) => setState(() {}),
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
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 255,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  scrollPadding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'e.g. My favorite films',
                    errorMaxLines: 2,
                    prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                    alignLabelWithHint: true,
                    suffixIcon: _descriptionController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            tooltip: 'Clear description',
                            onPressed: () {
                              setState(() {
                                _descriptionController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  onChanged: (_) => setState(() {}),
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
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(isEditing ? 'Save Changes' : 'Create'),
          ),
        ],
      ),
    );
  }
}
