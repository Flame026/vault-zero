import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class PreferencesRepository {
  static const String _preferencesFileName = 'vault_zero_preferences.json';
  final Future<Directory> Function()? getDocsDir;

  PreferencesRepository({this.getDocsDir});

  Future<File> _getPreferencesFile([
    String fileName = _preferencesFileName,
  ]) async {
    final customDocsDir = getDocsDir;
    final directory = customDocsDir != null
        ? await customDocsDir()
        : await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  Future<Map<String, dynamic>> loadPreferences() async {
    try {
      final currentFile = await _getPreferencesFile();

      if (!await currentFile.exists()) {
        return {};
      }

      final jsonText = await currentFile.readAsString();
      final dynamic decoded = jsonDecode(jsonText);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<void>? _activeSave;

  Future<void> savePreferences(Map<String, dynamic> data) {
    // Chain saves to avoid concurrent temp file rename collisions
    final previousSave = _activeSave ?? Future.value();
    final nextSave = previousSave.then((_) => _executeSave(data));
    _activeSave = nextSave.catchError((_) {});
    return nextSave;
  }

  Future<void> _executeSave(Map<String, dynamic> data) async {
    File? tempFile;
    try {
      final file = await _getPreferencesFile();
      // Read existing to preserve unknown keys when saving partial updates
      Map<String, dynamic> existing = {};
      if (await file.exists()) {
        try {
          final jsonText = await file.readAsString();
          final dynamic decoded = jsonDecode(jsonText);
          if (decoded is Map<String, dynamic>) {
            existing = Map<String, dynamic>.from(decoded);
          } else if (decoded is Map) {
            existing = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }

      existing.addAll(data);

      // Atomic write via temp file to prevent corruption on sudden termination
      tempFile = File('${file.path}.tmp');
      await tempFile.writeAsString(jsonEncode(existing), flush: true);
      await tempFile.rename(file.path);
    } catch (_) {
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  Future<String?> getString(String key) async {
    final prefs = await loadPreferences();
    final value = prefs[key];
    return value is String ? value : null;
  }

  /// Waits for any pending save operations to complete.
  Future<void> flush() async {
    final active = _activeSave;
    if (active != null) {
      await active;
    }
  }

  Future<void> setString(String key, String value) async {
    await savePreferences({key: value});
  }
}

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository();
});
