import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/follows_provider.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/src/rust/api/messages.dart';

/// Converts ChatMessage to MessageModel for UI display
class MessageConverter {
  static Future<MessageModel> fromChatMessage(
    ChatMessage messageData, {
    required String? currentUserPublicKey,
    String? groupId,
    required Ref ref,
    Map<String, ChatMessage>? messageCache,
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

    final reactions = _convertReactions(messageData.reactions);

    // Handle reply information
    MessageModel? replyToMessage;
    if (messageData.isReply && messageData.replyToId != null) {
      final originalMessage = messageCache?[messageData.replyToId!];
      if (originalMessage != null) {
        final replyContent =
            originalMessage.content.isNotEmpty ? originalMessage.content : 'No content available';

        final replyTimestamp = DateTime.fromMillisecondsSinceEpoch(
          originalMessage.createdAt.toInt() * 1000,
        );

        final replySender = await _createUserFromMetadata(
          originalMessage.pubkey,
          currentUserPubkey: currentUserPublicKey,
          ref: ref,
        );

        replyToMessage = MessageModel(
          id: messageData.replyToId!,
          content: replyContent,
          type: MessageType.text,
          createdAt: replyTimestamp,
          sender: replySender,
          isMe: currentUserPublicKey != null && originalMessage.pubkey == currentUserPublicKey,
          groupId: groupId,
          status: MessageStatus.delivered,
          kind: originalMessage.kind, // Use the original message's kind
        );
      } else {
        // Fallback for missing original message
        replyToMessage = MessageModel(
          id: messageData.replyToId!,
          content: 'Message not found',
          type: MessageType.text,
          createdAt: DateTime.now(),
          sender: User(
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
      kind: messageData.kind, // Use the actual kind from the backend data
    );
  }

  static Future<List<MessageModel>> fromChatMessageList(
    List<ChatMessage> messageDataList, {
    required String? currentUserPublicKey,
    String? groupId,
    required Ref ref,
  }) async {
    // Filter valid messages first
    final validMessages =
        messageDataList.where((msg) => !msg.isDeleted && msg.content.isNotEmpty).toList();

    // Build message cache for reply lookups
    final messageCache = <String, ChatMessage>{};
    for (final msg in validMessages) {
      messageCache[msg.id] = msg;
    }

    // Pre-fetch unique user metadata to avoid duplicate lookups
    final uniquePubkeys = <String>{};
    for (final msg in validMessages) {
      uniquePubkeys.add(msg.pubkey);
      // Also add reply authors if they exist
      if (msg.isReply && msg.replyToId != null) {
        final originalMsg = messageCache[msg.replyToId!];
        if (originalMsg != null) {
          uniquePubkeys.add(originalMsg.pubkey);
        }
      }
      // Add reaction users
      for (final userReaction in msg.reactions.userReactions) {
        uniquePubkeys.add(userReaction.user);
      }
    }

    // Batch fetch all user metadata using build-safe helper
    final userCache = await _batchFetchUserMetadata(uniquePubkeys, currentUserPublicKey, ref);

    // Process all messages using cached data
    final messages =
        validMessages
            .map(
              (messageData) => _fromChatMessageWithCache(
                messageData,
                currentUserPublicKey: currentUserPublicKey,
                groupId: groupId,
                messageCache: messageCache,
                userCache: userCache,
              ),
            )
            .toList();

    return messages;
  }

  /// Convert ChatMessage to MessageModel using cached user data
  static MessageModel _fromChatMessageWithCache(
    ChatMessage messageData, {
    required String? currentUserPublicKey,
    String? groupId,
    required Map<String, ChatMessage> messageCache,
    required Map<String, User> userCache,
  }) {
    final isMe = currentUserPublicKey != null && messageData.pubkey == currentUserPublicKey;

    // Use cached user data
    final sender =
        userCache[messageData.pubkey] ??
        User(
          id: messageData.pubkey,
          displayName: 'Unknown User',
          nip05: '',
          publicKey: messageData.pubkey,
        );

    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      messageData.createdAt.toInt() * 1000,
    );

    final status = isMe ? MessageStatus.sent : MessageStatus.delivered;

    final reactions = _convertReactionsWithCache(messageData.reactions, userCache);

    // Handle reply information
    MessageModel? replyToMessage;
    if (messageData.isReply && messageData.replyToId != null) {
      final originalMessage = messageCache[messageData.replyToId!];
      if (originalMessage != null) {
        final replyContent =
            originalMessage.content.isNotEmpty ? originalMessage.content : 'No content available';

        final replyTimestamp = DateTime.fromMillisecondsSinceEpoch(
          originalMessage.createdAt.toInt() * 1000,
        );

        final replySender =
            userCache[originalMessage.pubkey] ??
            User(
              id: originalMessage.pubkey,
              displayName: 'Unknown User',
              nip05: '',
              publicKey: originalMessage.pubkey,
            );

        replyToMessage = MessageModel(
          id: messageData.replyToId!,
          content: replyContent,
          type: MessageType.text,
          createdAt: replyTimestamp,
          sender: replySender,
          isMe: currentUserPublicKey != null && originalMessage.pubkey == currentUserPublicKey,
          groupId: groupId,
          status: MessageStatus.delivered,
          kind: originalMessage.kind, // Use the original message's kind
        );
      } else {
        // Fallback for missing original message
        replyToMessage = MessageModel(
          id: messageData.replyToId!,
          content: 'Message not found',
          type: MessageType.text,
          createdAt: DateTime.now(),
          sender: User(
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
      kind: messageData.kind, // Use the actual kind from the backend data
    );
  }

  /// Convert MessageWithTokens to MessageModel
  static Future<MessageModel> fromMessageWithTokens(
    MessageWithTokens messageData, {
    required String? currentUserPublicKey,
    String? groupId,
    required Ref ref,
    ChatMessage? replyInfo,
    Map<String, MessageWithTokens>? originalMessageLookup,
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
          kind: originalMessage.kind, // Use the original message's kind
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
      kind: messageData.kind, // Use the actual kind from the backend data
    );
  }

  /// Converts a list of MessageWithTokens to MessageModel list with reply mapping
  static Future<List<MessageModel>> fromMessageWithTokensList(
    List<MessageWithTokens> messageDataList, {
    required String? currentUserPublicKey,
    String? groupId,
    required Ref ref,
    List<ChatMessage>? aggregatedMessages, // TODO: For reply mapping
  }) async {
    // Create lookup maps for reply functionality
    final Map<String, ChatMessage> replyMap = {};
    final Map<String, MessageWithTokens> originalMessageMap = {};

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

    // Filter messages with content
    final validMessages =
        messageDataList.where((msg) => msg.content != null && msg.content!.isNotEmpty).toList();

    // Pre-fetch unique user metadata to avoid duplicate lookups
    final uniquePubkeys = <String>{};
    for (final msg in validMessages) {
      uniquePubkeys.add(msg.pubkey);
      // Also add reply authors if they exist
      final replyInfo = replyMap[msg.id];
      if (replyInfo?.isReply == true && replyInfo?.replyToId != null) {
        final originalMsg = originalMessageMap[replyInfo!.replyToId!];
        if (originalMsg != null) {
          uniquePubkeys.add(originalMsg.pubkey);
        }
      }
      // Add reaction users from aggregated data
      if (replyInfo != null) {
        for (final userReaction in replyInfo.reactions.userReactions) {
          uniquePubkeys.add(userReaction.user);
        }
      }
    }

    // Batch fetch all user metadata in parallel using build-safe helper
    final userCache = await _batchFetchUserMetadata(uniquePubkeys, currentUserPublicKey, ref);

    // Process messages in parallel using cached user data
    final futures = validMessages.map((messageData) async {
      final aggregatedData = replyMap[messageData.id];

      return await _fromMessageWithTokensWithCache(
        messageData,
        currentUserPublicKey: currentUserPublicKey,
        groupId: groupId,
        replyInfo: aggregatedData,
        originalMessageLookup: originalMessageMap,
        userCache: userCache,
      );
    });

    // Wait for all messages to be processed in parallel
    final messages = await Future.wait(futures);
    return messages;
  }

  /// Convert MessageWithTokens to MessageModel using cached user data
  static Future<MessageModel> _fromMessageWithTokensWithCache(
    MessageWithTokens messageData, {
    required String? currentUserPublicKey,
    String? groupId,
    ChatMessage? replyInfo,
    Map<String, MessageWithTokens>? originalMessageLookup,
    required Map<String, User> userCache,
  }) async {
    final isMe = currentUserPublicKey != null && messageData.pubkey == currentUserPublicKey;

    // Use cached user data instead of fetching
    final sender =
        userCache[messageData.pubkey] ??
        User(
          id: messageData.pubkey,
          displayName: 'Unknown User',
          nip05: '',
          publicKey: messageData.pubkey,
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

        // Use cached user data for reply sender too
        final replySender =
            userCache[originalMessage.pubkey] ??
            User(
              id: originalMessage.pubkey,
              displayName: 'Unknown User',
              nip05: '',
              publicKey: originalMessage.pubkey,
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
          kind: originalMessage.kind, // Use the original message's kind
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

    // Convert reactions from aggregated data if available
    final reactions =
        replyInfo != null
            ? _convertReactionsWithCache(replyInfo.reactions, userCache)
            : <Reaction>[];

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
      kind: messageData.kind, // Use the actual kind from the backend data
    );
  }

  /// Creates a User Model object from metadata cache with build-safe fetching
  static Future<User> _createUserFromMetadata(
    String pubkey, {
    String? currentUserPubkey,
    required Ref ref,
  }) async {
    // If this is the current user, return 'You'
    if (currentUserPubkey != null && pubkey == currentUserPubkey) {
      return User(
        id: pubkey,
        displayName: 'You',
        nip05: '',
        publicKey: pubkey,
      );
    }

    try {
      // First try contacts provider for cached data
      final followsNotifier = ref.read(followsProvider.notifier);
      final follow = followsNotifier.findFollowByPubkey(pubkey);

      if (follow != null) {
        final contactModel = ContactModel.fromUser(user: follow);
        return User(
          id: pubkey,
          displayName:
              contactModel.displayName.isNotEmpty ? contactModel.displayName : 'Unknown User',
          nip05: contactModel.nip05 ?? '',
          publicKey: pubkey,
          imagePath: contactModel.imagePath,
        );
      }

      // If not found in contacts, try metadata cache with build-safe scheduling
      return await Future.microtask(() async {
        final metadataCache = ref.read(metadataCacheProvider.notifier);
        final contactModel = await metadataCache.getContactModel(pubkey);

        return User(
          id: pubkey,
          displayName: contactModel.displayName,
          nip05: contactModel.nip05 ?? '',
          publicKey: pubkey,
          imagePath: contactModel.imagePath,
        );
      });
    } catch (e) {
      // Return fallback user if both lookups fail
      return User(
        id: pubkey,
        displayName: 'Unknown User',
        nip05: '',
        publicKey: pubkey,
      );
    }
  }

  /// Batch fetch all user metadata in parallel with build-safe scheduling
  static Future<Map<String, User>> _batchFetchUserMetadata(
    Set<String> uniquePubkeys,
    String? currentUserPublicKey,
    Ref ref,
  ) async {
    // Schedule metadata fetching in microtask to avoid build-time modifications
    return await Future.microtask(() async {
      final metadataCache = ref.read(metadataCacheProvider.notifier);
      final userFutures = uniquePubkeys.map(
        (pubkey) =>
            metadataCache.getContactModel(pubkey).then((contact) => MapEntry(pubkey, contact)),
      );
      final userResults = await Future.wait(userFutures);
      return Map<String, User>.fromEntries(
        userResults.map(
          (entry) => MapEntry(
            entry.key,
            User(
              id: entry.key,
              displayName: entry.key == currentUserPublicKey ? 'You' : entry.value.displayName,
              nip05: entry.value.nip05 ?? '',
              publicKey: entry.key,
              imagePath: entry.value.imagePath,
            ),
          ),
        ),
      );
    });
  }

  /// Convert ReactionSummary to MessageModel reactions format
  static List<Reaction> _convertReactions(ReactionSummary reactions) {
    final List<Reaction> convertedReactions = [];

    // Convert user reactions to Reaction objects
    for (final userReaction in reactions.userReactions) {
      final user = User(
        id: userReaction.user,
        displayName: 'Unknown User', // Will be resolved by metadata cache later
        nip05: '',
        publicKey: userReaction.user,
      );

      final reaction = Reaction(
        emoji: userReaction.emoji,
        user: user,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          userReaction.createdAt.toInt() * 1000,
        ),
      );

      convertedReactions.add(reaction);
    }

    return convertedReactions;
  }

  /// Convert ReactionSummary to MessageModel reactions format with user cache
  static List<Reaction> _convertReactionsWithCache(
    ReactionSummary reactions,
    Map<String, User> userCache,
  ) {
    final List<Reaction> convertedReactions = [];

    // Convert user reactions to Reaction objects
    for (final userReaction in reactions.userReactions) {
      final user =
          userCache[userReaction.user] ??
          User(
            id: userReaction.user,
            displayName: 'Unknown User',
            nip05: '',
            publicKey: userReaction.user,
          );

      final reaction = Reaction(
        emoji: userReaction.emoji,
        user: user,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          userReaction.createdAt.toInt() * 1000,
        ),
      );

      convertedReactions.add(reaction);
    }

    return convertedReactions;
  }
}
