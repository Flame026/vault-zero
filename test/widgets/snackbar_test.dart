import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault_zero/presentation/common/widgets/vault_snackbar.dart';

void main() {
  testWidgets('Floating SnackBar renders with icon and text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Export Complete!'),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.text('Export Complete!'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets(
    'VaultSnackbar helper displays success, error, and info snackbars',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => VaultSnackbar.showSuccess(
                      context,
                      'Saved successfully!',
                    ),
                    child: const Text('Show Success'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        VaultSnackbar.showError(context, 'Failed to save!'),
                    child: const Text('Show Error'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        VaultSnackbar.showInfo(context, 'Info update!'),
                    child: const Text('Show Info'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Test Show Success
      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();
      expect(find.text('Saved successfully!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);

      // Test Show Error
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();
      expect(find.text('Failed to save!'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      // Test Show Info
      await tester.tap(find.text('Show Info'));
      await tester.pumpAndSettle();
      expect(find.text('Info update!'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    },
  );
}
