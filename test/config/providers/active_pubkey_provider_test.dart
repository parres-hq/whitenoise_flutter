import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';

import 'active_pubkey_provider_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  group('ActivePubkeyProvider Tests', () {
    late ProviderContainer container;
    late MockFlutterSecureStorage mockStorage;

    ProviderContainer createContainer({MockFlutterSecureStorage? storage}) {
      return ProviderContainer(
        overrides: [
          if (storage != null)
            activePubkeyProvider.overrideWith(() => ActivePubkeyNotifier(storage: storage)),
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

        test('sets state to null', () async {
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

      group('when storage has a pubkey string', () {
        setUp(() async {
          when(
            mockStorage.read(key: 'active_account_pubkey'),
          ).thenAnswer((_) async => 'test_pubkey_123');
        });

        test('sets state to the pubkey string', () async {
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
            mockStorage.write(key: 'active_account_pubkey', value: 'test_pubkey_123'),
          ).thenAnswer((_) async {});
        });
        test('updates state', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          await notifier.setActivePubkey('test_pubkey_123');
          final state = container.read(activePubkeyProvider);
          expect(state, 'test_pubkey_123');
        });

        test('notifies to listeners', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          bool wasNotified = false;

          container.listen(activePubkeyProvider, (previous, next) {
            wasNotified = true;
          });

          await notifier.setActivePubkey('test_pubkey_123');
          expect(wasNotified, isTrue);
        });
      });

      group('when state is empty string', () {
        setUp(() async {
          when(mockStorage.write(key: 'active_account_pubkey', value: '')).thenAnswer((_) async {});
          await container.read(activePubkeyProvider.notifier).setActivePubkey('');
          when(
            mockStorage.write(key: 'active_account_pubkey', value: 'test_pubkey_123'),
          ).thenAnswer((_) async {});
        });

        test('updates state', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          expect(container.read(activePubkeyProvider), '');
          await notifier.setActivePubkey('test_pubkey_123');
          expect(container.read(activePubkeyProvider), 'test_pubkey_123');
        });

        test('notifies to listeners', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          bool wasNotified = false;

          container.listen(activePubkeyProvider, (previous, next) {
            wasNotified = true;
          });

          await notifier.setActivePubkey('test_pubkey_123');
          expect(wasNotified, isTrue);
        });
      });

      group('when state is a pubkey string', () {
        setUp(() async {
          when(
            mockStorage.write(key: 'active_account_pubkey', value: 'test_pubkey_123'),
          ).thenAnswer((_) async {});
          await container.read(activePubkeyProvider.notifier).setActivePubkey('test_pubkey_123');
          when(
            mockStorage.write(key: 'active_account_pubkey', value: 'test_pubkey_456'),
          ).thenAnswer((_) async {});
        });

        test('updates state', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          expect(container.read(activePubkeyProvider), 'test_pubkey_123');
          await notifier.setActivePubkey('test_pubkey_456');
          expect(container.read(activePubkeyProvider), 'test_pubkey_456');
        });

        test('notifies to listeners', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          bool wasNotified = false;

          container.listen(activePubkeyProvider, (previous, next) {
            wasNotified = true;
          });

          await notifier.setActivePubkey('test_pubkey_456');
          expect(wasNotified, isTrue);
        });
      });
    });

    group('clearActivePubkey', () {
      group('when state is null', () {
        setUp(() async {
          when(mockStorage.delete(key: 'active_account_pubkey')).thenAnswer((_) async {});
        });
        test('updates state to null', () async {
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
          expect(wasNotified, isFalse);
        });
      });

      group('when state is empty string', () {
        setUp(() async {
          when(mockStorage.write(key: 'active_account_pubkey', value: '')).thenAnswer((_) async {});
          await container.read(activePubkeyProvider.notifier).setActivePubkey('');
          when(mockStorage.delete(key: 'active_account_pubkey')).thenAnswer((_) async {});
        });

        test('updates state to null', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          expect(container.read(activePubkeyProvider), '');
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
            mockStorage.write(key: 'active_account_pubkey', value: 'test_pubkey_123'),
          ).thenAnswer((_) async {});
          await container.read(activePubkeyProvider.notifier).setActivePubkey('test_pubkey_123');
          when(mockStorage.delete(key: 'active_account_pubkey')).thenAnswer((_) async {});
        });

        test('updates state to null', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          expect(container.read(activePubkeyProvider), 'test_pubkey_123');
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

      group('when state is empty string', () {
        setUp(() async {
          when(mockStorage.write(key: 'active_account_pubkey', value: '')).thenAnswer((_) async {});
          await container.read(activePubkeyProvider.notifier).setActivePubkey('');
          when(mockStorage.deleteAll()).thenAnswer((_) async {});
        });

        test('updates state to null', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          expect(container.read(activePubkeyProvider), '');
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
            mockStorage.write(key: 'active_account_pubkey', value: 'test_pubkey_123'),
          ).thenAnswer((_) async {});
          await container.read(activePubkeyProvider.notifier).setActivePubkey('test_pubkey_123');
          when(mockStorage.deleteAll()).thenAnswer((_) async {});
        });

        test('updates state to null', () async {
          final notifier = container.read(activePubkeyProvider.notifier);
          expect(container.read(activePubkeyProvider), 'test_pubkey_123');
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
