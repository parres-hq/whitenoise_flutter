// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/states/chat_state.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/utils.dart';

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

      final messages = await fetchMessagesForGroup(
        pubkey: publicKey,
        groupId: groupIdObj,
      );

      // Sort messages by creation time (oldest first)
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

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

      _logger.info('ChatProvider: Loaded ${messages.length} messages for group $groupId');
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
    int kind = 1, // Default to text message
    List<Tag>? tags,
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

      // Add the sent message to the local state
      final currentMessages = state.groupMessages[groupId] ?? [];
      final updatedMessages = [...currentMessages, sentMessage];

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

      _logger.info('ChatProvider: Message sent successfully to group $groupId');
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
    final updatedMessages = Map<String, List<MessageWithTokensData>>.from(state.groupMessages);
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

  /// Helper method to set error for a specific group
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
  List<MessageWithTokensData> getMessagesForGroup(String groupId) {
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
  MessageWithTokensData? getLatestMessageForGroup(String groupId) {
    return state.getLatestMessageForGroup(groupId);
  }

  /// Get unread message count for a group
  int getUnreadCountForGroup(String groupId) {
    return state.getUnreadCountForGroup(groupId);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
