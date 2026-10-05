import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/presentation/common/widgets/vault_destructive_dialog.dart';
import 'package:vault_zero/presentation/databases/widgets/delete_confirmation_dialog.dart';
import 'package:vault_zero/presentation/fields/widgets/delete_field_dialog.dart';
import 'package:vault_zero/presentation/records/widgets/delete_record_dialog.dart';

void main() {
  group('Delete Dialogs Widget Tests', () {
    testWidgets(
      'DeleteConfirmationDialog renders database name and confirms deletion',
      (tester) async {
        bool? confirmed;
        final testDb = DatabaseDefinition(
          id: 'db-1',
          name: 'Movies Catalog',
          description: 'Test database',
          fields: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    confirmed = await DeleteConfirmationDialog.show(
                      context,
                      database: testDb,
                    );
                  },
                  child: const Text('Delete DB'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete DB'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Database?'), findsOneWidget);
        expect(find.textContaining('Movies Catalog'), findsOneWidget);
        expect(find.text('Delete Permanently'), findsOneWidget);

        await tester.tap(find.text('Delete Permanently'));
        await tester.pumpAndSettle();

        expect(confirmed, isTrue);
      },
    );

    testWidgets('DeleteFieldDialog renders field name and cancels deletion', (
      tester,
    ) async {
      bool? confirmed;
      final testField = FieldDefinition(
        id: 'f-1',
        databaseId: 'db-1',
        name: 'Rating',
        type: FieldType.decimal,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  confirmed = await DeleteFieldDialog.show(
                    context,
                    field: testField,
                  );
                },
                child: const Text('Delete Field'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete Field'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Field?'), findsOneWidget);
      expect(find.textContaining('Rating'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(confirmed, isFalse);
    });

    testWidgets(
      'VaultDestructiveDialog renders custom title and content directly',
      (tester) async {
        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await VaultDestructiveDialog.show(
                      context,
                      title: 'Purge Cache?',
                      content: const Text(
                        'All temporary caches will be purged.',
                      ),
                      confirmText: 'Purge',
                    );
                  },
                  child: const Text('Open Purge Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Purge Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Purge Cache?'), findsOneWidget);
        expect(
          find.text('All temporary caches will be purged.'),
          findsOneWidget,
        );
        expect(find.text('Purge'), findsOneWidget);

        await tester.tap(find.text('Purge'));
        await tester.pumpAndSettle();

        expect(result, isTrue);
      },
    );
    testWidgets('DeleteRecordDialog displays record title and warning banner', (
      tester,
    ) async {
      bool? confirmed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  confirmed = await DeleteRecordDialog.show(
                    context,
                    recordTitle: 'Vintage Camera',
                  );
                },
                child: const Text('Delete Item'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete Item'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Record?'), findsOneWidget);
      expect(find.textContaining('Vintage Camera'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });

    testWidgets(
      'DeleteRecordDialog falls back gracefully without recordTitle',
      (tester) async {
        bool? confirmed;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    confirmed = await DeleteRecordDialog.show(context);
                  },
                  child: const Text('Delete Item'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete Item'));
        await tester.pumpAndSettle();

        expect(find.textContaining('this record'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(confirmed, isFalse);
      },
    );

    testWidgets(
      'DeleteRecordDialog renders without overflow in short landscape (800x320) (stripes regression test)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 320);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => DeleteRecordDialog.show(
                    context,
                    recordTitle: 'A very long record title that wraps',
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Delete Record?'), findsOneWidget);
      },
    );
  });
}
