import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../domain/models/field_definition.dart';
import '../common/widgets/vault_app_bar.dart';
import '../common/widgets/vault_card.dart';
import '../common/widgets/vault_discard_dialog.dart';
import '../common/widgets/vault_icon_badge.dart';
import '../common/widgets/vault_snackbar.dart';
import '../common/error_sanitizer.dart';
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
  late final FocusNode _optionFocusNode;
  late bool _isRequired;
  late FieldType _selectedType;
  late List<String> _choiceOptions;
  late final List<String> _initialChoiceOptions;
  String? _choiceError;
  String? _optionError;
  bool _isSaving = false;
  bool _isDiscarding = false;

  bool get _isEditing => widget.initialField != null;

  void _onFieldChanged() {
    if (mounted) {
      setState(() {
        if (_optionError != null) _optionError = null;
      });
    }
  }

  bool get _isDirty {
    final initialName = widget.initialField?.name ?? '';
    if (_nameController.text.trim() != initialName.trim()) return true;

    final initialRequired = widget.initialField?.isRequired ?? false;
    if (_isRequired != initialRequired) return true;

    final initialType = widget.initialField?.type ?? FieldType.text;
    if (_selectedType != initialType) return true;

    if (_choiceOptions.length != _initialChoiceOptions.length) return true;
    for (int i = 0; i < _choiceOptions.length; i++) {
      if (_choiceOptions[i] != _initialChoiceOptions[i]) return true;
    }

    if (_optionController.text.trim().isNotEmpty) return true;

    return false;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialField?.name ?? '',
    );
    _optionController = TextEditingController();
    _optionFocusNode = FocusNode();
    _nameController.addListener(_onFieldChanged);
    _optionController.addListener(_onFieldChanged);
    _isRequired = widget.initialField?.isRequired ?? false;
    _selectedType = widget.initialField?.type ?? FieldType.text;

    if (widget.initialField?.configuration is ChoiceConfig) {
      _choiceOptions = List<String>.from(
        (widget.initialField!.configuration as ChoiceConfig).options,
      );
    } else {
      _choiceOptions = [];
    }
    _initialChoiceOptions = List<String>.unmodifiable(_choiceOptions);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _optionController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _optionController.dispose();
    _optionFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    return VaultDiscardDialog.show(context);
  }

  void _addOption() {
    final opt = _optionController.text.trim();
    if (opt.isEmpty) return;
    if (_choiceOptions.any(
      (existing) => existing.toLowerCase() == opt.toLowerCase(),
    )) {
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
    _optionFocusNode.requestFocus();
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

    final controller = ref.read(
      fieldListControllerProvider(widget.databaseId).notifier,
    );
    final FieldConfig? config = _selectedType == FieldType.choice
        ? ChoiceConfig(options: List.unmodifiable(_choiceOptions))
        : null;

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await controller.updateField(
          widget.initialField!,
          name: _nameController.text.trim(),
          isRequired: _isRequired,
          configuration: config,
        );
      } else {
        await controller.createField(
          name: _nameController.text.trim(),
          type: _selectedType,
          isRequired: _isRequired,
          configuration: config,
        );
      }

      if (mounted) {
        VaultSnackbar.showSuccess(
          context,
          _isEditing ? 'Field updated' : 'Field created',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        VaultSnackbar.showError(
          context,
          'Failed to save field: ${sanitizeErrorMessage(e)}',
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
        return Icons.tag_rounded;
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

    return PopScope(
      canPop: !_isDirty || _isSaving || _isDiscarding,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _confirmDiscard();
        if (shouldDiscard && context.mounted) {
          setState(() => _isDiscarding = true);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: VaultAppBar(
          title: _isEditing ? 'Edit Field' : 'New Field',
          subtitle: _isEditing
              ? 'Modify field attributes'
              : 'Define new field for database',
          actions: [
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      final shouldDiscard = await _confirmDiscard();
                      if (shouldDiscard && context.mounted) {
                        setState(() => _isDiscarding = true);
                        Navigator.of(context).pop();
                      }
                    },
              child: const Text('Cancel'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(72, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                ),
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
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
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    VaultCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          VaultIconBadge(
                            icon: _isEditing
                                ? Icons.edit_attributes_rounded
                                : Icons.schema_rounded,
                            iconColor: colorScheme.primary,
                            backgroundColor: colorScheme.primaryContainer
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isEditing
                                      ? 'Editing Field Schema'
                                      : 'New Field Definition',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  _isEditing
                                      ? 'Update field configuration. The field type cannot be modified once created.'
                                      : 'Configure the field name, data type, and validation rules for this database.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Field Name Input
                    TextFormField(
                      controller: _nameController,
                      maxLength: 60,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      textInputAction: TextInputAction.next,
                      scrollPadding: const EdgeInsets.all(AppSpacing.xxl),
                      decoration: InputDecoration(
                        labelText: 'Field Name',
                        hintText: 'e.g. Status',
                        errorMaxLines: 2,
                        prefixIcon: const Icon(
                          Icons.label_outline_rounded,
                          size: 20,
                        ),
                        suffixIcon: _nameController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                tooltip: 'Clear field name',
                                onPressed: () {
                                  _nameController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      textCapitalization: TextCapitalization.words,
                      autofocus: !_isEditing,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a field name';
                        }
                        if (value.trim().length > 60) {
                          return 'Name must be 60 characters or less';
                        }
                        final controller = ref.read(
                          fieldListControllerProvider(
                            widget.databaseId,
                          ).notifier,
                        );
                        if (!controller.isNameUnique(
                          value,
                          excludeFieldId: widget.initialField?.id,
                        )) {
                          return 'A field with this name already exists';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Field Type Selector
                    if (_isEditing)
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Field Type',
                          helperText:
                              'Field type cannot be changed after creation',
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getTypeIcon(_selectedType),
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              _getTypeLabel(_selectedType),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
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
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<FieldType>(
                              segments: const [
                                ButtonSegment(
                                  value: FieldType.text,
                                  label: Text('Text'),
                                  icon: Icon(
                                    Icons.text_fields_rounded,
                                    size: 18,
                                  ),
                                ),
                                ButtonSegment(
                                  value: FieldType.boolean,
                                  label: Text('Yes/No'),
                                  icon: Icon(
                                    Icons.check_box_outlined,
                                    size: 18,
                                  ),
                                ),
                                ButtonSegment(
                                  value: FieldType.choice,
                                  label: Text('Choice'),
                                  icon: Icon(Icons.list_alt_rounded, size: 18),
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
                    // Choice options management section
                    if (_selectedType == FieldType.choice) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      Row(
                        children: [
                          Text(
                            'Choice Options',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: _choiceOptions.isEmpty
                                  ? colorScheme.surfaceContainerHighest
                                  : colorScheme.secondaryContainer,
                              borderRadius: AppRadius.radiusSm,
                            ),
                            child: Text(
                              '${_choiceOptions.length} ${_choiceOptions.length == 1 ? 'option' : 'options'}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _choiceOptions.isEmpty
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _optionController,
                              focusNode: _optionFocusNode,
                              scrollPadding: const EdgeInsets.all(
                                AppSpacing.xxl,
                              ),
                              decoration: InputDecoration(
                                labelText: 'New Option',
                                hintText: 'e.g. In Stock',
                                prefixIcon: const Icon(
                                  Icons.radio_button_checked_rounded,
                                  size: 20,
                                ),
                                suffixIcon: _optionController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear_rounded,
                                          size: 18,
                                        ),
                                        tooltip: 'Clear option text',
                                        onPressed: () {
                                          _optionController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                errorText: _optionError,
                              ),
                              textCapitalization: TextCapitalization.words,
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _addOption(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: IconButton.filled(
                              onPressed: _addOption,
                              icon: const Icon(Icons.add_rounded, size: 20),
                              tooltip: 'Add Option',
                            ),
                          ),
                        ],
                      ),
                      if (_choiceError != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _choiceError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      if (_choiceOptions.isEmpty)
                        Text(
                          'No options added yet. Add at least one option above.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: _choiceOptions.map((opt) {
                            return InputChip(
                              label: Text(opt),
                              deleteButtonTooltipMessage: 'Remove option $opt',
                              onDeleted: () {
                                setState(() {
                                  _choiceOptions.remove(opt);
                                  if (_choiceOptions.isEmpty) {
                                    _choiceError =
                                        'Please add at least one choice option';
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    // Required Switch
                    VaultCard(
                      padding: EdgeInsets.zero,
                      child: SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: AppRadius.radiusSm,
                          ),
                          child: Icon(
                            Icons.star_outline_rounded,
                            size: 20,
                            color: _isRequired
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        title: const Text('Required Field'),
                        subtitle: const Text(
                          'Must be filled out for every record',
                        ),
                        value: _isRequired,
                        onChanged: (val) => setState(() => _isRequired = val),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
