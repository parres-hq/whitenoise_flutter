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
    MessageModel? replyToMessage,
    bool skipReactions = false,
    bool Function({required String myPubkey, required String otherPubkey})? isMeFn,
  }) {
    final isMe = (isMeFn ?? PubkeyUtils.isMe)(
      myPubkey: currentUserPublicKey,
      otherPubkey: messageData.pubkey,
    );

    final sender = usersMap[messageData.pubkey] ?? _unknownUser(pubkey: messageData.pubkey);
    final createdAt = messageData.createdAt.toLocal();

    final status = isMe ? MessageStatus.sent : MessageStatus.delivered;

    final List<Reaction> emptyReactions = [];
    final reactions =
        skipReactions
            ? emptyReactions
            : ReactionConverter.fromReactionSummary(
              reactionSummary: messageData.reactions,
              usersMap: usersMap,
            );

    // If this is a reply message but no replyToMessage was provided, create a placeholder
    final finalReplyTo =
        replyToMessage ??
        (messageData.isReply && messageData.replyToId != null
            ? _emptyReplyToMessage(replyToId: messageData.replyToId!, groupId: groupId)
            : null);

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
      replyTo: finalReplyTo,
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
    final validMessages =
        chatMessages.where((msg) => !msg.isDeleted && msg.content.isNotEmpty).toList();
    final chatMessagesMap = <String, ChatMessage>{};
    for (final msg in validMessages) {
      chatMessagesMap[msg.id] = msg;
    }

    final messageModels = <MessageModel>[];
    final messageModelsMap = <String, MessageModel>{};
    for (final messageData in validMessages) {
      final MessageModel? replyToMessage = _buildReplyToMessage(
        messageData: messageData,
        messageModelsMap: messageModelsMap,
        groupId: groupId,
      );
      final messageModel = fromChatMessage(
        messageData,
        currentUserPublicKey: currentUserPublicKey,
        groupId: groupId,
        usersMap: usersMap,
        replyToMessage: replyToMessage,
        isMeFn: isMeFn,
      );
      messageModelsMap[messageModel.id] = messageModel;
      messageModels.add(messageModel);
    }

    return messageModels;
  }

  static MessageModel createOptimisticMessage({
    required String content,
    required String currentUserPublicKey,
    required String groupId,
    required int kind,
    MessageModel? replyToMessage,
  }) {
    final messageHash =
        '${currentUserPublicKey}_${content}_${DateTime.now().millisecondsSinceEpoch}'.hashCode
            .abs()
            .toString();
    final optimisticId = 'temporal_message_$messageHash';

    final currentUser = domain_user.User(
      id: currentUserPublicKey,
      displayName: 'You',
      nip05: '',
      publicKey: currentUserPublicKey,
    );

    return MessageModel(
      id: optimisticId,
      content: content,
      type: MessageType.text,
      createdAt: DateTime.now(),
      sender: currentUser,
      isMe: true,
      groupId: groupId,
      status: MessageStatus.sending,
      replyTo: replyToMessage,
      kind: kind,
    );
  }

  static domain_user.User _unknownUser({required String pubkey}) {
    return domain_user.User(
      id: pubkey,
      displayName: 'Unknown User',
      nip05: '',
      publicKey: pubkey,
    );
  }

  static MessageModel? _buildReplyToMessage({
    required ChatMessage messageData,
    required Map<String, MessageModel> messageModelsMap,
    required String groupId,
  }) {
    final replyToId = messageData.replyToId;
    if (messageData.isReply && replyToId != null) {
      final replyToMessage =
          messageModelsMap[replyToId] ??
          _emptyReplyToMessage(replyToId: replyToId, groupId: groupId);
      return replyToMessage;
    }
    return null;
  }

  static MessageModel _emptyReplyToMessage({required String replyToId, required String groupId}) {
    return MessageModel(
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
}
