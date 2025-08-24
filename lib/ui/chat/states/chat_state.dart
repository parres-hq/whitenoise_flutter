import 'package:whitenoise/src/rust/api/messages.dart';

class ChatState {
  final List<MessageWithTokens> messages;
  final bool isLoading;
  final MessageWithTokens? replyingTo;
  final MessageWithTokens? editingMessage;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.replyingTo,
    this.editingMessage,
    this.error,
  });

  ChatState copyWith({
    List<MessageWithTokens>? messages,
    bool? isLoading,
    MessageWithTokens? replyingTo,
    MessageWithTokens? editingMessage,
    String? error,
    bool clearReplyingTo = false,
    bool clearEditingMessage = false,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      replyingTo: clearReplyingTo ? null : (replyingTo ?? this.replyingTo),
      editingMessage: clearEditingMessage ? null : (editingMessage ?? this.editingMessage),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
