import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/src/rust/api/messages.dart';

/// Converts ChatMessageData to MessageModel for UI display
class MessageConverter {
  /// Converts a ChatMessageData to MessageModel
  static Future<MessageModel> fromChatMessageData(
    ChatMessageData messageData, {
    required String? currentUserPublicKey,
    String? groupId,
    required Ref ref,
  }) async {
    final isMe = currentUserPublicKey != null && messageData.pubkey == currentUserPublicKey;

    final sender = await _createUserFromMetadata(
      messageData.pubkey,
      currentUserPubkey: currentUserPublicKey,
      ref: ref,
    );

    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      messageData.createdAt.toInt() * 1000,
    );

    final status = isMe ? MessageStatus.sent : MessageStatus.delivered;

    // Convert reactions from ChatMessageData
    final reactions = _convertReactions(messageData.reactions);

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
    );
  }

  /// Converts a list of ChatMessageData to MessageModel list
  static Future<List<MessageModel>> fromChatMessageDataList(
    List<ChatMessageData> messageDataList, {
    required String? currentUserPublicKey,
    String? groupId,
    required Ref ref,
  }) async {
    final List<MessageModel> messages = [];

    for (final messageData in messageDataList) {
      // Skip deleted messages if desired (or include them with special handling)
      if (!messageData.isDeleted && messageData.content.isNotEmpty) {
        final message = await fromChatMessageData(
          messageData,
          currentUserPublicKey: currentUserPublicKey,
          groupId: groupId,
          ref: ref,
        );
        messages.add(message);
      }
    }

    return messages;
  }

  /// Convert MessageWithTokensData to MessageModel
  static Future<MessageModel> fromMessageWithTokensData(
    MessageWithTokensData messageData, {
    required String? currentUserPublicKey,
    String? groupId,
    required Ref ref,
    ChatMessageData? replyInfo, // For reply information mapping
    Map<String, MessageWithTokensData>?
    originalMessageLookup, // For looking up original message content
  }) async {
    final isMe = currentUserPublicKey != null && messageData.pubkey == currentUserPublicKey;

    final sender = await _createUserFromMetadata(
      messageData.pubkey,
      currentUserPubkey: currentUserPublicKey,
      ref: ref,
    );

    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      messageData.createdAt.toInt() * 1000,
    );

    final status = isMe ? MessageStatus.sent : MessageStatus.delivered;

    // Extract reply information from aggregated data if available
    MessageModel? replyToMessage;
    if (replyInfo != null && replyInfo.isReply && replyInfo.replyToId != null) {
      final originalMessage = originalMessageLookup?[replyInfo.replyToId!];

      if (originalMessage != null) {
        final replyContent =
            originalMessage.content?.isNotEmpty == true
                ? originalMessage.content!
                : 'No content available';
        final replyTimestamp = DateTime.fromMillisecondsSinceEpoch(
          originalMessage.createdAt.toInt() * 1000,
        );

        final replySender = await _createUserFromMetadata(
          originalMessage.pubkey,
          currentUserPubkey: currentUserPublicKey,
          ref: ref,
        );

        replyToMessage = MessageModel(
          id: replyInfo.replyToId!,
          content: replyContent,
          type: MessageType.text,
          createdAt: replyTimestamp,
          sender: replySender,
          isMe: currentUserPublicKey != null && originalMessage.pubkey == currentUserPublicKey,
          groupId: groupId,
          status: MessageStatus.delivered,
        );
      } else {
        // Fallback for missing original message
        replyToMessage = MessageModel(
          id: replyInfo.replyToId!,
          content: 'No content available',
          type: MessageType.text,
          createdAt: DateTime.now(),
          sender: User(
            id: 'unknown',
            name: 'Unknown User',
            nip05: '',
            publicKey: 'unknown',
          ),
          isMe: false,
          groupId: groupId,
          status: MessageStatus.delivered,
        );
      }
    }

    // Convert reactions from aggregated data if available
    final reactions = replyInfo != null ? _convertReactions(replyInfo.reactions) : <Reaction>[];

    return MessageModel(
      id: messageData.id,
      content: messageData.content ?? '',
      type: MessageType.text,
      createdAt: createdAt,
      sender: sender,
      isMe: isMe,
      groupId: groupId,
      status: status,
      replyTo: replyToMessage,
      reactions: reactions,
    );
  }

  /// Converts a list of MessageWithTokensData to MessageModel list with reply mapping
  /// TODO: Temporary solution using aggregated messages for reply information until API consolidation
  static Future<List<MessageModel>> fromMessageWithTokensDataList(
    List<MessageWithTokensData> messageDataList, {
    required String? currentUserPublicKey,
    String? groupId,
    required Ref ref,
    List<ChatMessageData>? aggregatedMessages, // TODO: For reply mapping
  }) async {
    final List<MessageModel> messages = [];

    // Create lookup maps for reply functionality
    final Map<String, ChatMessageData> replyMap = {};
    final Map<String, MessageWithTokensData> originalMessageMap = {};

    // Build original message lookup from primary message data
    for (final msg in messageDataList) {
      originalMessageMap[msg.id] = msg;
    }

    // Build reply information lookup from aggregated data
    if (aggregatedMessages != null) {
      for (final aggMsg in aggregatedMessages) {
        replyMap[aggMsg.id] = aggMsg;
      }
    }

    for (final messageData in messageDataList) {
      // Only process messages that have content
      if (messageData.content != null && messageData.content!.isNotEmpty) {
        // Get reply information from aggregated data if available
        final aggregatedData = replyMap[messageData.id];

        final message = await fromMessageWithTokensData(
          messageData,
          currentUserPublicKey: currentUserPublicKey,
          groupId: groupId,
          ref: ref,
          replyInfo: aggregatedData,
          originalMessageLookup: originalMessageMap,
        );
        messages.add(message);
      }
    }

    return messages;
  }

  /// Creates a User object from metadata cache (asynchronous)
  static Future<User> _createUserFromMetadata(
    String pubkey, {
    String? currentUserPubkey,
    required Ref ref,
  }) async {
    // If this is the current user, return 'You'
    if (currentUserPubkey != null && pubkey == currentUserPubkey) {
      return User(
        id: pubkey,
        name: 'You',
        nip05: '',
        publicKey: pubkey,
      );
    }

    try {
      // First try contacts provider for cached data
      final contacts = ref.read(contactsProvider);
      final contactModels = contacts.contactModels ?? [];

      final contact = contactModels.where((contact) => contact.publicKey == pubkey).toList();

      if (contact.isNotEmpty) {
        final contactModel = contact.first;
        return User(
          id: pubkey,
          name:
              contactModel.displayName?.isNotEmpty == true
                  ? contactModel.displayName!
                  : contactModel.name,
          nip05: contactModel.nip05 ?? '',
          publicKey: pubkey,
          imagePath: contactModel.imagePath,
          username: contactModel.displayName,
        );
      }

      // If not found in contacts, try metadata cache
      final metadataCache = ref.read(metadataCacheProvider.notifier);
      final contactModel = await metadataCache.getContactModel(pubkey);

      return User(
        id: pubkey,
        name: contactModel.displayNameOrName,
        nip05: contactModel.nip05 ?? '',
        publicKey: pubkey,
        imagePath: contactModel.imagePath,
        username: contactModel.displayName,
      );
    } catch (e) {
      // Return fallback user if both lookups fail
      return User(
        id: pubkey,
        name: 'Unknown User',
        nip05: '',
        publicKey: pubkey,
      );
    }
  }

  /// Convert ReactionSummaryData to MessageModel reactions format
  static List<Reaction> _convertReactions(ReactionSummaryData reactions) {
    final List<Reaction> result = [];

    for (final userReaction in reactions.userReactions) {
      final reactionDateTime = DateTime.fromMillisecondsSinceEpoch(
        userReaction.createdAt.toInt() * 1000,
      );

      // Create a simple user object for the reaction with fallback name
      final fallbackName =
          userReaction.user.length >= 8 ? userReaction.user.substring(0, 8) : userReaction.user;

      final reactionUser = User(
        id: userReaction.user,
        name: fallbackName,
        nip05: '',
        publicKey: userReaction.user,
      );

      result.add(
        Reaction(
          emoji: userReaction.emoji,
          user: reactionUser,
          createdAt: reactionDateTime,
        ),
      );
    }

    return result;
  }
}
