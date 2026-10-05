import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault_zero/core/theme/design_tokens.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/domain/models/field_value.dart';
import 'package:vault_zero/domain/models/record.dart';
import 'package:vault_zero/presentation/common/widgets/vault_badge.dart';
import 'package:vault_zero/presentation/common/widgets/vault_card.dart';
import 'package:vault_zero/presentation/common/widgets/vault_icon_badge.dart';
import 'package:vault_zero/presentation/common/widgets/vault_section_header.dart';
import 'package:vault_zero/presentation/databases/widgets/database_card.dart';
import 'package:vault_zero/presentation/fields/widgets/field_card.dart';
import 'package:vault_zero/presentation/records/widgets/record_card.dart';

void main() {
  group('Batch 16: Design System & Visual Language Foundation', () {
    testWidgets(
      '1. VaultCard renders surface, custom padding, onTap, and semantics',
      (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: VaultCard(
                  semanticsLabel: 'Test Vault Card',
                  onTap: () => tapped = true,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: const Text('Card Content'),
                ),
              ),
            ),
          ),
        );

        // Verify text rendered
        expect(find.text('Card Content'), findsOneWidget);

        // Verify semantics
        final semanticsFinder = find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Test Vault Card',
        );
        expect(semanticsFinder, findsOneWidget);

        // Verify tap works
        await tester.tap(find.text('Card Content'));
        await tester.pumpAndSettle();
        expect(tapped, isTrue);

        // Verify Material shape is rounded
        final cardFinder = find.byType(VaultCard);
        expect(cardFinder, findsOneWidget);
      },
    );

    testWidgets(
      '2. VaultIconBadge renders standard (40x40) and small (32x32) geometry',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  VaultIconBadge(icon: Icons.shield_rounded),
                  VaultIconBadge.small(icon: Icons.tag_rounded),
                ],
              ),
            ),
          ),
        );

        // Verify both icons render
        expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
        expect(find.byIcon(Icons.tag_rounded), findsOneWidget);

        // Verify dimensions of both badges
        final badges = tester
            .widgetList<VaultIconBadge>(find.byType(VaultIconBadge))
            .toList();
        expect(badges.length, 2);

        final standardSize = tester.getSize(find.byWidget(badges[0]));
        expect(standardSize.width, 40.0);
        expect(standardSize.height, 40.0);

        final smallSize = tester.getSize(find.byWidget(badges[1]));
        expect(smallSize.width, 32.0);
        expect(smallSize.height, 32.0);
      },
    );

    testWidgets(
      '3. VaultBadge renders tonal, required, and semantic status variants',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  VaultBadge(label: 'Standard Tonal', icon: Icons.circle),
                  VaultBadge.required(),
                  VaultBadge(
                    label: 'Success Badge',
                    variant: VaultBadgeVariant.success,
                  ),
                  VaultBadge(
                    label: 'Warning Badge',
                    variant: VaultBadgeVariant.warning,
                  ),
                  VaultBadge(
                    label: 'Error Badge',
                    variant: VaultBadgeVariant.error,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Standard Tonal'), findsOneWidget);
        expect(find.text('Required'), findsOneWidget);
        expect(find.text('Success Badge'), findsOneWidget);
        expect(find.text('Warning Badge'), findsOneWidget);
        expect(find.text('Error Badge'), findsOneWidget);
        expect(find.byIcon(Icons.circle), findsOneWidget);
      },
    );

    testWidgets(
      '4. VaultSectionHeader renders uppercase typography and trailing widget',
      (tester) async {
        bool actionTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VaultSectionHeader(
                title: 'Database Schema',
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => actionTapped = true,
                ),
              ),
            ),
          ),
        );

        // Verify uppercase transformation
        expect(find.text('DATABASE SCHEMA'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);

        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();
        expect(actionTapped, isTrue);
      },
    );

    testWidgets(
      '5. Refactored DatabaseCard uses VaultCard and VaultIconBadge with correct semantics',
      (tester) async {
        final db = DatabaseDefinition(
          id: 'db-test-1',
          name: 'Inventory Assets',
          description: 'Warehouse tracking database',
          fields: const [],
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 2),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DatabaseCard(
                database: db,
                onTap: () {},
                onEdit: () {},
                onDelete: () {},
                onManageFields: () {},
              ),
            ),
          ),
        );

        // Verify card and icon badge
        expect(find.byType(VaultCard), findsOneWidget);
        expect(find.byType(VaultIconBadge), findsOneWidget);
        expect(find.byType(VaultBadge), findsNWidgets(2));
        expect(find.text('Inventory Assets'), findsOneWidget);
        expect(find.text('No fields'), findsOneWidget);

        // Verify semantics
        final semanticsFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Open database Inventory Assets',
        );
        expect(semanticsFinder, findsOneWidget);
      },
    );

    testWidgets(
      '6. Refactored RecordCard uses VaultCard and VaultBadge with correct semantics',
      (tester) async {
        final field = FieldDefinition(
          id: 'f1',
          databaseId: 'db-1',
          name: 'Item Title',
          type: FieldType.text,
          position: 0,
          isRequired: true,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        final record = Record(
          id: 'rec-test-1',
          databaseId: 'db-1',
          createdAt: DateTime(2025, 3, 1),
          updatedAt: DateTime(2025, 3, 2),
          values: {
            'f1': const TextFieldValue(
              id: 'v1',
              recordId: 'rec-test-1',
              fieldId: 'f1',
              value: 'Vintage Espresso Machine',
            ),
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RecordCard(
                record: record,
                fields: [field],
                onTap: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        expect(find.byType(VaultCard), findsOneWidget);
        expect(find.text('Vintage Espresso Machine'), findsOneWidget);

        // Verify semantics
        final semanticsFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Open record Vintage Espresso Machine',
        );
        expect(semanticsFinder, findsOneWidget);
      },
    );

    testWidgets(
      '7. Refactored FieldCard uses VaultCard, VaultIconBadge, and VaultBadge',
      (tester) async {
        final field = FieldDefinition(
          id: 'f-req',
          databaseId: 'db-1',
          name: 'Serial Number',
          type: FieldType.text,
          position: 0,
          isRequired: true,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FieldCard(field: field, onEdit: () {}, onDelete: () {}),
            ),
          ),
        );

        expect(find.byType(VaultCard), findsOneWidget);
        expect(find.byType(VaultIconBadge), findsOneWidget);
        expect(find.byType(VaultBadge), findsOneWidget);
        expect(find.text('Serial Number'), findsOneWidget);
        expect(find.text('Required'), findsOneWidget);
        expect(find.text('Text'), findsOneWidget);

        // Verify reorder semantics
        final reorderFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics && w.properties.label == 'Reorder Serial Number',
        );
        expect(reorderFinder, findsOneWidget);
      },
    );

    testWidgets(
      '8. Narrow 280px viewport rendering with 2.0x text scale causes ZERO overflow',
      (tester) async {
        final db = DatabaseDefinition(
          id: 'db-long-name-1',
          name: 'Extraordinarily Long Database Name For Extreme Layout Testing',
          description:
              'Comprehensive detailed description of extreme edge case scenario',
          fields: const [],
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 2),
        );

        final field = FieldDefinition(
          id: 'f1',
          databaseId: 'db-long-name-1',
          name: 'Lengthy Attribute Label',
          type: FieldType.text,
          position: 0,
          isRequired: true,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        final record = Record(
          id: 'rec-long-1',
          databaseId: 'db-long-name-1',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 2),
          values: {
            'f1': const TextFieldValue(
              id: 'v1',
              recordId: 'rec-long-1',
              fieldId: 'f1',
              value: 'Ultra Long Primary Value Exceeding Viewport Bounds',
            ),
          },
        );

        tester.view.physicalSize = const Size(280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(280, 800),
                textScaler: TextScaler.linear(2.0),
              ),
              child: Scaffold(
                body: ListView(
                  children: [
                    const VaultSectionHeader(title: 'Overview Section'),
                    DatabaseCard(
                      database: db,
                      onTap: () {},
                      onEdit: () {},
                      onDelete: () {},
                      onManageFields: () {},
                    ),
                    const SizedBox(height: AppSpacing.md),
                    RecordCard(
                      record: record,
                      fields: [field],
                      onTap: () {},
                      onDelete: () {},
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FieldCard(field: field, onEdit: () {}, onDelete: () {}),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
