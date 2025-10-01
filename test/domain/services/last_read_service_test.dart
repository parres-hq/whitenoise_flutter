import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:whitenoise/domain/services/last_read_service.dart';

import 'last_read_service_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  group('LastReadService', () {
    late MockFlutterSecureStorage mockStorage;
    const String testGroupId = 'test-group-123';
    final DateTime testTimestamp = DateTime(2024, 1, 15, 10, 30, 45);
    final String testTimestampString = testTimestamp.millisecondsSinceEpoch.toString();

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
    });

    group('setLastRead', () {
      group('with custom timestamp', () {
        test('sets the last read timestamp with custom value', () async {
          when(
            mockStorage.write(
              key: 'last_read_$testGroupId',
              value: testTimestampString,
            ),
          ).thenAnswer((_) async => {});

          await LastReadService.setLastRead(
            groupId: testGroupId,
            timestamp: testTimestamp,
            storage: mockStorage,
          );

          verify(
            mockStorage.write(
              key: 'last_read_$testGroupId',
              value: testTimestampString,
            ),
          ).called(1);
        });
      });

      group('without timestamp', () {
        test('sets the last read timestamp with current time', () async {
          final beforeCall = DateTime.now();

          when(
            mockStorage.write(
              key: 'last_read_$testGroupId',
              value: anyNamed('value'),
            ),
          ).thenAnswer((_) async => {});

          await LastReadService.setLastRead(
            groupId: testGroupId,
            storage: mockStorage,
          );

          final afterCall = DateTime.now();

          // Verify the timestamp is within reasonable bounds
          final capturedValue =
              verify(
                    mockStorage.write(
                      key: 'last_read_$testGroupId',
                      value: captureAnyNamed('value'),
                    ),
                  ).captured.first
                  as String;

          final capturedTimestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(capturedValue));
          expect(
            capturedTimestamp.isAfter(beforeCall.subtract(const Duration(seconds: 1))),
            isTrue,
          );
          expect(capturedTimestamp.isBefore(afterCall.add(const Duration(seconds: 1))), isTrue);
        });
      });

      group('with error', () {
        test('handles storage error gracefully', () async {
          when(
            mockStorage.write(
              key: 'last_read_$testGroupId',
              value: testTimestampString,
            ),
          ).thenThrow(Exception('Storage error'));

          // Should not throw
          await LastReadService.setLastRead(
            groupId: testGroupId,
            timestamp: testTimestamp,
            storage: mockStorage,
          );

          verify(
            mockStorage.write(
              key: 'last_read_$testGroupId',
              value: testTimestampString,
            ),
          ).called(1);
        });
      });

      group('with different group IDs', () {
        test('uses correct key format for different groups', () async {
          const groupId1 = 'group-1';
          const groupId2 = 'group-2';

          when(
            mockStorage.write(
              key: anyNamed('key'),
              value: anyNamed('value'),
            ),
          ).thenAnswer((_) async => {});

          await LastReadService.setLastRead(
            groupId: groupId1,
            timestamp: testTimestamp,
            storage: mockStorage,
          );

          await LastReadService.setLastRead(
            groupId: groupId2,
            timestamp: testTimestamp,
            storage: mockStorage,
          );

          verify(
            mockStorage.write(key: 'last_read_$groupId1', value: testTimestampString),
          ).called(1);
          verify(
            mockStorage.write(key: 'last_read_$groupId2', value: testTimestampString),
          ).called(1);
        });
      });
    });

    group('getLastRead', () {
      group('without stored timestamp', () {
        setUp(() {
          when(mockStorage.read(key: 'last_read_$testGroupId')).thenAnswer((_) async => null);
        });

        test('returns null', () async {
          final timestamp = await LastReadService.getLastRead(
            groupId: testGroupId,
            storage: mockStorage,
          );

          expect(timestamp, isNull);
          verify(mockStorage.read(key: 'last_read_$testGroupId')).called(1);
        });
      });

      group('with stored timestamp', () {
        setUp(() {
          when(
            mockStorage.read(key: 'last_read_$testGroupId'),
          ).thenAnswer((_) async => testTimestampString);
        });

        test('returns the correct timestamp', () async {
          final timestamp = await LastReadService.getLastRead(
            groupId: testGroupId,
            storage: mockStorage,
          );

          expect(timestamp, equals(testTimestamp));
          verify(mockStorage.read(key: 'last_read_$testGroupId')).called(1);
        });
      });

      group('with invalid timestamp format', () {
        setUp(() {
          when(
            mockStorage.read(key: 'last_read_$testGroupId'),
          ).thenAnswer((_) async => 'invalid-timestamp');
        });

        test('returns null', () async {
          final timestamp = await LastReadService.getLastRead(
            groupId: testGroupId,
            storage: mockStorage,
          );

          expect(timestamp, isNull);
          verify(mockStorage.read(key: 'last_read_$testGroupId')).called(1);
        });
      });

      group('with empty string', () {
        setUp(() {
          when(mockStorage.read(key: 'last_read_$testGroupId')).thenAnswer((_) async => '');
        });

        test('returns null', () async {
          final timestamp = await LastReadService.getLastRead(
            groupId: testGroupId,
            storage: mockStorage,
          );

          expect(timestamp, isNull);
          verify(mockStorage.read(key: 'last_read_$testGroupId')).called(1);
        });
      });

      group('with error', () {
        setUp(() {
          when(
            mockStorage.read(key: 'last_read_$testGroupId'),
          ).thenThrow(Exception('Storage error'));
        });

        test('returns null', () async {
          final timestamp = await LastReadService.getLastRead(
            groupId: testGroupId,
            storage: mockStorage,
          );

          expect(timestamp, isNull);
          verify(mockStorage.read(key: 'last_read_$testGroupId')).called(1);
        });
      });

      group('with different group IDs', () {
        test('uses correct key format for different groups', () async {
          const groupId1 = 'group-1';
          const groupId2 = 'group-2';

          when(mockStorage.read(key: anyNamed('key'))).thenAnswer((_) async => testTimestampString);

          await LastReadService.getLastRead(groupId: groupId1, storage: mockStorage);
          await LastReadService.getLastRead(groupId: groupId2, storage: mockStorage);

          verify(mockStorage.read(key: 'last_read_$groupId1')).called(1);
          verify(mockStorage.read(key: 'last_read_$groupId2')).called(1);
        });
      });
    });

    group('integration tests', () {
      test('setLastRead and getLastRead work together', () async {
        when(
          mockStorage.write(
            key: 'last_read_$testGroupId',
            value: testTimestampString,
          ),
        ).thenAnswer((_) async => {});

        when(
          mockStorage.read(key: 'last_read_$testGroupId'),
        ).thenAnswer((_) async => testTimestampString);

        // Set the timestamp
        await LastReadService.setLastRead(
          groupId: testGroupId,
          timestamp: testTimestamp,
          storage: mockStorage,
        );

        // Get the timestamp
        final retrievedTimestamp = await LastReadService.getLastRead(
          groupId: testGroupId,
          storage: mockStorage,
        );

        expect(retrievedTimestamp, equals(testTimestamp));
        verify(
          mockStorage.write(key: 'last_read_$testGroupId', value: testTimestampString),
        ).called(1);
        verify(mockStorage.read(key: 'last_read_$testGroupId')).called(1);
      });

      test('handles edge case timestamps', () async {
        final edgeCases = [
          DateTime.fromMillisecondsSinceEpoch(0), // Unix epoch
          DateTime.fromMillisecondsSinceEpoch(1), // Minimum positive value
          DateTime.fromMillisecondsSinceEpoch(9999999999999), // Far future
          DateTime(1970, 1, 1), // Unix epoch (different constructor)
          DateTime(2038, 1, 19, 3, 14, 7), // Year 2038 problem
        ];

        for (final edgeTimestamp in edgeCases) {
          final timestampString = edgeTimestamp.millisecondsSinceEpoch.toString();

          when(
            mockStorage.write(
              key: 'last_read_$testGroupId',
              value: timestampString,
            ),
          ).thenAnswer((_) async => {});

          when(
            mockStorage.read(key: 'last_read_$testGroupId'),
          ).thenAnswer((_) async => timestampString);

          await LastReadService.setLastRead(
            groupId: testGroupId,
            timestamp: edgeTimestamp,
            storage: mockStorage,
          );

          final retrievedTimestamp = await LastReadService.getLastRead(
            groupId: testGroupId,
            storage: mockStorage,
          );

          expect(retrievedTimestamp, equals(edgeTimestamp));
        }
      });
    });
  });
}
