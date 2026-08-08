import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme_provider.dart';
import 'legacy/presentation/screens/character_entry_screen.dart';

void main() {
  runApp(const ProviderScope(child: VaultZeroApp()));
}

class VaultZeroApp extends ConsumerStatefulWidget {
  const VaultZeroApp({super.key});

  @override
  ConsumerState<VaultZeroApp> createState() => _VaultZeroAppState();
}

class _VaultZeroAppState extends ConsumerState<VaultZeroApp> {
  static const Duration _splashDuration = Duration(milliseconds: 1200);

  bool _showSplash = true;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
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
      isDark ? const Color(0xFF121016) : const Color(0xFFFBF9FE),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Vault Zero',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.mode,
      theme: _buildTheme(
        brightness: Brightness.light,
        seedColor: themeState.preset.seedColor,
      ),
      darkTheme: _buildTheme(
        brightness: Brightness.dark,
        seedColor: themeState.preset.seedColor,
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _showSplash
            ? const VaultZeroSplashScreen(key: ValueKey('vault-zero-splash'))
            : const CharacterEntryScreen(key: ValueKey('vault-zero-home')),
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
