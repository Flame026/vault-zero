import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'theme_preset.dart';

class ThemeState {
  final ThemeMode mode;
  final ThemePreset preset;

  const ThemeState({
    required this.mode,
    required this.preset,
  });

  ThemeState copyWith({
    ThemeMode? mode,
    ThemePreset? preset,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      preset: preset ?? this.preset,
    );
  }
}

class ThemeController extends Notifier<ThemeState> {
  static const String _preferencesFileName = 'vault_zero_preferences.json';
  static const String _legacyPreferencesFileName = 'character_collector_preferences.json';

  @override
  ThemeState build() {
    _loadPreferences();
    return const ThemeState(mode: ThemeMode.light, preset: ThemePreset.royalPurple);
  }

  Future<File> _getPreferencesFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  Future<void> _loadPreferences() async {
    try {
      final currentFile = await _getPreferencesFile(_preferencesFileName);
      final legacyFile = await _getPreferencesFile(_legacyPreferencesFileName);

      final File sourceFile;

      if (await currentFile.exists()) {
        sourceFile = currentFile;
      } else if (await legacyFile.exists()) {
        sourceFile = legacyFile;
      } else {
        return;
      }

      final jsonText = await sourceFile.readAsString();
      final data = jsonDecode(jsonText) as Map<String, dynamic>;

      final savedThemeMode = data['themeMode'] == 'dark' ? ThemeMode.dark : ThemeMode.light;
      final savedPresetName = data['themePreset'] as String?;

      final savedPreset = ThemePreset.values.firstWhere(
        (preset) => preset.name == savedPresetName,
        orElse: () => ThemePreset.royalPurple,
      );

      state = ThemeState(mode: savedThemeMode, preset: savedPreset);

      if (sourceFile.path == legacyFile.path) {
        await _savePreferences();
      }
    } catch (_) {
      // Keep defaults
    }
  }

  Future<void> _savePreferences() async {
    try {
      final file = await _getPreferencesFile(_preferencesFileName);
      final data = <String, String>{
        'themeMode': state.mode == ThemeMode.dark ? 'dark' : 'light',
        'themePreset': state.preset.name,
      };

      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (_) {}
  }

  void changeMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
    _savePreferences();
  }

  void changePreset(ThemePreset preset) {
    state = state.copyWith(preset: preset);
    _savePreferences();
  }
}

final themeProvider = NotifierProvider<ThemeController, ThemeState>(() {
  return ThemeController();
});
