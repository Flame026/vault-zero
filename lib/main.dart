import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_provider.dart';
import 'core/preferences/preferences_repository.dart';
import 'core/storage/temp_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'presentation/databases/controllers/database_list_controller.dart';
import 'presentation/databases/database_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: VaultZeroApp()));
}

class VaultZeroApp extends ConsumerStatefulWidget {
  const VaultZeroApp({super.key});

  @override
  ConsumerState<VaultZeroApp> createState() => _VaultZeroAppState();
}

class _VaultZeroAppState extends ConsumerState<VaultZeroApp>
    with WidgetsBindingObserver {
  static const Duration _splashDuration = Duration(milliseconds: 1200);

  bool _showSplash = true;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Startup Optimization: Pre-warm database and schema providers concurrently
    // during the splash animation so that the home screen loads instantaneously.
    _prewarmServices();

    _splashTimer = Timer(_splashDuration, () {
      _dismissSplash();
    });
  }

  void _prewarmServices() {
    // Non-blocking background warmup and temp storage cleanup
    unawaited(() async {
      try {
        await ref.read(databaseProvider.future);
        await ref.read(databaseListControllerProvider.future);
        await ref.read(tempStorageServiceProvider).pruneStaleExportFiles();
      } catch (_) {
        // Errors will be caught and displayed by the presentation layer
      }
    }());
  }

  void _dismissSplash() {
    if (!mounted || !_showSplash) return;
    _splashTimer?.cancel();
    _splashTimer = null;
    setState(() {
      _showSplash = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-synchronize overlay styles and ensure theme responds to any platform changes
      if (mounted) {
        setState(() {});
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Ensure pending preference writes are flushed and clean up any temp files
      unawaited(() async {
        try {
          await ref.read(preferencesRepositoryProvider).flush();
          await ref.read(tempStorageServiceProvider).pruneStaleExportFiles();
        } catch (_) {}
      }());
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _splashTimer?.cancel();
    _splashTimer = null;
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
      themeAnimationDuration: const Duration(milliseconds: 250),
      themeAnimationCurve: Curves.easeInOutCubic,
      home: Builder(
        builder: (context) {
          final isDark = switch (themeState.mode) {
            ThemeMode.dark => true,
            ThemeMode.light => false,
            ThemeMode.system =>
              MediaQuery.platformBrightnessOf(context) == Brightness.dark,
          };
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _showSplash
                  ? VaultZeroSplashScreen(
                      key: const ValueKey('vault-zero-splash'),
                      onDismiss: _dismissSplash,
                    )
                  : const DatabaseListScreen(key: ValueKey('vault-zero-home')),
            ),
          );
        },
      ),
    );
  }
}

class VaultZeroSplashScreen extends StatelessWidget {
  final VoidCallback? onDismiss;

  const VaultZeroSplashScreen({super.key, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SizedBox.expand(
          child: Image.asset(
            'assets/branding/vault_zero_splash.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
