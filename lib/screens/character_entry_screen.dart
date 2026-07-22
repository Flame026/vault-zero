import 'dart:io';

import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../models/character.dart';

enum ThemePreset {
  royalPurple(
    label: 'Royal Purple',
    description: 'The original Vault Zero look',
    seedColor: Color(0xFF6F35D3),
  ),
  oceanBlue(
    label: 'Ocean Blue',
    description: 'Cool, clear, and focused',
    seedColor: Color(0xFF1769AA),
  ),
  emeraldGreen(
    label: 'Emerald Green',
    description: 'Calm, natural, and balanced',
    seedColor: Color(0xFF16835B),
  ),
  sunsetOrange(
    label: 'Sunset Orange',
    description: 'Warm, energetic, and bold',
    seedColor: Color(0xFFD85B24),
  ),
  rosePink(
    label: 'Rose Pink',
    description: 'Soft, expressive, and vivid',
    seedColor: Color(0xFFC13D75),
  );

  const ThemePreset({
    required this.label,
    required this.description,
    required this.seedColor,
  });

  final String label;
  final String description;
  final Color seedColor;
}

class CharacterEntryScreen extends StatefulWidget {
  const CharacterEntryScreen({
    super.key,
    required this.themeMode,
    required this.selectedThemePreset,
    required this.onThemeModeChanged,
    required this.onThemePresetChanged,
  });

  final ThemeMode themeMode;
  final ThemePreset selectedThemePreset;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<ThemePreset> onThemePresetChanged;

  @override
  State<CharacterEntryScreen> createState() => _CharacterEntryScreenState();
}

class _CharacterEntryScreenState extends State<CharacterEntryScreen> {
  final scrollController = ScrollController();

  final nameController = TextEditingController();
  final factionController = TextEditingController();
  final classController = TextEditingController();
  final titleController = TextEditingController();
  final skill1Controller = TextEditingController();
  final skill2Controller = TextEditingController();
  final skill3Controller = TextEditingController();
  final skill4Controller = TextEditingController();

  final nameFocusNode = FocusNode();
  final factionFocusNode = FocusNode();
  final classFocusNode = FocusNode();
  final titleFocusNode = FocusNode();
  final skill1FocusNode = FocusNode();
  final skill2FocusNode = FocusNode();
  final skill3FocusNode = FocusNode();
  final skill4FocusNode = FocusNode();

  Character? editingCharacter;
  int characterCount = 0;
  bool isExporting = false;

  bool get isEditing => editingCharacter != null;

  @override
  void initState() {
    super.initState();
    loadCharacterCount();
  }

  @override
  void dispose() {
    scrollController.dispose();

    nameController.dispose();
    factionController.dispose();
    classController.dispose();
    titleController.dispose();
    skill1Controller.dispose();
    skill2Controller.dispose();
    skill3Controller.dispose();
    skill4Controller.dispose();

    nameFocusNode.dispose();
    factionFocusNode.dispose();
    classFocusNode.dispose();
    titleFocusNode.dispose();
    skill1FocusNode.dispose();
    skill2FocusNode.dispose();
    skill3FocusNode.dispose();
    skill4FocusNode.dispose();

    super.dispose();
  }

