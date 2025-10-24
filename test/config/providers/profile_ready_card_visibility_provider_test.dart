import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/profile_ready_card_visibility_provider.dart';
import '../../shared/mocks/mock_active_pubkey_notifier.dart';

class _MockFailingSharedPreferences implements SharedPreferences {
  @override
  Future<bool> setBool(String key, bool value) async {
    throw Exception('Mock SharedPreferences error');
  }

  @override
  Future<bool> remove(String key) async {
    throw Exception('Mock SharedPreferences error');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('ProfileReadyCardVisibilityProvider Tests', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    late ProviderContainer container;
    late ProfileReadyCardVisibilityNotifier notifier;

    ProviderContainer createContainer({String? mockedPubkey}) {
      return ProviderContainer(
        overrides: [
          activePubkeyProvider.overrideWith(() => MockActivePubkeyNotifier(mockedPubkey)),
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

          group('when an error occurs', () {
            late SharedPreferences mockFailingPrefs;

            setUp(() async {
              mockFailingPrefs = _MockFailingSharedPreferences();
              container = ProviderContainer(
                overrides: [
                  profileReadyCardVisibilityProvider.overrideWith(
                    () => ProfileReadyCardVisibilityNotifier(sharedPreferences: mockFailingPrefs),
                  ),
                  activePubkeyProvider.overrideWith(
                    () => MockActivePubkeyNotifier('test_pubkey_123'),
                  ),
                ],
              );
              notifier = container.read(profileReadyCardVisibilityProvider.notifier);
              notifier.build();
              await Future.delayed(Duration.zero);
            });

            tearDown(() {
              container.dispose();
            });

            test('handles error gracefully, changing visibility', () async {
              expect(await container.read(profileReadyCardVisibilityProvider.future), true);
              await notifier.dismissCard();
              final result = await container.read(profileReadyCardVisibilityProvider.future);
              expect(result, false);
            });
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

          group('when an error occurs', () {
            late SharedPreferences mockFailingPrefs;

            setUp(() async {
              mockFailingPrefs = _MockFailingSharedPreferences();
              container = ProviderContainer(
                overrides: [
                  profileReadyCardVisibilityProvider.overrideWith(
                    () => ProfileReadyCardVisibilityNotifier(sharedPreferences: mockFailingPrefs),
                  ),
                  activePubkeyProvider.overrideWith(
                    () => MockActivePubkeyNotifier('test_pubkey_123'),
                  ),
                ],
              );
              notifier = container.read(profileReadyCardVisibilityProvider.notifier);
              notifier.build();
              await Future.delayed(Duration.zero);
            });

            tearDown(() {
              container.dispose();
            });

            test('handles error gracefully, maintaining visibility as true', () async {
              expect(await container.read(profileReadyCardVisibilityProvider.future), true);
              await notifier.resetVisibility();
              final result = await container.read(profileReadyCardVisibilityProvider.future);
              expect(result, true);
            });
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
