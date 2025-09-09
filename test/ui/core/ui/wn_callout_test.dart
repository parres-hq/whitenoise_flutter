import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/ui/core/ui/wn_callout.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

void main() {
  group('WnCallout Tests', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const ScreenUtilInit(
          designSize: Size(375, 812),
          child: MaterialApp(
            home: WnCallout(
              title: 'Test Title',
              description: 'Test Description',
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('renders description', (tester) async {
      await tester.pumpWidget(
        const ScreenUtilInit(
          designSize: Size(375, 812),
          child: MaterialApp(
            home: WnCallout(
              title: 'Test Title',
              description: 'Test Description',
            ),
          ),
        ),
      );
      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('displays information icon', (tester) async {
      await tester.pumpWidget(
        const ScreenUtilInit(
          designSize: Size(375, 812),
          child: MaterialApp(
            home: WnCallout(
              title: 'Title',
              description: 'Description',
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is WnImage &&
              widget.src.contains('assets/svgs/ic_information.svg'),
        ),
        findsOneWidget,
      );
    });
  });
}
