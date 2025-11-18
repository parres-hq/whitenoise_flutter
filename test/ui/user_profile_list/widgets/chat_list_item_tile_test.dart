import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/pinned_chats_provider.dart';
import 'package:whitenoise/config/states/chat_state.dart';
import 'package:whitenoise/config/states/group_state.dart';
import 'package:whitenoise/domain/models/chat_list_item.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

import 'package:whitenoise/ui/user_profile_list/widgets/chat_list_item_tile.dart';
import '../../../shared/mocks/mock_active_pubkey_notifier.dart';
import '../../../test_helpers.dart';

class MockGroupsNotifier extends GroupsNotifier {
  final Map<String, String> displayNames;
  final Map<String, GroupType> types;
  final Map<String, List<User>> members;

  MockGroupsNotifier({
    required this.displayNames,
    required this.types,
    required this.members,
  });

  @override
  GroupsState build() {
    return GroupsState(
      groupDisplayNames: displayNames,
      groupTypes: types,
      groupMembers: members,
    );
  }
}

class MockChatNotifier extends ChatNotifier {
  final Map<String, List<MessageModel>> groupMessages;

  MockChatNotifier({this.groupMessages = const {}});

  @override
  ChatState build() {
    return ChatState(groupMessages: groupMessages);
  }
}

class MockPinnedChatsNotifier extends PinnedChatsNotifier {
  @override
  Set<String> build() {
    return {};
  }
}

Finder findMediaIcon() {
  return find.byWidgetPredicate(
    (widget) => widget is WnImage && widget.src.contains('ic_image'),
  );
}

MediaFile _createTestMediaFile() {
  return MediaFile(
    id: 'media-123',
    accountPubkey: 'account-pubkey',
    originalFileHash: 'hash',
    encryptedFileHash: 'encrypted-hash',
    mlsGroupId: 'group-123',
    filePath: '/path/to/image.jpg',
    mimeType: 'image/jpeg',
    mediaType: 'image',
    blossomUrl: 'https://example.com/image.jpg',
    nostrKey: 'nostr-key',
    createdAt: DateTime(2025),
  );
}

