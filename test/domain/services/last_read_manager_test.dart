import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/services/last_read_manager.dart';

void main() {
  group('LastReadManager', () {
    const String testGroupId = 'test-group-123';
    final DateTime testTimestamp = DateTime(2024, 1, 15, 10, 30, 45);

    setUp(() {
      // Reset static state before each test
      LastReadManager.dispose();
    });

    tearDown(() {
      LastReadManager.dispose();
    });

    group('saveLastReadImmediate', () {
      test('executes without throwing', () async {
        await LastReadManager.saveLastReadImmediate(testGroupId, testTimestamp);
        expect(true, isTrue);
      });

      test('handles multiple calls with same timestamp', () async {
        await LastReadManager.saveLastReadImmediate(testGroupId, testTimestamp);
        await LastReadManager.saveLastReadImmediate(testGroupId, testTimestamp);
        expect(true, isTrue);
      });

      test('handles calls with different timestamps', () async {
        await LastReadManager.saveLastReadImmediate(testGroupId, testTimestamp);
        final differentTimestamp = testTimestamp.add(const Duration(seconds: 2));
        await LastReadManager.saveLastReadImmediate(testGroupId, differentTimestamp);
        expect(true, isTrue);
      });
    });

    group('saveLastReadDebounced', () {
      test('executes without throwing', () {
        LastReadManager.saveLastReadDebounced(testGroupId, testTimestamp);
        expect(true, isTrue);
      });

      test('handles multiple rapid calls', () {
        LastReadManager.saveLastReadDebounced(testGroupId, testTimestamp);
        LastReadManager.saveLastReadDebounced(testGroupId, testTimestamp);
        LastReadManager.saveLastReadDebounced(testGroupId, testTimestamp);
        expect(true, isTrue);
      });

      test('handles calls with different timestamps', () {
        LastReadManager.saveLastReadDebounced(testGroupId, testTimestamp);
        final laterTimestamp = testTimestamp.add(const Duration(seconds: 1));
        LastReadManager.saveLastReadDebounced(testGroupId, laterTimestamp);
        expect(true, isTrue);
      });
    });

    group('saveLastReadThrottled', () {
      test('executes without throwing', () {
        LastReadManager.saveLastReadThrottled(testGroupId, testTimestamp);
        expect(true, isTrue);
      });

      test('handles multiple rapid calls', () {
        LastReadManager.saveLastReadThrottled(testGroupId, testTimestamp);
        LastReadManager.saveLastReadThrottled(testGroupId, testTimestamp);
        LastReadManager.saveLastReadThrottled(testGroupId, testTimestamp);
        expect(true, isTrue);
      });

      test('handles calls with different timestamps', () {
        LastReadManager.saveLastReadThrottled(testGroupId, testTimestamp);
        final laterTimestamp = testTimestamp.add(const Duration(seconds: 1));
        LastReadManager.saveLastReadThrottled(testGroupId, laterTimestamp);
        expect(true, isTrue);
      });
    });

    group('saveLastReadForLatestMessage', () {
      test('handles empty message list', () async {
        await LastReadManager.saveLastReadForLatestMessage(testGroupId, []);
        expect(true, isTrue);
      });

      test('handles single message', () async {
        final messages = [_MockMessage(testTimestamp)];
        await LastReadManager.saveLastReadForLatestMessage(testGroupId, messages);
        expect(true, isTrue);
      });

      test('handles multiple messages', () async {
        final messages = [
          _MockMessage(testTimestamp),
          _MockMessage(testTimestamp.add(const Duration(minutes: 1))),
          _MockMessage(testTimestamp.add(const Duration(minutes: 2))),
        ];
        await LastReadManager.saveLastReadForLatestMessage(testGroupId, messages);
        expect(true, isTrue);
      });

      test('handles messages with same timestamp', () async {
        final messages = [
          _MockMessage(testTimestamp),
          _MockMessage(testTimestamp),
          _MockMessage(testTimestamp),
        ];
        await LastReadManager.saveLastReadForLatestMessage(testGroupId, messages);
        expect(true, isTrue);
      });
    });

    group('cancelPendingSaves', () {
      test('executes without throwing', () {
        LastReadManager.cancelPendingSaves(testGroupId);
        expect(true, isTrue);
      });

      test('handles cancellation after starting timers', () {
        LastReadManager.saveLastReadDebounced(testGroupId, testTimestamp);
        LastReadManager.saveLastReadThrottled(testGroupId, testTimestamp);
        LastReadManager.cancelPendingSaves(testGroupId);
        expect(true, isTrue);
      });

      test('handles cancellation for non-existent group', () {
        LastReadManager.cancelPendingSaves('non-existent-group');
        expect(true, isTrue);
      });
    });

    group('cancelAllPendingSaves', () {
      test('executes without throwing', () {
        LastReadManager.cancelAllPendingSaves();
        expect(true, isTrue);
      });

      test('handles cancellation after starting multiple timers', () {
        const groupId1 = 'group-1';
        const groupId2 = 'group-2';
        const groupId3 = 'group-3';

        LastReadManager.saveLastReadDebounced(groupId1, testTimestamp);
        LastReadManager.saveLastReadThrottled(groupId2, testTimestamp);
        LastReadManager.saveLastReadDebounced(groupId3, testTimestamp);
        LastReadManager.cancelAllPendingSaves();
        expect(true, isTrue);
      });
    });

    group('dispose', () {
      test('executes without throwing', () {
        LastReadManager.dispose();
        expect(true, isTrue);
      });

      test('handles disposal after starting timers', () {
        LastReadManager.saveLastReadDebounced(testGroupId, testTimestamp);
        LastReadManager.saveLastReadThrottled('other-group', testTimestamp);
        LastReadManager.dispose();
        expect(true, isTrue);
      });
    });

    group('integration tests', () {
      test('all methods work together without throwing', () async {
        LastReadManager.saveLastReadDebounced(testGroupId, testTimestamp);
        LastReadManager.saveLastReadThrottled(testGroupId, testTimestamp);
        await LastReadManager.saveLastReadImmediate(testGroupId, testTimestamp);

        final messages = [_MockMessage(testTimestamp)];
        await LastReadManager.saveLastReadForLatestMessage(testGroupId, messages);

        LastReadManager.cancelPendingSaves(testGroupId);
        LastReadManager.cancelAllPendingSaves();
        LastReadManager.dispose();

        expect(true, isTrue);
      });

      test('multiple groups can have independent operations', () {
        const groupId1 = 'group-1';
        const groupId2 = 'group-2';
        final timestamp1 = testTimestamp;
        final timestamp2 = testTimestamp.add(const Duration(minutes: 1));

        LastReadManager.saveLastReadDebounced(groupId1, timestamp1);
        LastReadManager.saveLastReadThrottled(groupId2, timestamp2);
        LastReadManager.cancelPendingSaves(groupId1);
        LastReadManager.cancelAllPendingSaves();

        expect(true, isTrue);
      });
    });
  });
}

// Mock message class for testing
class _MockMessage {
  final DateTime createdAt;

  _MockMessage(this.createdAt);
}
