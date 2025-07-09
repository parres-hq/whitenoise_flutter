// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/states/chat_state.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/utils/message_converter.dart';

class ChatNotifier extends Notifier<ChatState> {
  final _logger = Logger('ChatNotifier');

  @override
  ChatState build() => const ChatState();

  // Helper to check if auth is available
  bool _isAuthAvailable() {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      state = state.copyWith(error: 'Not authenticated');
      return false;
    }
    return true;
  }

  /// Load messages for a specific group
  Future<void> loadMessagesForGroup(String groupId) async {
    if (!_isAuthAvailable()) {
      return;
    }

    // Set loading state for this specific group
    state = state.copyWith(
      groupLoadingStates: {
        ...state.groupLoadingStates,
        groupId: true,
      },
      groupErrorStates: {
        ...state.groupErrorStates,
        groupId: null,
      },
    );

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        _setGroupError(groupId, 'No active account found');
        return;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final groupIdObj = await groupIdFromString(hexString: groupId);

      _logger.info('ChatProvider: Loading messages for group $groupId');

      // Use fetchAggregatedMessagesForGroup which includes all message data including replies
      final aggregatedMessages = await fetchAggregatedMessagesForGroup(
        pubkey: publicKey,
        groupId: groupIdObj,
      );

      _logger.info(
        'ChatProvider: Fetched ${aggregatedMessages.length} aggregated messages',
      );

      // Sort messages by creation time (oldest first)
      aggregatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final messages = await MessageConverter.fromChatMessageDataList(
        aggregatedMessages,
        currentUserPublicKey: activeAccountData.pubkey,
        groupId: groupId,
        ref: ref,
      );

      state = state.copyWith(
        groupMessages: {
          ...state.groupMessages,
          groupId: messages,
        },
        groupLoadingStates: {
          ...state.groupLoadingStates,
          groupId: false,
        },
      );

      _logger.info('ChatProvider: Loaded ${aggregatedMessages.length} messages for group $groupId');
    } catch (e, st) {
      _logger.severe('ChatProvider.loadMessagesForGroup', e, st);
      String errorMessage = 'Failed to load messages';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning('Failed to convert WhitenoiseError to string: $conversionError');
          errorMessage = 'Failed to load messages due to an internal error';
        }
      } else {
        errorMessage = e.toString();
      }
      _setGroupError(groupId, errorMessage);
    }
  }

  /// Send a message to a group
  Future<MessageWithTokensData?> sendMessage({
    required String groupId,
    required String message,
    int kind = 9, // Default to text message
    List<Tag>? tags,
    bool isEditing = false,
    void Function()? onMessageSent,
  }) async {
    if (!_isAuthAvailable()) {
      return null;
    }

    // Set sending state for this group
    state = state.copyWith(
      sendingStates: {
        ...state.sendingStates,
        groupId: true,
      },
      groupErrorStates: {
        ...state.groupErrorStates,
        groupId: null,
      },
    );

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        _setGroupError(groupId, 'No active account found');
        return null;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final groupIdObj = await groupIdFromString(hexString: groupId);

      _logger.info('ChatProvider: Sending message to group $groupId');

      final sentMessage = await sendMessageToGroup(
        pubkey: publicKey,
        groupId: groupIdObj,
        message: message,
        kind: kind,
        tags: tags,
      );

      // Convert sent message to MessageModel and add to local state
      final currentMessages = state.groupMessages[groupId] ?? [];

      // Create ChatMessageData from the sent message
      final sentChatMessageData = ChatMessageData(
        id: sentMessage.id,
        pubkey: sentMessage.pubkey,
        content: sentMessage.content ?? '',
        createdAt: sentMessage.createdAt,
        tags: const [],
        isReply: false,
        replyToId: null,
        isDeleted: false,
        contentTokens: const [],
        reactions: const ReactionSummaryData(byEmoji: [], userReactions: []),
        kind: sentMessage.kind,
      );

      // Build message cache from current messages for consistency
      final messageCache = <String, ChatMessageData>{};
      for (final msg in currentMessages) {
        // Convert existing MessageModel back to ChatMessageData for cache
        final chatMessageData = ChatMessageData(
          id: msg.id,
          pubkey: msg.sender.publicKey,
          content: msg.content ?? '',
          createdAt: BigInt.from(msg.createdAt.millisecondsSinceEpoch ~/ 1000),
          tags: const [],
          isReply: msg.replyTo != null,
          replyToId: msg.replyTo?.id,
          isDeleted: false,
          contentTokens: const [],
          reactions: const ReactionSummaryData(byEmoji: [], userReactions: []),
          kind: msg.kind, // Use the actual message kind
        );
        messageCache[msg.id] = chatMessageData;
      }

      final sentMessageModel = await MessageConverter.fromChatMessageData(
        sentChatMessageData,
        currentUserPublicKey: activeAccountData.pubkey,
        groupId: groupId,
        ref: ref,
        messageCache: messageCache,
      );
      final updatedMessages = [...currentMessages, sentMessageModel];

      state = state.copyWith(
        groupMessages: {
          ...state.groupMessages,
          groupId: updatedMessages,
        },
        sendingStates: {
          ...state.sendingStates,
          groupId: false,
        },
      );

      // Update group order by triggering a resort based on the new message
      _updateGroupOrderForNewMessage(groupId);

      _logger.info('ChatProvider: Message sent successfully to group $groupId');
      onMessageSent?.call();
      return sentMessage;
    } catch (e, st) {
      _logger.severe('ChatProvider.sendMessage', e, st);
      String errorMessage = 'Failed to send message';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning('Failed to convert WhitenoiseError to string: $conversionError');
          errorMessage = 'Failed to send message due to an internal error';
        }
      } else {
        errorMessage = e.toString();
      }
      _setGroupError(groupId, errorMessage);

      // Clear sending state
      state = state.copyWith(
        sendingStates: {
          ...state.sendingStates,
          groupId: false,
        },
      );

      return null;
    }
  }

  /// Send a legacy NIP-04 message
  Future<bool> sendLegacyNip04Message({
    required String contactPubkey,
    required String message,
  }) async {
    if (!_isAuthAvailable()) {
      throw Exception('Not authenticated');
    }

    final activeAccountData = await ref.read(activeAccountProvider.notifier).getActiveAccountData();
    if (activeAccountData == null) {
      throw Exception('No active account found');
    }

    final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
    final contactPublicKey = await publicKeyFromString(publicKeyString: contactPubkey);

    _logger.info(
      'ChatProvider: Sending legacy NIP-04 message to $contactPubkey from ${activeAccountData.pubkey}',
    );

    try {
      final tags = <Tag>[];
      await sendDirectMessageNip04(
        sender: publicKey,
        receiver: contactPublicKey,
        content: message,
        tags: tags,
      );

      _logger.info('ChatProvider: Legacy NIP-04 message sent successfully');
      return true;
    } catch (e, st) {
      _logger.severe('ChatProvider.sendLegacyNip04Message', e, st);
      String errorMessage = 'Failed to send legacy NIP-04 message';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning('Failed to convert WhitenoiseError to string: $conversionError');
          errorMessage = 'Failed to send message due to an internal error';
        }
      } else {
        errorMessage = e.toString();
      }
      throw Exception(errorMessage);
    }
  }

  /// Refresh messages for a group (reload from server)
  Future<void> refreshMessagesForGroup(String groupId) async {
    await loadMessagesForGroup(groupId);
  }

  /// Set the currently selected group
  void setSelectedGroup(String? groupId) {
    state = state.copyWith(selectedGroupId: groupId);

    // Auto-load messages when selecting a group
    if (groupId != null) {
      loadMessagesForGroup(groupId);
    }
  }

  /// Clear messages for a specific group
  void clearMessagesForGroup(String groupId) {
    final updatedMessages = Map<String, List<MessageModel>>.from(state.groupMessages);
    updatedMessages.remove(groupId);

    state = state.copyWith(groupMessages: updatedMessages);
  }

  /// Clear all chat data
  void clearAllData() {
    state = const ChatState();
  }

  /// Load messages for multiple groups
  Future<void> loadMessagesForGroups(List<String> groupIds) async {
    final futures = groupIds.map((groupId) => loadMessagesForGroup(groupId));
    await Future.wait(futures);
  }

  Future<void> checkForNewMessages(String groupId) async {
    if (!_isAuthAvailable()) {
      return;
    }

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        return;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final groupIdObj = await groupIdFromString(hexString: groupId);

      // Use fetchAggregatedMessagesForGroup for polling as well
      final aggregatedMessages = await fetchAggregatedMessagesForGroup(
        pubkey: publicKey,
        groupId: groupIdObj,
      );

      aggregatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final newMessages = await MessageConverter.fromChatMessageDataList(
        aggregatedMessages,
        currentUserPublicKey: activeAccountData.pubkey,
        groupId: groupId,
        ref: ref,
      );

      final currentMessages = state.groupMessages[groupId] ?? [];
      if (newMessages.length > currentMessages.length) {
        final newMessagesOnly = newMessages.skip(currentMessages.length).toList();

        state = state.copyWith(
          groupMessages: {
            ...state.groupMessages,
            groupId: [...currentMessages, ...newMessagesOnly],
          },
        );

        // Update group order when new messages are received
        _updateGroupOrderForNewMessage(groupId);

        _logger.info(
          'ChatProvider: Added ${newMessagesOnly.length} new messages for group $groupId',
        );
      }
    } catch (e, st) {
      _logger.severe('ChatProvider.checkForNewMessages', e, st);
    }
  }

  Future<void> checkForNewMessagesInGroups(List<String> groupIds) async {
    final futures = groupIds.map((groupId) => checkForNewMessages(groupId));
    await Future.wait(futures);
  }

  void _setGroupError(String groupId, String error) {
    state = state.copyWith(
      groupLoadingStates: {
        ...state.groupLoadingStates,
        groupId: false,
      },
      groupErrorStates: {
        ...state.groupErrorStates,
        groupId: error,
      },
      sendingStates: {
        ...state.sendingStates,
        groupId: false,
      },
    );
  }

  /// Clear error for a specific group
  void clearGroupError(String groupId) {
    state = state.copyWith(
      groupErrorStates: {
        ...state.groupErrorStates,
        groupId: null,
      },
    );
  }

  /// Get messages for a specific group (convenience method)
  List<MessageModel> getMessagesForGroup(String groupId) {
    return state.getMessagesForGroup(groupId);
  }

  /// Check if a group is currently loading
  bool isGroupLoading(String groupId) {
    return state.isGroupLoading(groupId);
  }

  /// Get error for a specific group
  String? getGroupError(String groupId) {
    return state.getGroupError(groupId);
  }

  /// Check if currently sending a message to a group
  bool isSendingToGroup(String groupId) {
    return state.isSendingToGroup(groupId);
  }

  /// Get the latest message for a group
  MessageModel? getLatestMessageForGroup(String groupId) {
    return state.getLatestMessageForGroup(groupId);
  }

  bool isSameSender(int index, {String? groupId}) {
    final gId = groupId ??= state.selectedGroupId;
    if (gId == null) return false;
    final groupMessages = state.groupMessages[gId] ?? [];
    if (index <= 0 || index >= groupMessages.length) return false;
    return groupMessages[index].sender.publicKey == groupMessages[index - 1].sender.publicKey;
  }

  bool isNextSameSender(int index, {String? groupId}) {
    final gId = groupId ??= state.selectedGroupId;
    if (gId == null) return false;
    final groupMessages = state.groupMessages[gId] ?? [];
    if (index < 0 || index >= groupMessages.length - 1) return false;
    return groupMessages[index].sender.publicKey == groupMessages[index + 1].sender.publicKey;
  }

  /// Get unread message count for a group
  int getUnreadCountForGroup(String groupId) {
    return state.getUnreadCountForGroup(groupId);
  }

  /// Get the message being replied to for a group
  MessageModel? getReplyingTo(String groupId) {
    return state.getReplyingTo(groupId);
  }

  /// Get the message being edited for a group
  MessageModel? getEditingMessage(String groupId) {
    return state.getEditingMessage(groupId);
  }

  /// Check if currently replying to a message in a group
  bool isReplying(String groupId) {
    return state.isReplying(groupId);
  }

  /// Check if currently editing a message in a group
  bool isEditing(String groupId) {
    return state.isEditing(groupId);
  }

  /// Get the message being replied to for the currently selected group
  MessageModel? get currentReplyingTo {
    if (state.selectedGroupId == null) return null;
    return state.getReplyingTo(state.selectedGroupId!);
  }

  /// Get the message being edited for the currently selected group
  MessageModel? get currentEditingMessage {
    if (state.selectedGroupId == null) return null;
    return state.getEditingMessage(state.selectedGroupId!);
  }

  /// Check if currently replying in the selected group
  bool get isCurrentlyReplying {
    if (state.selectedGroupId == null) return false;
    return state.isReplying(state.selectedGroupId!);
  }

  /// Check if currently editing in the selected group
  bool get isCurrentlyEditing {
    if (state.selectedGroupId == null) return false;
    return state.isEditing(state.selectedGroupId!);
  }

  /// Add or remove a reaction to/from a message
  Future<bool> updateMessageReaction({
    required MessageModel message,
    required String reaction,
    int? messageKind,
  }) async {
    if (!_isAuthAvailable()) {
      return false;
    }

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        _setGroupError(message.groupId ?? '', 'No active account found');
        return false;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final groupIdObj = await groupIdFromString(hexString: message.groupId ?? '');

      _logger.info('ChatProvider: Adding reaction "$reaction" to message ${message.id}');

      // Create reaction content (emoji) - NIP-25 compliant
      // Content MUST include user-generated-content indicating the value of the reaction
      // (conventionally +, -, or an emoji)
      final reactionContent = reaction; // This should be an emoji like 👍, ❤️, etc.

      // Use the message's actual kind (now stored in MessageModel)
      final originalMessageKind = messageKind ?? message.kind;

      // NIP-25 compliant reaction tags
      // According to NIP-25:
      // - MUST have e tag with event id being reacted to
      // - SHOULD have p tag with pubkey of event being reacted to
      // - SHOULD have k tag with stringified kind number of reacted event
      final reactionTags = [
        // e tag: ["e", <event-id>, <relay-hint>, <pubkey-hint>]
        await tagFromVec(vec: ['e', message.id, '', message.sender.publicKey]),
        // p tag: ["p", <pubkey>, <relay-hint>]
        await tagFromVec(vec: ['p', message.sender.publicKey, '']),
        // k tag: ["k", <kind-number>]
        await tagFromVec(vec: ['k', originalMessageKind.toString()]),
      ];

      // Send reaction message (kind 7 for reactions in Nostr)
      await sendMessageToGroup(
        pubkey: publicKey,
        groupId: groupIdObj,
        message: reactionContent,
        kind: 7, // Nostr kind 7 = reaction
        tags: reactionTags,
      );

      // Refresh messages to get updated reactions
      await refreshMessagesForGroup(message.groupId ?? '');

      _logger.info('ChatProvider: Reaction added successfully');
      return true;
    } catch (e, st) {
      _logger.severe('ChatProvider.updateMessageReaction', e, st);
      
      String errorMessage = 'Failed to add reaction';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning('Failed to convert WhitenoiseError to string: $conversionError');
          errorMessage = 'Failed to update reaction due to an internal error';
        }
      } else {
        errorMessage = e.toString();
      }
      _setGroupError(message.groupId ?? '', errorMessage);
      return false;
    }
  }

  /// Send a reply message to a specific message
  Future<MessageWithTokensData?> sendReplyMessage({
    required String groupId,
    required String replyToMessageId,
    required String message,
    void Function()? onMessageSent,
  }) async {
    if (!_isAuthAvailable()) {
      return null;
    }

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        _setGroupError(groupId, 'No active account found');
        return null;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final groupIdObj = await groupIdFromString(hexString: groupId);

      _logger.info('ChatProvider: Sending reply to message $replyToMessageId');

      // Create tags for reply
      final replyTags = [
        await tagFromVec(vec: ['e', replyToMessageId]),
      ];

      // Send the reply message using rust API
      final sentMessage = await sendMessageToGroup(
        pubkey: publicKey,
        groupId: groupIdObj,
        message: message,
        kind: 9, // Kind 9 for replies
        tags: replyTags,
      );

      // Convert to MessageModel and add to local state
      final currentMessages = state.groupMessages[groupId] ?? [];

      // Create ChatMessageData for the reply message
      final sentChatMessageData = ChatMessageData(
        id: sentMessage.id,
        pubkey: sentMessage.pubkey,
        content: sentMessage.content ?? '',
        createdAt: sentMessage.createdAt,
        tags: const [],
        isReply: true,
        replyToId: replyToMessageId,
        isDeleted: false,
        contentTokens: const [],
        reactions: const ReactionSummaryData(byEmoji: [], userReactions: []),
        kind: sentMessage.kind,
      );

      // Build message cache from current messages for reply lookup
      final messageCache = <String, ChatMessageData>{};
      for (final msg in currentMessages) {
        // Convert existing MessageModel back to ChatMessageData for cache
        final chatMessageData = ChatMessageData(
          id: msg.id,
          pubkey: msg.sender.publicKey,
          content: msg.content ?? '',
          createdAt: BigInt.from(msg.createdAt.millisecondsSinceEpoch ~/ 1000),
          tags: const [],
          isReply: msg.replyTo != null,
          replyToId: msg.replyTo?.id,
          isDeleted: false,
          contentTokens: const [],
          reactions: const ReactionSummaryData(byEmoji: [], userReactions: []),
          kind: msg.kind, // Use the actual message kind
        );
        messageCache[msg.id] = chatMessageData;
      }

      final sentMessageModel = await MessageConverter.fromChatMessageData(
        sentChatMessageData,
        currentUserPublicKey: activeAccountData.pubkey,
        groupId: groupId,
        ref: ref,
        messageCache: messageCache,
      );
      final updatedMessages = [...currentMessages, sentMessageModel];

      state = state.copyWith(
        groupMessages: {
          ...state.groupMessages,
          groupId: updatedMessages,
        },
      );

      _updateGroupOrderForNewMessage(groupId);
      onMessageSent?.call();
      return sentMessage;
    } catch (e, st) {
      _logger.severe('ChatProvider.sendReplyMessage', e, st);
      String errorMessage = 'Failed to send reply';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning('Failed to convert WhitenoiseError to string: $conversionError');
          errorMessage = 'Failed to send reply due to an internal error';
        }
      } else {
        errorMessage = e.toString();
      }
      _setGroupError(groupId, errorMessage);
      return null;
    }
  }

  /// Delete a message
  Future<bool> deleteMessage({
    required String groupId,
    required String messageId,
    required int messageKind,
    required String messagePubkey,
  }) async {
    if (!_isAuthAvailable()) {
      return false;
    }

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        _setGroupError(groupId, 'No active account found');
        return false;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final groupIdObj = await groupIdFromString(hexString: groupId);

      _logger.info('ChatProvider: Deleting message $messageId');

      // Create tags for deletion (NIP-09)
      final deleteTags = [
        await tagFromVec(vec: ['e', messageId]),
        await tagFromVec(vec: ['p', messagePubkey]), // Author of the message being deleted
        await tagFromVec(vec: ['k', messageKind.toString()]), // Kind of the message being deleted
      ];

      // Send deletion message using rust API
      await sendMessageToGroup(
        pubkey: publicKey,
        groupId: groupIdObj,
        message: '', // Empty content for deletion
        kind: 5, // Nostr kind 5 = deletion
        tags: deleteTags,
      );

      // Refresh messages to get updated state
      await refreshMessagesForGroup(groupId);

      _logger.info('ChatProvider: Message deleted successfully');
      return true;
    } catch (e, st) {
      _logger.severe('ChatProvider.deleteMessage', e, st);
      String errorMessage = 'Failed to delete message';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning('Failed to convert WhitenoiseError to string: $conversionError');
          errorMessage = 'Failed to delete message due to an internal error';
        }
      } else {
        errorMessage = e.toString();
      }
      _setGroupError(groupId, errorMessage);
      return false;
    }
  }

  void handleReply(MessageModel message, {String? groupId}) {
    final targetGroupId = groupId ?? message.groupId;
    if (targetGroupId == null) return;

    state = state.copyWith(
      replyingTo: {
        ...state.replyingTo,
        targetGroupId: message,
      },
      // Clear editing when starting a reply
      editingMessage: {
        ...state.editingMessage,
        targetGroupId: null,
      },
    );
  }

  void handleEdit(MessageModel message, {String? groupId}) {
    final targetGroupId = groupId ?? message.groupId;
    if (targetGroupId == null) return;

    state = state.copyWith(
      editingMessage: {
        ...state.editingMessage,
        targetGroupId: message,
      },
      // Clear replying when starting an edit
      replyingTo: {
        ...state.replyingTo,
        targetGroupId: null,
      },
    );
  }

  void cancelReply({String? groupId}) {
    if (groupId == null && state.selectedGroupId == null) return;
    final targetGroupId = groupId ?? state.selectedGroupId!;

    state = state.copyWith(
      replyingTo: {
        ...state.replyingTo,
        targetGroupId: null,
      },
    );
  }

  void cancelEdit({String? groupId}) {
    if (groupId == null && state.selectedGroupId == null) return;
    final targetGroupId = groupId ?? state.selectedGroupId!;

    state = state.copyWith(
      editingMessage: {
        ...state.editingMessage,
        targetGroupId: null,
      },
    );
  }

  void _updateGroupOrderForNewMessage(String groupId) {
    final now = DateTime.now();

    ref.read(groupsProvider.notifier).updateGroupActivityTime(groupId, now);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
