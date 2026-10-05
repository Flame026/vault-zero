import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vault_zero/presentation/settings/settings_screen.dart';

void main() {
  testWidgets(
    'SettingsScreen displays Appearance, Data Safety & Backup, and Import sections',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SettingsScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsWidgets);
      expect(find.text('Theme Color'), findsOneWidget);
      expect(find.text('Theme Mode'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      expect(find.text('DATA SAFETY & BACKUP'), findsWidgets);
      expect(find.text('Backup Vault'), findsOneWidget);
      expect(find.text('Restore Vault'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('IMPORT DATA'), 200);
      await tester.pumpAndSettle();

      expect(find.text('IMPORT DATA'), findsWidgets);
      expect(find.text('Import CSV'), findsOneWidget);
      expect(find.text('Import Excel'), findsOneWidget);

      // Verify about / version footer by scrolling to it
      await tester.scrollUntilVisible(find.text('Vault Zero'), 200);
      await tester.pumpAndSettle();

      expect(find.text('Vault Zero'), findsOneWidget);
      expect(find.text('Version 1.0.0 • Offline & Private'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'SettingsScreen allows switching theme mode between System, Light, and Dark',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SettingsScreen())),
      );
      await tester.pumpAndSettle();

      // Tap Dark mode segment
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(find.text('Dark appearance'), findsOneWidget);

      // Tap Light mode segment
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(find.text('Light appearance'), findsOneWidget);

      // Tap System mode segment
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();
      expect(find.text('System (Follows device setting)'), findsOneWidget);
    },
  );

  testWidgets('SettingsScreen renders master-detail on wide screens (>= 900)', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('CATEGORIES'), findsOneWidget);
    expect(find.text('Appearance'), findsWidgets);
    expect(find.text('Data Management'), findsOneWidget);

    // Tap Data Management category
    await tester.tap(find.text('Data Management'));
    await tester.pumpAndSettle();

    expect(find.text('DATA SAFETY & BACKUP'), findsOneWidget);
    expect(find.text('IMPORT DATA'), findsOneWidget);
    expect(find.text('Backup Vault'), findsOneWidget);
    expect(find.text('Restore Vault'), findsOneWidget);
  });

  testWidgets(
    'SettingsScreen renders without overflow in short phone landscape (800x360)',
    (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SettingsScreen())),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Settings'), findsOneWidget);
    },
  );
}
