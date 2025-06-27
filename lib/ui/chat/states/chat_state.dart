import 'package:whitenoise/domain/models/message_model.dart';

class ChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final MessageModel? replyingTo;
  final MessageModel? editingMessage;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.replyingTo,
    this.editingMessage,
    this.error,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    MessageModel? replyingTo,
    MessageModel? editingMessage,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      replyingTo: replyingTo ?? this.replyingTo,
      editingMessage: editingMessage ?? this.editingMessage,
      error: error ?? this.error,
    );
  }
}
