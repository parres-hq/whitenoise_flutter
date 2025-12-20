import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/chat_stream_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/states/group_state.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import '../../shared/mocks/mock_active_pubkey_notifier.dart';

class MockGroupsNotifier extends GroupsNotifier {
  final Map<String, List<User>>? _members;

  MockGroupsNotifier({Map<String, List<User>>? members}) : _members = members, super();

  @override
  GroupsState build() {
    return GroupsState(groupMembers: _members);
  }
}

void main() {
  group('ChatStreamNotifier Tests', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    late ProviderContainer container;
    late StreamController<MessageStreamItem> streamController;

    const testActivePubkey = '0000000000000000000000000000000000000000000000000000000000000001';
    const otherPubkey = '0000000000000000000000000000000000000000000000000000000000000002';
    const testGroupId = 'test_group_id';

    final testUser = User(
      id: testActivePubkey,
      displayName: 'Me',
      nip05: '',
      publicKey: testActivePubkey,
    );

    final otherUser = User(
      id: otherPubkey,
      displayName: 'Other',
      nip05: '',
      publicKey: otherPubkey,
    );

    Stream<MessageStreamItem> mockSubscriber({required String groupId}) {
      return streamController.stream;
    }

    setUp(() {
      streamController = StreamController<MessageStreamItem>();
      container = ProviderContainer(
        overrides: [
          activePubkeyProvider.overrideWith(
            () => MockActivePubkeyNotifier(testActivePubkey),
          ),
          groupsProvider.overrideWith(
            () => MockGroupsNotifier(
              members: {
                testGroupId: [testUser, otherUser],
              },
            ),
          ),
        ],
      );
    });

    tearDown(() {
      streamController.close();
      container.dispose();
    });

    ChatMessage createChatMessage({
      required String id,
      required String content,
      required String pubkey,
      required DateTime createdAt,
    }) {
      return ChatMessage(
        id: id,
        pubkey: pubkey,
        content: content,
        createdAt: createdAt,
        tags: [],
        isReply: false,
        isDeleted: false,
        contentTokens: [],
        reactions: const ReactionSummary(byEmoji: [], userReactions: []),
        mediaAttachments: [],
        kind: 1,
      );
    }

    test('should yield empty list when activePubkey is null', () async {
      final container = ProviderContainer(
        overrides: [
          activePubkeyProvider.overrideWith(
            () => MockActivePubkeyNotifier(null),
          ),
        ],
      );

      final stream = container.read(chatStreamProvider(testGroupId).future);
      final result = await stream;
      expect(result, isEmpty);
    });

    test('should handle InitialSnapshot and yield sorted messages', () async {
      final overrides = [
        chatStreamProvider.overrideWith(
          () => ChatStreamNotifier(subscriber: mockSubscriber),
        ),
        activePubkeyProvider.overrideWith(
          () => MockActivePubkeyNotifier(testActivePubkey),
        ),
        groupsProvider.overrideWith(
          () => MockGroupsNotifier(
            members: {
              testGroupId: [testUser, otherUser],
            },
          ),
        ),
      ];

      final testContainer = ProviderContainer(overrides: overrides);

      // Create unordered messages
      final msg1 = createChatMessage(
        id: '1',
        content: 'First',
        pubkey: testActivePubkey,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      final msg2 = createChatMessage(
        id: '2',
        content: 'Second',
        pubkey: otherPubkey,
        createdAt: DateTime.now(),
      );

      final future = testContainer.read(
        chatStreamProvider(testGroupId).future,
      );

      streamController.add(
        MessageStreamItem.initialSnapshot(
          messages: [msg2, msg1],
        ), // Sent out of order
      );

      final messages = await future;

      expect(messages.length, 2);
      // Should be sorted by createdAt
      expect(messages[0].id, '1');
      expect(messages[1].id, '2');
    });

    test('should handle Update (New Message) and maintain sort order', () async {
      final overrides = [
        chatStreamProvider.overrideWith(
          () => ChatStreamNotifier(subscriber: mockSubscriber),
        ),
        activePubkeyProvider.overrideWith(
          () => MockActivePubkeyNotifier(testActivePubkey),
        ),
        groupsProvider.overrideWith(
          () => MockGroupsNotifier(
            members: {
              testGroupId: [testUser, otherUser],
            },
          ),
        ),
      ];

      final testContainer = ProviderContainer(overrides: overrides);

      final msg1 = createChatMessage(
        id: '1',
        content: 'First',
        pubkey: testActivePubkey,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      final results = <List<MessageModel>>[];
      final sub = testContainer.listen(
        chatStreamProvider(testGroupId),
        (previous, next) {
          if (next.hasValue) {
            results.add(next.value!);
          }
        },
      );

      // 1. Initial Snapshot
      streamController.add(
        MessageStreamItem.initialSnapshot(messages: [msg1]),
      );

      // Wait a microtask to ensure stream processes
      await Future.delayed(Duration.zero);
      expect(results.length, 1);
      expect(results.last.length, 1);

      // 2. Add New Message
      final msg2 = createChatMessage(
        id: '2',
        content: 'Second',
        pubkey: otherPubkey,
        createdAt: DateTime.now(),
      );

      streamController.add(
        MessageStreamItem.update(
          update: MessageUpdate(
            trigger: UpdateTrigger.newMessage,
            message: msg2,
          ),
        ),
      );

      await Future.delayed(Duration.zero);

      expect(results.length, 2);
      expect(results.last.length, 2);
      expect(results.last.last.id, '2');

      sub.close();
    });

    test('should update existing message on update trigger', () async {
      final overrides = [
        chatStreamProvider.overrideWith(
          () => ChatStreamNotifier(subscriber: mockSubscriber),
        ),
        activePubkeyProvider.overrideWith(
          () => MockActivePubkeyNotifier(testActivePubkey),
        ),
        groupsProvider.overrideWith(
          () => MockGroupsNotifier(
            members: {
              testGroupId: [testUser, otherUser],
            },
          ),
        ),
      ];

      final testContainer = ProviderContainer(overrides: overrides);

      final msg1 = createChatMessage(
        id: '1',
        content: 'Original Content',
        pubkey: testActivePubkey,
        createdAt: DateTime.now(),
      );

      final results = <List<MessageModel>>[];
      final sub = testContainer.listen(
        chatStreamProvider(testGroupId),
        (previous, next) {
          if (next.hasValue) {
            results.add(next.value!);
          }
        },
      );

      streamController.add(
        MessageStreamItem.initialSnapshot(messages: [msg1]),
      );

      await Future.delayed(Duration.zero);
      expect(results.length, 1);
      expect(results.last.first.content, 'Original Content');

      // Update the message content
      final updatedMsg1 = ChatMessage(
        id: '1',
        pubkey: testActivePubkey,
        content: 'Updated Content',
        createdAt: msg1.createdAt,
        tags: [],
        isReply: false,
        isDeleted: false,
        contentTokens: [],
        reactions: const ReactionSummary(byEmoji: [], userReactions: []),
        mediaAttachments: [],
        kind: 1,
      );

      streamController.add(
        MessageStreamItem.update(
          update: MessageUpdate(
            trigger: UpdateTrigger.newMessage,
            message: updatedMsg1,
          ),
        ),
      );

      await Future.delayed(Duration.zero);

      expect(results.length, 2);
      expect(results.last.first.content, 'Updated Content');

      sub.close();
    });

    test('should yield empty list if stream errors immediately', () async {
      final overrides = [
        chatStreamProvider.overrideWith(
          () => ChatStreamNotifier(subscriber: mockSubscriber),
        ),
        activePubkeyProvider.overrideWith(
          () => MockActivePubkeyNotifier(testActivePubkey),
        ),
        groupsProvider.overrideWith(
          () => MockGroupsNotifier(
            members: {
              testGroupId: [testUser, otherUser],
            },
          ),
        ),
      ];

      final testContainer = ProviderContainer(overrides: overrides);

      final future = testContainer.read(
        chatStreamProvider(testGroupId).future,
      );

      // Add error immediately
      streamController.addError(Exception('Stream error'));

      final result = await future;
      expect(result, isEmpty);
    });

    test('should preserve stale data (not yield empty) if stream errors after yielding', () async {
      final overrides = [
        chatStreamProvider.overrideWith(
          () => ChatStreamNotifier(subscriber: mockSubscriber),
        ),
        activePubkeyProvider.overrideWith(
          () => MockActivePubkeyNotifier(testActivePubkey),
        ),
        groupsProvider.overrideWith(
          () => MockGroupsNotifier(
            members: {
              testGroupId: [testUser, otherUser],
            },
          ),
        ),
      ];

      final testContainer = ProviderContainer(overrides: overrides);

      final msg1 = createChatMessage(
        id: '1',
        content: 'First',
        pubkey: testActivePubkey,
        createdAt: DateTime.now(),
      );

      final results = <AsyncValue<List<MessageModel>>>[];
      final sub = testContainer.listen(
        chatStreamProvider(testGroupId),
        (previous, next) {
          results.add(next);
        },
      );

      // 1. Initial Snapshot
      streamController.add(
        MessageStreamItem.initialSnapshot(messages: [msg1]),
      );
      await Future.delayed(Duration.zero);

      expect(results.last.value!.length, 1);

      // 2. Error
      streamController.addError(Exception('Run error'));
      await Future.delayed(Duration.zero);

      expect(results.last.value!.length, 1);
      expect(results.last, isA<AsyncData>());

      sub.close();
    });
    test('should handle empty group members list gracefully', () async {
      final overrides = [
        chatStreamProvider.overrideWith(
          () => ChatStreamNotifier(subscriber: mockSubscriber),
        ),
        activePubkeyProvider.overrideWith(
          () => MockActivePubkeyNotifier(testActivePubkey),
        ),

        groupsProvider.overrideWith(
          () => MockGroupsNotifier(
            members: {
              testGroupId: [],
            },
          ),
        ),
      ];

      final testContainer = ProviderContainer(overrides: overrides);

      final msg1 = createChatMessage(
        id: '1',
        content: 'Content',
        pubkey: otherPubkey,
        createdAt: DateTime.now(),
      );

      final future = testContainer.read(
        chatStreamProvider(testGroupId).future,
      );

      streamController.add(
        MessageStreamItem.initialSnapshot(messages: [msg1]),
      );

      final messages = await future;

      expect(messages.length, 1);
      expect(messages.first.content, 'Content');
      expect(messages.first.sender.id, otherPubkey);
      expect(messages.first.sender.displayName, 'shared.unknownUser');
    });
  });
}
