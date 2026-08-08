import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/character.dart';
import '../repositories/legacy_character_repository.dart';

final characterListControllerProvider = AsyncNotifierProvider<CharacterListController, List<Character>>(() {
  return CharacterListController();
});

class CharacterListController extends AsyncNotifier<List<Character>> {
  @override
  Future<List<Character>> build() async {
    return _fetchCharacters();
  }

  Future<List<Character>> _fetchCharacters() async {
    final repo = await ref.watch(legacyCharacterRepositoryProvider.future);
    return repo.getAllCharacters();
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(legacyCharacterRepositoryProvider.future);
      return repo.searchCharacters(query);
    });
  }

  Future<void> saveCharacter(Character character) async {
    final repo = await ref.read(legacyCharacterRepositoryProvider.future);
    if (character.id == null) {
      await repo.insertCharacter(character);
    } else {
      await repo.updateCharacter(character);
    }
    // Refresh list
    state = await AsyncValue.guard(_fetchCharacters);
  }

  Future<void> deleteCharacter(int id) async {
    final repo = await ref.read(legacyCharacterRepositoryProvider.future);
    await repo.deleteCharacter(id);
    // Refresh list
    state = await AsyncValue.guard(_fetchCharacters);
  }

  Future<int> getCount() async {
    final repo = await ref.read(legacyCharacterRepositoryProvider.future);
    return repo.getCharacterCount();
  }
}
