import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:character_collector/core/preferences/preferences_repository.dart';
import 'package:character_collector/core/theme/theme_preset.dart';
import 'package:character_collector/core/theme/theme_provider.dart';

// Note: To run path_provider in unit tests without a mock platform, 
// we typically need to mock it or use an integration test. 
// For this quick test, we will create a mock PreferencesRepository to verify ThemeController logic.

class MockPreferencesRepository implements PreferencesRepository {
  Map<String, dynamic> fakeStorage = {};

  @override
  Future<Map<String, dynamic>> loadPreferences() async {
    return fakeStorage;
  }

  @override
  Future<void> savePreferences(Map<String, dynamic> data) async {
    fakeStorage.addAll(data);
  }
}

void main() {
  test('ThemeController initializes with default values when empty', () {
    final mockRepo = MockPreferencesRepository();
    final container = ProviderContainer(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    final state = container.read(themeProvider);
    expect(state.mode, ThemeMode.light);
    expect(state.preset, ThemePreset.royalPurple);
  });

  test('ThemeController loads existing values', () async {
    final mockRepo = MockPreferencesRepository();
    mockRepo.fakeStorage = {
      'themeMode': 'dark',
      'themePreset': 'emeraldGreen',
    };

    final container = ProviderContainer(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    // Initial read sets up the provider
    container.read(themeProvider);
    
    // Allow the async microtask in build() to complete
    await Future.delayed(Duration.zero);

    final state = container.read(themeProvider);
    expect(state.mode, ThemeMode.dark);
    expect(state.preset, ThemePreset.emeraldGreen);
  });

  test('ThemeController saves changes', () async {
    final mockRepo = MockPreferencesRepository();
    final container = ProviderContainer(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    final controller = container.read(themeProvider.notifier);
    
    controller.changeMode(ThemeMode.dark);
    controller.changePreset(ThemePreset.sunsetOrange);

    // Allow microtasks to complete
    await Future.delayed(Duration.zero);

    expect(mockRepo.fakeStorage['themeMode'], 'dark');
    expect(mockRepo.fakeStorage['themePreset'], 'sunsetOrange');
  });
}
