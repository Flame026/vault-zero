import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'presentation/databases/database_list_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Vault Zero',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.mode,
      theme: themeState.preset.buildTheme(Brightness.light),
      darkTheme: themeState.preset.buildTheme(Brightness.dark),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _showSplash
            ? const VaultZeroSplashScreen(key: ValueKey('vault-zero-splash'))
            : const DatabaseListScreen(key: ValueKey('vault-zero-home')),
      ),
    );
  }
}

class VaultZeroSplashScreen extends StatelessWidget {
  const VaultZeroSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
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
