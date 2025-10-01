import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/chat_list_sorting_provider.dart';
import 'package:whitenoise/domain/models/chat_list_item.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/src/rust/api/groups.dart';

void main() {
  group('ChatListSortingProvider Tests', () {
    late ProviderContainer container;
    late ChatListSortingNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(chatListSortingProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('sortChatItems', () {
      test('sorts pinned items before unpinned items', () {
        final unpinnedItem = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
        );
        final pinnedItem = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now().subtract(const Duration(hours: 1)),
          isPinned: true,
        );

        final items = [unpinnedItem, pinnedItem];
        final sorted = notifier.sortChatItems(items);

        expect(sorted.first.isPinned, isTrue);
        expect(sorted.last.isPinned, isFalse);
      });

      test('sorts by date within same pin status (most recent first)', () {
        final older = DateTime.now().subtract(const Duration(hours: 2));
        final newer = DateTime.now().subtract(const Duration(hours: 1));

        final olderItem = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: older,
        );
        final newerItem = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: newer,
        );

        final items = [olderItem, newerItem];
        final sorted = notifier.sortChatItems(items);

        expect(sorted.first.dateCreated, equals(newer));
        expect(sorted.last.dateCreated, equals(older));
      });

      test('sorts pinned items by date (most recent first)', () {
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

        final items = [olderPinned, newerPinned];
        final sorted = notifier.sortChatItems(items);

        expect(sorted.first.dateCreated, equals(newer));
        expect(sorted.last.dateCreated, equals(older));
      });

      test('does not mutate original list', () {
        final item1 = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
        );
        final item2 = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now().subtract(const Duration(hours: 1)),
          isPinned: true,
        );

        final originalItems = [item1, item2];
        final originalOrder = List.from(originalItems);

        notifier.sortChatItems(originalItems);

        expect(originalItems, equals(originalOrder));
      });

      test('handles empty list', () {
        final sorted = notifier.sortChatItems([]);
        expect(sorted, isEmpty);
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

      test('handles all pinned items', () {
        final pinnedItem1 = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
          isPinned: true,
        );
        final pinnedItem2 = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
          isPinned: true,
        );

        final items = [pinnedItem1, pinnedItem2];
        final separated = notifier.separatePinnedChats(items);

        expect(separated.pinned.length, equals(2));
        expect(separated.unpinned, isEmpty);
      });

      test('handles all unpinned items', () {
        final unpinnedItem1 = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
        );
        final unpinnedItem2 = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
        );

        final items = [unpinnedItem1, unpinnedItem2];
        final separated = notifier.separatePinnedChats(items);

        expect(separated.pinned, isEmpty);
        expect(separated.unpinned.length, equals(2));
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
        final group = Group(
          mlsGroupId: 'group1',
          nostrGroupId: 'nostr1',
          name: 'Test Group',
          description: 'A test group',
          adminPubkeys: [],
          epoch: BigInt.zero,
          state: GroupState.active,
        );

        final matchingItem = ChatListItem.fromGroup(group: group);
        final nonMatchingItem = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
        );

        final items = [matchingItem, nonMatchingItem];
        final filtered = notifier.filterChatItems(items, 'test');

        expect(filtered.length, equals(1));
        expect(filtered.first.displayName.toLowerCase(), contains('test'));
      });

      test('filters by subtitle (case insensitive)', () {
        final sender = User(
          id: 'sender1',
          displayName: 'Test User',
          nip05: '',
          publicKey: 'sender1',
        );

        final message = MessageModel(
          id: 'msg1',
          content: 'Hello World',
          type: MessageType.text,
          createdAt: DateTime.now(),
          sender: sender,
          groupId: 'group1',
          isMe: false,
        );

        final group = Group(
          mlsGroupId: 'group1',
          nostrGroupId: 'nostr1',
          name: 'Group',
          description: 'Description',
          adminPubkeys: [],
          epoch: BigInt.zero,
          state: GroupState.active,
        );

        final matchingItem = ChatListItem.fromGroup(
          group: group,
          lastMessage: message,
        );
        final nonMatchingItem = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
        );

        final items = [matchingItem, nonMatchingItem];
        final filtered = notifier.filterChatItems(items, 'hello');

        expect(filtered.length, equals(1));
        expect(filtered.first.subtitle.toLowerCase(), contains('hello'));
      });

      test('filters by last message content (case insensitive)', () {
        final sender = User(
          id: 'sender1',
          displayName: 'Test User',
          nip05: '',
          publicKey: 'sender1',
        );

        final message = MessageModel(
          id: 'msg1',
          content: 'Important message',
          type: MessageType.text,
          createdAt: DateTime.now(),
          sender: sender,
          groupId: 'group1',
          isMe: false,
        );

        final group = Group(
          mlsGroupId: 'group1',
          nostrGroupId: 'nostr1',
          name: 'Group',
          description: 'Description',
          adminPubkeys: [],
          epoch: BigInt.zero,
          state: GroupState.active,
        );

        final matchingItem = ChatListItem.fromGroup(
          group: group,
          lastMessage: message,
        );
        final nonMatchingItem = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
        );

        final items = [matchingItem, nonMatchingItem];
        final filtered = notifier.filterChatItems(items, 'important');

        expect(filtered.length, equals(1));
      });

      test('returns empty list when no items match', () {
        final item = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
        );

        final items = [item];
        final filtered = notifier.filterChatItems(items, 'nonexistent');

        expect(filtered, isEmpty);
      });
    });

    group('processChatsForDisplay', () {
      test('filters and sorts chat items correctly', () {
        final sender = User(
          id: 'sender1',
          displayName: 'Test User',
          nip05: '',
          publicKey: 'sender1',
        );

        final message = MessageModel(
          id: 'msg1',
          content: 'Test message',
          type: MessageType.text,
          createdAt: DateTime.now(),
          sender: sender,
          groupId: 'group1',
          isMe: false,
        );

        final group1 = Group(
          mlsGroupId: 'group1',
          nostrGroupId: 'nostr1',
          name: 'Test Group',
          description: 'Description',
          adminPubkeys: [],
          epoch: BigInt.zero,
          state: GroupState.active,
        );

        final group2 = Group(
          mlsGroupId: 'group2',
          nostrGroupId: 'nostr2',
          name: 'Other Group',
          description: 'Description',
          adminPubkeys: [],
          epoch: BigInt.zero,
          state: GroupState.active,
        );

        final matchingUnpinned = ChatListItem.fromGroup(
          group: group1,
          lastMessage: message,
        );
        final matchingPinned = ChatListItem.fromGroup(
          group: group1,
          isPinned: true,
        );
        final nonMatching = ChatListItem.fromGroup(group: group2);

        final items = [matchingUnpinned, nonMatching, matchingPinned];
        final processed = notifier.processChatsForDisplay(items, 'test');

        expect(processed.length, equals(2));
        expect(processed.first.isPinned, isTrue); // Pinned item first
        expect(processed.last.isPinned, isFalse); // Unpinned item last
      });

      test('returns all items sorted when search query is empty', () {
        final unpinnedItem = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
        );
        final pinnedItem = ChatListItem(
          type: ChatListItemType.chat,
          dateCreated: DateTime.now(),
          isPinned: true,
        );

        final items = [unpinnedItem, pinnedItem];
        final processed = notifier.processChatsForDisplay(items, '');

        expect(processed.length, equals(2));
        expect(processed.first.isPinned, isTrue);
        expect(processed.last.isPinned, isFalse);
      });
    });
  });
}
