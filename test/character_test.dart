import 'package:character_collector/legacy/models/character.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Character model', () {
    test('converts to and from a database map', () {
      final character = Character(
        id: 7,
        name: 'Astra',
        faction: 'Vanguard',
        characterClass: 'Mage',
        title: 'Keeper of Zero',
        skill1: 'Arc Pulse',
        skill2: 'Void Step',
        skill3: 'Index Shield',
        skill4: 'Final Archive',
      );

      final restoredCharacter = Character.fromMap(character.toMap());

      expect(restoredCharacter.id, 7);
      expect(restoredCharacter.name, 'Astra');
      expect(restoredCharacter.faction, 'Vanguard');
      expect(restoredCharacter.characterClass, 'Mage');
      expect(restoredCharacter.title, 'Keeper of Zero');
      expect(restoredCharacter.skill1, 'Arc Pulse');
      expect(restoredCharacter.skill2, 'Void Step');
      expect(restoredCharacter.skill3, 'Index Shield');
      expect(restoredCharacter.skill4, 'Final Archive');
    });

    test('copyWith changes selected fields and preserves the rest', () {
      final original = Character(
        id: 3,
        name: 'Nova',
        faction: 'Archive',
        characterClass: 'Rogue',
        title: 'The Unindexed',
        skill1: 'Silent Entry',
        skill2: 'Ghost Record',
        skill3: 'Null Mark',
        skill4: 'Zero Trace',
      );

      final updated = original.copyWith(
        name: 'Nova Prime',
        title: 'The Indexed',
      );

      expect(updated.id, original.id);
      expect(updated.name, 'Nova Prime');
      expect(updated.faction, original.faction);
      expect(updated.characterClass, original.characterClass);
      expect(updated.title, 'The Indexed');
      expect(updated.skill1, original.skill1);
      expect(updated.skill2, original.skill2);
      expect(updated.skill3, original.skill3);
      expect(updated.skill4, original.skill4);
    });
  });
}
