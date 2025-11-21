import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/group_messages_provider.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart' show User;
import 'package:whitenoise/domain/services/message_sender_service.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
import 'package:whitenoise/src/rust/api/messages.dart' show MessageWithTokens;

import '../../shared/mocks/mock_active_pubkey_notifier.dart';
import '../../shared/mocks/mock_auth_notifier.dart';

class MockMessageSenderService implements MessageSenderService {
  MessageWithTokens? messageToReturn;
  Exception? errorToThrow;
  int sendCallCount = 0;
  int reactionCallCount = 0;

  MockMessageSenderService({
    this.messageToReturn,
    this.errorToThrow,
  });

  @override
  Future<MessageWithTokens> sendMessage({
    required String pubkey,
    required String groupId,
    required String content,
    required List<MediaFile> mediaFiles,
  }) async {
    sendCallCount++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return messageToReturn!;
  }

  @override
  Future<MessageWithTokens> sendReaction({
    required String pubkey,
    required String groupId,
    required String messageId,
    required String messagePubkey,
    required int messageKind,
    required String emoji,
  }) async {
    reactionCallCount++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    // Return a dummy message as it's not used for reaction response in the provider usually
    return MessageWithTokens(
      id: 'reaction-id',
      pubkey: pubkey,
      kind: 7,
      createdAt: DateTime.now(),
      content: emoji,
      tokens: [],
    );
  }

  @override
  Future<MessageWithTokens> sendReply({
    required String pubkey,
    required String groupId,
    required String replyToMessageId,
    required String content,
    required List<MediaFile> mediaFiles,
  }) async {
    sendCallCount++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return messageToReturn!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGroupMessagesNotifier extends GroupMessagesNotifier {
  List<MessageModel> messagesToReturn;
  final Exception? errorToThrow;
  int fetchCallCount = 0;

  MockGroupMessagesNotifier({
    required this.messagesToReturn,
    this.errorToThrow,
  });

  @override
  Future<List<MessageModel>> fetchMessages() async {
    fetchCallCount++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return List<MessageModel>.from(messagesToReturn);
  }

  void updateMessages(List<MessageModel> messages) {
    messagesToReturn = messages;
  }
}

MessageModel createTestMessage({
  required String id,
  required String content,
  required String senderPubkey,
  required DateTime createdAt,
  String? groupId,
  MessageStatus status = MessageStatus.sent,
  MessageModel? replyTo,
  List<Reaction>? reactions,
}) {
  return MessageModel(
    id: id,
    content: content,
    type: MessageType.text,
    createdAt: createdAt,
    sender: User(
      id: senderPubkey,
      publicKey: senderPubkey,
      displayName: 'Test User',
      nip05: '',
    ),
    isMe: false,
    groupId: groupId,
    status: status,
    replyTo: replyTo,
    reactions: reactions ?? [],
  );
}

void main() {
  group('ChatProvider Reaction Tests', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    late ProviderContainer container;
    const testGroupId = 'test-group-123';
    const testPubkey = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';

    late MockMessageSenderService mockMessageSenderService;
    late MockGroupMessagesNotifier mockGroupMessagesNotifier;
    late MessageModel testMessage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // LastReadManager doesn't need init

      mockMessageSenderService = MockMessageSenderService();

      testMessage = createTestMessage(
        id: 'msg-1',
        content: 'Hello',
        senderPubkey: 'other-user-pubkey',
        createdAt: DateTime.now(),
        groupId: testGroupId,
      );

      mockGroupMessagesNotifier = MockGroupMessagesNotifier(
        messagesToReturn: [testMessage],
      );

      container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            () => MockAuthNotifier(isAuthenticated: true),
          ),
          activePubkeyProvider.overrideWith(
            () => MockActivePubkeyNotifier(testPubkey),
          ),
          groupMessagesProvider.overrideWith(
            () => mockGroupMessagesNotifier,
          ),
          chatProvider.overrideWith(
            () => ChatNotifier(messageSenderService: mockMessageSenderService),
          ),
        ],
      );

