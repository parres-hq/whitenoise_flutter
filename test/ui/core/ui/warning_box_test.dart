import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/ui/warning_box.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

import '../../../test_helpers.dart';

void main() {
  group('WarningBox Tests', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const WarningBox(
            title: 'Test Title',
            description: 'Test Description',
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('renders description', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const WarningBox(
            title: 'Test Title',
            description: 'Test Description',
          ),
        ),
      );

      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('displays default warning icon when iconPath is not provided', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const WarningBox(
            title: 'Title',
            description: 'Description',
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is WnImage &&
              widget.src == AssetsPaths.icWarning,
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays custom icon when iconPath is provided', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const WarningBox(
            title: 'Title',
            description: 'Description',
            iconPath: AssetsPaths.icInfoFilled,
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is WnImage &&
              widget.src == AssetsPaths.icInfoFilled,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows border when showBorder is true', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const WarningBox(
            title: 'Title',
            description: 'Description',
          ),
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(WarningBox),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isNotNull);
    });

    testWidgets('hides border when showBorder is false', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const WarningBox(
            title: 'Title',
            description: 'Description',
            showBorder: false,
          ),
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(WarningBox),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isNull);
    });

    testWidgets('uses custom backgroundColor when provided', (tester) async {
      const customColor = Color(0xFF123456);

      await tester.pumpWidget(
        createTestWidget(
          const WarningBox(
            title: 'Title',
            description: 'Description',
            backgroundColor: customColor,
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(WarningBox),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, customColor);
    });

    testWidgets('uses custom borderColor when provided', (tester) async {
      const customColor = Color(0xFF654321);

      await tester.pumpWidget(
        createTestWidget(
          const WarningBox(
            title: 'Title',
            description: 'Description',
            borderColor: customColor,
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(WarningBox),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration?;
      final border = decoration?.border as Border?;
      expect(border?.top.color, customColor);
    });

    testWidgets('uses custom iconColor when provided', (tester) async {
      const customColor = Color(0xFFABCDEF);

      await tester.pumpWidget(
        createTestWidget(
          const WarningBox(
            title: 'Title',
            description: 'Description',
            iconColor: customColor,
          ),
        ),
      );

      final iconFinder = find.byWidgetPredicate(
        (widget) => widget is WnImage,
      );

      expect(iconFinder, findsOneWidget);

      final icon = tester.widget<WnImage>(iconFinder);
      expect(icon.color, customColor);
    });

    testWidgets('uses custom titleColor when provided', (tester) async {
      const customColor = Color(0xFFFEDCBA);

      await tester.pumpWidget(
        createTestWidget(
          const WarningBox(
            title: 'Title',
            description: 'Description',
            titleColor: customColor,
          ),
        ),
      );

      final titleFinder = find.text('Title');
      expect(titleFinder, findsOneWidget);

      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.color, customColor);
    });

    testWidgets('uses custom descriptionColor when provided', (tester) async {
      const customColor = Color(0xFF987654);

      await tester.pumpWidget(
        createTestWidget(
          const WarningBox(
            title: 'Title',
            description: 'Description',
            descriptionColor: customColor,
          ),
        ),
      );

      final descriptionFinder = find.text('Description');
      expect(descriptionFinder, findsOneWidget);

      final descriptionWidget = tester.widget<Text>(descriptionFinder);
      expect(descriptionWidget.style?.color, customColor);
    });
  });
}

