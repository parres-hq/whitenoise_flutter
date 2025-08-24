import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/ui/chat/utils/message_extensions.dart';
import 'package:whitenoise/utils/big_int_extension.dart';

enum ChatListItemType { chat, welcome }

class ChatListItem {
  final ChatListItemType type;
  final Group? groupData;
  final Welcome? welcomeData;
  final MessageModel? lastMessage;
  final DateTime dateCreated;

  const ChatListItem({
    required this.type,
    this.groupData,
    this.welcomeData,
    this.lastMessage,
    required this.dateCreated,
  });

  factory ChatListItem.fromGroup({
    required Group groupData,
    MessageModel? lastMessage,
  }) {
    return ChatListItem(
      type: ChatListItemType.chat,
      groupData: groupData,
      lastMessage: lastMessage,
      dateCreated: lastMessage?.createdAt ?? DateTime.now(),
    );
  }

  factory ChatListItem.fromWelcome({
    required Welcome welcomeData,
  }) {
    return ChatListItem(
      type: ChatListItemType.welcome,
      welcomeData: welcomeData,
      dateCreated:
          DateTime.now(), // TODO big plans: fill with welcome created at. welcomeData.createdAtDateTime,
    );
  }

  String get displayName {
    switch (type) {
      case ChatListItemType.chat:
        return groupData?.name ?? '';
      case ChatListItemType.welcome:
        // TODO big plans: use sender name from Welcome
        return 'Unknown Sender'; // TODO big plans:welcomeData.senderName;
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
        return groupData?.mlsGroupId ?? '';
      case ChatListItemType.welcome:
        return ''; // welcomeData?.id ?? '' TODO big plans: use welcome id
    }
  }
}
