import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/utils/big_int_extension.dart';

enum ChatListItemType { chat, welcome }

class ChatListItem {
  final ChatListItemType type;
  final GroupData? groupData;
  final WelcomeData? welcomeData;
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
    required GroupData groupData,
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
    required WelcomeData welcomeData,
  }) {
    return ChatListItem(
      type: ChatListItemType.welcome,
      welcomeData: welcomeData,
      dateCreated: welcomeData.createdAt.toDateTime(),
    );
  }

  String get displayName {
    switch (type) {
      case ChatListItemType.chat:
        return groupData?.name ?? '';
      case ChatListItemType.welcome:
        return welcomeData?.groupName ?? '';
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
        return welcomeData?.id ?? '';
    }
  }
}
