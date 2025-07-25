import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/toast_message_provider.dart';
import 'package:whitenoise/config/states/toast_state.dart';
import 'package:whitenoise/utils/clipboard_utils.dart';

/// Mock implementation of WidgetRef for testing
class _MockWidgetRef implements WidgetRef {
  final ProviderContainer _container;
  _MockWidgetRef(this._container);

  @override
  T read<T>(ProviderListenable<T> provider) => _container.read(provider);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('ClipboardUtils Tests', () {
    late ProviderContainer container;
    late _MockWidgetRef mockRef;
    late List<MethodCall> clipboardCalls;

    setUp(() {
      container = ProviderContainer();
      mockRef = _MockWidgetRef(container);
      clipboardCalls = [];
      
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        clipboardCalls.add(methodCall);
        return null;
      });
    });

    tearDown(() {
      container.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    void verifyClipboardCall(String expectedText) {
      expect(clipboardCalls.length, 1);
      expect(clipboardCalls.first.method, 'Clipboard.setData');
      expect(clipboardCalls.first.arguments['text'], expectedText);
    }

    void verifyToastMessage(String expectedMessage) {
      final toastState = container.read(toastMessageProvider);
      expect(toastState.messages.length, 1);
      expect(toastState.messages.first.message, expectedMessage);
      expect(toastState.messages.first.type, ToastType.success);
      expect(toastState.messages.first.autoDismiss, true);
    }

    group('copyWithToast', () {
      test('copies text to clipboard and shows default toast', () {
        const testText = 'Hello, World!';

        ClipboardUtils.copyWithToast(ref: mockRef, textToCopy: testText);

        verifyClipboardCall(testText);
        verifyToastMessage('Copied to clipboard');
      });

      test('copies text to clipboard and shows custom toast message', () {
        const testText = 'Custom text to copy';
        const customMessage = 'Custom copied message';

        ClipboardUtils.copyWithToast(
          ref: mockRef,
          textToCopy: testText,
          message: customMessage,
        );

        verifyClipboardCall(testText);
        verifyToastMessage(customMessage);
      });
    });
  });
}
