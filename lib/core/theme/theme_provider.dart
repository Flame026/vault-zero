import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/preferences_repository.dart';
import 'theme_preset.dart';

class ThemeState {
  final ThemeMode mode;
  final ThemePreset preset;
  final bool isLoaded;

  const ThemeState({
    required this.mode,
    required this.preset,
    this.isLoaded = false,
  });

  ThemeState copyWith({ThemeMode? mode, ThemePreset? preset, bool? isLoaded}) {
    return ThemeState(
      mode: mode ?? this.mode,
      preset: preset ?? this.preset,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          preset == other.preset &&
          isLoaded == other.isLoaded;

  @override
  int get hashCode => Object.hash(mode, preset, isLoaded);
}

class ThemeController extends Notifier<ThemeState> {
  late final PreferencesRepository _preferencesRepo;
  bool _userMutated = false;

  @override
  ThemeState build() {
    _preferencesRepo = ref.watch(preferencesRepositoryProvider);
    _userMutated = false;
    // Asynchronous load triggers state update later
    _loadPreferences();
    return const ThemeState(
      mode: ThemeMode.system,
      preset: ThemePreset.royalPurple,
      isLoaded: false,
    );
  }

  Future<void> _loadPreferences() async {
    try {
      final data = await _preferencesRepo.loadPreferences();

      // If user has already changed theme before load completed, don't overwrite!
      if (_userMutated) return;

      if (data.isNotEmpty) {
        final savedModeStr = data['themeMode'];
        final savedThemeMode = switch (savedModeStr) {
          'dark' => ThemeMode.dark,
          'light' => ThemeMode.light,
          'system' => ThemeMode.system,
          _ => ThemeMode.system,
        };
        final savedPresetName = data['themePreset'];

        final savedPreset = ThemePreset.values.firstWhere(
          (preset) => preset.name == savedPresetName,
          orElse: () => ThemePreset.royalPurple,
        );

        state = ThemeState(
          mode: savedThemeMode,
          preset: savedPreset,
          isLoaded: true,
        );
      } else {
        state = state.copyWith(isLoaded: true);
      }
    } catch (_) {
      // Safe fallback on preference read failure
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> _savePreferences() async {
    try {
      final modeStr = switch (state.mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
      };
      final data = <String, dynamic>{
        'themeMode': modeStr,
        'themePreset': state.preset.name,
      };
      await _preferencesRepo.savePreferences(data);
    } catch (_) {
      // Errors in preference saving are non-fatal to active UI state
    }
  }

  Future<void> changeMode(ThemeMode mode) async {
    _userMutated = true;
    state = state.copyWith(mode: mode);
    await _savePreferences();
  }

  Future<void> changePreset(ThemePreset preset) async {
    _userMutated = true;
    state = state.copyWith(preset: preset);
    await _savePreferences();
  }
}

final themeProvider = NotifierProvider<ThemeController, ThemeState>(() {
  return ThemeController();
});
