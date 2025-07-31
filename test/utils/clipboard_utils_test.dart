import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/toast_message_provider.dart';
import 'package:whitenoise/config/states/toast_state.dart';
import 'package:whitenoise/utils/clipboard_utils.dart';

class _MockWidgetRef implements WidgetRef {
  final ProviderContainer _container;
  _MockWidgetRef(this._container);

  @override
  T read<T>(ProviderListenable<T> provider) => _container.read(provider);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('ClipboardUtils', () {
    late ProviderContainer container;
    late _MockWidgetRef mockRef;

    setUp(() {
      container = ProviderContainer();
      mockRef = _MockWidgetRef(container);
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    tearDown(() {
      container.dispose();
    });

    group('copyWithToast', () {
      test('shows toast message', () async {
        await ClipboardUtils.copyWithToast(ref: mockRef, textToCopy: 'Hello, World!');
        final toastState = container.read(toastMessageProvider);
        expect(toastState.messages.length, 1);
      });

      test('shows success toast message', () async {
        await ClipboardUtils.copyWithToast(ref: mockRef, textToCopy: 'Hello, World!');
        final toastState = container.read(toastMessageProvider);
        final toastMessage = toastState.messages.first;
        expect(toastMessage.type, ToastType.success);
      });

      test('shows auto dismissable toast message', () async {
        await ClipboardUtils.copyWithToast(ref: mockRef, textToCopy: 'Hello, World!');
        final toastState = container.read(toastMessageProvider);
        final toastMessage = toastState.messages.first;
        expect(toastMessage.autoDismiss, true);
      });

      test('shows default success message', () async {
        await ClipboardUtils.copyWithToast(ref: mockRef, textToCopy: 'Hello, World!');
        final toastState = container.read(toastMessageProvider);
        final toastMessage = toastState.messages.first;
        expect(toastMessage.message, 'Copied to clipboard');
      });

      group('with custom success message', () {
        test('shows default success message', () async {
          await ClipboardUtils.copyWithToast(
            ref: mockRef,
            textToCopy: 'Hello, World!',
            successMessage: 'woop woop!',
          );

          final toastState = container.read(toastMessageProvider);
          final toastMessage = toastState.messages.first;
          expect(toastMessage.message, 'woop woop!');
        });
      });

      group('with empty text to copy', () {
        test('shows toast message', () async {
          await ClipboardUtils.copyWithToast(ref: mockRef, textToCopy: '');
          final toastState = container.read(toastMessageProvider);
          expect(toastState.messages.length, 1);
        });

        test('shows error toast message', () async {
          await ClipboardUtils.copyWithToast(ref: mockRef, textToCopy: '');
          final toastState = container.read(toastMessageProvider);
          final toastMessage = toastState.messages.first;
          expect(toastMessage.type, ToastType.error);
        });

        test('shows auto dismissable toast message', () async {
          await ClipboardUtils.copyWithToast(ref: mockRef, textToCopy: '');
          final toastState = container.read(toastMessageProvider);
          final toastMessage = toastState.messages.first;
          expect(toastMessage.autoDismiss, true);
        });

        test('shows default no text message', () async {
          await ClipboardUtils.copyWithToast(ref: mockRef, textToCopy: '');
          final toastState = container.read(toastMessageProvider);
          final toastMessage = toastState.messages.first;
          expect(toastMessage.message, 'Nothing to copy');
        });

        group('with custom no text message', () {
          test('shows custom no text message', () async {
            await ClipboardUtils.copyWithToast(
              ref: mockRef,
              textToCopy: '',
              noTextMessage: 'Oops! This looks empty',
            );
            final toastState = container.read(toastMessageProvider);
            final toastMessage = toastState.messages.first;
            expect(
              toastMessage.message,
              'Oops! This looks empty',
            );
          });
        });
      });

      group('with null text to copy', () {
        test('shows toast message', () async {
          await ClipboardUtils.copyWithToast(ref: mockRef);
          final toastState = container.read(toastMessageProvider);
          expect(toastState.messages.length, 1);
        });

        test('shows error toast message', () async {
          await ClipboardUtils.copyWithToast(ref: mockRef);
          final toastState = container.read(toastMessageProvider);
          final toastMessage = toastState.messages.first;
          expect(toastMessage.type, ToastType.error);
        });

        test('shows auto dismissable toast message', () async {
          await ClipboardUtils.copyWithToast(ref: mockRef);
          final toastState = container.read(toastMessageProvider);
          final toastMessage = toastState.messages.first;
          expect(toastMessage.autoDismiss, true);
        });

        test('shows default no text message', () async {
          await ClipboardUtils.copyWithToast(ref: mockRef);
          final toastState = container.read(toastMessageProvider);
          final toastMessage = toastState.messages.first;
          expect(toastMessage.message, 'Nothing to copy');
        });

        group('with custom no text message', () {
          test('shows custom no text message', () async {
            await ClipboardUtils.copyWithToast(
              ref: mockRef,
              noTextMessage: 'Oops! This looks null',
            );
            final toastState = container.read(toastMessageProvider);
            final toastMessage = toastState.messages.first;
            expect(
              toastMessage.message,
              'Oops! This looks null',
            );
          });
        });
      });

      group('when a clipboard error occurs', () {
        setUp(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, (call) async {
                if (call.method == 'Clipboard.setData') {
                  throw PlatformException(code: 'clipboard_error', message: 'Failed to copy');
                }
                return null;
              });
        });

        tearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        test('shows error toast message', () async {
          await ClipboardUtils.copyWithToast(ref: mockRef, textToCopy: 'Hello, World!');
          final toastState = container.read(toastMessageProvider);
          final toastMessage = toastState.messages.first;
          expect(toastMessage.type, ToastType.error);
        });

        test('shows auto dismissable error toast message', () async {
          await ClipboardUtils.copyWithToast(ref: mockRef, textToCopy: 'Hello, World!');
          final toastState = container.read(toastMessageProvider);
          final toastMessage = toastState.messages.first;
          expect(toastMessage.autoDismiss, true);
        });

        test('shows default error message', () async {
          await ClipboardUtils.copyWithToast(ref: mockRef, textToCopy: 'Hello, World!');
          final toastState = container.read(toastMessageProvider);
          final toastMessage = toastState.messages.first;
          expect(toastMessage.message, 'Failed to copy to clipboard');
        });

        group('with custom error message', () {
          test('shows custom error message', () async {
            await ClipboardUtils.copyWithToast(
              ref: mockRef,
              textToCopy: 'Hello, World!',
              errorMessage: 'Oops! Clipboard is broken',
            );
            final toastState = container.read(toastMessageProvider);
            final toastMessage = toastState.messages.first;
            expect(toastMessage.message, 'Oops! Clipboard is broken');
          });
        });
      });
    });
  });
}
