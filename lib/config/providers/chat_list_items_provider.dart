import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/pinned_chats_provider.dart';
import 'package:whitenoise/config/providers/welcomes_provider.dart';
import 'package:whitenoise/domain/models/chat_list_item.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';

class ChatListItemsNotifier extends Notifier<List<ChatListItem>> {
  @override
  List<ChatListItem> build() {
    ref.watch(groupsProvider);
    ref.watch(welcomesProvider);
    ref.watch(chatProvider);
    ref.watch(pinnedChatsProvider);

    final groupsState = ref.read(groupsProvider);
    final groupList = groupsState.groups ?? [];
    final groupCreatedAts = groupsState.groupCreatedAts ?? {};
    final welcomesList = ref.read(welcomesProvider).welcomes ?? [];
    final chatState = ref.read(chatProvider);
    final pinnedChats = ref.read(pinnedChatsProvider);

    final chatItems = <ChatListItem>[];

    for (final group in groupList) {
      final lastMessage = chatState.getLatestMessageForGroup(group.mlsGroupId);
      final isPinned = pinnedChats.contains(group.mlsGroupId);
      final createdAt = groupCreatedAts[group.mlsGroupId];
      chatItems.add(
        ChatListItem.fromGroup(
          group: group,
          lastMessage: lastMessage,
          isPinned: isPinned,
          createdAt: createdAt,
        ),
      );
    }

    final pendingWelcomes = welcomesList.where((welcome) => welcome.state == WelcomeState.pending);
    for (final welcome in pendingWelcomes) {
      chatItems.add(ChatListItem.fromWelcome(welcome: welcome));
    }

    chatItems.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

    return chatItems;
  }
}

final chatListItemsProvider = NotifierProvider<ChatListItemsNotifier, List<ChatListItem>>(
  ChatListItemsNotifier.new,
);
