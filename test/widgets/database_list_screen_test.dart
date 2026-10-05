import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/presentation/databases/controllers/database_list_controller.dart';
import 'package:vault_zero/presentation/databases/database_list_screen.dart';

class MockDatabaseListController extends DatabaseListController {
  final List<DatabaseDefinition> databases;
  MockDatabaseListController(this.databases);

  @override
  Future<List<DatabaseDefinition>> build() async {
    return databases;
  }
}

void main() {
  group('DatabaseListScreen Responsive Layout Tests', () {
    testWidgets(
      'Empty state renders without overflow in phone landscape (800x360)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseListControllerProvider.overrideWith(
                () => MockDatabaseListController([]),
              ),
            ],
            child: const MaterialApp(home: DatabaseListScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Your Databases'), findsOneWidget);
        expect(find.text('Create Database'), findsOneWidget);
        // FloatingActionButton is omitted in empty state to prioritize the central action and save space
        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );

    testWidgets(
      'Empty state renders without overflow in short-height landscape (640x320)',
      (tester) async {
        tester.view.physicalSize = const Size(640, 320);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseListControllerProvider.overrideWith(
                () => MockDatabaseListController([]),
              ),
            ],
            child: const MaterialApp(home: DatabaseListScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Your Databases'), findsOneWidget);
        expect(find.text('Create Database'), findsOneWidget);
      },
    );

    testWidgets('Empty state renders correctly in portrait (400x800)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseListControllerProvider.overrideWith(
              () => MockDatabaseListController([]),
            ),
          ],
          child: const MaterialApp(home: DatabaseListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Your Databases'), findsOneWidget);
      expect(find.text('Create Database'), findsOneWidget);
    });

    testWidgets(
      'Populated databases render without overflow in landscape GridView (800x360)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final db = DatabaseDefinition(
          id: 'db1',
          name: 'Sample Database',
          description:
              'This is a multi-line database description intended to verify that responsive card heights fit properly.',
          fields: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseListControllerProvider.overrideWith(
                () => MockDatabaseListController([db]),
              ),
            ],
            child: const MaterialApp(home: DatabaseListScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Sample Database'), findsOneWidget);
        // FloatingActionButton is shown when databases are populated
        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );

    testWidgets(
      'Error state renders without overflow in phone landscape (800x360)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseListControllerProvider.overrideWith(
                () => ErrorDatabaseListController(),
              ),
            ],
            child: const MaterialApp(home: DatabaseListScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Failed to load databases'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      },
    );

    testWidgets('Database search filters databases and allows clearing', (
      tester,
    ) async {
      final db1 = DatabaseDefinition(
        id: 'db1',
        name: 'Books',
        description: 'Reading list',
        fields: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final db2 = DatabaseDefinition(
        id: 'db2',
        name: 'Movies',
        description: 'Films to watch',
        fields: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseListControllerProvider.overrideWith(
              () => MockDatabaseListController([db1, db2]),
            ),
          ],
          child: const MaterialApp(home: DatabaseListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Books'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);

      // Tap search icon
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(find.byType(TextField), 'movie');
      await tester.pumpAndSettle();

      expect(find.text('Books'), findsNothing);
      expect(find.text('Movies'), findsOneWidget);

      // Enter query with no match
      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pumpAndSettle();

      expect(find.text('No Databases Found'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);

      // Tap Clear Search
      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();

      expect(find.text('Books'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
    });
  });
}

class ErrorDatabaseListController extends DatabaseListController {
  @override
  Future<List<DatabaseDefinition>> build() async {
    throw Exception('Simulated database loading failure');
  }
}
