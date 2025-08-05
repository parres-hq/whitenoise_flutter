import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/profile_ready_card_visibility_provider.dart';

class MockActiveAccountNotifier extends ActiveAccountNotifier {
  final String? _mockValue;

  MockActiveAccountNotifier(this._mockValue);

  @override
  String? build() => _mockValue;
}

void main() {
  group('ProfileReadyCardVisibilityProvider Tests', () {
    late ProviderContainer container;
    late ProfileReadyCardVisibilityNotifier notifier;

    ProviderContainer createContainer({String? mockedPubkey}) {
      return ProviderContainer(
        overrides: [
          activeAccountProvider.overrideWith(() => MockActiveAccountNotifier(mockedPubkey)),
        ],
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      container.dispose();
    });

    group('initial state', () {
      group('when there is no active account', () {
        test('returns true', () async {
          container = createContainer();
          final result = await container.read(profileReadyCardVisibilityProvider.future);
          expect(result, true);
        });
      });

      group('with active account', () {
        group('when it has not been dismissed', () {
          test('returns true', () async {
            SharedPreferences.setMockInitialValues({
              'profile_ready_card_dismissed_test_pubkey_345': true,
            });
            container = createContainer(mockedPubkey: 'test_pubkey_123');
            final result = await container.read(profileReadyCardVisibilityProvider.future);
            expect(result, true);
          });
        });

        group('when it has been dismissed', () {
          test('returns false', () async {
            SharedPreferences.setMockInitialValues({
              'profile_ready_card_dismissed_test_pubkey_123': true,
            });

            container = createContainer(mockedPubkey: 'test_pubkey_123');
            final result = await container.read(profileReadyCardVisibilityProvider.future);
            expect(result, false);
          });
        });
      });
    });

    group('dismissCard', () {
      group('when there is no active account', () {
        test('dismiss returns false', () async {
          container = createContainer();
          notifier = container.read(profileReadyCardVisibilityProvider.notifier);

          await notifier.dismissCard();
          final result = await container.read(profileReadyCardVisibilityProvider.future);
          expect(result, false);
        });
      });

      group('with active account', () {
        group('when it has not been dismissed', () {
          setUp(() async {
            container = createContainer(mockedPubkey: 'test_pubkey_123');
            await container.read(profileReadyCardVisibilityProvider.future);
            notifier = container.read(profileReadyCardVisibilityProvider.notifier);
          });
          test('dismiss returns false', () async {
            await notifier.dismissCard();
            final result = await container.read(profileReadyCardVisibilityProvider.future);
            expect(result, false);
          });

          test('updates shared preferences', () async {
            await notifier.dismissCard();
            final prefs = await SharedPreferences.getInstance();
            final isDismissed = prefs.getBool('profile_ready_card_dismissed_test_pubkey_123');
            expect(isDismissed, true);
          });

          test('notifies listeners', () async {
            container = createContainer(mockedPubkey: 'test_pubkey_123');
            notifier = container.read(profileReadyCardVisibilityProvider.notifier);
            bool hasNotified = false;
            container.listen(profileReadyCardVisibilityProvider, (previous, next) {
              hasNotified = true;
            });

            await notifier.dismissCard();
            expect(hasNotified, true);
          });
        });

        group('when it has been dismissed', () {
          setUp(() async {
            SharedPreferences.setMockInitialValues({
              'profile_ready_card_dismissed_test_pubkey_123': true,
            });
            container = createContainer(mockedPubkey: 'test_pubkey_123');
            await container.read(profileReadyCardVisibilityProvider.future);
            notifier = container.read(profileReadyCardVisibilityProvider.notifier);
          });
          test('dismiss returns false', () async {
            await notifier.dismissCard();
            final result = await container.read(profileReadyCardVisibilityProvider.future);
            expect(result, false);
          });

          test('updates shared preferences', () async {
            await notifier.dismissCard();

            final prefs = await SharedPreferences.getInstance();
            final isDismissed = prefs.getBool('profile_ready_card_dismissed_test_pubkey_123');
            expect(isDismissed, true);
          });

          test('notifies listeners', () async {
            bool hasNotified = false;
            container.listen(profileReadyCardVisibilityProvider, (previous, next) {
              hasNotified = true;
            });

            await notifier.dismissCard();
            expect(hasNotified, true);
          });
        });
      });
    });

    group('resetVisibility', () {
      group('when there is no active account', () {
        test('reset returns true', () async {
          container = createContainer();
          notifier = container.read(profileReadyCardVisibilityProvider.notifier);

          await notifier.resetVisibility();
          final result = await container.read(profileReadyCardVisibilityProvider.future);
          expect(result, true);
        });
      });

      group('with active account', () {
        group('when it has not been dismissed', () {
          setUp(() async {
            container = createContainer(mockedPubkey: 'test_pubkey_123');
            await container.read(profileReadyCardVisibilityProvider.future);
            notifier = container.read(profileReadyCardVisibilityProvider.notifier);
          });
          test('reset returns true', () async {
            await notifier.resetVisibility();
            final result = await container.read(profileReadyCardVisibilityProvider.future);
            expect(result, true);
          });

          test('removes pubkey from shared preferences', () async {
            await notifier.resetVisibility();
            final prefs = await SharedPreferences.getInstance();
            final isDismissed = prefs.getBool('profile_ready_card_dismissed_test_pubkey_123');
            expect(isDismissed, null);
          });

          test('notifies listeners', () async {
            bool hasNotified = false;
            container.listen(profileReadyCardVisibilityProvider, (previous, next) {
              hasNotified = true;
            });

            await notifier.resetVisibility();
            expect(hasNotified, true);
          });
        });

        group('when it has been dismissed', () {
          setUp(() async {
            SharedPreferences.setMockInitialValues({
              'profile_ready_card_dismissed_test_pubkey_123': true,
            });
            container = createContainer(mockedPubkey: 'test_pubkey_123');
            await container.read(profileReadyCardVisibilityProvider.future);
            notifier = container.read(profileReadyCardVisibilityProvider.notifier);
          });
          test('reset returns true', () async {
            await notifier.resetVisibility();
            final result = await container.read(profileReadyCardVisibilityProvider.future);
            expect(result, true);
          });

          test('removes pubkey from shared preferences', () async {
            await notifier.resetVisibility();
            final prefs = await SharedPreferences.getInstance();
            final isDismissed = prefs.getBool('profile_ready_card_dismissed_test_pubkey_123');
            expect(isDismissed, null);
          });

          test('notifies listeners', () async {
            bool hasNotified = false;
            container.listen(profileReadyCardVisibilityProvider, (previous, next) {
              hasNotified = true;
            });

            await notifier.resetVisibility();
            expect(hasNotified, true);
          });
        });
      });
    });
  });
}
