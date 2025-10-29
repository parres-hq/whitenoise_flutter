import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart' as domain_user;
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
import 'package:whitenoise/utils/message_converter.dart';

bool mockPubkeyUtilsIsMe({required String myPubkey, required String otherPubkey}) {
  return myPubkey == otherPubkey;
}

void main() {
  group('MessageConverter Tests', () {
    final currentUserPublicKey = 'npub1zg69v7ys40x77y352eufp27daufrg4ncjz4ummcjx3t83y9tehhsqepuh0';
    final otherUserPublicKey = 'npub140x77y352eufp27daufrg4ncjz4ummcjx3t83y9tehh3ydzk0zgqwxq8j0';
    final groupId = 'group_123';

    final currentUser = domain_user.User(
      id: currentUserPublicKey,
      displayName: 'Current User',
      nip05: 'current@example.com',
      publicKey: currentUserPublicKey,
    );

    final otherUser = domain_user.User(
      id: otherUserPublicKey,
      displayName: 'Other User',
      nip05: 'other@example.com',
      publicKey: otherUserPublicKey,
    );

    final usersMap = <String, domain_user.User>{
      currentUserPublicKey: currentUser,
      otherUserPublicKey: otherUser,
    };

    group('fromChatMessage', () {
      group('when message is from current user', () {
        final chatMessage = ChatMessage(
          id: 'msg_123',
          pubkey: currentUserPublicKey,
          content: 'Hello world!',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1234567890000),
          tags: [],
          isReply: false,
          isDeleted: false,
          contentTokens: [],
          reactions: const ReactionSummary(byEmoji: [], userReactions: []),
          mediaAttachments: [],
          kind: 9,
        );

        test('converts to MessageModel with isMe true and sent status', () {
          final result = MessageConverter.fromChatMessage(
            chatMessage,
            currentUserPublicKey: currentUserPublicKey,
            groupId: groupId,
            usersMap: usersMap,
            isMeFn: mockPubkeyUtilsIsMe,
          );

          expect(result.id, 'msg_123');
          expect(result.content, 'Hello world!');
          expect(result.type, MessageType.text);
          expect(result.createdAt, DateTime.fromMillisecondsSinceEpoch(1234567890000));
          expect(result.sender, currentUser);
          expect(result.isMe, true);
          expect(result.groupId, groupId);
          expect(result.status, MessageStatus.sent);
          expect(result.kind, 9);
          expect(result.reactions, isEmpty);
          expect(result.replyTo, isNull);
        });
      });

      group('when message is from other user', () {
        final chatMessage = ChatMessage(
          id: 'msg_456',
          pubkey: otherUserPublicKey,
          content: 'How are you?',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1234567891000),
          tags: [],
          isReply: false,
          isDeleted: false,
          contentTokens: [],
          reactions: const ReactionSummary(byEmoji: [], userReactions: []),
          mediaAttachments: [],
          kind: 9,
        );

        test('converts to MessageModel with isMe false and delivered status', () {
          final result = MessageConverter.fromChatMessage(
            chatMessage,
            currentUserPublicKey: currentUserPublicKey,
            groupId: groupId,
            usersMap: usersMap,
            isMeFn: mockPubkeyUtilsIsMe,
          );

          expect(result.id, 'msg_456');
          expect(result.content, 'How are you?');
          expect(result.sender, otherUser);
          expect(result.isMe, false);
          expect(result.status, MessageStatus.delivered);
        });
      });

      group('when message is from unknown user', () {
        final unknownUserPubkey =
            'fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321';
        final chatMessage = ChatMessage(
          id: 'msg_789',
          pubkey: unknownUserPubkey,
          content: 'Hello from unknown',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1234567892000),
          tags: [],
          isReply: false,
          isDeleted: false,
          contentTokens: [],
          reactions: const ReactionSummary(byEmoji: [], userReactions: []),
          mediaAttachments: [],
          kind: 9,
        );

        test('converts to MessageModel with unknown user', () {
          final result = MessageConverter.fromChatMessage(
            chatMessage,
            currentUserPublicKey: currentUserPublicKey,
            groupId: groupId,
            usersMap: usersMap,
            isMeFn: mockPubkeyUtilsIsMe,
          );

          expect(result.sender.id, unknownUserPubkey);
          expect(result.sender.displayName, 'shared.unknownUser'.tr());
          expect(result.sender.nip05, '');
          expect(result.sender.publicKey, unknownUserPubkey);
        });
      });

      group('when message has reactions', () {
        final userReaction = UserReaction(
          user: otherUserPublicKey,
          emoji: '👍',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1234567893000),
        );

        final chatMessage = ChatMessage(
          id: 'msg_with_reactions',
          pubkey: currentUserPublicKey,
          content: 'Message with reactions',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1234567890000),
          tags: [],
          isReply: false,
          isDeleted: false,
          contentTokens: [],
          reactions: ReactionSummary(byEmoji: [], userReactions: [userReaction]),
          mediaAttachments: [],
          kind: 9,
        );

        test('converts reactions correctly', () {
          final result = MessageConverter.fromChatMessage(
            chatMessage,
            currentUserPublicKey: currentUserPublicKey,
            groupId: groupId,
            usersMap: usersMap,
            isMeFn: mockPubkeyUtilsIsMe,
          );

          expect(result.reactions, hasLength(1));
          final reaction = result.reactions[0];
          expect(reaction.emoji, '👍');
          expect(reaction.user, otherUser);
        });
      });

      group('when message has media files', () {
        final testMediaFile1 = MediaFile(
          id: 'media1',
          mlsGroupId: groupId,
          accountPubkey: currentUserPublicKey,
          filePath: '/path/to/image1.jpg',
          fileHash: 'hash1',
          mimeType: 'image/jpeg',
          mediaType: 'image',
          blossomUrl: 'https://example.com/image1.jpg',
          nostrKey: 'nostr_key1',
          createdAt: DateTime(2024),
        );

        final testMediaFile2 = MediaFile(
          id: 'media2',
          mlsGroupId: groupId,
          accountPubkey: currentUserPublicKey,
          filePath: '/path/to/image2.jpg',
          fileHash: 'hash2',
          mimeType: 'image/jpeg',
          mediaType: 'image',
          blossomUrl: 'https://example.com/image2.jpg',
          nostrKey: 'nostr_key2',
          createdAt: DateTime(2024, 1, 2),
        );

        final chatMessage = ChatMessage(
          id: 'msg_with_media',
          pubkey: currentUserPublicKey,
          content: 'Message with media',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1234567890000),
          tags: [],
          isReply: false,
          isDeleted: false,
          contentTokens: [],
          reactions: const ReactionSummary(byEmoji: [], userReactions: []),
          mediaAttachments: [testMediaFile1, testMediaFile2],
          kind: 9,
        );

        test('converts media attachments correctly', () {
          final result = MessageConverter.fromChatMessage(
            chatMessage,
            currentUserPublicKey: currentUserPublicKey,
            groupId: groupId,
            usersMap: usersMap,
            isMeFn: mockPubkeyUtilsIsMe,
          );

          expect(result.mediaAttachments, hasLength(2));
          expect(result.mediaAttachments[0], testMediaFile1);
          expect(result.mediaAttachments[1], testMediaFile2);
          expect(result.mediaAttachments[0].id, 'media1');
          expect(result.mediaAttachments[1].id, 'media2');
        });
      });

      group('when message is a reply', () {
        final originalMessageModel = MessageModel(
          id: 'original_msg',
          content: 'Original message',
          type: MessageType.text,
          createdAt: DateTime.fromMillisecondsSinceEpoch(1234567890000),
          sender: otherUser,
          isMe: false,
          groupId: groupId,
          status: MessageStatus.delivered,
        );

        final replyMessage = ChatMessage(
          id: 'reply_msg',
          pubkey: currentUserPublicKey,
          content: 'This is a reply',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1234567891000),
          tags: [],
          isReply: true,
          replyToId: 'original_msg',
          isDeleted: false,
          contentTokens: [],
          reactions: const ReactionSummary(byEmoji: [], userReactions: []),
          mediaAttachments: [],
          kind: 9,
        );

        test('converts reply message with replyTo populated', () {
          final result = MessageConverter.fromChatMessage(
            replyMessage,
            currentUserPublicKey: currentUserPublicKey,
            groupId: groupId,
            usersMap: usersMap,
            replyToMessage: originalMessageModel,
            isMeFn: mockPubkeyUtilsIsMe,
          );

          expect(result.replyTo, isA<MessageModel>());
          expect(result.replyTo?.id, 'original_msg');
          expect(result.replyTo?.content, 'Original message');
          expect(result.replyTo?.sender, otherUser);
          expect(result.replyTo?.isMe, false);
        });

        group('when original reply to message is not provided', () {
          test('returns default replyTo', () {
            final result = MessageConverter.fromChatMessage(
              replyMessage,
              currentUserPublicKey: currentUserPublicKey,
              groupId: groupId,
              usersMap: usersMap,
              isMeFn: mockPubkeyUtilsIsMe,
            );

            expect(result.replyTo, isA<MessageModel>());
            expect(result.replyTo?.content, 'Message not found');
          });
        });
      });

      group('when reply references missing message', () {
        final replyMessage = ChatMessage(
          id: 'reply_msg',
          pubkey: currentUserPublicKey,
          content: 'This is a reply',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1234567891000),
          tags: [],
          isReply: true,
          replyToId: 'missing_msg',
          isDeleted: false,
          contentTokens: [],
          reactions: const ReactionSummary(byEmoji: [], userReactions: []),
          mediaAttachments: [],
          kind: 9,
        );

        test('handles null replyToMessage when replyToId is present', () {
          final result = MessageConverter.fromChatMessage(
            replyMessage,
            currentUserPublicKey: currentUserPublicKey,
            groupId: groupId,
            usersMap: usersMap,
            isMeFn: mockPubkeyUtilsIsMe,
          );

          expect(result.content, 'This is a reply');
          expect(result.sender, currentUser);
          expect(result.isMe, true);
        });

        test('when replyToMessage is not provided, returns default replyTo', () {
          final result = MessageConverter.fromChatMessage(
            replyMessage,
            currentUserPublicKey: currentUserPublicKey,
            groupId: groupId,
            usersMap: usersMap,
            isMeFn: mockPubkeyUtilsIsMe,
          );

          expect(result.replyTo, isA<MessageModel>());
          expect(result.replyTo?.content, 'Message not found');
          expect(result.content, 'This is a reply');
          expect(result.id, 'reply_msg');
        });
      });
    });

    group('fromChatMessageList', () {
      group('when list contains valid messages', () {
        final messages = [
          ChatMessage(
            id: 'msg_1',
            pubkey: currentUserPublicKey,
            content: 'First message',
            createdAt: DateTime.fromMillisecondsSinceEpoch(1234567890000),
            tags: [],
            isReply: false,
            isDeleted: false,
            contentTokens: [],
            reactions: const ReactionSummary(byEmoji: [], userReactions: []),
            mediaAttachments: [],
            kind: 9,
          ),
          ChatMessage(
            id: 'msg_2',
            pubkey: otherUserPublicKey,
            content: 'Second message',
            createdAt: DateTime.fromMillisecondsSinceEpoch(1234567891000),
            tags: [],
            isReply: false,
            isDeleted: false,
            contentTokens: [],
            reactions: const ReactionSummary(byEmoji: [], userReactions: []),
            mediaAttachments: [],
            kind: 9,
          ),
        ];

        test('converts all valid messages', () async {
          final result = await MessageConverter.fromChatMessageList(
            messages,
            currentUserPublicKey: currentUserPublicKey,
            groupId: groupId,
            usersMap: usersMap,
            isMeFn: mockPubkeyUtilsIsMe,
          );

          expect(result, hasLength(2));
          expect(result[0].id, 'msg_1');
          expect(result[0].sender, currentUser);
          expect(result[1].id, 'msg_2');
          expect(result[1].sender, otherUser);
        });
      });

      group('when list contains deleted messages', () {
        final messages = [
          ChatMessage(
            id: 'msg_valid',
            pubkey: currentUserPublicKey,
            content: 'Valid message',
            createdAt: DateTime.fromMillisecondsSinceEpoch(1234567890000),
            tags: [],
            isReply: false,
            isDeleted: false,
            contentTokens: [],
            reactions: const ReactionSummary(byEmoji: [], userReactions: []),
            mediaAttachments: [],
            kind: 9,
          ),
          ChatMessage(
            id: 'msg_deleted',
            pubkey: otherUserPublicKey,
            content: 'Deleted message',
            createdAt: DateTime.fromMillisecondsSinceEpoch(1234567891000),
            tags: [],
            isReply: false,
            isDeleted: true,
            contentTokens: [],
            reactions: const ReactionSummary(byEmoji: [], userReactions: []),
            mediaAttachments: [],
            kind: 9,
          ),
        ];

        test('filters out deleted messages', () async {
          final result = await MessageConverter.fromChatMessageList(
            messages,
            currentUserPublicKey: currentUserPublicKey,
            groupId: groupId,
            usersMap: usersMap,
            isMeFn: mockPubkeyUtilsIsMe,
          );

          expect(result, hasLength(1));
          expect(result[0].id, 'msg_valid');
        });
      });

      group('when list contains empty content messages without media', () {
        final messages = [
          ChatMessage(
            id: 'msg_valid',
            pubkey: currentUserPublicKey,
            content: 'Valid message',
            createdAt: DateTime.fromMillisecondsSinceEpoch(1234567890000),
            tags: [],
            isReply: false,
            isDeleted: false,
            contentTokens: [],
            reactions: const ReactionSummary(byEmoji: [], userReactions: []),
            mediaAttachments: [],
            kind: 9,
          ),
          ChatMessage(
            id: 'msg_empty',
            pubkey: otherUserPublicKey,
            content: '',
            createdAt: DateTime.fromMillisecondsSinceEpoch(1234567891000),
            tags: [],
            isReply: false,
            isDeleted: false,
            contentTokens: [],
            reactions: const ReactionSummary(byEmoji: [], userReactions: []),
            mediaAttachments: [],
            kind: 9,
          ),
        ];

        test('filters out empty content messages without media', () async {
          final result = await MessageConverter.fromChatMessageList(
            messages,
            currentUserPublicKey: currentUserPublicKey,
            groupId: groupId,
            usersMap: usersMap,
            isMeFn: mockPubkeyUtilsIsMe,
          );

          expect(result, hasLength(1));
          expect(result[0].id, 'msg_valid');
        });
      });

      group('when list contains messages with media but no content', () {
        final messagesWithMedia = [
          ChatMessage(
            id: 'msg_with_media',
            pubkey: otherUserPublicKey,
            content: '',
            createdAt: DateTime.fromMillisecondsSinceEpoch(1234567891000),
            tags: [],
            isReply: false,
            isDeleted: false,
            contentTokens: [],
            reactions: const ReactionSummary(byEmoji: [], userReactions: []),
            mediaAttachments: [
              MediaFile(
                id: 'media1',
                mlsGroupId: groupId,
                accountPubkey: otherUserPublicKey,
                filePath: '/path/to/image.jpg',
                fileHash: 'hash1',
                mimeType: 'image/jpeg',
                mediaType: 'image',
                blossomUrl: 'https://example.com/image.jpg',
                nostrKey: 'nostr_key1',
                createdAt: DateTime(2024),
              ),
            ],
            kind: 9,
          ),
        ];
        test('does not filter out messages without content but with media', () async {
          final result = await MessageConverter.fromChatMessageList(
            messagesWithMedia,
            currentUserPublicKey: currentUserPublicKey,
            groupId: groupId,
            usersMap: usersMap,
            isMeFn: mockPubkeyUtilsIsMe,
          );

          expect(result, hasLength(1));
          expect(result[0].id, 'msg_with_media');
          expect(result[0].content, '');
          expect(result[0].mediaAttachments, hasLength(1));
        });
      });

      group('when list is empty', () {
        test('returns empty list', () async {
          final result = await MessageConverter.fromChatMessageList(
            [],
            currentUserPublicKey: currentUserPublicKey,
            groupId: groupId,
            usersMap: usersMap,
            isMeFn: mockPubkeyUtilsIsMe,
          );

          expect(result, isEmpty);
        });
      });
    });

    group('createOptimisticMessage', () {
      final testMediaFile1 = MediaFile(
        id: 'optimistic_media1',
        mlsGroupId: groupId,
        accountPubkey: currentUserPublicKey,
        filePath: '/path/to/optimistic_image1.jpg',
        fileHash: 'optimistic_hash1',
        mimeType: 'image/jpeg',
        mediaType: 'image',
        blossomUrl: 'https://example.com/optimistic_image1.jpg',
        nostrKey: 'optimistic_nostr_key1',
        createdAt: DateTime(2024),
      );

      final testMediaFile2 = MediaFile(
        id: 'optimistic_media2',
        mlsGroupId: groupId,
        accountPubkey: currentUserPublicKey,
        filePath: '/path/to/optimistic_image2.jpg',
        fileHash: 'optimistic_hash2',
        mimeType: 'image/jpeg',
        mediaType: 'image',
        blossomUrl: 'https://example.com/optimistic_image2.jpg',
        nostrKey: 'optimistic_nostr_key2',
        createdAt: DateTime(2024, 1, 2),
      );
      group('when not replying to a message', () {
        late MessageModel optimisticMessage;

        group('without media files', () {
          setUp(() {
            optimisticMessage = MessageConverter.createOptimisticMessage(
              content: 'Optimistic message',
              currentUserPublicKey: currentUserPublicKey,
              groupId: groupId,
              mediaFiles: [],
            );
          });

          test('returns expected content', () {
            expect(optimisticMessage.content, 'Optimistic message');
          });

          test('returns me as sender', () {
            expect(optimisticMessage.sender.displayName, 'You');
            expect(optimisticMessage.sender.publicKey, currentUserPublicKey);
          });

          test('returns true for isMe', () {
            expect(optimisticMessage.isMe, true);
          });

          test('returns expected groupId', () {
            expect(optimisticMessage.groupId, groupId);
          });

          test('returns sending status', () {
            expect(optimisticMessage.status, MessageStatus.sending);
          });

          test('returns kind 9', () {
            expect(optimisticMessage.kind, 9);
          });

          test('has no reply to', () {
            expect(optimisticMessage.replyTo, isNull);
          });

          test('id has temporal message prefix', () {
            expect(optimisticMessage.id.startsWith('temporal_message_'), true);
          });

          test('has no media attachments', () {
            expect(optimisticMessage.mediaAttachments, isEmpty);
          });
        });

        group('with media files', () {
          setUp(() {
            optimisticMessage = MessageConverter.createOptimisticMessage(
              content: 'Optimistic message with multiple media',
              currentUserPublicKey: currentUserPublicKey,
              groupId: groupId,
              mediaFiles: [testMediaFile1, testMediaFile2],
            );
          });

          test('has no reply to', () {
            expect(optimisticMessage.replyTo, isNull);
          });

          test('has expected media attachments', () {
            expect(optimisticMessage.mediaAttachments.length, 2);
            expect(optimisticMessage.mediaAttachments[0], testMediaFile1);
            expect(optimisticMessage.mediaAttachments[1], testMediaFile2);
            expect(optimisticMessage.mediaAttachments[0].id, 'optimistic_media1');
            expect(optimisticMessage.mediaAttachments[1].id, 'optimistic_media2');
          });
        });
      });

      group('when replying to a message', () {
        late MessageModel optimisticMessage;
        final replyToMessage = MessageModel(
          id: 'original_msg',
          content: 'Original message',
          type: MessageType.text,
          createdAt: DateTime.now(),
          sender: otherUser,
          isMe: false,
          groupId: groupId,
          status: MessageStatus.delivered,
        );

        group('without media files', () {
          setUp(() {
            optimisticMessage = MessageConverter.createOptimisticMessage(
              content: 'Optimistic reply',
              currentUserPublicKey: currentUserPublicKey,
              groupId: groupId,
              mediaFiles: [],
              replyToMessage: replyToMessage,
            );
          });

          test('has expected content', () {
            expect(optimisticMessage.content, 'Optimistic reply');
          });

          test('reply to id matches original message id', () {
            expect(optimisticMessage.replyTo?.id, 'original_msg');
          });

          test('reply to content matches original message content', () {
            expect(optimisticMessage.replyTo?.content, 'Original message');
          });

          test('returns true for isMe', () {
            expect(optimisticMessage.isMe, true);
          });

          test('returns expected groupId', () {
            expect(optimisticMessage.groupId, groupId);
          });

          test('returns sending status', () {
            expect(optimisticMessage.status, MessageStatus.sending);
          });

          test('id has temporal message prefix', () {
            expect(optimisticMessage.id.startsWith('temporal_message_'), true);
          });

          test('has no media attachments', () {
            expect(optimisticMessage.mediaAttachments, isEmpty);
          });
        });

        group('with media files', () {
          setUp(() {
            optimisticMessage = MessageConverter.createOptimisticMessage(
              content: 'Optimistic message with multiple media',
              currentUserPublicKey: currentUserPublicKey,
              groupId: groupId,
              mediaFiles: [testMediaFile1, testMediaFile2],
              replyToMessage: replyToMessage,
            );
          });

          test('reply to id matches original message id', () {
            expect(optimisticMessage.replyTo?.id, 'original_msg');
          });

          test('has expected media attachments', () {
            expect(optimisticMessage.mediaAttachments.length, 2);
            expect(optimisticMessage.mediaAttachments[0], testMediaFile1);
            expect(optimisticMessage.mediaAttachments[1], testMediaFile2);
            expect(optimisticMessage.mediaAttachments[0].id, 'optimistic_media1');
            expect(optimisticMessage.mediaAttachments[1].id, 'optimistic_media2');
          });
        });
      });
    });
  });
}
