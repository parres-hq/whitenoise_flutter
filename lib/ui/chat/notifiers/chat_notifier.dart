import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/domain/models/message_model.dart';

import 'package:whitenoise/ui/chat/states/chat_state.dart' as ui_state;
import 'package:whitenoise/ui/chat/utils/message_extensions.dart';

class ChatNotifier extends Notifier<ui_state.ChatState> {
  final _logger = Logger('ChatNotifier');

  @override
  ui_state.ChatState build() => const ui_state.ChatState();

  Future<void> initialize(String groupId) async {
    // Set current user pubkey for message helper
    final currentUserPubkey = await _getCurrentUserPubkey();
    if (currentUserPubkey != null) {
      MessageHelper.setCurrentUserPubkey(currentUserPubkey);
    }

    // Load messages from chat provider
    await loadMessagesForGroup(groupId);
  }

  Future<void> loadMessagesForGroup(String groupId) async {
    final chatProviderNotifier = ref.read(chatProvider.notifier);
    await chatProviderNotifier.loadMessagesForGroup(groupId);

    final chatState = ref.read(chatProvider);
    final messagesWithTokens = chatState.getMessagesForGroup(groupId);

    final messages =
        messagesWithTokens.map((message) {
          // Convert MessageWithTokensData to MessageModel for UI
          return MessageModel.fromMessageWithTokens(message);
        }).toList();

    state = state.copyWith(messages: messages);
  }

  bool _isAuthAvailable() {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      state = state.copyWith(error: 'Not authenticated');
      return false;
    }
    return true;
  }

  Future<String?> _getCurrentUserPubkey() async {
    if (!_isAuthAvailable()) return null;

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return null;
      }

      return activeAccountData.pubkey;
    } catch (e) {
      _logger.severe('Error getting current user pubkey: $e');
      return null;
    }
  }

  /// Check if a message is from the current user
  Future<bool> isMessageFromMe(MessageModel message) async {
    final currentUserPubkey = await _getCurrentUserPubkey();
    if (currentUserPubkey == null) return false;
    return message.sender.publicKey == currentUserPubkey;
  }

  Future<void> updateMessageReaction({
    required MessageModel message,
    required String reaction,
  }) async {
    // TODO: Implement reaction handling for MessageModel
    // This would need to be handled via the chat provider
    _logger.info('Reaction handling not yet implemented for MessageModel');
  }

  void sendNewMessageOrEdit(
    MessageModel message, {
    bool isEditing = false,
    required String groupId,
    VoidCallback? onMessageSent,
  }) async {
    final chatProviderNotifier = ref.read(chatProvider.notifier);

    if (isEditing) {
      // TODO: Implement message editing
      _logger.info('Message editing not yet implemented');
    } else {
      // Send new message via chat provider
      final content = message.content ?? '';
      if (content.isEmpty) {
        _logger.warning('Cannot send empty message');
        return;
      }
      final sentMessage = await chatProviderNotifier.sendMessage(
        groupId: groupId,
        message: content,
      );

      if (sentMessage != null) {
        // Refresh local messages
        await loadMessagesForGroup(groupId);
        onMessageSent?.call();
      }
    }
  }

  void handleReply(MessageModel message) {
    state = state.copyWith(
      replyingTo: message,
      clearEditingMessage: true,
    );
  }

  void handleEdit(MessageModel message) {
    state = state.copyWith(
      editingMessage: message,
      clearReplyingTo: true,
    );
  }

  void cancelReply() {
    state = state.copyWith(
      clearReplyingTo: true,
    );
  }

  void cancelEdit() {
    state = state.copyWith(
      clearEditingMessage: true,
    );
  }

  bool isSameSender(int index) {
    if (index <= 0 || index >= state.messages.length) return false;
    return state.messages[index].sender.publicKey == state.messages[index - 1].sender.publicKey;
  }

  bool isNextSameSender(int index) {
    if (index < 0 || index >= state.messages.length - 1) return false;
    return state.messages[index].sender.publicKey == state.messages[index + 1].sender.publicKey;
  }

  void setError(String error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

final chatNotifierProvider = NotifierProvider<ChatNotifier, ui_state.ChatState>(
  ChatNotifier.new,
);
