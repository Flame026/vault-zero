import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../domain/models/field_definition.dart';
import '../../../domain/models/record.dart';
import '../common/widgets/vault_app_bar.dart';
import '../common/widgets/vault_card.dart';
import '../common/widgets/vault_discard_dialog.dart';
import '../common/widgets/vault_icon_badge.dart';
import '../common/widgets/vault_snackbar.dart';
import '../common/error_sanitizer.dart';
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
  late final Map<String, dynamic> _initialValues;
  late final List<FocusNode> _focusNodes;
  bool _isSaving = false;
  bool _isDiscarding = false;

  @override
  void initState() {
    super.initState();
    _values = {};
    _initialValues = {};
    for (final field in widget.fields) {
      final fieldValue = widget.initialRecord?.values[field.id];
      _values[field.id] = fieldValue?.value;
      _initialValues[field.id] = fieldValue?.value;
    }
    _focusNodes = List.generate(widget.fields.length, (index) => FocusNode());
  }

  bool get _isDirty {
    for (final field in widget.fields) {
      final initial = _initialValues[field.id];
      final current = _values[field.id];
      if (initial == null && current == null) continue;
      if (initial == null && current is String && current.trim().isEmpty) {
        continue;
      }
      if (current == null && initial is String && initial.trim().isEmpty) {
        continue;
      }
      if (initial is DateTime && current is DateTime) {
        if (initial.isAtSameMomentAs(current)) continue;
        return true;
      }
      if (initial != current) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    return VaultDiscardDialog.show(context);
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
      // Direct focus to the first invalid field
      for (int i = 0; i < widget.fields.length; i++) {
        final field = widget.fields[i];
        final val = _values[field.id];
        if (field.isRequired &&
            (val == null || (val is String && val.trim().isEmpty))) {
          _focusNodes[i].requestFocus();
          break;
        }
      }
      return;
    }

    final controller = ref.read(
      recordListControllerProvider(widget.databaseId).notifier,
    );

    setState(() => _isSaving = true);
    try {
      await controller.saveRecord(
        existingRecord: widget.initialRecord,
        fields: widget.fields,
        rawValues: _values,
      );

      if (mounted) {
        _initialValues.clear();
        _values.clear();
        VaultSnackbar.showSuccess(
          context,
          widget.initialRecord != null ? 'Record updated' : 'Record created',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        VaultSnackbar.showError(
          context,
          'Failed to save record: ${sanitizeErrorMessage(e)}',
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.initialRecord != null;
    final fieldCount = widget.fields.length;
    final subtitleText = '$fieldCount ${fieldCount == 1 ? 'field' : 'fields'}';

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
          title: isEditing ? 'Edit Record' : 'New Record',
          subtitle: subtitleText,
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
                onPressed: _isSaving ? null : _onSave,
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
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: ListView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: widget.fields.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: VaultCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              VaultIconBadge(
                                icon: isEditing
                                    ? Icons.edit_note_rounded
                                    : Icons.add_circle_outline_rounded,
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
                                      isEditing
                                          ? 'Editing Record'
                                          : 'New Record Entry',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      isEditing
                                          ? 'Update values below. Changes are saved upon confirmation.'
                                          : 'Complete the fields below. Required fields are clearly marked.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final fieldIndex = index - 1;
                    final field = widget.fields[fieldIndex];
                    final isLast = fieldIndex == widget.fields.length - 1;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: isLast ? AppSpacing.xxl : AppSpacing.lg,
                      ),
                      child: DynamicFieldInput(
                        field: field,
                        initialValue: _values[field.id],
                        focusNode: _focusNodes[fieldIndex],
                        autofocus: !isEditing && fieldIndex == 0,
                        textInputAction: isLast
                            ? TextInputAction.done
                            : TextInputAction.next,
                        onFieldSubmitted: (_) {
                          if (isLast) {
                            _onSave();
                          } else {
                            FocusScope.of(
                              context,
                            ).requestFocus(_focusNodes[fieldIndex + 1]);
                          }
                        },
                        onChanged: (val) {
                          final wasDirty = _isDirty;
                          _values[field.id] = val;
                          if (wasDirty != _isDirty) {
                            setState(() {});
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
