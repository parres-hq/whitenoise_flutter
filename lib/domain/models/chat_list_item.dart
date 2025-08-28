import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';

enum ChatListItemType { chat, welcome }

class ChatListItem {
  final ChatListItemType type;
  final Group? group;
  final Welcome? welcome;
  final MessageModel? lastMessage;
  final DateTime dateCreated;

  const ChatListItem({
    required this.type,
    this.group,
    this.welcome,
    this.lastMessage,
    required this.dateCreated,
  });

  factory ChatListItem.fromGroup({
    required Group group,
    MessageModel? lastMessage,
  }) {
    return ChatListItem(
      type: ChatListItemType.chat,
      group: group,
      lastMessage: lastMessage,
      dateCreated: lastMessage?.createdAt ?? DateTime.now(),
    );
  }

  factory ChatListItem.fromWelcome({
    required Welcome welcome,
  }) {
    return ChatListItem(
      type: ChatListItemType.welcome,
      welcome: welcome,
      dateCreated: welcome.createdAtDateTime,
    );
  }

  String get displayName {
    switch (type) {
      case ChatListItemType.chat:
        return group?.name ?? '';
      case ChatListItemType.welcome:
        return welcome.senderName;
    }
  }

  String get subtitle {
    switch (type) {
      case ChatListItemType.chat:
        return lastMessage?.content ?? '';
      case ChatListItemType.welcome:
        return 'invite';
    }
  }

  String get id {
    switch (type) {
      case ChatListItemType.chat:
        return group?.mlsGroupId ?? '';
      case ChatListItemType.welcome:
        return welcome?.id ?? '';
    }
  }
}
