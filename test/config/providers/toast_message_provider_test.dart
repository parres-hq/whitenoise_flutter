import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/toast_message_provider.dart';
import 'package:whitenoise/config/states/toast_state.dart';

void main() {
  group('ToastMessageProvider Tests', () {
    group('showToast', () {
      late ProviderContainer container;
      late ToastMessageNotifier notifier;

      setUp(() {
        container = ProviderContainer();
        notifier = container.read(toastMessageProvider.notifier);
      });

      tearDown(() {
        container.dispose();
      });

      test('it has 3s default duration', () {
        notifier.showToast(message: 'You are awesome!', type: ToastType.success);
        final toastState = container.read(toastMessageProvider);
        expect(toastState.messages.first.durationMs, 3000);
      });

      group('with success type', () {
        group('when message is short', () {
          test('returns original message', () {
            notifier.showToast(message: 'You are awesome!', type: ToastType.success);
            final toastState = container.read(toastMessageProvider);
            expect(toastState.messages.first.message, 'You are awesome!');
          });

          group('with exception word', () {
            test('returns default success message', () {
              notifier.showToast(message: 'You are exceptional!', type: ToastType.success);
              final toastState = container.read(toastMessageProvider);
              expect(toastState.messages.first.message, 'Operation completed successfully.');
            });
          });
          group('with connection error related words', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'connection network timeout unreachable',
                type: ToastType.success,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'connection network timeout unreachable',
              );
            });
          });

          group('with authentication error related words', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'forbidden authentication invalid key login',
                type: ToastType.success,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'forbidden authentication invalid key login',
              );
            });
          });

          group('with parsing error related words', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'parse format invalid malformed',
                type: ToastType.success,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'parse format invalid malformed',
              );
            });
          });
          group('with database error related words', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'database storage failed to save failed to load',
                type: ToastType.success,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'database storage failed to save failed to load',
              );
            });
          });
          group('with server error related words', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'server internal error 500 503',
                type: ToastType.success,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'server internal error 500 503',
              );
            });
          });

          group('with at word', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'at ',
                type: ToastType.success,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'at ',
              );
            });
          });
        });
        group('when message is long', () {
          test('returns default success message', () {
            notifier.showToast(
              message:
                  'This is a very long message that exceeds the 80 character limit and should be replaced with default message',
              type: ToastType.success,
            );

            final toastState = container.read(toastMessageProvider);
            expect(toastState.messages.first.message, 'Operation completed successfully.');
          });
        });
      });

      group('with warning type', () {
        group('when message is short', () {
          test('returns original message', () {
            notifier.showToast(message: 'Warning! This is important!', type: ToastType.warning);
            final toastState = container.read(toastMessageProvider);
            expect(toastState.messages.first.message, 'Warning! This is important!');
          });

          group('with exception word', () {
            test('returns default warning message', () {
              notifier.showToast(message: 'Exceptional warning!', type: ToastType.warning);
              final toastState = container.read(toastMessageProvider);
              expect(toastState.messages.first.message, 'Warning: Please check your input.');
            });
          });
          group('with connection error related words', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'connection network timeout unreachable',
                type: ToastType.warning,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'connection network timeout unreachable',
              );
            });
          });

          group('with authentication error related words', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'forbidden authentication invalid key login',
                type: ToastType.warning,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'forbidden authentication invalid key login',
              );
            });
          });

          group('with parsing error related words', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'parse format invalid malformed',
                type: ToastType.warning,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'parse format invalid malformed',
              );
            });
          });
          group('with database error related words', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'database storage failed to save failed to load',
                type: ToastType.warning,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'database storage failed to save failed to load',
              );
            });
          });
          group('with server error related words', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'server internal error 500 503',
                type: ToastType.warning,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'server internal error 500 503',
              );
            });
          });

          group('with at word', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'Warning at whitenoise',
                type: ToastType.warning,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'Warning at whitenoise',
              );
            });
          });
        });
        group('when message is long', () {
          test('returns default warning message', () {
            notifier.showToast(
              message:
                  'This is a very long warning message that exceeds the 80 character limit and should be replaced with default message',
              type: ToastType.warning,
            );

            final toastState = container.read(toastMessageProvider);
            expect(toastState.messages.first.message, 'Warning: Please check your input.');
          });
        });
      });

      group('with info type', () {
        group('when message is short', () {
          test('returns original message', () {
            notifier.showToast(message: 'This is important info!', type: ToastType.info);
            final toastState = container.read(toastMessageProvider);
            expect(toastState.messages.first.message, 'This is important info!');
          });

          group('with exception word', () {
            test('returns default info message', () {
              notifier.showToast(message: 'This info is exceptional!', type: ToastType.info);
              final toastState = container.read(toastMessageProvider);
              expect(toastState.messages.first.message, 'Information updated.');
            });
          });
          group('with connection error related words', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'connection network timeout unreachable',
                type: ToastType.info,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'connection network timeout unreachable',
              );
            });
          });

          group('with authentication error related words', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'forbidden authentication invalid key login',
                type: ToastType.info,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'forbidden authentication invalid key login',
              );
            });
          });

          group('with parsing error related words', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'parse format invalid malformed',
                type: ToastType.info,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'parse format invalid malformed',
              );
            });
          });
          group('with database error related words', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'database storage failed to save failed to load',
                type: ToastType.info,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'database storage failed to save failed to load',
              );
            });
          });
          group('with server error related words', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'server internal error 500 503',
                type: ToastType.info,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'server internal error 500 503',
              );
            });
          });

          group('with at word', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'New info at whitenoise',
                type: ToastType.info,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'New info at whitenoise',
              );
            });
          });
        });
        group('when message is long', () {
          test('returns default info message', () {
            notifier.showToast(
              message:
                  'This is a very long info message that exceeds the 80 character limit and should be replaced with default message',
              type: ToastType.info,
            );

            final toastState = container.read(toastMessageProvider);
            expect(toastState.messages.first.message, 'Information updated.');
          });
        });
      });

      group('with error type', () {
        group('when message is short', () {
          test('returns original message', () {
            notifier.showToast(message: 'Error! This is critical!', type: ToastType.error);
            final toastState = container.read(toastMessageProvider);
            expect(toastState.messages.first.message, 'Error! This is critical!');
          });

          group('with exception word', () {
            test('returns default error message', () {
              notifier.showToast(message: 'Exceptional error!', type: ToastType.error);
              final toastState = container.read(toastMessageProvider);
              expect(toastState.messages.first.message, 'An error occurred. Please try again.');
            });
          });
          group('with connection error related words', () {
            test('returns connection error message', () {
              notifier.showToast(
                message: 'connection network timeout unreachable',
                type: ToastType.error,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'Connection failed. Please check your internet and try again.',
              );
            });
          });

          group('with authentication error related words', () {
            test('returns authentication error message', () {
              notifier.showToast(
                message: 'forbidden authentication invalid key login',
                type: ToastType.error,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'Authentication failed. Please check your credentials.',
              );
            });
          });

          group('with parsing error related words', () {
            test('returns parsing error message', () {
              notifier.showToast(
                message: 'parse format invalid malformed',
                type: ToastType.error,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'Invalid format. Please check your input and try again.',
              );
            });
          });
          group('with database error related words', () {
            test('returns original message', () {
              notifier.showToast(
                message: 'database storage failed to save failed to load',
                type: ToastType.error,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'Failed to save data. Please try again.',
              );
            });
          });
          group('with server error related words', () {
            test('returns server error message', () {
              notifier.showToast(
                message: 'server internal error 500 503',
                type: ToastType.error,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'Server error. Please try again later.',
              );
            });
          });

          group('with at word', () {
            test('returns unknown message', () {
              notifier.showToast(
                message: 'Opps something went wrong at whitenoise',
                type: ToastType.error,
              );
              final toastState = container.read(toastMessageProvider);
              expect(
                toastState.messages.first.message,
                'Something went wrong. Please try again.',
              );
            });
          });
        });
        group('when message is long', () {
          group('when error message is over 80 characters', () {
            test('returns default error message', () {
              notifier.showToast(
                message:
                    'This very long error message exceeds the 80 characters limit! Please check it again',
                type: ToastType.error,
              );

              final toastState = container.read(toastMessageProvider);
              expect(toastState.messages.first.message, 'An error occurred. Please try again.');
            });
          });

          group('when error message is over 100 characters', () {
            test('returns other default error message', () {
              notifier.showToast(
                message:
                    'This is a very long warning message that exceeds the 80 character limit and should be replaced with default message',
                type: ToastType.error,
              );

              final toastState = container.read(toastMessageProvider);
              expect(toastState.messages.first.message, 'Something went wrong. Please try again.');
            });
          });
        });
      });

      group('with auto dismiss', () {
        setUp(() {
          container = ProviderContainer();
          notifier = container.read(toastMessageProvider.notifier);
          notifier.setStackMode(ToastStackMode.stack);
          notifier.showToast(message: 'Not your keys, not your coins', type: ToastType.warning);
          notifier.showToast(message: 'Stay humble and stack sats', type: ToastType.info);
          notifier.showToast(
            message: 'Hodl!',
            type: ToastType.success,
            autoDismiss: true,
            durationMs: 1,
          );
        });

        tearDown(() {
          container.dispose();
        });

        test('dismisses the auto dismissable message', () async {
          await Future.delayed(const Duration(milliseconds: 1));
          final updatedState = container.read(toastMessageProvider);
          expect(
            updatedState.messages.where((msg) => msg.type == ToastType.success),
            isEmpty,
          );
        });

        test('does not dismiss other messages', () async {
          final toastState = container.read(toastMessageProvider);
          expect(toastState.messages.length, 3);
          await Future.delayed(const Duration(milliseconds: 1));
          final updatedState = container.read(toastMessageProvider);
          expect(updatedState.messages.length, 2);
        });
      });
    });

    group('showSuccess', () {
      late ProviderContainer container;
      late ToastMessageNotifier notifier;

      setUp(() {
        container = ProviderContainer();
        notifier = container.read(toastMessageProvider.notifier);
      });

      tearDown(() {
        container.dispose();
      });

      test('shows success toast message', () {
        notifier.showSuccess('Success!');
        final toastState = container.read(toastMessageProvider);
        expect(toastState.messages.first.type, ToastType.success);
      });

      group('with auto dismiss', () {
        test('dismisses message', () async {
          notifier.showSuccess('Success!', autoDismiss: true, durationMs: 1);
          final toastState = container.read(toastMessageProvider);
          expect(toastState.messages.length, 1);
          await Future.delayed(const Duration(milliseconds: 1));
          final updatedState = container.read(toastMessageProvider);
          expect(updatedState.messages.length, 0);
        });
      });
    });

    group('showWarning', () {
      late ProviderContainer container;
      late ToastMessageNotifier notifier;

      setUp(() {
        container = ProviderContainer();
        notifier = container.read(toastMessageProvider.notifier);
      });

      tearDown(() {
        container.dispose();
      });

      test('shows warning toast message', () {
        notifier.showWarning('Warning!');
        final toastState = container.read(toastMessageProvider);
        expect(toastState.messages.first.type, ToastType.warning);
      });

      group('with auto dismiss', () {
        test('dismisses message', () async {
          notifier.showWarning('Warning!', autoDismiss: true, durationMs: 1);
          final toastState = container.read(toastMessageProvider);
          expect(toastState.messages.length, 1);
          await Future.delayed(const Duration(milliseconds: 1));
          final updatedState = container.read(toastMessageProvider);
          expect(updatedState.messages.length, 0);
        });
      });
    });

    group('showInfo', () {
      late ProviderContainer container;
      late ToastMessageNotifier notifier;

      setUp(() {
        container = ProviderContainer();
        notifier = container.read(toastMessageProvider.notifier);
      });

      tearDown(() {
        container.dispose();
      });

      test('shows info toast message', () {
        notifier.showInfo('Info!');
        final toastState = container.read(toastMessageProvider);
        expect(toastState.messages.first.type, ToastType.info);
      });

      group('with auto dismiss', () {
        test('dismisses message', () async {
          notifier.showInfo('Info!', autoDismiss: true, durationMs: 1);
          final toastState = container.read(toastMessageProvider);
          expect(toastState.messages.length, 1);
          await Future.delayed(const Duration(milliseconds: 1));
          final updatedState = container.read(toastMessageProvider);
          expect(updatedState.messages.length, 0);
        });
      });
    });

    group('showError', () {
      late ProviderContainer container;
      late ToastMessageNotifier notifier;

      setUp(() {
        container = ProviderContainer();
        notifier = container.read(toastMessageProvider.notifier);
      });

      tearDown(() {
        container.dispose();
      });

      test('shows error toast message', () {
        notifier.showError('Error!');
        final toastState = container.read(toastMessageProvider);
        expect(toastState.messages.first.type, ToastType.error);
      });

      group('with auto dismiss', () {
        test('dismisses message', () async {
          notifier.showError('Error!', autoDismiss: true, durationMs: 1);
          final toastState = container.read(toastMessageProvider);
          expect(toastState.messages.length, 1);
          await Future.delayed(const Duration(milliseconds: 1));
          final updatedState = container.read(toastMessageProvider);
          expect(updatedState.messages.length, 0);
        });
      });
    });

    group('showRawToast', () {
      late ProviderContainer container;
      late ToastMessageNotifier notifier;

      setUp(() {
        container = ProviderContainer();
        notifier = container.read(toastMessageProvider.notifier);
      });

      tearDown(() {
        container.dispose();
      });

      test('shows raw message without sanitization', () {
        notifier.showRawToast(
          message: 'Exception: raw technical error message',
          type: ToastType.error,
        );
        final toastState = container.read(toastMessageProvider);
        expect(toastState.messages.first.message, 'Exception: raw technical error message');
      });

      test('shows correct toast type', () {
        notifier.showRawToast(message: 'Raw success', type: ToastType.success);
        final toastState = container.read(toastMessageProvider);
        expect(toastState.messages.first.type, ToastType.success);
      });

      group('with auto dismiss', () {
        setUp(() {
          notifier.setStackMode(ToastStackMode.stack);
          notifier.showRawToast(message: 'Not your keys, not your coins', type: ToastType.warning);
          notifier.showRawToast(message: 'Stay humble and stack sats', type: ToastType.info);
          notifier.showRawToast(
            message: 'Hodl!',
            type: ToastType.success,
            autoDismiss: true,
            durationMs: 1,
          );
        });
        test('dismisses the auto dismissable message', () async {
          await Future.delayed(const Duration(milliseconds: 1));
          final updatedState = container.read(toastMessageProvider);
          expect(
            updatedState.messages.where((msg) => msg.type == ToastType.success),
            isEmpty,
          );
        });

        test('does not dismiss other messages', () async {
          final toastState = container.read(toastMessageProvider);
          expect(toastState.messages.length, 3);
          await Future.delayed(const Duration(milliseconds: 1));
          final updatedState = container.read(toastMessageProvider);
          expect(updatedState.messages.length, 2);
        });
      });
    });

    group('dismissToast', () {
      late ProviderContainer container;
      late ToastMessageNotifier notifier;

      setUp(() {
        container = ProviderContainer();
        notifier = container.read(toastMessageProvider.notifier);
      });

      tearDown(() {
        container.dispose();
      });

      test('removes specific toast', () {
        notifier.showSuccess('Success!');
        final toastState = container.read(toastMessageProvider);
        expect(toastState.messages.first.message, 'Success!');
        final toastId = toastState.messages.first.id;

        notifier.dismissToast(toastId);
        final updatedState = container.read(toastMessageProvider);
        expect(updatedState.messages, isEmpty);
      });
    });

    group('dismissAll', () {
      late ProviderContainer container;
      late ToastMessageNotifier notifier;

      setUp(() {
        container = ProviderContainer();
        notifier = container.read(toastMessageProvider.notifier);
      });

      tearDown(() {
        container.dispose();
      });

      test('removes all toast messages', () {
        notifier.showSuccess('Success!');
        notifier.showError('Error!');

        notifier.dismissAll();
        final toastState = container.read(toastMessageProvider);
        expect(toastState.messages, isEmpty);
      });
    });
  });
}
