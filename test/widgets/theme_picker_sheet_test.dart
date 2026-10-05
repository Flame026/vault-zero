import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vault_zero/core/theme/theme_preset.dart';
import 'package:vault_zero/core/theme/theme_provider.dart';
import 'package:vault_zero/presentation/settings/widgets/theme_picker_sheet.dart';

void main() {
  testWidgets('ThemePickerSheet renders presets and marks active preset', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ThemePickerSheet(isDialog: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Theme Color'), findsOneWidget);
    expect(find.text('Royal Purple'), findsOneWidget);
    expect(find.text('Ocean Blue'), findsOneWidget);
    expect(find.text('Emerald Green'), findsOneWidget);

    // Initial preset is Royal Purple, which should have ACTIVE badge
    expect(find.text('ACTIVE'), findsOneWidget);

    // Tap Ocean Blue
    await tester.tap(find.text('Ocean Blue'));
    await tester.pumpAndSettle();

    // Ocean Blue now active
    expect(find.text('ACTIVE'), findsOneWidget);
    final context = tester.element(find.byType(ThemePickerSheet));
    final container = ProviderScope.containerOf(context);
    expect(container.read(themeProvider).preset, ThemePreset.oceanBlue);
  });

  testWidgets('ThemePickerSheet renders in bottom sheet mode without error', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ThemePickerSheet(isDialog: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Theme Color'), findsOneWidget);
    expect(find.text('Choose an appearance for Vault Zero'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets(
    'ThemePickerSheet renders without overflow at narrow 320px width and 2.0x text scale (stripes regression test)',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: const Scaffold(body: ThemePickerSheet(isDialog: false)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Theme Color'), findsOneWidget);
    },
  );
}