  Future<void> loadCharacterCount() async {
    final count = await DatabaseHelper.instance.getCharacterCount();

    if (!mounted) return;

    setState(() {
      characterCount = count;
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void clearForm() {
    FocusScope.of(context).unfocus();

    nameController.clear();
    factionController.clear();
    classController.clear();
    titleController.clear();
    skill1Controller.clear();
    skill2Controller.clear();
    skill3Controller.clear();
    skill4Controller.clear();

    setState(() {
      editingCharacter = null;
    });
  }

  void startEditing(Character character) {
    nameController.text = character.name;
    factionController.text = character.faction;
    classController.text = character.characterClass;
    titleController.text = character.title;
    skill1Controller.text = character.skill1;
    skill2Controller.text = character.skill2;
    skill3Controller.text = character.skill3;
    skill4Controller.text = character.skill4;

    setState(() {
      editingCharacter = character;
    });

    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }

    showMessage('Editing ${character.name}');
  }

  Future<void> saveCharacter() async {
    FocusScope.of(context).unfocus();

    final name = nameController.text.trim();

    if (name.isEmpty) {
      showMessage('Character name is required');

      nameFocusNode.requestFocus();
      return;
    }

    final character = Character(
      id: editingCharacter?.id,
      name: name,
      faction: factionController.text.trim(),
      characterClass: classController.text.trim(),
      title: titleController.text.trim(),
      skill1: skill1Controller.text.trim(),
      skill2: skill2Controller.text.trim(),
      skill3: skill3Controller.text.trim(),
      skill4: skill4Controller.text.trim(),
    );

    final wasEditing = isEditing;

    if (wasEditing) {
      await DatabaseHelper.instance.updateCharacter(character);
    } else {
      await DatabaseHelper.instance.insertCharacter(character);
    }

    await loadCharacterCount();

    if (!mounted) return;

    clearForm();

    showMessage(
      wasEditing ? '${character.name} updated' : '${character.name} saved',
    );
  }

  Future<void> confirmDelete(
    Character character,
    Future<void> Function() afterDelete,
  ) async {
    if (character.id == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          iconPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          icon: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_forever_rounded,
              size: 36,
              color: colorScheme.onErrorContainer,
            ),
          ),
          title: const Text(
            'Delete Character?',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Are you sure you want to permanently delete ',
                    ),
                    TextSpan(
                      text: '“${character.name}”',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.45,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withAlpha(120),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This action cannot be undone.',
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('DELETE'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await DatabaseHelper.instance.deleteCharacter(character.id!);
    await loadCharacterCount();
    await afterDelete();

    if (!mounted) return;

    if (editingCharacter?.id == character.id) {
      clearForm();
    }

    showMessage('${character.name} deleted');
  }

  Future<void> showSavedCharacters() async {
    final searchController = TextEditingController();

    List<Character> characters =
        await DatabaseHelper.instance.getAllCharacters();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> refreshList() async {
              final query = searchController.text.trim();

              final updatedCharacters = query.isEmpty
                  ? await DatabaseHelper.instance.getAllCharacters()
                  : await DatabaseHelper.instance.searchCharacters(query);

              if (!mounted) return;

              setModalState(() {
                characters = updatedCharacters;
              });
            }

            final colorScheme = Theme.of(context).colorScheme;

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.92,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 2, 18, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Saved Characters',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${characters.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        labelText: 'Search name, faction, class, or title',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  searchController.clear();
                                  FocusScope.of(context).unfocus();
                                  refreshList();
                                },
                                icon: const Icon(Icons.close),
                              )
                            : null,
                      ),
                      onChanged: (_) {
                        refreshList();
                      },
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: characters.isEmpty
                          ? emptyCharactersState(
                              isSearching:
                                  searchController.text.trim().isNotEmpty,
                              onAction: () {
                                if (searchController.text.trim().isNotEmpty) {
                                  searchController.clear();
                                  FocusScope.of(context).unfocus();
                                  refreshList();
                                  return;
                                }

                                Navigator.pop(sheetContext);

                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    nameFocusNode.requestFocus();
                                  }
                                });
                              },
                            )
                          : ListView.builder(
                              itemCount: characters.length,
                              itemBuilder: (context, index) {
                                final character = characters[index];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                child: Text(
                                                  character.name.isEmpty
                                                      ? '?'
                                                      : character.name[0]
                                                          .toUpperCase(),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      character.name,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (character.title.isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 3),
                                                        child: Text(
                                                          character.title,
                                                          style: TextStyle(
                                                            color: colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              if (character.faction.isNotEmpty)
                                                Chip(
                                                  avatar: const Icon(
                                                    Icons.flag_outlined,
                                                    size: 18,
                                                  ),
                                                  label: Text(
                                                    character.faction,
                                                  ),
                                                ),
                                              if (character.characterClass
                                                  .isNotEmpty)
                                                Chip(
                                                  avatar: const Icon(
                                                    Icons.category_outlined,
                                                    size: 18,
                                                  ),
                                                  label: Text(
                                                    character.characterClass,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () {
                                                    Navigator.pop(
                                                      sheetContext,
                                                    );
                                                    startEditing(character);
                                                  },
                                                  icon: const Icon(Icons.edit),
                                                  label: const Text('EDIT'),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        colorScheme.error,
                                                  ),
                                                  onPressed: () async {
                                                    await confirmDelete(
                                                      character,
                                                      refreshList,
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                  label: const Text('DELETE'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
  }

  Widget emptyCharactersState({
    required bool isSearching,
    required VoidCallback onAction,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final icon = isSearching
        ? Icons.search_off_rounded
        : Icons.person_add_alt_1_rounded;

    final title = isSearching
        ? 'No matching characters'
        : 'Your collection is empty';

    final message = isSearching
        ? 'Try a different name, faction, class, or title.'
        : 'Create your first character and it will appear here.';

    final buttonText = isSearching
        ? 'CLEAR SEARCH'
        : 'CREATE FIRST CHARACTER';

    final buttonIcon = isSearching
        ? Icons.refresh_rounded
        : Icons.add_rounded;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 24,
        ),
        child: Card(
          color: colorScheme.surfaceContainerHighest,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 42,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: isSearching
                      ? OutlinedButton.icon(
                          onPressed: onAction,
                          icon: Icon(buttonIcon),
                          label: Text(buttonText),
                        )
                      : FilledButton.icon(
                          onPressed: onAction,
                          icon: Icon(buttonIcon),
                          label: Text(buttonText),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _themePreviewDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withAlpha(190),
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> showThemePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final screenHeight = MediaQuery.sizeOf(sheetContext).height;

        return SizedBox(
          height: screenHeight * 0.78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Theme Colour',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your choice works in both light and dark mode.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: ThemePreset.values.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 10);
                    },
                    itemBuilder: (context, index) {
                      final preset = ThemePreset.values[index];
                      final isSelected =
                          preset == widget.selectedThemePreset;

                      final previewLight = Color.lerp(
                        preset.seedColor,
                        Colors.white,
                        0.62,
                      )!;
                      final previewDark = Color.lerp(
                        preset.seedColor,
                        Colors.black,
                        0.34,
                      )!;

                      return Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        color: isSelected
                            ? colorScheme.primaryContainer.withAlpha(150)
                            : colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: BorderSide(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            widget.onThemePresetChanged(preset);
                            Navigator.pop(sheetContext);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned(
                                        left: 0,
                                        child: _themePreviewDot(
                                          previewLight,
                                          24,
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        child: _themePreviewDot(
                                          previewDark,
                                          24,
                                        ),
                                      ),
                                      _themePreviewDot(
                                        preset.seedColor,
                                        30,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        preset.label,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        preset.description,
                                        style: TextStyle(
                                          color:
                                              colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_rounded,
                                          size: 17,
                                          color: colorScheme.onPrimary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            color: colorScheme.onPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String buildExportFileName(DateTime dateTime) {
    final year = dateTime.year;
    final month = twoDigits(dateTime.month);
    final day = twoDigits(dateTime.day);
    final hour = twoDigits(dateTime.hour);
    final minute = twoDigits(dateTime.minute);
    final second = twoDigits(dateTime.second);

    return 'vault_zero_characters_$year-$month-${day}_$hour-$minute-$second.xlsx';
  }

  Future<void> shareExportFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Vault Zero Export',
    );
  }

  Future<void> showExportSuccessDialog({
    required File file,
    required String fileName,
    required int exportedCount,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          iconPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          icon: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.task_alt_rounded,
              size: 38,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          title: const Text(
            'Export Complete',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$exportedCount character${exportedCount == 1 ? '' : 's'} exported successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('CLOSE'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(dialogContext);

                      try {
                        await shareExportFile(file);
                      } catch (_) {
                        if (!mounted) return;
                        await showExportErrorDialog();
                      }
                    },
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('SHARE AGAIN'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> showExportErrorDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          iconPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          icon: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 38,
              color: colorScheme.onErrorContainer,
            ),
          ),
          title: const Text(
            'Export Failed',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'The Excel file could not be prepared or shared. Check your storage and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.45,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('GOT IT'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> exportToExcel() async {
    if (isExporting) return;

    FocusScope.of(context).unfocus();

    setState(() {
      isExporting = true;
    });

    try {
      final characters = await DatabaseHelper.instance.getAllCharacters();

      if (characters.isEmpty) {
        showMessage('No characters to export');
        return;
      }

      final excel = Excel.createExcel();
      final sheet = excel['Characters'];

      sheet.appendRow([
        TextCellValue('Name'),
        TextCellValue('Faction'),
        TextCellValue('Class'),
        TextCellValue('Title'),
        TextCellValue('Skill1'),
        TextCellValue('Skill2'),
        TextCellValue('Skill3'),
        TextCellValue('Skill4'),
      ]);

      for (final character in characters) {
        sheet.appendRow([
          TextCellValue(character.name),
          TextCellValue(character.faction),
          TextCellValue(character.characterClass),
          TextCellValue(character.title),
          TextCellValue(character.skill1),
          TextCellValue(character.skill2),
          TextCellValue(character.skill3),
          TextCellValue(character.skill4),
        ]);
      }

      excel.delete('Sheet1');

      final bytes = excel.save();

      if (bytes == null) {
        throw StateError('Excel package returned no file data.');
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = buildExportFileName(DateTime.now());
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(bytes, flush: true);
      await shareExportFile(file);

      if (!mounted) return;

      await showExportSuccessDialog(
        file: file,
        fileName: fileName,
        exportedCount: characters.length,
      );
    } catch (_) {
      if (!mounted) return;

      await showExportErrorDialog();
    } finally {
      if (mounted) {
        setState(() {
          isExporting = false;
        });
      }
    }
  }

  Widget field(
    String label,
    TextEditingController controller, {
    required FocusNode focusNode,
    required TextInputAction textInputAction,
    required ValueChanged<String> onSubmitted,
    int maxLines = 1,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: maxLines,
        keyboardType: TextInputType.text,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: maxLines == 1 && icon != null ? Icon(icon) : null,
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }

  Widget fullWidthButton({
    required VoidCallback? onPressed,
    required Widget child,
    bool filled = false,
  }) {
    final button = filled
        ? FilledButton(
            onPressed: onPressed,
            child: child,
          )
        : OutlinedButton(
            onPressed: onPressed,
            child: child,
          );

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }

  Widget sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Card(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget headerCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seedColor = widget.selectedThemePreset.seedColor;

    final secondGradientColor = Color.lerp(
      seedColor,
      Colors.black,
      isDark ? 0.34 : 0.12,
    )!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            seedColor,
            secondGradientColor,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(height: 14),
          const Text(
            'Build your character vault',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Characters stored: $characterCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget editCard() {
    if (!isEditing) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Card(
        color: colorScheme.tertiaryContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: colorScheme.tertiary.withAlpha(110),
          ),
        ),
        child: ListTile(
          textColor: colorScheme.onTertiaryContainer,
          iconColor: colorScheme.onTertiaryContainer,
          leading: const Icon(Icons.edit),
          title: Text('Editing ${editingCharacter!.name}'),
          subtitle: const Text('Save to update or cancel editing.'),
          trailing: IconButton(
            onPressed: clearForm,
            icon: const Icon(Icons.close),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonText = isEditing ? 'UPDATE CHARACTER' : 'SAVE CHARACTER';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Zero'),
        actions: [
          IconButton(
            tooltip: 'Choose theme colour',
            onPressed: showThemePicker,
            icon: const Icon(Icons.palette_outlined),
          ),
          IconButton(
            tooltip: isDark ? 'Use light mode' : 'Use dark mode',
            onPressed: () {
              widget.onThemeModeChanged(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
            icon: Icon(
              isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        child: Column(
          children: [
            headerCard(),
            editCard(),
            sectionCard(
              title: 'Basic Details',
              icon: Icons.badge_outlined,
              children: [
                field(
                  'Character Name',
                  nameController,
                  focusNode: nameFocusNode,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => factionFocusNode.requestFocus(),
                  icon: Icons.person_outline,
                ),
                field(
                  'Faction',
                  factionController,
                  focusNode: factionFocusNode,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => classFocusNode.requestFocus(),
                  icon: Icons.flag_outlined,
                ),
                field(
                  'Class',
                  classController,
                  focusNode: classFocusNode,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => titleFocusNode.requestFocus(),
                  icon: Icons.category_outlined,
                ),
                field(
                  'Character Title',
                  titleController,
                  focusNode: titleFocusNode,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => skill1FocusNode.requestFocus(),
                  icon: Icons.workspace_premium_outlined,
                ),
              ],
            ),
            sectionCard(
              title: 'Skills',
              icon: Icons.bolt_outlined,
              children: [
                field(
                  'Skill 1',
                  skill1Controller,
                  focusNode: skill1FocusNode,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => skill2FocusNode.requestFocus(),
                  maxLines: 5,
                ),
                field(
                  'Skill 2',
                  skill2Controller,
                  focusNode: skill2FocusNode,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => skill3FocusNode.requestFocus(),
                  maxLines: 5,
                ),
                field(
                  'Skill 3',
                  skill3Controller,
                  focusNode: skill3FocusNode,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => skill4FocusNode.requestFocus(),
                  maxLines: 5,
                ),
                field(
                  'Skill 4',
                  skill4Controller,
                  focusNode: skill4FocusNode,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  maxLines: 5,
                ),
              ],
            ),
            sectionCard(
              title: 'Actions',
              icon: Icons.tune,
              children: [
                fullWidthButton(
                  filled: true,
                  onPressed: saveCharacter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isEditing ? Icons.save_as : Icons.save),
                      const SizedBox(width: 8),
                      Text(buttonText),
                    ],
                  ),
                ),
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  fullWidthButton(
                    onPressed: clearForm,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close),
                        SizedBox(width: 8),
                        Text('CANCEL EDITING'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                fullWidthButton(
                  onPressed: showSavedCharacters,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.manage_search),
                      SizedBox(width: 8),
                      Text('VIEW / SEARCH SAVED CHARACTERS'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                fullWidthButton(
                  onPressed: isExporting ? null : exportToExcel,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isExporting)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                          ),
                        )
                      else
                        const Icon(Icons.file_upload_outlined),
                      const SizedBox(width: 8),
                      Text(
                        isExporting
                            ? 'PREPARING EXCEL...'
                            : 'EXPORT TO EXCEL',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
