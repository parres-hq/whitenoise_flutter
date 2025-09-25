import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/domain/services/message_filter_service.dart';

void main() {
  group('MessageFilterService', () {
    group('getRecentSendingMessages', () {
      test('returns empty list when no sending messages exist', () {
        final currentMessages = [
          _createMessage(
            id: '1',
            content: 'sent message',
            createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
          ),
        ];
        final newMessages = [
          _createMessage(
            id: '2',
            content: 'server message',
            createdAt: DateTime.now(),
          ),
        ];

        final result = MessageFilterService.getRecentSendingMessages(
          currentMessages: currentMessages,
          newMessages: newMessages,
        );

        expect(result, isEmpty);
      });

      test('returns empty list when new messages list is empty', () {
        final currentMessages = [
          _createMessage(
            id: '1',
            content: 'sending message',
            status: MessageStatus.sending,
            createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
          ),
        ];
        final newMessages = <MessageModel>[];

        final result = MessageFilterService.getRecentSendingMessages(
          currentMessages: currentMessages,
          newMessages: newMessages,
        );

        expect(result, isEmpty);
      });

      test('preserves recent sending message with different content', () {
        final now = DateTime.now();
        final recentTime = now.subtract(const Duration(seconds: 30));

        final currentMessages = [
          _createMessage(
            id: '1',
            content: 'sending different message',
            status: MessageStatus.sending,
            createdAt: recentTime,
          ),
        ];
        final newMessages = [
          _createMessage(
            id: '2',
            content: 'server message',
            createdAt: now,
          ),
        ];

        final result = MessageFilterService.getRecentSendingMessages(
          currentMessages: currentMessages,
          newMessages: newMessages,
        );

        expect(result, hasLength(1));
        expect(result.first.id, equals('1'));
        expect(result.first.content, equals('sending different message'));
        expect(result.first.status, equals(MessageStatus.sending));
      });

      test('does not preserve old sending message even with different content', () {
        final now = DateTime.now();
        final oldTime = now.subtract(const Duration(minutes: 2)); // Older than 1 minute

        final currentMessages = [
          _createMessage(
            id: '1',
            content: 'old sending message',
            status: MessageStatus.sending,
            createdAt: oldTime,
          ),
        ];
        final newMessages = [
          _createMessage(
            id: '2',
            content: 'server message',
            createdAt: now,
          ),
        ];

        // Act
        final result = MessageFilterService.getRecentSendingMessages(
          currentMessages: currentMessages,
          newMessages: newMessages,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('does not preserve recent sending message with same content', () {
        // Arrange
        final now = DateTime.now();
        final recentTime = now.subtract(const Duration(seconds: 30));

        final currentMessages = [
          _createMessage(
            id: '1',
            content: 'same message',
            status: MessageStatus.sending,
            createdAt: recentTime,
          ),
        ];
        final newMessages = [
          _createMessage(
            id: '2',
            content: 'same message',
            createdAt: now,
          ),
        ];

        final result = MessageFilterService.getRecentSendingMessages(
          currentMessages: currentMessages,
          newMessages: newMessages,
        );

        expect(result, isEmpty);
      });

      test('handles whitespace differences in content comparison', () {
        final now = DateTime.now();
        final recentTime = now.subtract(const Duration(seconds: 30));

        final currentMessages = [
          _createMessage(
            id: '1',
            content: '  same message  ',
            status: MessageStatus.sending,
            createdAt: recentTime,
          ),
        ];
        final newMessages = [
          _createMessage(
            id: '2',
            content: 'same message',
            createdAt: now,
          ),
        ];

        final result = MessageFilterService.getRecentSendingMessages(
          currentMessages: currentMessages,
          newMessages: newMessages,
        );

        expect(result, isEmpty);
      });

      test('preserves multiple recent sending messages with different content', () {
        final now = DateTime.now();
        final recentTime1 = now.subtract(const Duration(seconds: 30));
        final recentTime2 = now.subtract(const Duration(seconds: 45));

        final currentMessages = [
          _createMessage(
            id: '1',
            content: 'first sending message',
            status: MessageStatus.sending,
            createdAt: recentTime1,
          ),
          _createMessage(
            id: '2',
            content: 'second sending message',
            status: MessageStatus.sending,
            createdAt: recentTime2,
          ),
        ];
        final newMessages = [
          _createMessage(
            id: '3',
            content: 'server message',
            createdAt: now,
          ),
        ];

        final result = MessageFilterService.getRecentSendingMessages(
          currentMessages: currentMessages,
          newMessages: newMessages,
        );

        expect(result, hasLength(2));
        expect(result.map((m) => m.id), containsAll(['1', '2']));
      });

      test('respects custom preservation duration', () {
        final now = DateTime.now();
        final customTime = now.subtract(const Duration(minutes: 2, seconds: 30)); // 2.5 minutes ago

        final currentMessages = [
          _createMessage(
            id: '1',
            content: 'old sending message',
            status: MessageStatus.sending,
            createdAt: customTime,
          ),
        ];
        final newMessages = [
          _createMessage(
            id: '2',
            content: 'server message',
            createdAt: now,
          ),
        ];

        // Act - with 3 minute preservation duration
        final result = MessageFilterService.getRecentSendingMessages(
          currentMessages: currentMessages,
          newMessages: newMessages,
          preservationDuration: const Duration(minutes: 3),
        );

        // Assert
        expect(result, hasLength(1));
        expect(result.first.id, equals('1'));
      });
    });
  });
}

/// Helper function to create a test MessageModel
MessageModel _createMessage({
  required String id,
  String content = 'test content',
  MessageStatus status = MessageStatus.sent,
  DateTime? createdAt,
}) {
  return MessageModel(
    id: id,
    content: content,
    type: MessageType.text,
    status: status,
    createdAt: createdAt ?? DateTime.now(),
    sender: User(
      id: 'test_id',
      publicKey: 'test_pubkey',
      displayName: 'Test User',
      nip05: '',
    ),
    isMe: false,
    reactions: [],
  );
}
