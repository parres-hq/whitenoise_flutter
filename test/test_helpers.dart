import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/toast_message_provider.dart';
import 'package:whitenoise/config/states/toast_state.dart';

/// Mock toast provider that doesn't create timers during tests
class MockToastNotifier extends ToastMessageNotifier {
  @override
  void showRawToast({
    required String message,
    required ToastType type,
    int? durationMs,
    bool? autoDismiss,
    bool? showBelowAppBar,
  }) {
  }
}

/// Mocks clipboard for tests
Map<String, dynamic> setupClipboardMock(WidgetTester tester) {
  final clipboardData = <String, dynamic>{};
  
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.setData') {
        clipboardData['text'] = methodCall.arguments['text'];
      }
      return null;
    },
  );
  
  return clipboardData;
}

/// Creates test widget with common providers overridden
Widget createTestWidget(
  Widget child, {
  List<Override>? additionalOverrides
}) {
  final overrides = [
    toastMessageProvider.overrideWith(() => MockToastNotifier()),
    if (additionalOverrides != null) ...additionalOverrides,
  ];

  return ProviderScope(
    overrides: overrides,
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: child),
      ),
    ),
  );
}
