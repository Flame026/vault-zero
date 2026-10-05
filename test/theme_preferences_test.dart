import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vault_zero/core/preferences/preferences_repository.dart';
import 'package:vault_zero/core/theme/theme_preset.dart';
import 'package:vault_zero/core/theme/theme_provider.dart';

// Note: To run path_provider in unit tests without a mock platform,
// we typically need to mock it or use an integration test.
// For this quick test, we will create a mock PreferencesRepository to verify ThemeController logic.

class MockPreferencesRepository implements PreferencesRepository {
  Map<String, dynamic> fakeStorage = {};

  @override
  Future<Directory> Function()? get getDocsDir => null;

  @override
  Future<Map<String, dynamic>> loadPreferences() async {
    return fakeStorage;
  }

  @override
  Future<void> savePreferences(Map<String, dynamic> data) async {
    fakeStorage.addAll(data);
  }

  @override
  Future<void> flush() async {}

  @override
  Future<String?> getString(String key) async {
    final value = fakeStorage[key];
    return value is String ? value : null;
  }

  @override
  Future<void> setString(String key, String value) async {
    fakeStorage[key] = value;
  }
}

void main() {
  test('ThemeController initializes with default values when empty', () {
    final mockRepo = MockPreferencesRepository();
    final container = ProviderContainer(
      overrides: [preferencesRepositoryProvider.overrideWithValue(mockRepo)],
    );

    final state = container.read(themeProvider);
    expect(state.mode, ThemeMode.system);
    expect(state.preset, ThemePreset.royalPurple);
  });

  test('ThemeController loads existing values (dark mode)', () async {
    final mockRepo = MockPreferencesRepository();
    mockRepo.fakeStorage = {'themeMode': 'dark', 'themePreset': 'emeraldGreen'};

    final container = ProviderContainer(
      overrides: [preferencesRepositoryProvider.overrideWithValue(mockRepo)],
    );

    container.read(themeProvider);
    await Future.delayed(Duration.zero);

    final state = container.read(themeProvider);
    expect(state.mode, ThemeMode.dark);
    expect(state.preset, ThemePreset.emeraldGreen);
  });

  test('ThemeController loads existing values (light mode)', () async {
    final mockRepo = MockPreferencesRepository();
    mockRepo.fakeStorage = {'themeMode': 'light', 'themePreset': 'oceanBlue'};

    final container = ProviderContainer(
      overrides: [preferencesRepositoryProvider.overrideWithValue(mockRepo)],
    );

    container.read(themeProvider);
    await Future.delayed(Duration.zero);

    final state = container.read(themeProvider);
    expect(state.mode, ThemeMode.light);
    expect(state.preset, ThemePreset.oceanBlue);
  });

  test('ThemeController loads existing values (system mode)', () async {
    final mockRepo = MockPreferencesRepository();
    mockRepo.fakeStorage = {
      'themeMode': 'system',
      'themePreset': 'sunsetOrange',
    };

    final container = ProviderContainer(
      overrides: [preferencesRepositoryProvider.overrideWithValue(mockRepo)],
    );

    container.read(themeProvider);
    await Future.delayed(Duration.zero);

    final state = container.read(themeProvider);
    expect(state.mode, ThemeMode.system);
    expect(state.preset, ThemePreset.sunsetOrange);
  });

  test(
    'ThemeController safely falls back on corrupted or missing values',
    () async {
      final mockRepo = MockPreferencesRepository();
      mockRepo.fakeStorage = {
        'themeMode': 'invalid_mode_name',
        'themePreset': 'non_existent_preset',
      };

      final container = ProviderContainer(
        overrides: [preferencesRepositoryProvider.overrideWithValue(mockRepo)],
      );

      container.read(themeProvider);
      await Future.delayed(Duration.zero);

      final state = container.read(themeProvider);
      expect(state.mode, ThemeMode.system);
      expect(state.preset, ThemePreset.royalPurple);
    },
  );

  test('ThemeController saves mode and preset changes', () async {
    final mockRepo = MockPreferencesRepository();
    final container = ProviderContainer(
      overrides: [preferencesRepositoryProvider.overrideWithValue(mockRepo)],
    );

    final controller = container.read(themeProvider.notifier);

    controller.changeMode(ThemeMode.dark);
    controller.changePreset(ThemePreset.sunsetOrange);

    await Future.delayed(Duration.zero);

    expect(mockRepo.fakeStorage['themeMode'], 'dark');
    expect(mockRepo.fakeStorage['themePreset'], 'sunsetOrange');

    controller.changeMode(ThemeMode.system);
    await Future.delayed(Duration.zero);
    expect(mockRepo.fakeStorage['themeMode'], 'system');
  });
}
