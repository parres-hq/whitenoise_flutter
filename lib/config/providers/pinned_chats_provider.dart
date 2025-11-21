import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/domain/models/chat_list_item.dart';

class PinnedChatsNotifier extends Notifier<Set<String>> {
  static final Logger _log = Logger('PinnedChatsNotifier');
  static const String _pinnedChatsKey = 'pinned_chats';

  static const _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Set<String> build() {
    // Listen to active account changes and load pinned chats for the account
    ref.listen<String?>(activePubkeyProvider, (previous, next) {
      if (previous != next) {
        _loadPinnedChats();
      }
    });

    _loadPinnedChats();
    return <String>{};
  }

  /// Get the storage key for the current user
  String _getStorageKey() {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    return '${_pinnedChatsKey}_$activePubkey';
  }

  /// Load pinned chats from secure storage
  Future<void> _loadPinnedChats() async {
    try {
      final storageKey = _getStorageKey();
      final pinnedChatsJson = await _defaultStorage.read(key: storageKey);

      if (pinnedChatsJson != null) {
        final List<dynamic> pinnedChatsList = jsonDecode(pinnedChatsJson);
        state = pinnedChatsList.cast<String>().toSet();
        _log.info('Loaded ${pinnedChatsList.length} pinned chats for current user');
      } else {
        state = <String>{};
      }
    } catch (e) {
      _log.severe('Failed to load pinned chats: $e');
      state = <String>{};
    }
  }

  /// Save pinned chats to secure storage
  Future<void> _savePinnedChats() async {
    try {
      final storageKey = _getStorageKey();
      final pinnedChatsJson = jsonEncode(state.toList());
      await _defaultStorage.write(key: storageKey, value: pinnedChatsJson);
      _log.info('Saved ${state.length} pinned chats for current user');
    } catch (e) {
      _log.severe('Failed to save pinned chats: $e');
    }
  }

  /// Pin a chat
  Future<void> pinChat(String chatId) async {
    if (state.contains(chatId)) {
      _log.info('Chat $chatId is already pinned');
      return;
    }

    state = {...state, chatId};
    await _savePinnedChats();
    _log.info('Pinned chat: $chatId');
  }

  /// Unpin a chat
  Future<void> unpinChat(String chatId) async {
    if (!state.contains(chatId)) {
      _log.info('Chat $chatId is not pinned');
      return;
    }

    state = {...state}..remove(chatId);
    await _savePinnedChats();
    _log.info('Unpinned chat: $chatId');
  }

  /// Toggle pin state of a chat
  Future<void> togglePin(String chatId) async {
    if (state.contains(chatId)) {
      await unpinChat(chatId);
    } else {
      await pinChat(chatId);
    }
  }

  /// Check if a chat is pinned
  bool isPinned(String chatId) {
    return state.contains(chatId);
  }

  /// Get all pinned chat IDs
  Set<String> getPinnedChatIds() {
    return Set.from(state);
  }

  /// Clear all pinned chats (for testing or account cleanup)
  Future<void> clearAllPinnedChats() async {
    state = <String>{};
    await _savePinnedChats();
    _log.info('Cleared all pinned chats');
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

  /// Separates chat items into pinned and unpinned lists with optional search filtering
  ({List<ChatListItem> pinned, List<ChatListItem> unpinned}) separatePinnedChats(
    List<ChatListItem> chatItems, {
    String searchQuery = '',
  }) {
    // First filter by search query if provided
    final filteredItems = searchQuery.isEmpty ? chatItems : filterChatItems(chatItems, searchQuery);

    final pinnedChats = <ChatListItem>[];
    final unpinnedChats = <ChatListItem>[];

    for (final item in filteredItems) {
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
}

final pinnedChatsProvider = NotifierProvider<PinnedChatsNotifier, Set<String>>(
  PinnedChatsNotifier.new,
);
