import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/pinned_chats_provider.dart';

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
  });
}