void main() {
  group('ChatListItemTile tests', () {
    late User testUser;
    late Group testGroup;
    late List<Override> baseOverrides;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await initializeTestLocalization();
    });

    setUp(() {
      testUser = User(
        id: 'user-123',
        displayName: 'Test User',
        nip05: '',
        publicKey: 'npub1test',
      );

      testGroup = Group(
        mlsGroupId: 'group-123',
        nostrGroupId: 'nostr-group-123',
        name: 'Test Group',
        description: '',
        adminPubkeys: [],
        lastMessageAt: DateTime(2025, 1, 2),
        epoch: BigInt.zero,
        state: GroupState.active,
      );

      baseOverrides = [
        activePubkeyProvider.overrideWith(() => MockActivePubkeyNotifier('account-pubkey')),
        groupsProvider.overrideWith(
          () => MockGroupsNotifier(
            displayNames: {'group-123': 'Test Group'},
            types: {'group-123': GroupType.group},
            members: {'group-123': []},
          ),
        ),
        chatProvider.overrideWith(
          () => MockChatNotifier(groupMessages: {'group-123': []}),
        ),
        pinnedChatsProvider.overrideWith(() => MockPinnedChatsNotifier()),
      ];
    });

    group('when last message has media with content', () {
      group('and message is from me', () {
        late ChatListItem item;

        setUp(() {
          final mediaFile = _createTestMediaFile();

          final message = MessageModel(
            id: 'msg-123',
            content: 'Check this out',
            type: MessageType.text,
            createdAt: DateTime(2025),
            sender: testUser,
            isMe: true,
            mediaAttachments: [mediaFile],
          );

          item = ChatListItem.fromGroup(
            group: testGroup,
            lastMessage: message,
          );
        });

        testWidgets('displays text with "You:" prefix', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              ChatListItemTile(item: item),
              overrides: baseOverrides,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('You: Check this out'), findsOneWidget);
        });

        testWidgets('displays media icon', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              ChatListItemTile(item: item),
              overrides: baseOverrides,
            ),
          );
          await tester.pumpAndSettle();

          expect(findMediaIcon(), findsOneWidget);
        });
      });

      group('and message is from other user', () {
        late ChatListItem item;

        setUp(() {
          final mediaFile = _createTestMediaFile();

          final message = MessageModel(
            id: 'msg-123',
            content: 'Check this out',
            type: MessageType.text,
            createdAt: DateTime(2025),
            sender: testUser,
            isMe: false,
            mediaAttachments: [mediaFile],
          );

          item = ChatListItem.fromGroup(
            group: testGroup,
            lastMessage: message,
          );
        });

        testWidgets('displays message text without prefix', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              ChatListItemTile(item: item),
              overrides: baseOverrides,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('You:'), findsNothing);
          expect(find.text('Check this out'), findsOneWidget);
        });

        testWidgets('displays media icon', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              ChatListItemTile(item: item),
              overrides: baseOverrides,
            ),
          );
          await tester.pumpAndSettle();

          expect(findMediaIcon(), findsOneWidget);
        });
      });
    });

    group('when last message has media without content', () {
      group('and message is from me', () {
        late ChatListItem item;

        setUp(() {
          final mediaFile = _createTestMediaFile();

          final message = MessageModel(
            id: 'msg-123',
            content: '',
            type: MessageType.text,
            createdAt: DateTime(2025),
            sender: testUser,
            isMe: true,
            mediaAttachments: [mediaFile],
          );

          item = ChatListItem.fromGroup(
            group: testGroup,
            lastMessage: message,
          );
        });

        testWidgets('displays "You: Photo" label', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              ChatListItemTile(item: item),
              overrides: baseOverrides,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('You: Photo'), findsOneWidget);
        });

        testWidgets('displays media icon', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              ChatListItemTile(item: item),
              overrides: baseOverrides,
            ),
          );
          await tester.pumpAndSettle();

          expect(findMediaIcon(), findsOneWidget);
        });
      });

      group('and message is from other user', () {
        late ChatListItem item;

        setUp(() {
          final mediaFile = _createTestMediaFile();

          final message = MessageModel(
            id: 'msg-123',
            content: '   ',
            type: MessageType.text,
            createdAt: DateTime(2025),
            sender: testUser,
            isMe: false,
            mediaAttachments: [mediaFile],
          );

          item = ChatListItem.fromGroup(
            group: testGroup,
            lastMessage: message,
          );
        });

        testWidgets('displays "Photo" label without "You:" prefix', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              ChatListItemTile(item: item),
              overrides: baseOverrides,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('You:'), findsNothing);
          expect(find.text('Photo'), findsOneWidget);
        });

        testWidgets('displays media icon', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              ChatListItemTile(item: item),
              overrides: baseOverrides,
            ),
          );
          await tester.pumpAndSettle();

          expect(findMediaIcon(), findsOneWidget);
        });
      });
    });

    group('when last message does not have media', () {
      group('and message is from me', () {
        late ChatListItem item;

        setUp(() {
          final message = MessageModel(
            id: 'msg-123',
            content: 'Hello there',
            type: MessageType.text,
            createdAt: DateTime(2025),
            sender: testUser,
            isMe: true,
          );

          item = ChatListItem.fromGroup(
            group: testGroup,
            lastMessage: message,
          );
        });

        testWidgets('displays text with "You:" prefix', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              ChatListItemTile(item: item),
              overrides: baseOverrides,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('You: Hello there'), findsOneWidget);
        });

        testWidgets('does not display media icon', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              ChatListItemTile(item: item),
              overrides: baseOverrides,
            ),
          );
          await tester.pumpAndSettle();

          expect(findMediaIcon(), findsNothing);
        });
      });

      group('and message is from other user', () {
        late ChatListItem item;

        setUp(() {
          final message = MessageModel(
            id: 'msg-123',
            content: 'Hello there',
            type: MessageType.text,
            createdAt: DateTime(2025),
            sender: testUser,
            isMe: false,
          );

          item = ChatListItem.fromGroup(
            group: testGroup,
            lastMessage: message,
          );
        });

        testWidgets('displays text without prefix', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              ChatListItemTile(item: item),
              overrides: baseOverrides,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('You:'), findsNothing);
          expect(find.text('Hello there'), findsOneWidget);
        });

        testWidgets('does not display media icon', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              ChatListItemTile(item: item),
              overrides: baseOverrides,
            ),
          );
          await tester.pumpAndSettle();

          expect(findMediaIcon(), findsNothing);
        });
      });
    });
  });
}
