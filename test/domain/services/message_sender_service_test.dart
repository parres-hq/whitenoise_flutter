import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/services/message_sender_service.dart';
import 'package:whitenoise/domain/services/nostr_tag_builder_service.dart';
import 'package:whitenoise/src/rust/api/messages.dart';

import '../../shared/mocks/mock_tag_test_helpers.dart';

class MockMessageWithTokens implements MessageWithTokens {
  @override
  final String id;
  @override
  final String pubkey;
  @override
  final int kind;
  @override
  final DateTime createdAt;
  @override
  final String? content;
  @override
  final List<SerializableToken> tokens;

  MockMessageWithTokens({
    required this.id,
    required this.pubkey,
    required this.kind,
    required this.createdAt,
    this.content,
    this.tokens = const [],
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SendMessageCall {
  final String pubkey;
  final String groupId;
  final String message;
  final int kind;
  final List<Tag>? tags;

  SendMessageCall({
    required this.pubkey,
    required this.groupId,
    required this.message,
    required this.kind,
    this.tags,
  });
}

Future<MessageWithTokens> Function({
  required String pubkey,
  required String groupId,
  required String message,
  required int kind,
  List<Tag>? tags,
})
mockSendMessageToGroup(
  List<SendMessageCall> capturedCalls,
  MessageWithTokens Function(SendMessageCall)? resultFactory,
) {
  return ({
    required String pubkey,
    required String groupId,
    required String message,
    required int kind,
    List<Tag>? tags,
  }) async {
    final call = SendMessageCall(
      pubkey: pubkey,
      groupId: groupId,
      message: message,
      kind: kind,
      tags: tags,
    );
    capturedCalls.add(call);

    if (resultFactory != null) {
      return resultFactory(call);
    }

    return MockMessageWithTokens(
      id: 'test-id',
      pubkey: pubkey,
      kind: kind,
      createdAt: DateTime.now(),
      content: message,
    );
  };
}

void main() {
  group('MessageSenderService', () {
    group('sendMessage', () {
      test('sends message with correct parameters', () async {
        final capturedCalls = <SendMessageCall>[];
        final service = MessageSenderService(
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );

        await service.sendMessage(
          pubkey: 'test-pubkey',
          groupId: 'test-group-id',
          content: 'Hello, world!',
        );

        expect(capturedCalls.length, 1);
        final call = capturedCalls.first;
        expect(call.pubkey, 'test-pubkey');
        expect(call.groupId, 'test-group-id');
        expect(call.message, 'Hello, world!');
        expect(call.kind, 9);
        expect(call.tags, isNull);
      });

      test('passes custom tags when provided', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];
        final customTags = [
          await mockTagFromVec(capturedTags)(vec: ['custom', 'tag']),
        ];

        final service = MessageSenderService(
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );

        await service.sendMessage(
          pubkey: 'test-pubkey',
          groupId: 'test-group-id',
          content: 'Message with tags',
          tags: customTags,
        );

        expect(capturedCalls.first.tags, customTags);
      });
      test('returns MessageWithTokens from rust API', () async {
        final capturedCalls = <SendMessageCall>[];
        final expectedResult = MockMessageWithTokens(
          id: 'result-id',
          pubkey: 'test-pubkey',
          kind: 9,
          createdAt: DateTime(2024),
          content: 'Test',
        );

        final service = MessageSenderService(
          sendMessageToGroupFn: mockSendMessageToGroup(
            capturedCalls,
            (_) => expectedResult,
          ),
        );

        final result = await service.sendMessage(
          pubkey: 'test-pubkey',
          groupId: 'test-group-id',
          content: 'Test',
        );

        expect(result, expectedResult);
      });

      test('handles empty content', () async {
        final capturedCalls = <SendMessageCall>[];
        final service = MessageSenderService(
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );

        await service.sendMessage(
          pubkey: 'test-pubkey',
          groupId: 'test-group-id',
          content: '',
        );

        expect(capturedCalls.first.message, '');
      });
    });

    group('sendReaction', () {
      test('sends reaction with kind 7', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];

        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );

        await service.sendReaction(
          pubkey: 'reactor-pubkey',
          groupId: 'test-group',
          messageId: 'msg-123',
          messagePubkey: 'author-pubkey',
          messageKind: 9,
          emoji: '👍',
        );

        expect(capturedCalls.length, 1);
        final call = capturedCalls.first;
        expect(call.kind, 7);
        expect(call.message, '👍');
      });

      test('builds correct reaction tags', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];

        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );

        await service.sendReaction(
          pubkey: 'reactor-pubkey',
          groupId: 'test-group',
          messageId: 'msg-123',
          messagePubkey: 'author-pubkey',
          messageKind: 9,
          emoji: '❤️',
        );

        // Verify reaction tags were created (e, p, k)
        expect(capturedTags.length, 3);
        final eTag = capturedTags.firstWhere((tag) => tag[0] == 'e');
        final pTag = capturedTags.firstWhere((tag) => tag[0] == 'p');
        final kTag = capturedTags.firstWhere((tag) => tag[0] == 'k');

        expect(eTag[1], 'msg-123');
        expect(pTag[1], 'author-pubkey');
        expect(kTag[1], '9');
      });

      test('passes all parameters correctly', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];

        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );

        await service.sendReaction(
          pubkey: 'my-pubkey',
          groupId: 'group-456',
          messageId: 'msg-789',
          messagePubkey: 'other-pubkey',
          messageKind: 1,
          emoji: '🎉',
        );

        final call = capturedCalls.first;
        expect(call.pubkey, 'my-pubkey');
        expect(call.groupId, 'group-456');
        expect(call.message, '🎉');
      });

      test('returns MessageWithTokens from rust API', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];
        final expectedResult = MockMessageWithTokens(
          id: 'reaction-id',
          pubkey: 'reactor-pubkey',
          kind: 7,
          createdAt: DateTime(2024),
          content: '👍',
        );

        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(
            capturedCalls,
            (_) => expectedResult,
          ),
        );

        final result = await service.sendReaction(
          pubkey: 'reactor-pubkey',
          groupId: 'test-group',
          messageId: 'msg-123',
          messagePubkey: 'author-pubkey',
          messageKind: 9,
          emoji: '👍',
        );

        expect(result, expectedResult);
      });

      test('handles different emoji reactions', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];

        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );

        final emojis = ['👍', '❤️', '😂', '🎉', '🔥'];

        for (final emoji in emojis) {
          await service.sendReaction(
            pubkey: 'test-pubkey',
            groupId: 'test-group',
            messageId: 'msg-id',
            messagePubkey: 'author',
            messageKind: 9,
            emoji: emoji,
          );
        }

        expect(capturedCalls.length, emojis.length);
        for (var i = 0; i < emojis.length; i++) {
          expect(capturedCalls[i].message, emojis[i]);
        }
      });
    });

    group('sendReply', () {
      test('sends reply with kind 9', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];

        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );

        await service.sendReply(
          pubkey: 'replier-pubkey',
          groupId: 'test-group',
          replyToMessageId: 'original-msg-id',
          content: 'This is a reply',
        );

        expect(capturedCalls.length, 1);
        final call = capturedCalls.first;
        expect(call.kind, 9); // Standard message kind
        expect(call.message, 'This is a reply');
      });

      test('builds correct reply tags', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];

        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );

        await service.sendReply(
          pubkey: 'replier-pubkey',
          groupId: 'test-group',
          replyToMessageId: 'original-msg-id',
          content: 'Reply content',
        );
        expect(capturedTags.length, 1);
        final eTag = capturedTags.first;
        expect(eTag[0], 'e');
        expect(eTag[1], 'original-msg-id');
      });

      test('passes all parameters correctly', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];

        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );

        await service.sendReply(
          pubkey: 'my-pubkey',
          groupId: 'group-789',
          replyToMessageId: 'msg-to-reply',
          content: 'My reply',
        );

        final call = capturedCalls.first;
        expect(call.pubkey, 'my-pubkey');
        expect(call.groupId, 'group-789');
        expect(call.message, 'My reply');
      });

      test('returns MessageWithTokens from rust API', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];
        final expectedResult = MockMessageWithTokens(
          id: 'reply-id',
          pubkey: 'replier-pubkey',
          kind: 9,
          createdAt: DateTime(2024),
          content: 'Reply',
        );

        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(
            capturedCalls,
            (_) => expectedResult,
          ),
        );

        final result = await service.sendReply(
          pubkey: 'replier-pubkey',
          groupId: 'test-group',
          replyToMessageId: 'original-msg',
          content: 'Reply',
        );

        expect(result, expectedResult);
      });

      test('handles empty reply content', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];

        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );

        await service.sendReply(
          pubkey: 'test-pubkey',
          groupId: 'test-group',
          replyToMessageId: 'msg-id',
          content: '',
        );

        expect(capturedCalls.first.message, '');
      });
    });

    group('sendDeletion', () {
      test('sends deletion with kind 5', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];

        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );

        await service.sendDeletion(
          pubkey: 'deleter-pubkey',
          groupId: 'test-group',
          messageId: 'msg-to-delete',
          messagePubkey: 'author-pubkey',
          messageKind: 9,
        );

        expect(capturedCalls.length, 1);
        final call = capturedCalls.first;
        expect(call.kind, 5); // Deletion kind
        expect(call.message, ''); // Empty content for deletions
      });

      test('builds correct deletion tags', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];

        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );

        await service.sendDeletion(
          pubkey: 'deleter-pubkey',
          groupId: 'test-group',
          messageId: 'msg-to-delete',
          messagePubkey: 'author-pubkey',
          messageKind: 9,
        );

        // Verify deletion tags were created (e, p, k)
        expect(capturedTags.length, 3);
        final eTag = capturedTags.firstWhere((tag) => tag[0] == 'e');
        final pTag = capturedTags.firstWhere((tag) => tag[0] == 'p');
        final kTag = capturedTags.firstWhere((tag) => tag[0] == 'k');

        expect(eTag[1], 'msg-to-delete');
        expect(pTag[1], 'author-pubkey');
        expect(kTag[1], '9');
      });

      test('passes all parameters correctly', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];

        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );

        await service.sendDeletion(
          pubkey: 'my-pubkey',
          groupId: 'group-999',
          messageId: 'delete-this',
          messagePubkey: 'other-pubkey',
          messageKind: 7,
        );

        final call = capturedCalls.first;
        expect(call.pubkey, 'my-pubkey');
        expect(call.groupId, 'group-999');
        expect(call.message, '');
      });

      test('returns MessageWithTokens from rust API', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];
        final expectedResult = MockMessageWithTokens(
          id: 'deletion-id',
          pubkey: 'deleter-pubkey',
          kind: 5,
          createdAt: DateTime(2024),
          content: '',
        );

        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(
            capturedCalls,
            (_) => expectedResult,
          ),
        );

        final result = await service.sendDeletion(
          pubkey: 'deleter-pubkey',
          groupId: 'test-group',
          messageId: 'msg-to-delete',
          messagePubkey: 'author-pubkey',
          messageKind: 9,
        );

        expect(result, expectedResult);
      });

      test('handles deletion of different message kinds', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];

        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );

        final kinds = [1, 7, 9, 42];

        for (final kind in kinds) {
          await service.sendDeletion(
            pubkey: 'test-pubkey',
            groupId: 'test-group',
            messageId: 'msg-id-$kind',
            messagePubkey: 'author',
            messageKind: kind,
          );
        }

        expect(capturedCalls.length, kinds.length);
        for (final call in capturedCalls) {
          expect(call.kind, 5);
        }

        for (var i = 0; i < kinds.length; i++) {
          final tagOffset = i * 3; // Each deletion creates 3 tags
          final kTag = capturedTags[tagOffset + 2];
          expect(kTag[0], 'k');
          expect(kTag[1], kinds[i].toString());
        }
      });
    });
    group('error handling', () {
      test('propagates errors from sendMessageToGroup', () async {
        final service = MessageSenderService(
          sendMessageToGroupFn: ({
            required String pubkey,
            required String groupId,
            required String message,
            required int kind,
            List<Tag>? tags,
          }) async {
            throw Exception('Network error');
          },
        );

        expect(
          () => service.sendMessage(
            pubkey: 'test',
            groupId: 'test',
            content: 'test',
          ),
          throwsException,
        );
      });

      test('propagates errors from tag builder', () async {
        final capturedCalls = <SendMessageCall>[];
        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(
            tagFromVecFn: ({required List<String> vec}) async {
              throw Exception('Tag creation failed');
            },
          ),
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );

        expect(
          () => service.sendReaction(
            pubkey: 'test',
            groupId: 'test',
            messageId: 'test',
            messagePubkey: 'test',
            messageKind: 9,
            emoji: '👍',
          ),
          throwsException,
        );
      });
    });
  });
}
