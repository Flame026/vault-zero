import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'screens/character_entry_screen.dart';

void main() {
  runApp(const VaultZeroApp());
}

class VaultZeroApp extends StatefulWidget {
  const VaultZeroApp({super.key});

  @override
  State<VaultZeroApp> createState() => _VaultZeroAppState();
}

class _VaultZeroAppState extends State<VaultZeroApp> {
  static const String _preferencesFileName =
      'vault_zero_preferences.json';

  static const String _legacyPreferencesFileName =
      'character_collector_preferences.json';

  static const Duration _splashDuration = Duration(milliseconds: 1200);

  ThemeMode _themeMode = ThemeMode.light;
  ThemePreset _themePreset = ThemePreset.royalPurple;
  bool _showSplash = true;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _loadPreferences();

    _splashTimer = Timer(_splashDuration, () {
      if (!mounted) return;

      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  Future<File> _getPreferencesFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();

    return File('${directory.path}/$fileName');
  }

  Future<void> _loadPreferences() async {
    try {
      final currentFile = await _getPreferencesFile(_preferencesFileName);
      final legacyFile = await _getPreferencesFile(
        _legacyPreferencesFileName,
      );

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

      final savedThemeMode = data['themeMode'] == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light;

      final savedPresetName = data['themePreset'] as String?;

      final savedPreset = ThemePreset.values.firstWhere(
        (preset) => preset.name == savedPresetName,
        orElse: () => ThemePreset.royalPurple,
      );

      if (!mounted) return;

      setState(() {
        _themeMode = savedThemeMode;
        _themePreset = savedPreset;
      });

      if (sourceFile.path == legacyFile.path) {
        await _savePreferences();
      }
    } catch (_) {
      // Keep the default theme if the preferences file cannot be read.
    }
  }

  Future<void> _savePreferences() async {
    try {
      final file = await _getPreferencesFile(_preferencesFileName);

      final data = <String, String>{
        'themeMode': _themeMode == ThemeMode.dark ? 'dark' : 'light',
        'themePreset': _themePreset.name,
      };

      await file.writeAsString(
        jsonEncode(data),
        flush: true,
      );
    } catch (_) {
      // Theme changes still work for the current session.
    }
  }

  void _changeThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });

    _savePreferences();
  }

  void _changeThemePreset(ThemePreset themePreset) {
    setState(() {
      _themePreset = themePreset;
    });

    _savePreferences();
  }

  ThemeData _buildTheme({
    required Brightness brightness,
    required Color seedColor,
  }) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    final scaffoldColor = Color.alphaBlend(
      seedColor.withAlpha(isDark ? 18 : 9),
      isDark
          ? const Color(0xFF121016)
          : const Color(0xFFFBF9FE),
    );

    return ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldColor,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: scaffoldColor,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vault Zero',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(
        brightness: Brightness.light,
        seedColor: _themePreset.seedColor,
      ),
      darkTheme: _buildTheme(
        brightness: Brightness.dark,
        seedColor: _themePreset.seedColor,
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _showSplash
            ? const VaultZeroSplashScreen(
                key: ValueKey('vault-zero-splash'),
              )
            : CharacterEntryScreen(
                key: const ValueKey('vault-zero-home'),
                themeMode: _themeMode,
                selectedThemePreset: _themePreset,
                onThemeModeChanged: _changeThemeMode,
                onThemePresetChanged: _changeThemePreset,
              ),
      ),
    );
  }
}

class VaultZeroSplashScreen extends StatelessWidget {
  const VaultZeroSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0B1019),
      child: SizedBox.expand(
        child: Image.asset(
          'assets/branding/vault_zero_splash.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
