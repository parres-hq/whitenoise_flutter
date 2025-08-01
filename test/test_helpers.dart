import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/providers/toast_message_provider.dart';
import 'package:whitenoise/config/states/toast_state.dart';

/// Mock toast notifier for tests that disables auto-dismiss to prevent timer issues
class MockToastMessageNotifier extends ToastMessageNotifier {
  @override
  void showToast({
    required String message,
    required ToastType type,
    int? durationMs,
    bool? autoDismiss,
    bool? showBelowAppBar,
  }) {
    // Force auto-dismiss to false to prevent timers in tests
    super.showToast(
      message: message,
      type: type,
      durationMs: durationMs,
      autoDismiss: false, // Always disable auto-dismiss in tests
      showBelowAppBar: showBelowAppBar,
    );
  }

  @override
  void showRawToast({
    required String message,
    required ToastType type,
    int? durationMs,
    bool? autoDismiss,
    bool? showBelowAppBar,
  }) {
    // Force auto-dismiss to false to prevent timers in tests
    super.showRawToast(
      message: message,
      type: type,
      durationMs: durationMs,
      autoDismiss: false, // Always disable auto-dismiss in tests
      showBelowAppBar: showBelowAppBar,
    );
  }
}

Widget createTestWidget(Widget child, {List<Override>? overrides}) {
  final defaultOverrides = [
    toastMessageProvider.overrideWith(() => MockToastMessageNotifier()),
  ];

  return ProviderScope(
    overrides: [...defaultOverrides, ...(overrides ?? [])],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder:
          (context, _) => MaterialApp(
            home: Scaffold(body: child),
          ),
    ),
  );
}
