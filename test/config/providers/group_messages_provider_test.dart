import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/group_messages_provider.dart';
import 'package:whitenoise/config/providers/user_profile_provider.dart';
import 'package:whitenoise/domain/models/user_profile.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';

import '../../shared/mocks/mock_active_pubkey_notifier.dart';

class MockUserProfileNotifier extends UserProfileNotifier {
  final Map<String, UserProfile> _userProfiles;

  MockUserProfileNotifier(this._userProfiles)
    : super(wnApiGetUserFn: null, getUserProfileFromMetadataFn: null);

  @override
  Future<UserProfile> getUserProfile(String pubkey, {bool blockingDataSync = true}) async {
    return _userProfiles[pubkey] ??
        UserProfile(
          publicKey: pubkey,
          displayName: 'shared.unknownUser'.tr(),
        );
  }
}

class MockPubkeyFormatter implements PubkeyFormatter {
  final String _pubkey;

  MockPubkeyFormatter(this._pubkey);

  @override
  String? toHex() {
    // Simple mock: return the pubkey as-is for comparison
    return _pubkey;
  }

  @override
  String? toNpub() => _pubkey;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<List<ChatMessage>> Function({required String pubkey, required String groupId})
mockFetchAggregatedMessagesForGroup(List<ChatMessage> mockMessages) {
  return ({required String pubkey, required String groupId}) async {
    return List<ChatMessage>.from(mockMessages);
  };
}

Future<List<String>> Function({required String pubkey, required String groupId}) mockGroupMembers(
  List<String> mockMembers,
) {
  return ({required String pubkey, required String groupId}) async {
    return List<String>.from(mockMembers);
  };
}

PubkeyFormatter Function({String? pubkey}) mockPubkeyFormatter() {
  return ({String? pubkey}) => MockPubkeyFormatter(pubkey ?? '');
}

bool Function({required String myPubkey, required String otherPubkey}) mockPubkeyUtilsIsMe() {
  return ({required String myPubkey, required String otherPubkey}) {
    return myPubkey == otherPubkey;
  };
}

void main() {
  group('GroupMessagesProvider Tests', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    late ProviderContainer container;

    final testUserProfiles = {
      'npub1testkey12345678901234567890': UserProfile(
        publicKey: 'npub1testkey12345678901234567890',
        displayName: 'Alice',
        imagePath: '/path/to/alice.jpg',
        nip05: 'alice@example.com',
      ),
      'npub140x77qfrg4ncnlkuh2v8v4pjzz4ummcpydzk0z07mjafsaj5xggq9d4zqy': UserProfile(
        publicKey: 'npub140x77qfrg4ncnlkuh2v8v4pjzz4ummcpydzk0z07mjafsaj5xggq9d4zqy',
        displayName: 'Bob',
        imagePath: '/path/to/bob.jpg',
        nip05: 'bob@example.com',
      ),
      'npub1zygjyg3nxdzyg424ven8waug3zvejqqq424thw7venwammhwlllsj2q4yf': UserProfile(
        publicKey: 'npub1zygjyg3nxdzyg424ven8waug3zvejqqq424thw7venwammhwlllsj2q4yf',
        displayName: 'Carl',
        imagePath: '/path/to/carl.jpg',
        nip05: 'carl@example.com',
      ),
    };

    final mockMessages = [
      ChatMessage(
        id: 'message_1',
        pubkey: 'npub1testkey12345678901234567890',
        content: 'Hello world!',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1234567890000),
        tags: [],
        isReply: false,
        isDeleted: false,
        contentTokens: [],
        reactions: const ReactionSummary(byEmoji: [], userReactions: []),
        kind: 9,
        mediaAttachments: [],
      ),
      ChatMessage(
        id: 'message_3',
        pubkey: 'npub140x77qfrg4ncnlkuh2v8v4pjzz4ummcpydzk0z07mjafsaj5xggq9d4zqy',
        content: 'Fine and you?',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1234567891100),
        tags: [],
        isReply: false,
        isDeleted: false,
        contentTokens: [],
        reactions: const ReactionSummary(byEmoji: [], userReactions: []),
        kind: 9,
        mediaAttachments: [],
      ),
      ChatMessage(
        id: 'message_2',
        pubkey: 'npub1zygjyg3nxdzyg424ven8waug3zvejqqq424thw7venwammhwlllsj2q4yf',
        content: 'How are you?',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1234567891000),
        tags: [],
        isReply: false,
        isDeleted: false,
        contentTokens: [],
        reactions: const ReactionSummary(byEmoji: [], userReactions: []),
        kind: 9,
        mediaAttachments: [],
      ),
    ];

    ProviderContainer createContainer({
      String? activePubkey,
      Map<String, UserProfile>? userProfiles,
      List<ChatMessage>? messages,
      List<String>? members,
    }) {
      return ProviderContainer(
        overrides: [
          activePubkeyProvider.overrideWith(() => MockActivePubkeyNotifier(activePubkey)),
          userProfileProvider.overrideWith(() => MockUserProfileNotifier(userProfiles ?? {})),
          groupMessagesProvider.overrideWith(
            () => GroupMessagesNotifier(
              fetchAggregatedMessagesForGroupFn: mockFetchAggregatedMessagesForGroup(
                messages ?? [],
              ),
              groupMembersFn: mockGroupMembers(members ?? []),
              isMeFn: mockPubkeyUtilsIsMe(),
            ),
          ),
        ],
      );
    }

    tearDown(() {
      container.dispose();
    });

    test('saves group id in state', () {
      container = createContainer(
        activePubkey: 'npub1zygjyg3nxdzyg424ven8waug3zvejqqq424thw7venwammhwlllsj2q4yf',
      );
      final notifier = container.read(groupMessagesProvider('test_group_123').notifier);
      final state = notifier.state;

      expect(state.groupId, 'test_group_123');
    });

    group('fetchMessages', () {
      group('when activePubkey is null', () {
        test('returns empty list', () async {
          container = createContainer();
          final notifier = container.read(groupMessagesProvider('test_group_123').notifier);

          final messages = await notifier.fetchMessages();

          expect(messages, isEmpty);
        });
      });

      group('when active pubkey is empty', () {
        test('returns empty list', () async {
          container = createContainer(activePubkey: '');
          final notifier = container.read(groupMessagesProvider('test_group_123').notifier);

          final messages = await notifier.fetchMessages();

          expect(messages, isEmpty);
        });
      });

      group('with Alice as active pubkey', () {
        late GroupMessagesNotifier notifier;

        setUp(() {
          container = createContainer(
            activePubkey: 'npub1testkey12345678901234567890',
            userProfiles: testUserProfiles,
            messages: mockMessages,
            members: [
              'npub1testkey12345678901234567890',
              'npub140x77qfrg4ncnlkuh2v8v4pjzz4ummcpydzk0z07mjafsaj5xggq9d4zqy',
              'npub1zygjyg3nxdzyg424ven8waug3zvejqqq424thw7venwammhwlllsj2q4yf',
            ],
          );
          notifier = container.read(groupMessagesProvider('test_group_123').notifier);
        });

        test('returns expected amount of messages', () async {
          final messages = await notifier.fetchMessages();
          expect(messages.length, 3);
        });

        test('returns messages in correct order', () async {
          final messages = await notifier.fetchMessages();
          expect(messages[0].id, 'message_1');
          expect(messages[1].id, 'message_2');
          expect(messages[2].id, 'message_3');
        });

        test('changes active pubkey display name to "You"', () async {
          final messages = await notifier.fetchMessages();
          expect(messages[0].sender.displayName, 'You');
          expect(messages[1].sender.displayName, 'Carl');
          expect(messages[2].sender.displayName, 'Bob');
        });
      });

      group('with Bob as active pubkey', () {
        late GroupMessagesNotifier notifier;

        setUp(() {
          container = createContainer(
            activePubkey: 'npub140x77qfrg4ncnlkuh2v8v4pjzz4ummcpydzk0z07mjafsaj5xggq9d4zqy',
            userProfiles: testUserProfiles,
            messages: mockMessages,
            members: [
              'npub1testkey12345678901234567890',
              'npub140x77qfrg4ncnlkuh2v8v4pjzz4ummcpydzk0z07mjafsaj5xggq9d4zqy',
              'npub1zygjyg3nxdzyg424ven8waug3zvejqqq424thw7venwammhwlllsj2q4yf',
            ],
          );
          notifier = container.read(groupMessagesProvider('test_group_123').notifier);
        });

        test('changes active pubkey display name to "You"', () async {
          final messages = await notifier.fetchMessages();
          expect(messages[0].sender.displayName, 'Alice');
          expect(messages[1].sender.displayName, 'Carl');
          expect(messages[2].sender.displayName, 'You');
        });
      });

      group('with Carl active pubkey', () {
        late GroupMessagesNotifier notifier;

        setUp(() {
          container = createContainer(
            activePubkey: 'npub1zygjyg3nxdzyg424ven8waug3zvejqqq424thw7venwammhwlllsj2q4yf',
            userProfiles: testUserProfiles,
            messages: mockMessages,
            members: [
              'npub1testkey12345678901234567890',
              'npub140x77qfrg4ncnlkuh2v8v4pjzz4ummcpydzk0z07mjafsaj5xggq9d4zqy',
              'npub1zygjyg3nxdzyg424ven8waug3zvejqqq424thw7venwammhwlllsj2q4yf',
            ],
          );
          notifier = container.read(groupMessagesProvider('test_group_123').notifier);
        });

        test('changes active pubkey display name to "You"', () async {
          final messages = await notifier.fetchMessages();
          expect(messages[0].sender.displayName, 'Alice');
          expect(messages[1].sender.displayName, 'You');
          expect(messages[2].sender.displayName, 'Bob');
        });
      });

      group('edge case: messages with same timestamp', () {
        late GroupMessagesNotifier notifier;
        final sameTimestamp = DateTime.fromMillisecondsSinceEpoch(1234567890000);

        setUp(() {
          // Create messages with identical timestamps but different IDs
          final messagesWithSameTimestamp = [
            ChatMessage(
              id: 'message_z_last',
              pubkey: 'npub140x77qfrg4ncnlkuh2v8v4pjzz4ummcpydzk0z07mjafsaj5xggq9d4zqy',
              content: 'Message Z',
              createdAt: sameTimestamp,
              tags: [],
              isReply: false,
              isDeleted: false,
              contentTokens: [],
              reactions: const ReactionSummary(byEmoji: [], userReactions: []),
              kind: 9,
              mediaAttachments: [],
            ),
            ChatMessage(
              id: 'message_a_first',
              pubkey: 'npub1testkey12345678901234567890',
              content: 'Message A',
              createdAt: sameTimestamp,
              tags: [],
              isReply: false,
              isDeleted: false,
              contentTokens: [],
              reactions: const ReactionSummary(byEmoji: [], userReactions: []),
              kind: 9,
              mediaAttachments: [],
            ),
            ChatMessage(
              id: 'message_m_middle',
              pubkey: 'npub1zygjyg3nxdzyg424ven8waug3zvejqqq424thw7venwammhwlllsj2q4yf',
              content: 'Message M',
              createdAt: sameTimestamp,
              tags: [],
              isReply: false,
              isDeleted: false,
              contentTokens: [],
              reactions: const ReactionSummary(byEmoji: [], userReactions: []),
              kind: 9,
              mediaAttachments: [],
            ),
          ];

          container = createContainer(
            activePubkey: 'npub1testkey12345678901234567890',
            userProfiles: testUserProfiles,
            messages: messagesWithSameTimestamp,
            members: [
              'npub1testkey12345678901234567890',
              'npub140x77qfrg4ncnlkuh2v8v4pjzz4ummcpydzk0z07mjafsaj5xggq9d4zqy',
              'npub1zygjyg3nxdzyg424ven8waug3zvejqqq424thw7venwammhwlllsj2q4yf',
            ],
          );
          notifier = container.read(groupMessagesProvider('test_group_123').notifier);
        });

        test('sorts messages with same timestamp deterministically by ID', () async {
          final messages = await notifier.fetchMessages();

          // Should be sorted by ID when timestamps are equal
          expect(messages.length, 3);
          expect(messages[0].id, 'message_a_first');
          expect(messages[1].id, 'message_m_middle');
          expect(messages[2].id, 'message_z_last');
        });

        test('maintains consistent order across multiple fetch calls', () async {
          // Fetch messages multiple times
          final messages1 = await notifier.fetchMessages();
          final messages2 = await notifier.fetchMessages();
          final messages3 = await notifier.fetchMessages();

          // Order should be identical across all calls (no reordering loop)
          expect(messages1.length, messages2.length);
          expect(messages2.length, messages3.length);

          for (int i = 0; i < messages1.length; i++) {
            expect(
              messages1[i].id,
              messages2[i].id,
              reason: 'Message order should be consistent between first and second fetch',
            );
            expect(
              messages2[i].id,
              messages3[i].id,
              reason: 'Message order should be consistent between second and third fetch',
            );
          }
        });

        test('handles mixed timestamps with some duplicates', () async {
          // Create a mix of messages: some with same timestamp, some with different
          final mixedMessages = [
            ChatMessage(
              id: 'msg_early',
              pubkey: 'npub1testkey12345678901234567890',
              content: 'Early message',
              createdAt: DateTime.fromMillisecondsSinceEpoch(1234567889000),
              tags: [],
              isReply: false,
              isDeleted: false,
              contentTokens: [],
              reactions: const ReactionSummary(byEmoji: [], userReactions: []),
              kind: 9,
              mediaAttachments: [],
            ),
            ChatMessage(
              id: 'msg_z_same_time',
              pubkey: 'npub140x77qfrg4ncnlkuh2v8v4pjzz4ummcpydzk0z07mjafsaj5xggq9d4zqy',
              content: 'Message Z same time',
              createdAt: sameTimestamp,
              tags: [],
              isReply: false,
              isDeleted: false,
              contentTokens: [],
              reactions: const ReactionSummary(byEmoji: [], userReactions: []),
              kind: 9,
              mediaAttachments: [],
            ),
            ChatMessage(
              id: 'msg_a_same_time',
              pubkey: 'npub1testkey12345678901234567890',
              content: 'Message A same time',
              createdAt: sameTimestamp,
              tags: [],
              isReply: false,
              isDeleted: false,
              contentTokens: [],
              reactions: const ReactionSummary(byEmoji: [], userReactions: []),
              kind: 9,
              mediaAttachments: [],
            ),
            ChatMessage(
              id: 'msg_late',
              pubkey: 'npub1zygjyg3nxdzyg424ven8waug3zvejqqq424thw7venwammhwlllsj2q4yf',
              content: 'Late message',
              createdAt: DateTime.fromMillisecondsSinceEpoch(1234567891000),
              tags: [],
              isReply: false,
              isDeleted: false,
              contentTokens: [],
              reactions: const ReactionSummary(byEmoji: [], userReactions: []),
              kind: 9,
              mediaAttachments: [],
            ),
          ];

          final mixedContainer = createContainer(
            activePubkey: 'npub1testkey12345678901234567890',
            userProfiles: testUserProfiles,
            messages: mixedMessages,
            members: [
              'npub1testkey12345678901234567890',
              'npub140x77qfrg4ncnlkuh2v8v4pjzz4ummcpydzk0z07mjafsaj5xggq9d4zqy',
              'npub1zygjyg3nxdzyg424ven8waug3zvejqqq424thw7venwammhwlllsj2q4yf',
            ],
          );
          final mixedNotifier = mixedContainer.read(
            groupMessagesProvider('test_group_123').notifier,
          );

          final messages = await mixedNotifier.fetchMessages();

          // Should be sorted by timestamp first, then by ID for same timestamps
          expect(messages.length, 4);
          expect(messages[0].id, 'msg_early');
          expect(messages[1].id, 'msg_a_same_time');
          expect(messages[2].id, 'msg_z_same_time');
          expect(messages[3].id, 'msg_late');

          mixedContainer.dispose();
        });
      });
    });

    group('default provider initialization', () {
      test('uses default constructor when no overrides provided', () {
        final container = ProviderContainer(
          overrides: [
            activePubkeyProvider.overrideWith(() => MockActivePubkeyNotifier('test_pubkey')),
          ],
        );

        final notifier1 = container.read(groupMessagesProvider('test_group_1').notifier);
        final notifier2 = container.read(groupMessagesProvider('test_group_2').notifier);

        expect(notifier1, isA<GroupMessagesNotifier>());
        expect(notifier1.state.groupId, 'test_group_1');
        expect(notifier2, isA<GroupMessagesNotifier>());
        expect(notifier2.state.groupId, 'test_group_2');
        expect(notifier1, isNot(same(notifier2)));

        container.dispose();
      });
    });
  });
}
