import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:whitenoise/domain/models/message_model.dart';

part 'chat_state.freezed.dart';

@Freezed(toStringOverride: false)
class ChatState with _$ChatState {
  const factory ChatState({
    // Map of groupId -> list of messages
    @Default({}) Map<String, List<MessageModel>> groupMessages,
    // Map of groupId -> unread message count
    @Default({}) Map<String, int> unreadCounts,
    // Currently selected group ID
    String? selectedGroupId,
    // Loading states per group
    @Default({}) Map<String, bool> groupLoadingStates,
    // Error states per group
    @Default({}) Map<String, String?> groupErrorStates,
    // Global loading state
    @Default(false) bool isLoading,
    // Global error state
    String? error,
    // Sending message states per group
    @Default({}) Map<String, bool> sendingStates,
    // Message being replied to per group
    @Default({}) Map<String, MessageModel?> replyingTo,
    // Message being edited per group
    @Default({}) Map<String, MessageModel?> editingMessage,
    // Digest cache for change detection (groupId -> digest)
    @Default({}) Map<String, String> messageDigests,
  }) = _ChatState;

  const ChatState._();

  /// Get messages for a specific group
  List<MessageModel> getMessagesForGroup(String groupId) {
    return groupMessages[groupId] ?? [];
  }

  /// Check if a group is currently loading
  bool isGroupLoading(String groupId) {
    return groupLoadingStates[groupId] ?? false;
  }

  /// Check if currently sending a message to a group
  bool isSendingToGroup(String groupId) {
    return sendingStates[groupId] ?? false;
  }

  /// Get the latest message for a group (for chat list preview)
  MessageModel? getLatestMessageForGroup(String groupId) {
    final messages = getMessagesForGroup(groupId);
    if (messages.isEmpty) return null;
    return messages.last;
  }

  /// Get unread message count for a group (placeholder - would need read status tracking)
  int getUnreadCountForGroup(String groupId) {
    return unreadCounts[groupId] ?? 0;
  }

  /// Get the message being replied to for a group
  MessageModel? getReplyingTo(String groupId) {
    return replyingTo[groupId];
  }

  /// Get the message being edited for a group
  MessageModel? getEditingMessage(String groupId) {
    return editingMessage[groupId];
  }

  /// Check if currently replying to a message in a group
  bool isReplying(String groupId) {
    return replyingTo[groupId] != null;
  }

  /// Check if currently editing a message in a group
  bool isEditing(String groupId) {
    return editingMessage[groupId] != null;
  }

  /// Check if messages have been loaded for a group
  bool areMessagesLoaded(String groupId) {
    return groupMessages.containsKey(groupId);
  }
}
