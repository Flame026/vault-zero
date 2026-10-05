import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/presentation/databases/widgets/database_form_dialog.dart';

void main() {
  group('DatabaseFormDialog Widget Tests', () {
    testWidgets('renders creation mode with prefix icons and submits data', (
      tester,
    ) async {
      Map<String, String>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DatabaseFormDialog.show(context);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Create Database'), findsOneWidget);
      expect(find.byIcon(Icons.storage_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notes_rounded), findsOneWidget);

      // Enter name and description
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Game Collection',
      );
      await tester.pumpAndSettle();

      // Clear button should be visible when name is not empty
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (Optional)'),
        'Favorite retro games',
      );
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!['name'], 'Game Collection');
      expect(result!['description'], 'Favorite retro games');
    });

    testWidgets('clear button clears name input and hides itself', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DatabaseFormDialog.show(
                  context,
                  initialDatabase: DatabaseDefinition(
                    id: 'd1',
                    name: 'Existing Db',
                    description: '',
                    fields: const [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Database'), findsOneWidget);
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      // Text should be empty and clear button should be gone
      expect(find.text('Existing Db'), findsNothing);
      expect(find.byIcon(Icons.clear_rounded), findsNothing);
    });
  });
}
