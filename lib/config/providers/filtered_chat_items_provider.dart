import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/chat_list_items_provider.dart';
import 'package:whitenoise/config/providers/pinned_chats_provider.dart';
import 'package:whitenoise/domain/models/chat_list_item.dart';

/// Provides separated and filtered chat items based on search query
/// Returns a record with pinned and unpinned chat items
final filteredChatItemsProvider =
    Provider.family<({List<ChatListItem> pinned, List<ChatListItem> unpinned}), String>((
      ref,
      searchQuery,
    ) {
      final chatItems = ref.watch(chatListItemsProvider);
      final pinnedChatsNotifier = ref.watch(pinnedChatsProvider.notifier);
      return pinnedChatsNotifier.separatePinnedChats(
        chatItems,
        searchQuery: searchQuery,
      );
    });
