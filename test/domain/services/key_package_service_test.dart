import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/services/key_package_service.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/relays.dart' as relays;
import 'package:whitenoise/src/rust/lib.dart';

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

class MockRelayUrl implements RelayUrl {
  final String url;

  MockRelayUrl({required this.url});

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('KeyPackageService', () {
    const testPublicKey = 'test-public-key';
    final testNip65Relays = [MockRelayUrl(url: 'wss://test-relay.com')];

    group('when key package is found at first attempt', () {
      Future<relays.Event?> fetchKeyPackageSuccess({
        required PublicKey pubkey,
        required List<RelayUrl> nip65Relays,
      }) async {
        return MockEvent(eventId: 'test-key-package-event-123');
      }

      test('returns key package', () async {
        final service = KeyPackageService(
          publicKey: testPublicKey,
          nip65Relays: testNip65Relays,
          fetchKeyPackage: fetchKeyPackageSuccess,
        );
        final result = await service.fetchWithRetry();
        expect((result as MockEvent).eventId, equals('test-key-package-event-123'));
      });
    });

    group('when key package is found at second attempt', () {
      test('returns key package', () async {
        int attemptCount = 0;

        Future<relays.Event?> fakeFailThenSuccess({
          required PublicKey pubkey,
          required List<RelayUrl> nip65Relays,
        }) async {
          attemptCount++;
          if (attemptCount == 1) {
            throw Exception('DroppableDisposedException');
          }
          return MockEvent(eventId: 'test-success-on-retry');
        }

        final service = KeyPackageService(
          publicKey: testPublicKey,
          nip65Relays: testNip65Relays,
          fetchKeyPackage: fakeFailThenSuccess,
        );
        final result = await service.fetchWithRetry();

        expect((result as MockEvent).eventId, equals('test-success-on-retry'));
      });
    });

    group('when key package is found at third attempt', () {
      test('returns key package', () async {
        int attemptCount = 0;

        Future<relays.Event?> fakeFailTwiceThenSuccess({
          required PublicKey pubkey,
          required List<RelayUrl> nip65Relays,
        }) async {
          attemptCount++;
          if (attemptCount <= 2) {
            throw Exception('DroppableDisposedException');
          }
          return MockEvent(eventId: 'test-success-on-third-attempt');
        }

        final service = KeyPackageService(
          publicKey: testPublicKey,
          nip65Relays: testNip65Relays,
          fetchKeyPackage: fakeFailTwiceThenSuccess,
        );
        final result = await service.fetchWithRetry();

        expect((result as MockEvent).eventId, equals('test-success-on-third-attempt'));
      });
    });

    group('when key package fails after all attempts', () {
      test('throws exception', () async {
        Future<relays.Event?> fakeAlwaysFails({
          required PublicKey pubkey,
          required List<RelayUrl> nip65Relays,
        }) async {
          throw Exception('DroppableDisposedException');
        }

        final service = KeyPackageService(
          publicKey: testPublicKey,
          nip65Relays: testNip65Relays,
          fetchKeyPackage: fakeAlwaysFails,
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
