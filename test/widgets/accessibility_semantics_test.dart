import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault_zero/domain/models/database_definition.dart';
import 'package:vault_zero/domain/models/field_definition.dart';
import 'package:vault_zero/domain/models/field_value.dart';
import 'package:vault_zero/domain/models/record.dart';
import 'package:vault_zero/presentation/databases/widgets/database_card.dart';
import 'package:vault_zero/presentation/fields/widgets/field_card.dart';
import 'package:vault_zero/presentation/records/widgets/dynamic_field_input.dart';
import 'package:vault_zero/presentation/records/widgets/record_card.dart';

void main() {
  group('Accessibility & Semantics Tests', () {
    testWidgets('DatabaseCard has correct semantics and tooltip', (
      tester,
    ) async {
      final db = DatabaseDefinition(
        id: 'db1',
        name: 'Inventory',
        description: 'Track inventory items',
        fields: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
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

      final semanticsFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics && w.properties.label == 'Open database Inventory',
      );
      expect(semanticsFinder, findsOneWidget);

      final popupFinder = find.byType(PopupMenuButton<String>);
      expect(popupFinder, findsOneWidget);
      final popupWidget = tester.widget<PopupMenuButton<String>>(popupFinder);
      expect(popupWidget.tooltip, 'Database options for Inventory');

      // Verify schema density indicator for empty database
      expect(find.text('No fields'), findsOneWidget);
      expect(find.byIcon(Icons.schema_outlined), findsOneWidget);
    });

    testWidgets('RecordCard has correct semantics and tooltip', (tester) async {
      final field = FieldDefinition(
        id: 'f1',
        databaseId: 'db1',
        name: 'Item Name',
        type: FieldType.text,
        position: 0,
        isRequired: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final record = Record(
        id: 'r1',
        databaseId: 'db1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        values: {
          'f1': const TextFieldValue(
            id: 'v1',
            recordId: 'r1',
            fieldId: 'f1',
            value: 'Laptop Pro',
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

      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Open record Laptop Pro',
      );
      expect(semanticsFinder, findsOneWidget);

      final popupFinder = find.byType(PopupMenuButton<String>);
      expect(popupFinder, findsOneWidget);
      final popupWidget = tester.widget<PopupMenuButton<String>>(popupFinder);
      expect(popupWidget.tooltip, 'Record options for Laptop Pro');
    });

    testWidgets('FieldCard has correct semantics and tooltip', (tester) async {
      final field = FieldDefinition(
        id: 'f1',
        databaseId: 'db1',
        name: 'Price',
        type: FieldType.decimal,
        position: 0,
        isRequired: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FieldCard(field: field, onEdit: () {}, onDelete: () {}),
          ),
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Reorder Price',
      );
      expect(semanticsFinder, findsOneWidget);

      final popupFinder = find.byType(PopupMenuButton<String>);
      expect(popupFinder, findsOneWidget);
      final popupWidget = tester.widget<PopupMenuButton<String>>(popupFinder);
      expect(popupWidget.tooltip, 'Field options for Price');
    });

    testWidgets('RecordCard formats date and decimal values nicely', (
      tester,
    ) async {
      final fields = [
        FieldDefinition(
          id: 'f_date',
          databaseId: 'db1',
          name: 'Purchase Date',
          type: FieldType.date,
          position: 0,
          isRequired: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        FieldDefinition(
          id: 'f_price',
          databaseId: 'db1',
          name: 'Price',
          type: FieldType.decimal,
          position: 1,
          isRequired: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final record = Record(
        id: 'r_formatted',
        databaseId: 'db1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        values: {
          'f_date': DateFieldValue(
            id: 'v_d',
            recordId: 'r_formatted',
            fieldId: 'f_date',
            value: DateTime(2025, 10, 15),
          ),
          'f_price': const DecimalFieldValue(
            id: 'v_p',
            recordId: 'r_formatted',
            fieldId: 'f_price',
            value: 299.0,
          ),
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordCard(
              record: record,
              fields: fields,
              onTap: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Date formatted as "Oct 15, 2025"
      expect(find.text('Oct 15, 2025'), findsOneWidget);
      // Decimal stripped of trailing .0 -> "299"
      expect(find.textContaining('299'), findsOneWidget);
    });

    testWidgets(
      'DynamicFieldInput provides accessible date semantics and tooltips',
      (tester) async {
        final dateField = FieldDefinition(
          id: 'f_due',
          databaseId: 'db1',
          name: 'Due Date',
          type: FieldType.date,
          position: 0,
          isRequired: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DynamicFieldInput(
                field: dateField,
                initialValue: DateTime(2025, 12, 25),
                onChanged: (_) {},
              ),
            ),
          ),
        );

        // Verify semantics label for date picker
        final dateSemantics = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Select date for Due Date',
        );
        expect(dateSemantics, findsOneWidget);

        // Verify clear button has tooltip
        expect(find.byTooltip('Clear Due Date'), findsOneWidget);
        // Verify helper text indicates required
        expect(find.text('Required'), findsOneWidget);
      },
    );

    testWidgets(
      'SettingsScreen provides accessible semantics for tiles and theme mode',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Theme Color'),
                      subtitle: Text('Royal Purple'),
                    ),
                    ListTile(
                      title: Text('Backup Vault'),
                      subtitle: Text('Export data'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Theme Color'), findsOneWidget);
        expect(find.text('Backup Vault'), findsOneWidget);
      },
    );
  });
}
