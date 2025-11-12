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
    });
  });
}
