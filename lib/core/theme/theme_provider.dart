import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/preferences_repository.dart';
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
  late final PreferencesRepository _preferencesRepo;

  @override
  ThemeState build() {
    _preferencesRepo = ref.watch(preferencesRepositoryProvider);
    // Asynchronous load triggers state update later
    _loadPreferences();
    return const ThemeState(mode: ThemeMode.light, preset: ThemePreset.royalPurple);
  }

  Future<void> _loadPreferences() async {
    final data = await _preferencesRepo.loadPreferences();

    if (data.isNotEmpty) {
      final savedThemeMode = data['themeMode'] == 'dark' ? ThemeMode.dark : ThemeMode.light;
      final savedPresetName = data['themePreset'] as String?;

      final savedPreset = ThemePreset.values.firstWhere(
        (preset) => preset.name == savedPresetName,
        orElse: () => ThemePreset.royalPurple,
      );

      state = ThemeState(mode: savedThemeMode, preset: savedPreset);
    }
  }

  Future<void> _savePreferences() async {
    final data = <String, dynamic>{
      'themeMode': state.mode == ThemeMode.dark ? 'dark' : 'light',
      'themePreset': state.preset.name,
    };
    await _preferencesRepo.savePreferences(data);
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
