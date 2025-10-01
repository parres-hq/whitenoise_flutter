import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/pinned_chats_provider.dart';
import 'package:whitenoise/domain/models/chat_list_item.dart';

void main() {
  group('PinnedChatsProvider Tests', () {
    late ProviderContainer container;
    late PinnedChatsNotifier notifier;
    const testChatId1 = 'chat_id_1';
    const testChatId2 = 'chat_id_2';

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(pinnedChatsProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('initialization', () {
      test('starts with empty set', () {
        final state = container.read(pinnedChatsProvider);
        expect(state, isEmpty);
      });
    });

    group('pinChat', () {
      test('adds chat to pinned set', () async {
        await notifier.pinChat(testChatId1);
        final state = container.read(pinnedChatsProvider);
        expect(state.contains(testChatId1), isTrue);
      });

      test('does not add duplicate chat', () async {
        await notifier.pinChat(testChatId1);
        await notifier.pinChat(testChatId1);
        final state = container.read(pinnedChatsProvider);
        expect(state.length, equals(1));
        expect(state.contains(testChatId1), isTrue);
      });

      test('adds multiple different chats', () async {
        await notifier.pinChat(testChatId1);
        await notifier.pinChat(testChatId2);
        final state = container.read(pinnedChatsProvider);
        expect(state.length, equals(2));
        expect(state.contains(testChatId1), isTrue);
        expect(state.contains(testChatId2), isTrue);
      });
    });

    group('unpinChat', () {
      test('removes chat from pinned set', () async {
        await notifier.pinChat(testChatId1);
        await notifier.unpinChat(testChatId1);
        final state = container.read(pinnedChatsProvider);
        expect(state.contains(testChatId1), isFalse);
      });

      test('does nothing when chat is not pinned', () async {
        await notifier.unpinChat(testChatId1);
        final state = container.read(pinnedChatsProvider);
        expect(state, isEmpty);
      });

      test('removes only specified chat', () async {
        await notifier.pinChat(testChatId1);
        await notifier.pinChat(testChatId2);
        await notifier.unpinChat(testChatId1);
        final state = container.read(pinnedChatsProvider);
        expect(state.length, equals(1));
        expect(state.contains(testChatId1), isFalse);
        expect(state.contains(testChatId2), isTrue);
      });
    });

    group('togglePin', () {
      test('pins chat when not pinned', () async {
        await notifier.togglePin(testChatId1);
        final state = container.read(pinnedChatsProvider);
        expect(state.contains(testChatId1), isTrue);
      });

      test('unpins chat when pinned', () async {
        await notifier.pinChat(testChatId1);
        await notifier.togglePin(testChatId1);
        final state = container.read(pinnedChatsProvider);
        expect(state.contains(testChatId1), isFalse);
      });

      test('toggles correctly multiple times', () async {
        // Start unpinned
        expect(container.read(pinnedChatsProvider).contains(testChatId1), isFalse);

        // Toggle to pinned
        await notifier.togglePin(testChatId1);
        expect(container.read(pinnedChatsProvider).contains(testChatId1), isTrue);

        // Toggle to unpinned
        await notifier.togglePin(testChatId1);
        expect(container.read(pinnedChatsProvider).contains(testChatId1), isFalse);
      });
    });

    group('isPinned', () {
      test('returns true for pinned chat', () async {
        await notifier.pinChat(testChatId1);
        expect(notifier.isPinned(testChatId1), isTrue);
      });

      test('returns false for unpinned chat', () {
        expect(notifier.isPinned(testChatId1), isFalse);
      });
    });

    group('getPinnedChatIds', () {
      test('returns empty set initially', () {
        final pinnedIds = notifier.getPinnedChatIds();
        expect(pinnedIds, isEmpty);
      });

      test('returns all pinned chat IDs', () async {
        await notifier.pinChat(testChatId1);
        await notifier.pinChat(testChatId2);
        final pinnedIds = notifier.getPinnedChatIds();
        expect(pinnedIds.length, equals(2));
        expect(pinnedIds.contains(testChatId1), isTrue);
        expect(pinnedIds.contains(testChatId2), isTrue);
      });

      test('returns copy of set (immutable)', () async {
        await notifier.pinChat(testChatId1);
        final pinnedIds = notifier.getPinnedChatIds();
        pinnedIds.add('modified_id');

        // Original set should be unchanged
        final originalPinnedIds = notifier.getPinnedChatIds();
        expect(originalPinnedIds.contains('modified_id'), isFalse);
        expect(originalPinnedIds.length, equals(1));
      });
    });

    group('clearAllPinnedChats', () {
      test('removes all pinned chats', () async {
        await notifier.pinChat(testChatId1);
        await notifier.pinChat(testChatId2);
        await notifier.clearAllPinnedChats();
        final state = container.read(pinnedChatsProvider);
        expect(state, isEmpty);
      });

      test('works when no chats are pinned', () async {
        await notifier.clearAllPinnedChats();
        final state = container.read(pinnedChatsProvider);
        expect(state, isEmpty);
      });
    });

    group('state notifications', () {
      test('notifies listeners when chat is pinned', () async {
        var notificationCount = 0;
        final listener = container.listen(
          pinnedChatsProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        await notifier.pinChat(testChatId1);
        expect(notificationCount, equals(1));

        listener.close();
      });

      test('notifies listeners when chat is unpinned', () async {
        await notifier.pinChat(testChatId1);

        var notificationCount = 0;
        final listener = container.listen(
          pinnedChatsProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        await notifier.unpinChat(testChatId1);
        expect(notificationCount, equals(1));

        listener.close();
      });
    });

    group('filterChatItems', () {
      test('returns all items when search query is empty', () {
        final item1 = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
        );
        final item2 = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
        );

        final items = [item1, item2];
        final filtered = notifier.filterChatItems(items, '');

        expect(filtered.length, equals(2));
      });

      test('filters by display name (case insensitive)', () {
        // Create a mock ChatListItem with a custom displayName for testing
        final matchingItem = MockChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
          mockDisplayName: 'Test Group',
        );

        final nonMatchingItem = MockChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
          mockDisplayName: 'Other Group',
        );

        final items = [matchingItem, nonMatchingItem];
        final filtered = notifier.filterChatItems(items, 'test');

        expect(filtered.length, equals(1));
        expect(filtered.first.displayName.toLowerCase(), contains('test'));
      });
    });

    group('separatePinnedChats', () {
      test('separates pinned and unpinned chats correctly', () {
        final pinnedItem = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
          isPinned: true,
        );
        final unpinnedItem = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
        );

        final items = [unpinnedItem, pinnedItem];
        final separated = notifier.separatePinnedChats(items);

        expect(separated.pinned.length, equals(1));
        expect(separated.unpinned.length, equals(1));
        expect(separated.pinned.first.isPinned, isTrue);
        expect(separated.unpinned.first.isPinned, isFalse);
      });

      test('filters chats by search query before separating', () {
        final matchingPinned = MockChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
          isPinned: true,
          mockDisplayName: 'Test Group',
        );

        final matchingUnpinned = MockChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
          mockDisplayName: 'Test Chat',
        );

        final nonMatchingPinned = MockChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
          isPinned: true,
          mockDisplayName: 'Other Group',
        );

        final nonMatchingUnpinned = MockChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
          mockDisplayName: 'Different Chat',
        );

        final items = [matchingPinned, matchingUnpinned, nonMatchingPinned, nonMatchingUnpinned];
        final separated = notifier.separatePinnedChats(items, searchQuery: 'test');

        expect(separated.pinned.length, equals(1));
        expect(separated.unpinned.length, equals(1));
        expect(separated.pinned.first.displayName.toLowerCase(), contains('test'));
        expect(separated.unpinned.first.displayName.toLowerCase(), contains('test'));
      });

      test('sorts pinned and unpinned lists by date (most recent first)', () {
        final older = DateTime.now().subtract(const Duration(hours: 2));
        final newer = DateTime.now().subtract(const Duration(hours: 1));

        final olderPinned = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: older,
          isPinned: true,
        );
        final newerPinned = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: newer,
          isPinned: true,
        );
        final olderUnpinned = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: older,
        );
        final newerUnpinned = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: newer,
        );

        final items = [olderPinned, olderUnpinned, newerPinned, newerUnpinned];
        final separated = notifier.separatePinnedChats(items);

        expect(separated.pinned.first.dateCreated, equals(newer));
        expect(separated.pinned.last.dateCreated, equals(older));
        expect(separated.unpinned.first.dateCreated, equals(newer));
        expect(separated.unpinned.last.dateCreated, equals(older));
      });
    });
  });
}

// Mock ChatListItem for testing without external dependencies
class MockChatListItem extends ChatListItem {
  final String mockDisplayName;
  final String mockSubtitle;

  const MockChatListItem({
    required super.type,
    required super.dateCreated,
    super.isPinned = false,
    this.mockDisplayName = '',
    this.mockSubtitle = '',
  });

  @override
  String get displayName => mockDisplayName;

  @override
  String get subtitle => mockSubtitle;

  @override
  String get id => 'mock_id';
}
