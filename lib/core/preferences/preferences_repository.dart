import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class PreferencesRepository {
  static const String _preferencesFileName = 'vault_zero_preferences.json';
  static const String _legacyPreferencesFileName = 'character_collector_preferences.json';

  Future<File> _getPreferencesFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  Future<Map<String, dynamic>> loadPreferences() async {
    try {
      final currentFile = await _getPreferencesFile(_preferencesFileName);
      final legacyFile = await _getPreferencesFile(_legacyPreferencesFileName);

      File? sourceFile;

      if (await currentFile.exists()) {
        sourceFile = currentFile;
      } else if (await legacyFile.exists()) {
        sourceFile = legacyFile;
      }

      if (sourceFile == null) {
        return {};
      }

      final jsonText = await sourceFile.readAsString();
      final data = jsonDecode(jsonText) as Map<String, dynamic>;

      // Migrate from legacy to current file location if needed
      if (sourceFile.path == legacyFile.path) {
        await savePreferences(data);
      }

      return data;
    } catch (_) {
      return {};
    }
  }

  Future<void> savePreferences(Map<String, dynamic> data) async {
    try {
      final file = await _getPreferencesFile(_preferencesFileName);
      // Read existing to preserve unknown keys when saving partial updates
      Map<String, dynamic> existing = {};
      if (await file.exists()) {
         try {
           final jsonText = await file.readAsString();
           existing = jsonDecode(jsonText) as Map<String, dynamic>;
         } catch (_) {}
      }
      
      existing.addAll(data);

      await file.writeAsString(jsonEncode(existing), flush: true);
    } catch (_) {}
  }
}

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository();
});
