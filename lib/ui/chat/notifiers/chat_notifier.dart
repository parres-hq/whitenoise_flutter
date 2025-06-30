import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/ui/chat/notifiers/tem_test_data.dart';
import 'package:whitenoise/ui/chat/states/chat_state.dart';

class ChatNotifier extends Notifier<ChatState> {
  final _logger = Logger('ChatNotifier');

  @override
  ChatState build() => const ChatState();

  void initialize() {
    state = ChatState(messages: testMessages().initialMessages ?? []);
  }

  bool _isAuthAvailable() {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      state = state.copyWith(error: 'Not authenticated');
      return false;
    }
    return true;
  }

  Future<User?> _getCurrentUser() async {
    if (!_isAuthAvailable()) return null;

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return null;
      }

      return User(
        id: activeAccountData.pubkey,
        name: 'You',
        nip05: '',
        publicKey: activeAccountData.pubkey,
      );
    } catch (e) {
      _logger.severe('Error getting current user: $e');
      return null;
    }
  }

  Future<void> updateMessageReaction({
    required MessageModel message,
    required String reaction,
  }) async {
    final currentUser = await _getCurrentUser();
    if (currentUser == null) return;

    final existingReactionIndex = message.reactions.indexWhere(
      (r) => r.emoji == reaction && r.user.id == currentUser.id,
    );

    List<Reaction> newReactions;
    if (existingReactionIndex != -1) {
      newReactions = List<Reaction>.from(message.reactions)..removeAt(existingReactionIndex);
    } else {
      final newReaction = Reaction(emoji: reaction, user: currentUser);
      newReactions = List<Reaction>.from(message.reactions)..add(newReaction);
    }

    final updatedMessage = message.copyWith(reactions: newReactions);
    final updatedMessages = _updateMessage(updatedMessage);
    state = state.copyWith(messages: updatedMessages);
  }

  void sendNewMessageOrEdit(
    MessageModel message,
    bool isEditing, {
    VoidCallback? onMessageSent,
  }) {
    List<MessageModel> updatedMessages;

    if (isEditing) {
      final index = state.messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        updatedMessages = List<MessageModel>.from(state.messages);
        updatedMessages[index] = message;
      } else {
        updatedMessages = state.messages;
      }
    } else {
      updatedMessages = [message, ...state.messages];
    }

    state = state.copyWith(
      messages: updatedMessages,
    );

    onMessageSent?.call();
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
    return state.messages[index].sender.nip05 == state.messages[index - 1].sender.nip05;
  }

  bool isNextSameSender(int index) {
    if (index < 0 || index >= state.messages.length - 1) return false;
    return state.messages[index].sender.nip05 == state.messages[index + 1].sender.nip05;
  }

  List<MessageModel> _updateMessage(MessageModel updatedMessage) {
    return state.messages.map((msg) {
      return msg.id == updatedMessage.id ? updatedMessage : msg;
    }).toList();
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

final chatNotifierProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
