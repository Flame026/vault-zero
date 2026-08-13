import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class PreferencesRepository {
  static const String _preferencesFileName = 'vault_zero_preferences.json';

  Future<File> _getPreferencesFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  Future<Map<String, dynamic>> loadPreferences() async {
    try {
      final currentFile = await _getPreferencesFile(_preferencesFileName);

      if (!await currentFile.exists()) {
        return {};
      }

      final jsonText = await currentFile.readAsString();
      final data = jsonDecode(jsonText) as Map<String, dynamic>;

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