      // Initialize the provider and load messages
      final notifier = container.read(chatProvider.notifier);
      await notifier.loadMessagesForGroup(testGroupId);
    });

    tearDown(() {
      container.dispose();
    });

    test('updateMessageReaction adds reaction optimistically', () async {
      final notifier = container.read(chatProvider.notifier);
      const reactionEmoji = '👍';

      // Verify initial state
      var messages = container.read(chatProvider).groupMessages[testGroupId];
      expect(messages!.first.reactions, isEmpty);

      // Add reaction
      final result = await notifier.updateMessageReaction(
        message: testMessage,
        reaction: reactionEmoji,
      );

      expect(result, true);
      expect(mockMessageSenderService.reactionCallCount, 1);

      // Verify optimistic update
      messages = container.read(chatProvider).groupMessages[testGroupId];
      expect(messages!.first.reactions, isNotEmpty);
      expect(messages.first.reactions.first.emoji, reactionEmoji);
      expect(messages.first.reactions.first.user.publicKey, testPubkey);
    });

    test('updateMessageReaction removes reaction optimistically (toggle)', () async {
      const reactionEmoji = '👍';

      // Setup: Message already has a reaction from current user
      final reaction = Reaction(
        emoji: reactionEmoji,
        user: User(
          id: testPubkey,
          publicKey: testPubkey,
          displayName: 'Me',
          nip05: '',
        ),
        createdAt: DateTime.now(),
      );

      final messageWithReaction = testMessage.copyWith(reactions: [reaction]);

      // Update the mock to return this message (simulating state before toggle)
      // We need to manually update the state because we can't easily inject it into the provider's internal state directly
      // without going through the load process again or using a method exposed for testing.
      // However, for this test, we can just call updateMessageReaction on the messageWithReaction.
      // But wait, the provider looks up the message in its state by ID.
      // So we need to ensure the provider's state has the message with reaction.

      // Let's re-initialize with the message having a reaction
      mockGroupMessagesNotifier = MockGroupMessagesNotifier(
        messagesToReturn: [messageWithReaction],
      );

      container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            () => MockAuthNotifier(isAuthenticated: true),
          ),
          activePubkeyProvider.overrideWith(
            () => MockActivePubkeyNotifier(testPubkey),
          ),
          groupMessagesProvider.overrideWith(
            () => mockGroupMessagesNotifier,
          ),
          chatProvider.overrideWith(
            () => ChatNotifier(messageSenderService: mockMessageSenderService),
          ),
        ],
      );

      final newNotifier = container.read(chatProvider.notifier);
      await newNotifier.loadMessagesForGroup(testGroupId);

      // Verify initial state has reaction
      var messages = container.read(chatProvider).groupMessages[testGroupId];
      expect(messages!.first.reactions, isNotEmpty);
      expect(messages.first.reactions.first.emoji, reactionEmoji);

      // Remove reaction (toggle)
      final result = await newNotifier.updateMessageReaction(
        message: messageWithReaction,
        reaction: reactionEmoji,
      );

      expect(result, true);
      expect(mockMessageSenderService.reactionCallCount, 1);

      // Verify optimistic removal
      messages = container.read(chatProvider).groupMessages[testGroupId];
      expect(messages!.first.reactions, isEmpty);
    });

    test('updateMessageReaction reverts optimistic update on failure', () async {
      final notifier = container.read(chatProvider.notifier);
      const reactionEmoji = '👍';

      // Setup failure
      mockMessageSenderService.errorToThrow = Exception('Network error');

      // Add reaction
      final result = await notifier.updateMessageReaction(
        message: testMessage,
        reaction: reactionEmoji,
      );

      expect(result, false);
      expect(mockMessageSenderService.reactionCallCount, 1);

      // Verify reaction is NOT present (reverted)
      final messages = container.read(chatProvider).groupMessages[testGroupId]!;
      expect(messages.first.reactions, isEmpty);
    });
  });
}
