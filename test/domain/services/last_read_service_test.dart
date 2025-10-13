import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/domain/services/last_read_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LastReadService', () {
    const String testGroupId = 'test-group-123';
    const String testActivePubkey = 'test-pubkey-123';
    final DateTime testTimestamp = DateTime(2024, 1, 15, 10, 30, 45);
    final int testTimestampMillis = testTimestamp.millisecondsSinceEpoch;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('setLastRead', () {
      group('with custom timestamp', () {
        test('sets the last read timestamp with custom value', () async {
          await LastReadService.setLastRead(
            groupId: testGroupId,
            activePubkey: testActivePubkey,
            timestamp: testTimestamp,
          );

          final prefs = await SharedPreferences.getInstance();
          final storedValue = prefs.getInt('last_read_${testActivePubkey}_$testGroupId');
          expect(storedValue, equals(testTimestampMillis));
        });
      });

      group('without timestamp', () {
        test('sets the last read timestamp with current time', () async {
          final beforeCall = DateTime.now();

          await LastReadService.setLastRead(
            groupId: testGroupId,
            activePubkey: testActivePubkey,
          );

          final afterCall = DateTime.now();

          final prefs = await SharedPreferences.getInstance();
          final storedValue = prefs.getInt('last_read_${testActivePubkey}_$testGroupId');

          expect(storedValue, isNotNull);
          final storedTimestamp = DateTime.fromMillisecondsSinceEpoch(storedValue!);

          expect(
            storedTimestamp.isAfter(beforeCall.subtract(const Duration(seconds: 1))),
            isTrue,
          );
          expect(storedTimestamp.isBefore(afterCall.add(const Duration(seconds: 1))), isTrue);
        });
      });

      group('with different group IDs', () {
        test('uses correct key format for different groups', () async {
          const groupId1 = 'group-1';
          const groupId2 = 'group-2';

          await LastReadService.setLastRead(
            groupId: groupId1,
            activePubkey: testActivePubkey,
            timestamp: testTimestamp,
          );

          await LastReadService.setLastRead(
            groupId: groupId2,
            activePubkey: testActivePubkey,
            timestamp: testTimestamp,
          );

          final prefs = await SharedPreferences.getInstance();
          expect(
            prefs.getInt('last_read_${testActivePubkey}_$groupId1'),
            equals(testTimestampMillis),
          );
          expect(
            prefs.getInt('last_read_${testActivePubkey}_$groupId2'),
            equals(testTimestampMillis),
          );
        });
      });
    });

    group('getLastRead', () {
      test('returns null when no timestamp is stored', () async {
        final timestamp = await LastReadService.getLastRead(
          groupId: 'some-other-group',
          activePubkey: testActivePubkey,
        );

        expect(timestamp, isNull);
      });

      test('returns the correct timestamp when stored', () async {
        // First set a value
        await LastReadService.setLastRead(
          groupId: testGroupId,
          activePubkey: testActivePubkey,
          timestamp: testTimestamp,
        );

        // Then get it back
        final timestamp = await LastReadService.getLastRead(
          groupId: testGroupId,
          activePubkey: testActivePubkey,
        );

        expect(timestamp, equals(testTimestamp));
      });

      test('uses correct key format for different groups', () async {
        const groupId1 = 'group-1';
        const groupId2 = 'group-2';
        final timestamp1 = DateTime(2024);
        final timestamp2 = DateTime(2024, 2);

        await LastReadService.setLastRead(
          groupId: groupId1,
          activePubkey: testActivePubkey,
          timestamp: timestamp1,
        );

        await LastReadService.setLastRead(
          groupId: groupId2,
          activePubkey: testActivePubkey,
          timestamp: timestamp2,
        );

        final result1 = await LastReadService.getLastRead(
          groupId: groupId1,
          activePubkey: testActivePubkey,
        );
        final result2 = await LastReadService.getLastRead(
          groupId: groupId2,
          activePubkey: testActivePubkey,
        );

        expect(result1, equals(timestamp1));
        expect(result2, equals(timestamp2));
      });
    });

    group('integration tests', () {
      test('setLastRead and getLastRead work together', () async {
        // Set the timestamp
        await LastReadService.setLastRead(
          groupId: testGroupId,
          activePubkey: testActivePubkey,
          timestamp: testTimestamp,
        );

        // Get the timestamp
        final retrievedTimestamp = await LastReadService.getLastRead(
          groupId: testGroupId,
          activePubkey: testActivePubkey,
        );

        expect(retrievedTimestamp, equals(testTimestamp));
      });

      test('handles edge case timestamps', () async {
        final edgeCases = [
          DateTime.fromMillisecondsSinceEpoch(0), // Unix epoch
          DateTime.fromMillisecondsSinceEpoch(1), // Minimum positive value
          DateTime.fromMillisecondsSinceEpoch(9999999999999), // Far future
          DateTime(1970), // Unix epoch (different constructor)
          DateTime(2038, 1, 19, 3, 14, 7), // Year 2038 problem
        ];

        for (final edgeTimestamp in edgeCases) {
          await LastReadService.setLastRead(
            groupId: testGroupId,
            activePubkey: testActivePubkey,
            timestamp: edgeTimestamp,
          );

          final retrievedTimestamp = await LastReadService.getLastRead(
            groupId: testGroupId,
            activePubkey: testActivePubkey,
          );

          expect(retrievedTimestamp, equals(edgeTimestamp));
        }
      });

      test('multiple accounts have separate last read timestamps', () async {
        const pubkey1 = 'pubkey-1';
        const pubkey2 = 'pubkey-2';
        final timestamp1 = DateTime(2024);
        final timestamp2 = DateTime(2024, 2);

        await LastReadService.setLastRead(
          groupId: testGroupId,
          activePubkey: pubkey1,
          timestamp: timestamp1,
        );

        await LastReadService.setLastRead(
          groupId: testGroupId,
          activePubkey: pubkey2,
          timestamp: timestamp2,
        );

        final result1 = await LastReadService.getLastRead(
          groupId: testGroupId,
          activePubkey: pubkey1,
        );

        final result2 = await LastReadService.getLastRead(
          groupId: testGroupId,
          activePubkey: pubkey2,
        );

        expect(result1, equals(timestamp1));
        expect(result2, equals(timestamp2));
      });

      test('updating timestamp for same group overwrites previous value', () async {
        final firstTimestamp = DateTime(2024);
        final secondTimestamp = DateTime(2024, 2);

        await LastReadService.setLastRead(
          groupId: testGroupId,
          activePubkey: testActivePubkey,
          timestamp: firstTimestamp,
        );

        await LastReadService.setLastRead(
          groupId: testGroupId,
          activePubkey: testActivePubkey,
          timestamp: secondTimestamp,
        );

        final retrievedTimestamp = await LastReadService.getLastRead(
          groupId: testGroupId,
          activePubkey: testActivePubkey,
        );

        expect(retrievedTimestamp, equals(secondTimestamp));
      });
    });
  });
}
