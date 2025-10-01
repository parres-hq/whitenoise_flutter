import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/domain/models/chat_list_item.dart';

class ChatListSortingNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Sorts chat items by pin status first (pinned items at top), then by date created (most recent first)
  List<ChatListItem> sortChatItems(List<ChatListItem> chatItems) {
    // Create a copy to avoid mutating the original list
    final sortedItems = List<ChatListItem>.from(chatItems);

    sortedItems.sort((a, b) {
      // First compare pin status - pinned items come first
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      // If both have same pin status, sort by date created (most recent first)
      return b.dateCreated.compareTo(a.dateCreated);
    });

    return sortedItems;
  }

  /// Separates chat items into pinned and unpinned lists
  ({List<ChatListItem> pinned, List<ChatListItem> unpinned}) separatePinnedChats(
    List<ChatListItem> chatItems,
  ) {
    final pinnedChats = <ChatListItem>[];
    final unpinnedChats = <ChatListItem>[];

    for (final item in chatItems) {
      if (item.isPinned) {
        pinnedChats.add(item);
      } else {
        unpinnedChats.add(item);
      }
    }

    // Sort each list by date created (most recent first)
    pinnedChats.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
    unpinnedChats.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

    return (pinned: pinnedChats, unpinned: unpinnedChats);
  }

  /// Filters chat items based on search query
  List<ChatListItem> filterChatItems(
    List<ChatListItem> chatItems,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) {
      return chatItems;
    }

    final searchLower = searchQuery.toLowerCase();
    return chatItems.where((item) {
      return item.displayName.toLowerCase().contains(searchLower) ||
          item.subtitle.toLowerCase().contains(searchLower) ||
          (item.lastMessage?.content?.toLowerCase().contains(searchLower) ?? false);
    }).toList();
  }

  /// Combined method to filter and sort chat items
  List<ChatListItem> processChatsForDisplay(
    List<ChatListItem> chatItems,
    String searchQuery,
  ) {
    final filteredItems = filterChatItems(chatItems, searchQuery);

    return sortChatItems(filteredItems);
  }
}

final chatListSortingProvider = NotifierProvider<ChatListSortingNotifier, void>(
  ChatListSortingNotifier.new,
);
