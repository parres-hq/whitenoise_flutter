import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart' as domain_user;
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

      group('when list contains empty content messages', () {
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
            kind: 9,
          ),
        ];

        test('filters out empty content messages', () async {
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
      test('creates optimistic message without reply', () {
        final result = MessageConverter.createOptimisticMessage(
          content: 'Optimistic message',
          currentUserPublicKey: currentUserPublicKey,
          groupId: groupId,
        );

        expect(result.content, 'Optimistic message');
        expect(result.sender.displayName, 'You');
        expect(result.sender.publicKey, currentUserPublicKey);
        expect(result.isMe, true);
        expect(result.groupId, groupId);
        expect(result.status, MessageStatus.sending);
        expect(result.kind, 9);
        expect(result.replyTo, isNull);
        expect(result.id.startsWith('temporal_message_'), true);
      });

      test('creates optimistic message with reply', () {
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

        final result = MessageConverter.createOptimisticMessage(
          content: 'Optimistic reply',
          currentUserPublicKey: currentUserPublicKey,
          groupId: groupId,
          replyToMessage: replyToMessage,
        );

        expect(result.content, 'Optimistic reply');
        expect(result.replyTo, isA<MessageModel>());
        expect(result.replyTo?.id, 'original_msg');
        expect(result.replyTo?.content, 'Original message');
        expect(result.status, MessageStatus.sending);
        expect(result.isMe, true);
      });
    });
  });
}
