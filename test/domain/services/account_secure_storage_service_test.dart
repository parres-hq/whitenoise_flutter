import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:whitenoise/domain/services/account_secure_storage_service.dart';

import 'account_secure_storage_service_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  group('AccountSecureStorageService', () {
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
    });

    group('getActivePubkey', () {
      group('without stored pubkey', () {
        setUp(() {
          when(mockStorage.read(key: 'active_account_pubkey')).thenAnswer((_) async => null);
        });

        test('returns null', () async {
          final pubkey = await AccountSecureStorageService.getActivePubkey(storage: mockStorage);
          expect(pubkey, isNull);
          verify(mockStorage.read(key: 'active_account_pubkey')).called(1);
        });
      });

      group('with stored pubkey', () {
        setUp(() {
          when(
            mockStorage.read(key: 'active_account_pubkey'),
          ).thenAnswer((_) async => 'my-test-pubkey');
        });

        test('returns the pubkey', () async {
          final pubkey = await AccountSecureStorageService.getActivePubkey(storage: mockStorage);
          expect(pubkey, 'my-test-pubkey');
          verify(mockStorage.read(key: 'active_account_pubkey')).called(1);
        });
      });

      group('with error', () {
        setUp(() {
          when(
            mockStorage.read(key: 'active_account_pubkey'),
          ).thenThrow(Exception('Storage error'));
        });

        test('returns null', () async {
          final pubkey = await AccountSecureStorageService.getActivePubkey(storage: mockStorage);
          expect(pubkey, isNull);
          verify(mockStorage.read(key: 'active_account_pubkey')).called(1);
        });
      });
    });

    group('setActivePubkey', () {
      test('sets the pubkey', () async {
        when(
          mockStorage.write(key: 'active_account_pubkey', value: 'my-test-pubkey'),
        ).thenAnswer((_) async => {});

        await AccountSecureStorageService.setActivePubkey('my-test-pubkey', storage: mockStorage);

        verify(mockStorage.write(key: 'active_account_pubkey', value: 'my-test-pubkey')).called(1);
      });

      group('with error', () {
        test('rethrows the error', () async {
          when(
            mockStorage.write(key: 'active_account_pubkey', value: 'my-test-pubkey'),
          ).thenThrow(Exception('Storage error'));

          await expectLater(
            () =>
                AccountSecureStorageService.setActivePubkey('my-test-pubkey', storage: mockStorage),
            throwsA(isA<Exception>()),
          );

          verify(
            mockStorage.write(key: 'active_account_pubkey', value: 'my-test-pubkey'),
          ).called(1);
        });
      });
    });

    group('clearActivePubkey', () {
      test('clears the pubkey', () async {
        when(mockStorage.delete(key: 'active_account_pubkey')).thenAnswer((_) async => {});

        await AccountSecureStorageService.clearActivePubkey(storage: mockStorage);

        verify(mockStorage.delete(key: 'active_account_pubkey')).called(1);
      });

      group('with error', () {
        test('rethrows the error', () async {
          when(
            mockStorage.delete(key: 'active_account_pubkey'),
          ).thenThrow(Exception('Storage error'));

          await expectLater(
            () => AccountSecureStorageService.clearActivePubkey(storage: mockStorage),
            throwsA(isA<Exception>()),
          );

          verify(mockStorage.delete(key: 'active_account_pubkey')).called(1);
        });
      });
    });

    group('clearAllSecureStorage', () {
      test('clears all secure storage data', () async {
        when(mockStorage.deleteAll()).thenAnswer((_) async => {});

        await AccountSecureStorageService.clearAllSecureStorage(storage: mockStorage);

        verify(mockStorage.deleteAll()).called(1);
      });

      group('with error', () {
        test('rethrows the error', () async {
          when(mockStorage.deleteAll()).thenThrow(Exception('Storage error'));

          await expectLater(
            () => AccountSecureStorageService.clearAllSecureStorage(storage: mockStorage),
            throwsA(isA<Exception>()),
          );

          verify(mockStorage.deleteAll()).called(1);
        });
      });
    });
  });
}
