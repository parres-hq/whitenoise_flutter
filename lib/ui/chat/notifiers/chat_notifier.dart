import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/ui/chat/states/chat_state.dart';

class ChatNotifier extends StateNotifier<ChatState> {
  final _logger = Logger('ChatNotifier');
  final User contact;
  final User currentUser;

  ChatNotifier({
    required this.contact,
    required List<MessageModel> initialMessages,
  }) : currentUser = User(
         id: 'current_user_id',
         name: 'You',
         nip05: 'current@user.com',
         publicKey: 'current_public_key',
       ),
       super(ChatState(messages: initialMessages));

  void updateMessageReaction({
    required MessageModel message,
    required String reaction,
  }) {
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
    );
  }

  void handleEdit(MessageModel message) {
    state = state.copyWith(
      editingMessage: message,
    );
  }

  void cancelReply() {
    state = state.copyWith(replyingTo: null);
  }

  void cancelEdit() {
    state = state.copyWith(editingMessage: null);
  }

  bool isSameSender(int index) {
    if (index <= 0 || index >= state.messages.length) return false;
    return state.messages[index].sender.id == state.messages[index - 1].sender.id;
  }

  bool isNextSameSender(int index) {
    if (index < 0 || index >= state.messages.length - 1) return false;
    return state.messages[index].sender.id == state.messages[index + 1].sender.id;
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
    state = state.copyWith(error: null);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

final chatNotifierProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, ChatNotifierParams>(
      (ref, params) => ChatNotifier(
        contact: params.contact,
        initialMessages: params.initialMessages,
      ),
    );

class ChatNotifierParams {
  final User contact;
  final List<MessageModel> initialMessages;

  ChatNotifierParams({
    required this.contact,
    required this.initialMessages,
  });
}
