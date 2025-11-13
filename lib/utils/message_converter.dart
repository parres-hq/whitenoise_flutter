import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart' as domain_user;
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
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
            ? _buildEmptyReplyToMessage(replyToId: messageData.replyToId!, groupId: groupId)
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
      mediaAttachments: messageData.mediaAttachments,
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
        chatMessages
            .where(
              (msg) =>
                  !msg.isDeleted && (msg.content.isNotEmpty || msg.mediaAttachments.isNotEmpty),
            )
            .toList();
    final chatMessagesMap = <String, ChatMessage>{};
    for (final msg in validMessages) {
      chatMessagesMap[msg.id] = msg;
    }

    final messageModels = <MessageModel>[];
    final messageModelsMap = <String, MessageModel>{};
    final Map<String, String?> messageIdsWithReplyToMap = {};
    for (final messageData in validMessages) {
      if (messageData.isReply) {
        messageIdsWithReplyToMap[messageData.id] = messageData.replyToId;
      }
      final messageModel = fromChatMessage(
        messageData,
        currentUserPublicKey: currentUserPublicKey,
        groupId: groupId,
        usersMap: usersMap,
        isMeFn: isMeFn,
      );
      messageModelsMap[messageModel.id] = messageModel;
      messageModels.add(messageModel);
    }
    final messageModelsWithReplies = _addReplies(
      messageModels: messageModels,
      messageIdsWithReplyToMap: messageIdsWithReplyToMap,
      chatMessagesMap: chatMessagesMap,
      messageModelsMap: messageModelsMap,
      groupId: groupId,
    );

    return messageModelsWithReplies;
  }

  static MessageModel createOptimisticMessage({
    required String id,
    required String content,
    required String currentUserPublicKey,
    required String groupId,
    required List<MediaFile> mediaFiles,
    MessageModel? replyToMessage,
  }) {
    final currentUser = domain_user.User(
      id: currentUserPublicKey,
      displayName: 'You',
      nip05: '',
      publicKey: currentUserPublicKey,
    );

    return MessageModel(
      id: id,
      content: content,
      type: MessageType.text,
      createdAt: DateTime.now(),
      sender: currentUser,
      isMe: true,
      groupId: groupId,
      status: MessageStatus.sending,
      replyTo: replyToMessage,
      mediaAttachments: mediaFiles,
    );
  }

  static domain_user.User _unknownUser({required String pubkey}) {
    return domain_user.User(
      id: pubkey,
      displayName: 'shared.unknownUser'.tr(),
      nip05: '',
      publicKey: pubkey,
    );
  }

  static List<MessageModel> _addReplies({
    required List<MessageModel> messageModels,
    required Map<String, String?> messageIdsWithReplyToMap,
    required Map<String, ChatMessage> chatMessagesMap,
    required Map<String, MessageModel> messageModelsMap,
    required String groupId,
  }) {
    final messageModelsWithReplies = <MessageModel>[];
    for (final messageModel in messageModels) {
      final messageModelWithReply = _addReply(
        messageModel: messageModel,
        messageIdsWithReplyToMap: messageIdsWithReplyToMap,
        chatMessagesMap: chatMessagesMap,
        messageModelsMap: messageModelsMap,
        groupId: groupId,
      );
      messageModelsWithReplies.add(messageModelWithReply);
    }
    return messageModelsWithReplies;
  }

  static MessageModel _addReply({
    required MessageModel messageModel,
    required Map<String, String?> messageIdsWithReplyToMap,
    required Map<String, ChatMessage> chatMessagesMap,
    required Map<String, MessageModel> messageModelsMap,
    required String groupId,
  }) {
    final messageId = messageModel.id;
    final replyToId = messageIdsWithReplyToMap[messageId];
    final chatMessage = chatMessagesMap[messageId]!;
    if (chatMessage.isReply) {
      final replyToMessage = _findReply(
        messageId: messageId,
        replyToId: replyToId,
        messageData: chatMessagesMap[messageId]!,
        messageModelsMap: messageModelsMap,
        groupId: groupId,
      );
      final updatedMessageModel = messageModel.copyWith(
        replyTo: replyToMessage,
      );
      return updatedMessageModel;
    } else {
      return messageModel;
    }
  }

  static MessageModel? _findReply({
    required String messageId,
    String? replyToId,
    required ChatMessage messageData,
    required Map<String, MessageModel> messageModelsMap,
    required String groupId,
  }) {
    final replyToMessage = messageModelsMap[replyToId];
    if (replyToMessage == null) {
      final emptyReplyToMessage = _buildEmptyReplyToMessage(
        replyToId: 'missing_reply_$messageId',
        groupId: groupId,
      );
      return emptyReplyToMessage;
    }
    return replyToMessage;
  }

  static MessageModel _buildEmptyReplyToMessage({
    required String replyToId,
    required String groupId,
  }) {
    return MessageModel(
      id: replyToId,
      content: 'Message not found',
      type: MessageType.text,
      createdAt: DateTime.now(),
      sender: domain_user.User(
        id: 'unknown',
        displayName: 'shared.unknownUser'.tr(),
        nip05: '',
        publicKey: 'unknown',
      ),
      isMe: false,
      groupId: groupId,
      status: MessageStatus.delivered,
      mediaAttachments: [],
    );
  }
}
