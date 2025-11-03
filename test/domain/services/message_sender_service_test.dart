import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/services/message_sender_service.dart';
import 'package:whitenoise/domain/services/nostr_tag_builder_service.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart';

import '../../shared/mocks/mock_tag_test_helpers.dart';

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

    return MessageWithTokens(
      id: 'test-id',
      pubkey: pubkey,
      kind: kind,
      createdAt: DateTime.now(),
      content: message,
      tokens: [],
    );
  };
}

void main() {
  group('MessageSenderService', () {
    group('sendMessage', () {
      group('without media files', () {
        late List<SendMessageCall> capturedCalls;
        late List<List<String>> capturedTags;
        late MessageSenderService service;

        setUp(() async {
          capturedCalls = <SendMessageCall>[];
          capturedTags = <List<String>>[];
          service = MessageSenderService(
            tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
            sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
          );
          await service.sendMessage(
            pubkey: 'test-pubkey',
            groupId: 'test-group-id',
            content: 'Hello, world!',
            mediaFiles: [],
          );
        });

        test('calls send message', () async {
          expect(capturedCalls.length, 1);
        });

        test('sends message with expected pubkey', () async {
          final call = capturedCalls.first;
          expect(call.pubkey, 'test-pubkey');
        });

        test('sends message with expected group id', () async {
          final call = capturedCalls.first;
          expect(call.groupId, 'test-group-id');
        });

        test('sends message with expected content', () async {
          final call = capturedCalls.first;
          expect(call.message, 'Hello, world!');
        });

        test('sends kind 9 message', () async {
          final call = capturedCalls.first;
          expect(call.kind, 9);
        });

        test('sends message with empty tags', () async {
          final call = capturedCalls.first;
          expect(call.tags, isEmpty);
        });
      });

      group('with single media file', () {
        late List<SendMessageCall> capturedCalls;
        late List<List<String>> capturedTags;
        late MessageSenderService service;
        final mediaFile = MediaFile(
          id: 'media-1',
          mlsGroupId: 'test-group-id',
          accountPubkey: 'test-pubkey',
          filePath: '/path/to/image.jpg',
          originalFileHash: 'abc123hash',
          encryptedFileHash: 'test-encrypted-hash',
          mimeType: 'image/jpeg',
          mediaType: 'image',
          blossomUrl: 'https://blossom.example.com/abc123',
          nostrKey: 'nostr-key-1',
          createdAt: DateTime(2024),
        );

        setUp(() async {
          capturedCalls = <SendMessageCall>[];
          capturedTags = <List<String>>[];
          service = MessageSenderService(
            tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
            sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
          );
          await service.sendMessage(
            pubkey: 'test-pubkey',
            groupId: 'test-group-id',
            content: 'Hello, world!',
            mediaFiles: [mediaFile],
          );
        });

        test('calls send message with one tag', () async {
          final call = capturedCalls.first;
          expect(call.tags?.length, 1);
        });

        test('media tag has expected values', () async {
          final mediaTag = capturedTags.first;
          expect(
            mediaTag,
            equals([
              'imeta',
              'url https://blossom.example.com/abc123',
              'm image/jpeg',
              'x abc123hash',
            ]),
          );
        });
      });

      group('with multiple media files', () {
        late List<SendMessageCall> capturedCalls;
        late List<List<String>> capturedTags;
        late MessageSenderService service;
        final mediaFile1 = MediaFile(
          id: 'media-1',
          mlsGroupId: 'test-group-id-1',
          accountPubkey: 'test-pubkey1',
          filePath: '/path/to/image1.jpg',
          originalFileHash: 'abc123hash1',
          encryptedFileHash: 'test-encrypted-hash1',
          mimeType: 'image/jpeg',
          mediaType: 'image',
          blossomUrl: 'https://blossom.example.com/abc123',
          nostrKey: 'nostr-key-1',
          createdAt: DateTime(2024),
        );

        final mediaFile2 = MediaFile(
          id: 'media-2',
          mlsGroupId: 'test-group-id-2',
          accountPubkey: 'test-pubkey2',
          filePath: '/path/to/image2.jpg',
          originalFileHash: 'def345hash2',
          encryptedFileHash: 'test-encrypted-hash2',
          mimeType: 'image/jpeg',
          mediaType: 'image',
          blossomUrl: 'https://blossom.example.com/def345',
          nostrKey: 'nostr-key-2',
          createdAt: DateTime(2025),
        );

        setUp(() async {
          capturedCalls = <SendMessageCall>[];
          capturedTags = <List<String>>[];
          service = MessageSenderService(
            tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
            sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
          );
          await service.sendMessage(
            pubkey: 'test-pubkey',
            groupId: 'test-group-id',
            content: 'Hello, world!',
            mediaFiles: [mediaFile1, mediaFile2],
          );
        });

        test('calls send message with expected number of tags', () async {
          final call = capturedCalls.first;
          expect(call.tags?.length, 2);
        });

        test('first media tag has expected values', () async {
          final mediaTag = capturedTags.first;
          expect(
            mediaTag,
            equals([
              'imeta',
              'url https://blossom.example.com/abc123',
              'm image/jpeg',
              'x abc123hash1',
            ]),
          );
        });

        test('second media tag has expected values', () async {
          final mediaTag = capturedTags.last;
          expect(
            mediaTag,
            equals([
              'imeta',
              'url https://blossom.example.com/def345',
              'm image/jpeg',
              'x def345hash2',
            ]),
          );
        });
      });

      group('with empty content and media', () {
        late List<SendMessageCall> capturedCalls;
        late List<List<String>> capturedTags;
        late MessageSenderService service;
        final mediaFile = MediaFile(
          id: 'media-1',
          mlsGroupId: 'test-group-id',
          accountPubkey: 'test-pubkey',
          filePath: '/path/to/image.jpg',
          originalFileHash: 'abc123hash',
          encryptedFileHash: 'test-encrypted-hash',
          mimeType: 'image/jpeg',
          mediaType: 'image',
          blossomUrl: 'https://blossom.example.com/abc123',
          nostrKey: 'nostr-key-1',
          createdAt: DateTime(2024),
        );

        setUp(() async {
          capturedCalls = <SendMessageCall>[];
          capturedTags = <List<String>>[];
          service = MessageSenderService(
            tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
            sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
          );
          await service.sendMessage(
            pubkey: 'test-pubkey',
            groupId: 'test-group-id',
            content: '',
            mediaFiles: [mediaFile],
          );
        });

        test('calls send message', () async {
          expect(capturedCalls.length, 1);
        });

        test('sends message with empty content', () async {
          final call = capturedCalls.first;
          expect(call.message, '');
        });

        test('sends message with one media tag', () async {
          final call = capturedCalls.first;
          expect(call.tags?.length, 1);
        });
      });
      test('returns MessageWithTokens from rust API', () async {
        final capturedCalls = <SendMessageCall>[];
        final capturedTags = <List<String>>[];
        final expectedResult = MessageWithTokens(
          id: 'result-id',
          pubkey: 'test-pubkey',
          kind: 9,
          createdAt: DateTime(2024),
          content: 'Test',
          tokens: const [],
        );

        final service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(
            capturedCalls,
            (_) => expectedResult,
          ),
        );

        final result = await service.sendMessage(
          pubkey: 'test-pubkey',
          groupId: 'test-group-id',
          content: 'Test',
          mediaFiles: [],
        );

        expect(result, expectedResult);
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
        final expectedResult = MessageWithTokens(
          id: 'reaction-id',
          pubkey: 'reactor-pubkey',
          kind: 7,
          createdAt: DateTime(2024),
          content: '👍',
          tokens: const [],
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
      late List<SendMessageCall> capturedCalls;
      late List<List<String>> capturedTags;
      late MessageSenderService service;

      setUp(() {
        capturedCalls = <SendMessageCall>[];
        capturedTags = <List<String>>[];
        service = MessageSenderService(
          tagBuilder: NostrTagBuilderService(tagFromVecFn: mockTagFromVec(capturedTags)),
          sendMessageToGroupFn: mockSendMessageToGroup(capturedCalls, null),
        );
      });

      test('sends reply with kind 9', () async {
        await service.sendReply(
          pubkey: 'replier-pubkey',
          groupId: 'test-group',
          replyToMessageId: 'original-msg-id',
          content: 'This is a reply',
          mediaFiles: [],
        );

        expect(capturedCalls.length, 1);
        final call = capturedCalls.first;
        expect(call.kind, 9); // Standard message kind
        expect(call.message, 'This is a reply');
      });

      test('builds correct reply tags', () async {
        await service.sendReply(
          pubkey: 'replier-pubkey',
          groupId: 'test-group',
          replyToMessageId: 'original-msg-id',
          content: 'Reply content',
          mediaFiles: [],
        );
        expect(capturedTags.length, 1);
        final eTag = capturedTags.first;
        expect(eTag[0], 'e');
        expect(eTag[1], 'original-msg-id');
      });

      test('passes all parameters correctly', () async {
        await service.sendReply(
          pubkey: 'my-pubkey',
          groupId: 'group-789',
          replyToMessageId: 'msg-to-reply',
          content: 'My reply',
          mediaFiles: [],
        );

        final call = capturedCalls.first;
        expect(call.pubkey, 'my-pubkey');
        expect(call.groupId, 'group-789');
        expect(call.message, 'My reply');
      });

      test('returns MessageWithTokens from rust API', () async {
        final expectedResult = MessageWithTokens(
          id: 'reply-id',
          pubkey: 'replier-pubkey',
          kind: 9,
          createdAt: DateTime(2024),
          content: 'Reply',
          tokens: const [],
        );

        service = MessageSenderService(
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
          mediaFiles: [],
        );

        expect(result, expectedResult);
      });

      test('handles empty reply content', () async {
        await service.sendReply(
          pubkey: 'test-pubkey',
          groupId: 'test-group',
          replyToMessageId: 'msg-id',
          content: '',
          mediaFiles: [],
        );

        expect(capturedCalls.first.message, '');
      });

      group('with media files', () {
        group('with single media file', () {
          final mediaFile = MediaFile(
            id: 'media-1',
            mlsGroupId: 'test-group-id',
            accountPubkey: 'test-pubkey',
            filePath: '/path/to/image.jpg',
            originalFileHash: 'abc123hash',
            encryptedFileHash: 'test-encrypted-hash',
            mimeType: 'image/jpeg',
            mediaType: 'image',
            blossomUrl: 'https://blossom.example.com/abc123',
            nostrKey: 'nostr-key-1',
            createdAt: DateTime(2024),
          );

          group('with content', () {
            setUp(() async {
              await service.sendReply(
                pubkey: 'test-pubkey',
                groupId: 'test-group',
                replyToMessageId: 'original-msg-id',
                content: 'Reply with media',
                mediaFiles: [mediaFile],
              );
            });

            test('sends message with 2 tags', () async {
              final call = capturedCalls.first;
              expect(call.tags?.length, 2);
            });

            test('first tag is reply tag', () async {
              final replyTag = capturedTags.first;
              expect(
                replyTag,
                equals([
                  'e',
                  'original-msg-id',
                ]),
              );
            });

            test('second tag is media tag', () async {
              final mediaTag = capturedTags.last;
              expect(
                mediaTag,
                equals([
                  'imeta',
                  'url https://blossom.example.com/abc123',
                  'm image/jpeg',
                  'x abc123hash',
                ]),
              );
            });
          });
          group('with empty content', () {
            setUp(() async {
              await service.sendReply(
                pubkey: 'test-pubkey',
                groupId: 'test-group',
                replyToMessageId: 'original-msg-id',
                content: '',
                mediaFiles: [mediaFile],
              );
            });

            test('sends message with 2 tags', () async {
              final call = capturedCalls.first;
              expect(call.tags?.length, 2);
            });

            test('first tag is reply tag', () async {
              final replyTag = capturedTags.first;
              expect(
                replyTag,
                equals([
                  'e',
                  'original-msg-id',
                ]),
              );
            });

            test('second tag is media tag', () async {
              final mediaTag = capturedTags.last;
              expect(
                mediaTag,
                equals([
                  'imeta',
                  'url https://blossom.example.com/abc123',
                  'm image/jpeg',
                  'x abc123hash',
                ]),
              );
            });
          });
        });
      });

      group('with multiple media files', () {
        final mediaFile1 = MediaFile(
          id: 'media-1',
          mlsGroupId: 'test-group-id',
          accountPubkey: 'test-pubkey',
          filePath: '/path/to/image1.jpg',
          originalFileHash: 'hash1',
          encryptedFileHash: 'test-encrypted-hash1',
          mimeType: 'image/jpeg',
          mediaType: 'image',
          blossomUrl: 'https://blossom.example.com/hash1',
          nostrKey: 'nostr-key-1',
          createdAt: DateTime(2024),
        );
        final mediaFile2 = MediaFile(
          id: 'media-2',
          mlsGroupId: 'test-group-id',
          accountPubkey: 'test-pubkey',
          filePath: '/path/to/image2.jpg',
          originalFileHash: 'hash2',
          encryptedFileHash: 'test-encrypted-hash2',
          mimeType: 'image/png',
          mediaType: 'image',
          blossomUrl: 'https://blossom.example.com/hash2',
          nostrKey: 'nostr-key-2',
          createdAt: DateTime(2025),
        );
        setUp(() async {
          await service.sendReply(
            pubkey: 'test-pubkey',
            groupId: 'test-group',
            replyToMessageId: 'original-msg-id',
            content: '',
            mediaFiles: [mediaFile1, mediaFile2],
          );
        });

        test('sends message with expected tags amount', () async {
          final call = capturedCalls.first;
          expect(call.tags?.length, 3);
        });

        test('first tag is reply tag', () async {
          final replyTag = capturedTags.first;
          expect(
            replyTag,
            equals([
              'e',
              'original-msg-id',
            ]),
          );
        });

        test('second tag is media tag', () async {
          final mediaTag = capturedTags[1];
          expect(
            mediaTag,
            equals([
              'imeta',
              'url https://blossom.example.com/hash1',
              'm image/jpeg',
              'x hash1',
            ]),
          );
        });

        test('third tag is media tag', () async {
          final mediaTag = capturedTags[2];
          expect(
            mediaTag,
            equals([
              'imeta',
              'url https://blossom.example.com/hash2',
              'm image/png',
              'x hash2',
            ]),
          );
        });
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
        final expectedResult = MessageWithTokens(
          id: 'deletion-id',
          pubkey: 'deleter-pubkey',
          kind: 5,
          createdAt: DateTime(2024),
          content: '',
          tokens: const [],
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
            mediaFiles: [],
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
