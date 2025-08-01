import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/services/key_package_service.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/relays.dart' as relays;

class MockEvent implements relays.Event {
  final String eventId;

  MockEvent({required this.eventId});

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class MockPublicKey implements PublicKey {
  final String key;

  MockPublicKey({required this.key});

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('KeyPackageService', () {
    const testPublicKey = 'test-public-key';

    group('when key package is found at first attempt', () {
      Future<relays.Event?> fetchKeyPackageSuccess({required PublicKey pubkey}) async {
        return MockEvent(eventId: 'test-key-package-event-123');
      }

      Future<PublicKey> mockPublicKeyFromString({required String publicKeyString}) async {
        return MockPublicKey(key: publicKeyString);
      }

      test('returns key package', () async {
        final service = KeyPackageService(
          publicKeyString: testPublicKey,
          fetchKeyPackage: fetchKeyPackageSuccess,
          publicKeyFromString: mockPublicKeyFromString,
        );
        final result = await service.fetchWithRetry();
        expect((result as MockEvent).eventId, equals('test-key-package-event-123'));
      });
    });

    group('when key package is found at second attempt', () {
      test('returns key package', () async {
        int attemptCount = 0;

        Future<relays.Event?> fakeFailThenSuccess({required PublicKey pubkey}) async {
          attemptCount++;
          if (attemptCount == 1) {
            throw Exception('DroppableDisposedException');
          }
          return MockEvent(eventId: 'test-success-on-retry');
        }

        Future<PublicKey> mockPublicKeyFromString({required String publicKeyString}) async {
          return MockPublicKey(key: publicKeyString);
        }

        final service = KeyPackageService(
          publicKeyString: testPublicKey,
          fetchKeyPackage: fakeFailThenSuccess,
          publicKeyFromString: mockPublicKeyFromString,
        );
        final result = await service.fetchWithRetry();

        expect((result as MockEvent).eventId, equals('test-success-on-retry'));
      });
    });

    group('when key package is found at third attempt', () {
      test('returns key package', () async {
        int attemptCount = 0;

        Future<relays.Event?> fakeFailTwiceThenSuccess({required PublicKey pubkey}) async {
          attemptCount++;
          if (attemptCount <= 2) {
            throw Exception('DroppableDisposedException');
          }
          return MockEvent(eventId: 'test-success-on-third-attempt');
        }

        Future<PublicKey> mockPublicKeyFromString({required String publicKeyString}) async {
          return MockPublicKey(key: publicKeyString);
        }

        final service = KeyPackageService(
          publicKeyString: testPublicKey,
          fetchKeyPackage: fakeFailTwiceThenSuccess,
          publicKeyFromString: mockPublicKeyFromString,
        );
        final result = await service.fetchWithRetry();

        expect((result as MockEvent).eventId, equals('test-success-on-third-attempt'));
      });
    });

    group('when key package fails after all attempts', () {
      test('throws exception', () async {
        Future<relays.Event?> fakeAlwaysFails({required PublicKey pubkey}) async {
          throw Exception('DroppableDisposedException');
        }

        Future<PublicKey> mockPublicKeyFromString({required String publicKeyString}) async {
          return MockPublicKey(key: publicKeyString);
        }

        final service = KeyPackageService(
          publicKeyString: testPublicKey,
          fetchKeyPackage: fakeAlwaysFails,
          publicKeyFromString: mockPublicKeyFromString,
        );
        expect(
          () => service.fetchWithRetry(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to fetch key package after 3 attempts'),
            ),
          ),
        );
      });
    });
  });
}
