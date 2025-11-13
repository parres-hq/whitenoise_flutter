// ignore_for_file: avoid_redundant_argument_values

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/group_messages_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/states/chat_state.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/services/last_read_manager.dart';
import 'package:whitenoise/domain/services/message_merger_service.dart';
import 'package:whitenoise/domain/services/message_sender_service.dart';
import 'package:whitenoise/domain/services/reaction_comparison_service.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/utils/message_converter.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';

class ChatNotifier extends Notifier<ChatState> {
  final _logger = Logger('ChatNotifier');
  late final MessageSenderService _messageSenderService;

  ChatNotifier({
    MessageSenderService? messageSenderService,
  }) {
    _messageSenderService = messageSenderService ?? MessageSenderService();
  }

  @override
  ChatState build() {
    // Listen to active account changes and refresh chats automatically
    ref.listen<String?>(activePubkeyProvider, (previous, next) {
      if (previous != null && next != null && previous != next) {
        // Schedule state changes after the build phase to avoid provider modification errors
        WidgetsBinding.instance.addPostFrameCallback((_) {
          clearAllData();
        });
      } else if (previous != null && next == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          clearAllData();
        });
      }
    });

    return const ChatState();
  }

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

    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    if (activePubkey.isEmpty) {
      _logger.severe('No active account found');
      return;
    }

    // Set loading state for this specific group
    state = state.copyWith(
      groupLoadingStates: {
        ...state.groupLoadingStates,
        groupId: true,
      },
    );

    try {
      _logger.info('ChatProvider: Loading messages for group $groupId');

      final dbMessages = await ref.read(groupMessagesProvider(groupId).notifier).fetchMessages();
      final stateMessages = state.groupMessages[groupId] ?? [];
      final mergedMessages = MessageMergerService.merge(
        stateMessages: stateMessages,
        dbMessages: dbMessages,
      );

      state = state.copyWith(
        groupMessages: {
          ...state.groupMessages,
          groupId: mergedMessages,
        },
        groupLoadingStates: {
          ...state.groupLoadingStates,
          groupId: false,
        },
      );
    } catch (e, st) {
      _logger.severe('ChatProvider.loadMessagesForGroup', e, st);
      state = state.copyWith(
        groupLoadingStates: {
          ...state.groupLoadingStates,
          groupId: false,
        },
      );
    }
  }

  Future<MessageWithTokens?> sendMessage({
    required String groupId,
    required String message,
    required List<MediaFile> mediaFiles,
    bool isEditing = false,
    void Function()? onMessageSent,
  }) async {
    if (!_isAuthAvailable()) {
      return null;
    }

    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    if (activePubkey.isEmpty) {
      _logger.severe(groupId, 'No active account found');
      return null;
    }

    state = state.copyWith(
      sendingStates: {
        ...state.sendingStates,
        groupId: true,
      },
    );

    try {
      _logger.info('ChatProvider: Sending message to group $groupId');

      state = state.copyWith(
        sendingStates: {
          ...state.sendingStates,
          groupId: true,
        },
      );

      final sendingMessage = await _messageSenderService.sendMessage(
        pubkey: activePubkey,
        groupId: groupId,
        content: message,
        mediaFiles: mediaFiles,
      );

      final optimisticMessageModel = MessageConverter.createOptimisticMessage(
        id: sendingMessage.id,
        content: message,
        currentUserPublicKey: activePubkey,
        groupId: groupId,
        mediaFiles: mediaFiles,
      );

      final stateMessages = state.groupMessages[groupId] ?? [];

      state = state.copyWith(
        groupMessages: {
          ...state.groupMessages,
          groupId: [...stateMessages, optimisticMessageModel],
        },
        sendingStates: {
          ...state.sendingStates,
          groupId: false,
        },
      );

      await _updateGroupOrderForNewMessage(groupId);

      // Save last read when user sends a message (immediate save)
      final messagesForLastRead = state.groupMessages[groupId] ?? [];
      if (messagesForLastRead.isNotEmpty) {
        final latestMessage = messagesForLastRead.last;
        LastReadManager.saveLastReadImmediate(groupId, latestMessage.createdAt);
      }

      _logger.info('ChatProvider: Message sent successfully to group $groupId');
      onMessageSent?.call();
      return sendingMessage;
    } catch (e, st) {
      _logger.severe('ChatProvider.sendMessage', e, st);
      state = state.copyWith(
        sendingStates: {
          ...state.sendingStates,
          groupId: false,
        },
      );
      return null;
    }
  }

  /// Refresh messages for a group (reload from server)
  Future<void> refreshMessagesForGroup(String groupId) async {
    await loadMessagesForGroup(groupId);
  }

  /// Set the currently selected group
  void setSelectedGroup(String? groupId) {
    state = state.copyWith(selectedGroupId: groupId);

    // Auto-load messages when selecting a group, but schedule it outside the build phase
    if (groupId != null) {
      Future.microtask(() {
        loadMessagesForGroup(groupId);
      });
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
      final activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) {
        return;
      }

      final dbMessages = await ref.read(groupMessagesProvider(groupId).notifier).fetchMessages();

      final stateMessages = state.groupMessages[groupId] ?? [];

      // Check for changes beyond just message count (reactions, edits, etc.)
      bool hasChanges = false;

      if (dbMessages.length != stateMessages.length) {
        // New or deleted messages
        hasChanges = true;
      } else if (dbMessages.isNotEmpty && stateMessages.isNotEmpty) {
        // Check if any message content or reactions have changed
        for (int i = 0; i < dbMessages.length; i++) {
          final newMsg = dbMessages[i];
          final currentMsg = stateMessages[i];

          // Compare message content and reactions
          if (newMsg.content != currentMsg.content ||
              ReactionComparisonService.areDifferent(newMsg.reactions, currentMsg.reactions)) {
            hasChanges = true;
            break;
          }
        }
      }

      if (hasChanges) {
        final groupMessages = MessageMergerService.merge(
          stateMessages: stateMessages,
          dbMessages: dbMessages,
        );

        state = state.copyWith(
          groupMessages: {
            ...state.groupMessages,
            groupId: groupMessages,
          },
        );

        _logger.info(
          'ChatProvider: Updated messages with content changes for group $groupId',
        );

        // Update group order when messages are updated
        _updateGroupOrderForNewMessage(groupId);
      }
    } catch (e, st) {
      _logger.severe('ChatProvider.checkForNewMessages', e, st);
    }
  }

  Future<void> checkForNewMessagesInGroups(List<String> groupIds) async {
    final futures = groupIds.map((groupId) => checkForNewMessages(groupId));
    await Future.wait(futures);
  }

  /// Get messages for a specific group (convenience method)
  List<MessageModel> getMessagesForGroup(String groupId) {
    return state.getMessagesForGroup(groupId);
  }

  /// Check if a group is currently loading
  bool isGroupLoading(String groupId) {
    return state.isGroupLoading(groupId);
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
    final selectedGroupId = groupId ?? state.selectedGroupId;
    if (selectedGroupId == null) return false;
    final groupMessages = state.groupMessages[selectedGroupId] ?? [];
    if (index <= 0 || index >= groupMessages.length) return false;
    final currentSenderPubkey = groupMessages[index].sender.publicKey;
    final currentSenderHexPubkey = PubkeyFormatter(pubkey: currentSenderPubkey).toHex() ?? '';
    final previousSenderPubkey = groupMessages[index - 1].sender.publicKey;
    final previousSenderHexPubkey = PubkeyFormatter(pubkey: previousSenderPubkey).toHex() ?? '';
    if (currentSenderHexPubkey.isEmpty || previousSenderHexPubkey.isEmpty) return false;
    return currentSenderHexPubkey == previousSenderHexPubkey;
  }

  bool isNextSameSender(int index, {String? groupId}) {
    final selectedGroupId = groupId ?? state.selectedGroupId;
    if (selectedGroupId == null) return false;
    final groupMessages = state.groupMessages[selectedGroupId] ?? [];
    if (index < 0 || index >= groupMessages.length - 1) return false;
    final currentSenderPubkey = groupMessages[index].sender.publicKey;
    final currentSenderHexPubkey = PubkeyFormatter(pubkey: currentSenderPubkey).toHex() ?? '';
    final nextSenderPubkey = groupMessages[index + 1].sender.publicKey;
    final nextSenderHexPubkey = PubkeyFormatter(pubkey: nextSenderPubkey).toHex() ?? '';
    if (currentSenderHexPubkey.isEmpty || nextSenderHexPubkey.isEmpty) return false;
    return currentSenderHexPubkey == nextSenderHexPubkey;
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
      final activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) {
        _logger.severe('No active account found');
        return false;
      }
      final groupId = message.groupId;
      if (groupId == null || groupId.isEmpty) {
        _logger.warning('Cannot update reaction: message has no groupId');
        return false;
      }

      _logger.info('ChatProvider: Adding reaction "$reaction" to message ${message.id}');

      // Use the message's actual kind (now stored in MessageModel)
      final originalMessageKind = messageKind ?? message.kind;
      await _messageSenderService.sendReaction(
        pubkey: activePubkey,
        groupId: message.groupId ?? '',
        messageId: message.id,
        messagePubkey: message.sender.publicKey,
        messageKind: originalMessageKind,
        emoji: reaction,
      );

      // Refresh messages to get updated reactions
      await refreshMessagesForGroup(message.groupId ?? '');

      _logger.info('ChatProvider: Reaction added successfully');
      return true;
    } catch (e, st) {
      _logger.severe('ChatProvider.updateMessageReaction', e, st);
      return false;
    }
  }

  /// Send a reply message to a specific message
  Future<MessageWithTokens?> sendReplyMessage({
    required String groupId,
    required String replyToMessageId,
    required String message,
    required List<MediaFile> mediaFiles,
    void Function()? onMessageSent,
  }) async {
    if (!_isAuthAvailable()) {
      return null;
    }

    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    if (activePubkey.isEmpty) {
      _logger.severe('No active account found');
      return null;
    }

    final allMessages = getMessagesForGroup(groupId);
    final replyToMessage = allMessages.firstWhereOrNull((msg) => msg.id == replyToMessageId);
    state = state.copyWith(
      sendingStates: {
        ...state.sendingStates,
        groupId: true,
      },
    );

    try {
      _logger.info('ChatProvider: Sending reply to message $replyToMessageId');

      final sendingMessage = await _messageSenderService.sendReply(
        pubkey: activePubkey,
        groupId: groupId,
        replyToMessageId: replyToMessageId,
        content: message,
        mediaFiles: mediaFiles,
      );

      final optimisticMessage = MessageConverter.createOptimisticMessage(
        id: sendingMessage.id,
        content: message,
        currentUserPublicKey: activePubkey,
        groupId: groupId,
        replyToMessage: replyToMessage,
        mediaFiles: mediaFiles,
      );

      final stateMessages = state.groupMessages[groupId] ?? [];

      state = state.copyWith(
        groupMessages: {
          ...state.groupMessages,
          groupId: [...stateMessages, optimisticMessage],
        },
        sendingStates: {
          ...state.sendingStates,
          groupId: false,
        },
      );

      _updateGroupOrderForNewMessage(groupId);
      onMessageSent?.call();
      return sendingMessage;
    } catch (e, st) {
      _logger.severe('ChatProvider.sendReplyMessage', e, st);
      state = state.copyWith(
        sendingStates: {
          ...state.sendingStates,
          groupId: false,
        },
      );

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
      final activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) {
        _logger.severe('No active account found');
        return false;
      }

      _logger.info('ChatProvider: Deleting message $messageId');

      await _messageSenderService.sendDeletion(
        pubkey: activePubkey,
        groupId: groupId,
        messageId: messageId,
        messagePubkey: messagePubkey,
        messageKind: messageKind,
      );

      // Refresh messages to get updated state
      await refreshMessagesForGroup(groupId);

      _logger.info('ChatProvider: Message deleted successfully');
      return true;
    } catch (e, st) {
      _logger.severe('ChatProvider.deleteMessage', e, st);
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

  Future<void> _updateGroupOrderForNewMessage(String groupId) async {
    final now = DateTime.now();

    await ref.read(groupsProvider.notifier).updateGroupActivityTime(groupId, now);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  () => ChatNotifier(),
);
