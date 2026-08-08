import 'dart:io';

import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../repositories/legacy_character_repository.dart';

final exportControllerProvider = AsyncNotifierProvider<ExportController, void>(() {
  return ExportController();
});

class ExportController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<File?> exportToExcel() async {
    state = const AsyncValue.loading();
    File? generatedFile;
    
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(legacyCharacterRepositoryProvider.future);
      final characters = await repo.getAllCharacters();

      if (characters.isEmpty) {
        throw StateError('No characters to export');
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
      final now = DateTime.now();
      final fileName = 'vault_zero_characters_${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}_${_twoDigits(now.hour)}-${_twoDigits(now.minute)}-${_twoDigits(now.second)}.xlsx';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(bytes, flush: true);
      generatedFile = file;
    });
    
    return generatedFile;
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
