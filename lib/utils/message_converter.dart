import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart' as domain_user;
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/utils/pubkey_utils.dart';
import 'package:whitenoise/utils/reaction_converter.dart';

/// Converts ChatMessage to MessageModel for UI display
class MessageConverter {
  static MessageModel fromChatMessage(
    ChatMessage messageData, {
    required String currentUserPublicKey,
    required String groupId,
    required Map<String, domain_user.User> usersMap,
    required Map<String, ChatMessage> chatMessagesMap,
    bool Function({required String myPubkey, required String otherPubkey})? isMeFn,
  }) {
    final isMe = (isMeFn ?? PubkeyUtils.isMe)(
      myPubkey: currentUserPublicKey,
      otherPubkey: messageData.pubkey,
    );

    final sender = usersMap[messageData.pubkey] ?? _unknownUser(pubkey: messageData.pubkey);

    final createdAt = messageData.createdAt;

    final status = isMe ? MessageStatus.sent : MessageStatus.delivered;

    final reactions = ReactionConverter.fromReactionSummary(
      reactionSummary: messageData.reactions,
      usersMap: usersMap,
    );

    MessageModel? replyToMessage;
    if (messageData.isReply && messageData.replyToId != null) {
      replyToMessage = _replyToMessage(
        replyToId: messageData.replyToId!,
        groupId: groupId,
        currentUserPublicKey: currentUserPublicKey,
        usersMap: usersMap,
        chatMessagesMap: chatMessagesMap,
        isMeFn: isMeFn,
      );
    }

    return MessageModel(
      id: messageData.id,
      content: messageData.content,
      type: MessageType.text,
      createdAt: createdAt,
      sender: sender,
      isMe: isMe,
      groupId: groupId,
      status: status,
      reactions: reactions,
      replyTo: replyToMessage,
      kind: messageData.kind,
    );
  }

  static Future<List<MessageModel>> fromChatMessageList(
    List<ChatMessage> chatMessages, {
    required String currentUserPublicKey,
    required String groupId,
    required Map<String, domain_user.User> usersMap,
    bool Function({required String myPubkey, required String otherPubkey})? isMeFn,
  }) async {
    // Filter valid messages first
    final validMessages =
        chatMessages.where((msg) => !msg.isDeleted && msg.content.isNotEmpty).toList();

    // Build messages map for reply lookups
    final chatMessagesMap = <String, ChatMessage>{};
    for (final msg in validMessages) {
      chatMessagesMap[msg.id] = msg;
    }

    final messages =
        validMessages
            .map(
              (messageData) => fromChatMessage(
                messageData,
                currentUserPublicKey: currentUserPublicKey,
                groupId: groupId,
                chatMessagesMap: chatMessagesMap,
                usersMap: usersMap,
                isMeFn: isMeFn,
              ),
            )
            .toList();

    return messages;
  }

  static MessageModel _replyToMessage({
    required String replyToId,
    required String groupId,
    required String currentUserPublicKey,
    required Map<String, domain_user.User> usersMap,
    required Map<String, ChatMessage> chatMessagesMap,
    bool Function({required String myPubkey, required String otherPubkey})? isMeFn,
  }) {
    MessageModel? replyToMessage;
    final originalMessage = chatMessagesMap[replyToId];
    if (originalMessage != null) {
      final replyContent =
          originalMessage.content.isNotEmpty ? originalMessage.content : 'No content available';

      final replyTimestamp = originalMessage.createdAt;
      final replySender =
          usersMap[originalMessage.pubkey] ?? _unknownUser(pubkey: originalMessage.pubkey);

      replyToMessage = MessageModel(
        id: replyToId,
        content: replyContent,
        type: MessageType.text,
        createdAt: replyTimestamp,
        sender: replySender,
        isMe: (isMeFn ?? PubkeyUtils.isMe)(
          myPubkey: currentUserPublicKey,
          otherPubkey: originalMessage.pubkey,
        ),
        groupId: groupId,
        status: MessageStatus.delivered,
        kind: originalMessage.kind,
      );
    } else {
      replyToMessage = MessageModel(
        id: replyToId,
        content: 'Message not found',
        type: MessageType.text,
        createdAt: DateTime.now(),
        sender: domain_user.User(
          id: 'unknown',
          displayName: 'Unknown User',
          nip05: '',
          publicKey: 'unknown',
        ),
        isMe: false,
        groupId: groupId,
        status: MessageStatus.delivered,
      );
    }
    return replyToMessage;
  }

  static domain_user.User _unknownUser({required String pubkey}) {
    return domain_user.User(
      id: pubkey,
      displayName: 'Unknown User',
      nip05: '',
      publicKey: pubkey,
    );
  }
}
