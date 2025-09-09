import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';

import 'active_pubkey_provider_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage, PubkeyFormatter])
void main() {
  group('ActivePubkeyProvider Tests', () {
    late ProviderContainer container;
    late MockFlutterSecureStorage mockStorage;
    final testNpubPubkey = 'npub1zygjyg3nxdzyg424ven8waug3zvejqqq424thw7venwammhwlllsj2q4yf';
    final testHexPubkey = '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff';
    final otherTestNpubPubkey = 'npub140x77qfrg4ncnlkuh2v8v4pjzz4ummcpydzk0z07mjafsaj5xggq9d4zqy';
    final otherTestHexPubkey = 'abcdef0123456789fedcba9876543210abcdef0123456789fedcba9876543210';

    final hexPubkeysMap = {
      testNpubPubkey: testHexPubkey,
      otherTestNpubPubkey: otherTestHexPubkey,
      testHexPubkey: testHexPubkey,
      otherTestHexPubkey: otherTestHexPubkey,
      '': '',
      ' test_pubkey_123 ': 'test_pubkey_123',
    };

    PubkeyFormatter Function({String? pubkey}) mockPubkeyFormatter() {
      return ({String? pubkey}) {
        final mock = MockPubkeyFormatter();
        when(mock.toHex()).thenReturn(hexPubkeysMap[pubkey]);
        return mock;
      };
    }

    ProviderContainer createContainer({
      MockFlutterSecureStorage? storage,
    }) {
      return ProviderContainer(
        overrides: [
          activePubkeyProvider.overrideWith(
            () => ActivePubkeyNotifier(
              storage: storage ?? mockStorage,
              pubkeyFormatter: mockPubkeyFormatter(),
            ),
          ),
        ],
      );
    }

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      container = createContainer(storage: mockStorage);
    });

    tearDown(() {
      container.dispose();
    });

    test('starts with null state', () {
      when(mockStorage.read(key: 'active_account_pubkey')).thenAnswer((_) async => null);

      final state = container.read(activePubkeyProvider);
      expect(state, isNull);
    });

    test('notifier is accessible', () {
      final notifier = container.read(activePubkeyProvider.notifier);
      expect(notifier, isA<ActivePubkeyNotifier>());
    });

    group('loadActivePubkey', () {
      group('when storage is null', () {
        setUp(() async {
          when(mockStorage.read(key: 'active_account_pubkey')).thenAnswer((_) async => null);
        });

        test('sets state to empty string', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          await notifier.loadActivePubkey();
          final state = container.read(activePubkeyProvider);
          expect(state, isNull);
        });

        test('does not notify to listeners', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          bool wasNotified = false;

          container.listen(activePubkeyProvider, (previous, next) {
            wasNotified = true;
          });

          await notifier.loadActivePubkey();
          expect(wasNotified, isFalse);
        });
      });

      group('when storage has empty string', () {
        setUp(() async {
          when(mockStorage.read(key: 'active_account_pubkey')).thenAnswer((_) async => '');
        });

        test('sets state to empty string', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          await notifier.loadActivePubkey();
          final state = container.read(activePubkeyProvider);
          expect(state, '');
        });

        test('notifies to listeners', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          bool wasNotified = false;

          container.listen(activePubkeyProvider, (previous, next) {
            wasNotified = true;
          });

          await notifier.loadActivePubkey();
          expect(wasNotified, isTrue);
        });
      });

      group('when storage has a pubkey string in bech32 format', () {
        setUp(() async {
          when(
            mockStorage.read(key: 'active_account_pubkey'),
          ).thenAnswer(
            (_) async => testNpubPubkey,
          );
        });

        test('sets state to the pubkey string in hex format', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          await notifier.loadActivePubkey();
          final state = container.read(activePubkeyProvider);
          expect(state, testHexPubkey);
        });

        test('notifies to listeners', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          bool wasNotified = false;

          container.listen(activePubkeyProvider, (previous, next) {
            wasNotified = true;
          });

          await notifier.loadActivePubkey();
          expect(wasNotified, isTrue);
        });
      });

      group('when storage has a pubkey string with whitespaces', () {
        setUp(() async {
          when(
            mockStorage.read(key: 'active_account_pubkey'),
          ).thenAnswer((_) async => ' test_pubkey_123 ');
        });

        test('sets state to the pubkey string without whitespaces', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          await notifier.loadActivePubkey();
          final state = container.read(activePubkeyProvider);
          expect(state, 'test_pubkey_123');
        });

        test('notifies to listeners', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          bool wasNotified = false;

          container.listen(activePubkeyProvider, (previous, next) {
            wasNotified = true;
          });

          await notifier.loadActivePubkey();
          expect(wasNotified, isTrue);
        });
      });
    });

    group('setActivePubkey', () {
      group('when state is null', () {
        setUp(() async {
          when(
            mockStorage.write(key: 'active_account_pubkey', value: testHexPubkey),
          ).thenAnswer((_) async {});
        });
        group('when pubkey is in npub format', () {
          test('updates state', () async {
            final notifier = container.read(activePubkeyProvider.notifier);
            await notifier.setActivePubkey(testNpubPubkey);
            final state = container.read(activePubkeyProvider);
            expect(state, testHexPubkey);
          });

          test('notifies to listeners', () async {
            final notifier = container.read(activePubkeyProvider.notifier);
            bool wasNotified = false;

            container.listen(activePubkeyProvider, (previous, next) {
              wasNotified = true;
            });

            await notifier.setActivePubkey(testNpubPubkey);
            expect(wasNotified, isTrue);
          });
        });

        group('when pubkey is in hex format', () {
          test('updates state', () async {
            final notifier = container.read(activePubkeyProvider.notifier);
            await notifier.setActivePubkey(testHexPubkey);
            final state = container.read(activePubkeyProvider);
            expect(state, testHexPubkey);
          });

          test('notifies to listeners', () async {
            final notifier = container.read(activePubkeyProvider.notifier);
            bool wasNotified = false;

            container.listen(activePubkeyProvider, (previous, next) {
              wasNotified = true;
            });

            await notifier.setActivePubkey(testHexPubkey);
            expect(wasNotified, isTrue);
          });
        });
      });

      group('when state is empty string', () {
        setUp(() async {
          when(mockStorage.write(key: 'active_account_pubkey', value: '')).thenAnswer((_) async {});
          await container.read(activePubkeyProvider.notifier).setActivePubkey('');
          when(
            mockStorage.write(key: 'active_account_pubkey', value: testHexPubkey),
          ).thenAnswer((_) async {});
        });

        group('when pubkey is in npub format', () {
          test('updates state', () async {
            final notifier = container.read(activePubkeyProvider.notifier);
            expect(container.read(activePubkeyProvider), '');
            await notifier.setActivePubkey(testNpubPubkey);
            expect(container.read(activePubkeyProvider), testHexPubkey);
          });

          test('notifies to listeners', () async {
            final notifier = container.read(activePubkeyProvider.notifier);
            bool wasNotified = false;

            container.listen(activePubkeyProvider, (previous, next) {
              wasNotified = true;
            });

            await notifier.setActivePubkey(testNpubPubkey);
            expect(wasNotified, isTrue);
          });
        });
        group('when pubkey is in hex format', () {
          test('updates state', () async {
            final notifier = container.read(activePubkeyProvider.notifier);
            expect(container.read(activePubkeyProvider), '');
            await notifier.setActivePubkey(testHexPubkey);
            expect(container.read(activePubkeyProvider), testHexPubkey);
          });

          test('notifies to listeners', () async {
            final notifier = container.read(activePubkeyProvider.notifier);
            bool wasNotified = false;

            container.listen(activePubkeyProvider, (previous, next) {
              wasNotified = true;
            });

            await notifier.setActivePubkey(testHexPubkey);
            expect(wasNotified, isTrue);
          });
        });
      });

      group('when state is a valid pubkey', () {
        setUp(() async {
          when(
            mockStorage.write(key: 'active_account_pubkey', value: testHexPubkey),
          ).thenAnswer((_) async {});
          await container.read(activePubkeyProvider.notifier).setActivePubkey(testHexPubkey);
          when(
            mockStorage.write(key: 'active_account_pubkey', value: otherTestHexPubkey),
          ).thenAnswer((_) async {});
        });

        group('when new pubkey is in npub format', () {
          test('updates state', () async {
            final notifier = container.read(activePubkeyProvider.notifier);
            expect(container.read(activePubkeyProvider), testHexPubkey);
            await notifier.setActivePubkey(otherTestNpubPubkey);
            expect(container.read(activePubkeyProvider), otherTestHexPubkey);
          });

          test('notifies to listeners', () async {
            final notifier = container.read(activePubkeyProvider.notifier);
            bool wasNotified = false;

            container.listen(activePubkeyProvider, (previous, next) {
              wasNotified = true;
            });

            await notifier.setActivePubkey(otherTestNpubPubkey);
            expect(wasNotified, isTrue);
          });
        });

        group('when new pubkey is in hex format', () {
          test('updates state', () async {
            final notifier = container.read(activePubkeyProvider.notifier);
            expect(container.read(activePubkeyProvider), testHexPubkey);
            await notifier.setActivePubkey(otherTestHexPubkey);
            expect(container.read(activePubkeyProvider), otherTestHexPubkey);
          });

          test('notifies to listeners', () async {
            final notifier = container.read(activePubkeyProvider.notifier);
            bool wasNotified = false;

            container.listen(activePubkeyProvider, (previous, next) {
              wasNotified = true;
            });

            await notifier.setActivePubkey(otherTestHexPubkey);
            expect(wasNotified, isTrue);
          });
        });
      });
    });

    group('clearActivePubkey', () {
      group('when storage is null', () {
        setUp(() async {
          when(mockStorage.delete(key: 'active_account_pubkey')).thenAnswer((_) async {});
        });
        test('updates state to empty string', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          await notifier.clearActivePubkey();
          final state = container.read(activePubkeyProvider);
          expect(state, isNull);
        });

        test('does not notify to listeners', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          bool wasNotified = false;

          container.listen(activePubkeyProvider, (previous, next) {
            wasNotified = true;
          });

          await notifier.clearActivePubkey();
          expect(wasNotified, false);
        });
      });

      group('when storage has empty string', () {
        setUp(() async {
          when(mockStorage.write(key: 'active_account_pubkey', value: '')).thenAnswer((_) async {});
          await container.read(activePubkeyProvider.notifier).setActivePubkey('');
          when(mockStorage.delete(key: 'active_account_pubkey')).thenAnswer((_) async {});
        });

        test('updates state to null', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          await notifier.clearActivePubkey();
          final state = container.read(activePubkeyProvider);
          expect(state, isNull);
        });

        test('notifies to listeners', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          bool wasNotified = false;

          container.listen(activePubkeyProvider, (previous, next) {
            wasNotified = true;
          });

          await notifier.clearActivePubkey();
          expect(wasNotified, isTrue);
        });
      });

      group('when state is a pubkey string', () {
        setUp(() async {
          when(
            mockStorage.write(key: 'active_account_pubkey', value: testHexPubkey),
          ).thenAnswer((_) async {});
          await container.read(activePubkeyProvider.notifier).setActivePubkey(testHexPubkey);
          when(mockStorage.delete(key: 'active_account_pubkey')).thenAnswer((_) async {});
        });

        test('updates state to null', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          expect(container.read(activePubkeyProvider), testHexPubkey);
          await notifier.clearActivePubkey();
          final state = container.read(activePubkeyProvider);
          expect(state, isNull);
        });

        test('notifies to listeners', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          bool wasNotified = false;

          container.listen(activePubkeyProvider, (previous, next) {
            wasNotified = true;
          });

          await notifier.clearActivePubkey();
          expect(wasNotified, isTrue);
        });
      });
    });

    group('clearAllSecureStorage', () {
      group('when state is null', () {
        setUp(() async {
          when(mockStorage.deleteAll()).thenAnswer((_) async {});
        });
        test('updates state to null', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          await notifier.clearAllSecureStorage();
          final state = container.read(activePubkeyProvider);
          expect(state, isNull);
        });

        test('does not notify to listeners', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          bool wasNotified = false;

          container.listen(activePubkeyProvider, (previous, next) {
            wasNotified = true;
          });

          await notifier.clearAllSecureStorage();
          expect(wasNotified, isFalse);
        });
      });

      group('when storage has empty string', () {
        setUp(() async {
          when(mockStorage.write(key: 'active_account_pubkey', value: '')).thenAnswer((_) async {});
          await container.read(activePubkeyProvider.notifier).setActivePubkey('');
          when(mockStorage.deleteAll()).thenAnswer((_) async {});
        });

        test('updates state to null', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          await notifier.clearAllSecureStorage();
          final state = container.read(activePubkeyProvider);
          expect(state, isNull);
        });

        test('notifies to listeners', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          bool wasNotified = false;

          container.listen(activePubkeyProvider, (previous, next) {
            wasNotified = true;
          });

          await notifier.clearAllSecureStorage();
          expect(wasNotified, isTrue);
        });
      });

      group('when state is a pubkey string', () {
        setUp(() async {
          when(
            mockStorage.write(key: 'active_account_pubkey', value: testHexPubkey),
          ).thenAnswer((_) async {});
          await container.read(activePubkeyProvider.notifier).setActivePubkey(testHexPubkey);
          when(mockStorage.deleteAll()).thenAnswer((_) async {});
        });

        test('updates state to null', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          expect(container.read(activePubkeyProvider), testHexPubkey);
          await notifier.clearAllSecureStorage();
          final state = container.read(activePubkeyProvider);
          expect(state, isNull);
        });

        test('notifies to listeners', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          bool wasNotified = false;

          container.listen(activePubkeyProvider, (previous, next) {
            wasNotified = true;
          });

          await notifier.clearAllSecureStorage();
          expect(wasNotified, isTrue);
        });
      });
    });
  });
}
