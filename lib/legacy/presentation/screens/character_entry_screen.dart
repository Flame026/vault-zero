import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/theme_provider.dart';
import '../../models/character.dart';
import '../controllers/character_list_controller.dart';
import '../controllers/export_controller.dart';
import '../widgets/character_list_sheet.dart';
import '../widgets/theme_picker_sheet.dart';

class CharacterEntryScreen extends ConsumerStatefulWidget {
  const CharacterEntryScreen({super.key});

  @override
  ConsumerState<CharacterEntryScreen> createState() => _CharacterEntryScreenState();
}

class _CharacterEntryScreenState extends ConsumerState<CharacterEntryScreen> {
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

  bool get isEditing => editingCharacter != null;

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

  void showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
      scrollController.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
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
    await ref.read(characterListControllerProvider.notifier).saveCharacter(character);
    clearForm();
    showMessage(wasEditing ? '${character.name} updated' : '${character.name} saved');
  }

  Future<void> showSavedCharacters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => CharacterListSheet(onEditRequested: startEditing),
    );
  }

  Future<void> showThemePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => const ThemePickerSheet(),
    );
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

  Widget fullWidthButton({required VoidCallback? onPressed, required Widget child, bool filled = false}) {
    final button = filled ? FilledButton(onPressed: onPressed, child: child) : OutlinedButton(onPressed: onPressed, child: child);
    return SizedBox(width: double.infinity, child: button);
  }

  Widget sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Card(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: colorScheme.outlineVariant)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget headerCard(int characterCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seedColor = ref.watch(themeProvider).preset.seedColor;
    final secondGradientColor = Color.lerp(seedColor, Colors.black, isDark ? 0.34 : 0.12)!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [seedColor, secondGradientColor]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
          const SizedBox(height: 14),
          const Text(
            'Build your character vault',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Characters stored: $characterCount',
            style: const TextStyle(color: Colors.white, fontSize: 15),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: colorScheme.tertiary.withAlpha(110))),
        child: ListTile(
          textColor: colorScheme.onTertiaryContainer,
          iconColor: colorScheme.onTertiaryContainer,
          leading: const Icon(Icons.edit),
          title: Text('Editing ${editingCharacter!.name}'),
          subtitle: const Text('Save to update or cancel editing.'),
          trailing: IconButton(onPressed: clearForm, icon: const Icon(Icons.close)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonText = isEditing ? 'UPDATE CHARACTER' : 'SAVE CHARACTER';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // We watch the characters to update the count in header
    final charactersState = ref.watch(characterListControllerProvider);
    final characterCount = charactersState.valueOrNull?.length ?? 0;
    
    final exportState = ref.watch(exportControllerProvider);
    final isExporting = exportState.isLoading;

    ref.listen(exportControllerProvider, (previous, next) {
      if (next.hasError) {
        showMessage('Export Failed. Check storage and try again.');
      }
    });

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
              ref.read(themeProvider.notifier).changeMode(isDark ? ThemeMode.light : ThemeMode.dark);
            },
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        child: Column(
          children: [
            headerCard(characterCount),
            editCard(),
            sectionCard(
              title: 'Basic Details',
              icon: Icons.badge_outlined,
              children: [
                field('Character Name', nameController, focusNode: nameFocusNode, textInputAction: TextInputAction.next, onSubmitted: (_) => factionFocusNode.requestFocus(), icon: Icons.person_outline),
                field('Faction', factionController, focusNode: factionFocusNode, textInputAction: TextInputAction.next, onSubmitted: (_) => classFocusNode.requestFocus(), icon: Icons.flag_outlined),
                field('Class', classController, focusNode: classFocusNode, textInputAction: TextInputAction.next, onSubmitted: (_) => titleFocusNode.requestFocus(), icon: Icons.category_outlined),
                field('Character Title', titleController, focusNode: titleFocusNode, textInputAction: TextInputAction.next, onSubmitted: (_) => skill1FocusNode.requestFocus(), icon: Icons.workspace_premium_outlined),
              ],
            ),
            sectionCard(
              title: 'Skills',
              icon: Icons.bolt_outlined,
              children: [
                field('Skill 1', skill1Controller, focusNode: skill1FocusNode, textInputAction: TextInputAction.next, onSubmitted: (_) => skill2FocusNode.requestFocus(), maxLines: 5),
                field('Skill 2', skill2Controller, focusNode: skill2FocusNode, textInputAction: TextInputAction.next, onSubmitted: (_) => skill3FocusNode.requestFocus(), maxLines: 5),
                field('Skill 3', skill3Controller, focusNode: skill3FocusNode, textInputAction: TextInputAction.next, onSubmitted: (_) => skill4FocusNode.requestFocus(), maxLines: 5),
                field('Skill 4', skill4Controller, focusNode: skill4FocusNode, textInputAction: TextInputAction.done, onSubmitted: (_) => FocusScope.of(context).unfocus(), maxLines: 5),
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
                      children: [Icon(Icons.close), SizedBox(width: 8), Text('CANCEL EDITING')],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                fullWidthButton(
                  onPressed: showSavedCharacters,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.manage_search), SizedBox(width: 8), Text('VIEW / SEARCH SAVED CHARACTERS')],
                  ),
                ),
                const SizedBox(height: 12),
                fullWidthButton(
                  onPressed: isExporting ? null : () async {
                    final file = await ref.read(exportControllerProvider.notifier).exportToExcel();
                    if (file != null && mounted) {
                      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Vault Zero Export'));
                      if (mounted) showMessage('Export Complete!');
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isExporting) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4)) else const Icon(Icons.file_upload_outlined),
                      const SizedBox(width: 8),
                      Text(isExporting ? 'PREPARING EXCEL...' : 'EXPORT TO EXCEL'),
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
