import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Creates test widget with common providers overridden
Widget createTestWidget(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder:
          (context, _) => MaterialApp(
            home: Scaffold(body: child),
          ),
    ),
  );
}
