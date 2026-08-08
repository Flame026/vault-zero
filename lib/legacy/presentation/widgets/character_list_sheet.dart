import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/character_list_controller.dart';
import '../../models/character.dart';

class CharacterListSheet extends ConsumerStatefulWidget {
  final ValueChanged<Character> onEditRequested;

  const CharacterListSheet({super.key, required this.onEditRequested});

  @override
  ConsumerState<CharacterListSheet> createState() => _CharacterListSheetState();
}

class _CharacterListSheetState extends ConsumerState<CharacterListSheet> {
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> confirmDelete(Character character) async {
    if (character.id == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          iconPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          icon: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: colorScheme.errorContainer, shape: BoxShape.circle),
            child: Icon(Icons.delete_forever_rounded, size: 36, color: colorScheme.onErrorContainer),
          ),
          title: const Text('Delete Character?', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Are you sure you want to permanently delete '),
                    TextSpan(text: '“${character.name}”', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: '?'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.45, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withAlpha(120),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: colorScheme.onErrorContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This action cannot be undone.',
                        style: TextStyle(color: colorScheme.onErrorContainer, fontWeight: FontWeight.w600),
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
                    style: FilledButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
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

    if (shouldDelete == true) {
      await ref.read(characterListControllerProvider.notifier).deleteCharacter(character.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${character.name} deleted')));
      }
    }
  }

  Widget emptyCharactersState(bool isSearching) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = isSearching ? Icons.search_off_rounded : Icons.person_add_alt_1_rounded;
    final title = isSearching ? 'No matching characters' : 'Your collection is empty';
    final message = isSearching ? 'Try a different name, faction, class, or title.' : 'Create your first character and it will appear here.';
    final buttonText = isSearching ? 'CLEAR SEARCH' : 'CREATE FIRST CHARACTER';
    final buttonIcon = isSearching ? Icons.refresh_rounded : Icons.add_rounded;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
        child: Card(
          color: colorScheme.surfaceContainerHighest,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
                  child: Icon(icon, size: 42, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 20),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: TextStyle(height: 1.4, color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: isSearching
                      ? OutlinedButton.icon(
                          onPressed: () {
                            searchController.clear();
                            FocusScope.of(context).unfocus();
                            ref.read(characterListControllerProvider.notifier).search('');
                          },
                          icon: Icon(buttonIcon),
                          label: Text(buttonText),
                        )
                      : FilledButton.icon(
                          onPressed: () => Navigator.pop(context),
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

  @override
  Widget build(BuildContext context) {
    final charactersState = ref.watch(characterListControllerProvider);
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
                  child: Text('Saved Characters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                if (charactersState.hasValue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      '${charactersState.value!.length}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
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
                          ref.read(characterListControllerProvider.notifier).search('');
                        },
                        icon: const Icon(Icons.close),
                      )
                    : null,
              ),
              onChanged: (query) => ref.read(characterListControllerProvider.notifier).search(query),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: charactersState.when(
                data: (characters) {
                  if (characters.isEmpty) {
                    return emptyCharactersState(searchController.text.trim().isNotEmpty);
                  }
                  return ListView.builder(
                    itemCount: characters.length,
                    itemBuilder: (context, index) {
                      final character = characters[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      child: Text(character.name.isEmpty ? '?' : character.name[0].toUpperCase()),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(character.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          if (character.title.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 3),
                                              child: Text(character.title, style: TextStyle(color: colorScheme.onSurfaceVariant)),
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
                                      Chip(avatar: const Icon(Icons.flag_outlined, size: 18), label: Text(character.faction)),
                                    if (character.characterClass.isNotEmpty)
                                      Chip(avatar: const Icon(Icons.category_outlined, size: 18), label: Text(character.characterClass)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          widget.onEditRequested(character);
                                        },
                                        icon: const Icon(Icons.edit),
                                        label: const Text('EDIT'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                                        onPressed: () => confirmDelete(character),
                                        icon: const Icon(Icons.delete_outline),
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
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
