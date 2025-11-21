import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/services/notification_content_builder_service.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';

import '../../test_helpers.dart';

Welcome _createWelcome({
  String id = 'default-welcome-id',
  String mlsGroupId = 'default-mls-group-id',
  String nostrGroupId = 'default-nostr-group-id',
  String groupName = 'Test Group',
  String groupDescription = '',
  List<String> groupAdminPubkeys = const [],
  List<String> groupRelays = const [],
  String welcomer = 'default-welcomer-pubkey',
  int memberCount = 2,
}) {
  return Welcome(
    id: id,
    mlsGroupId: mlsGroupId,
    nostrGroupId: nostrGroupId,
    groupName: groupName,
    groupDescription: groupDescription,
    groupAdminPubkeys: groupAdminPubkeys,
    groupRelays: groupRelays,
    welcomer: welcomer,
    memberCount: memberCount,
    state: WelcomeState.pending,
    createdAt: BigInt.from(DateTime.now().millisecondsSinceEpoch),
  );
}

Future<Group> _mockGetGroup({
  required String accountPubkey,
  required String groupId,
}) async {
  return Group(
    mlsGroupId: groupId,
    nostrGroupId: 'nostr-$groupId',
    name: 'Test Group',
    description: 'A test group',
    adminPubkeys: [],
    epoch: BigInt.from(1),
    state: GroupState.active,
  );
}

Future<List<String>> _mockGetGroupMembers({
  required String pubkey,
  required String groupId,
}) async {
  return [pubkey, 'other-member-pubkey'];
}

Future<FlutterMetadata> _mockGetUserMetadata({
  required String pubkey,
  bool blockingDataSync = false,
}) async {
  final Map<String, String> names = {
    'other-member-pubkey': 'Alice',
    'account-pubkey': 'Bob',
    'sender-pubkey': 'Charlie',
    'default-welcomer-pubkey': 'David',
  };

  return FlutterMetadata(
    name: names[pubkey],
    displayName: names[pubkey],
    custom: {},
  );
}

ChatMessage _createChatMessage({
  String id = 'msg-123',
  String pubkey = 'sender-pubkey',
  String content = 'Test message',
  List<MediaFile> mediaAttachments = const [],
}) {
  return ChatMessage(
    id: id,
    pubkey: pubkey,
    content: content,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1234567890000),
    tags: [],
    isReply: false,
    isDeleted: false,
    contentTokens: [],
    reactions: const ReactionSummary(byEmoji: [], userReactions: []),
    mediaAttachments: mediaAttachments,
    kind: 443,
  );
}

MediaFile _createMediaFile({
  String id = 'media-1',
  String filePath = '/path/to/file.jpg',
}) {
  return MediaFile(
    id: id,
    mlsGroupId: 'test-group-id',
    accountPubkey: 'account-pubkey',
    filePath: filePath,
    originalFileHash: 'hash',
    encryptedFileHash: 'encrypted-hash',
    mimeType: 'image/jpeg',
    mediaType: 'image',
    blossomUrl: 'https://example.com/file.jpg',
    nostrKey: 'nostr-key',
    createdAt: DateTime(2024),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeTestLocalization();
  });

  group('NotificationContentBuilderService tests', () {
    group('forGroup', () {
      test('returns a NotificationContentBuilderService instance', () async {
        final result = await NotificationContentBuilderService.forGroup(
          groupId: 'test-group-id',
          accountPubkey: 'account-pubkey',
          isDM: false,
          showReceiverAccountName: false,
          getGroupFn: _mockGetGroup,
          getGroupMembersFn: _mockGetGroupMembers,
          getUserMetadataFn: _mockGetUserMetadata,
        );

        expect(result, isA<NotificationContentBuilderService>());
      });

      test('sets groupId correctly', () async {
        final result = await NotificationContentBuilderService.forGroup(
          groupId: 'my-group-id',
          accountPubkey: 'account-pubkey',
          isDM: false,
          showReceiverAccountName: false,
          getGroupFn: _mockGetGroup,
          getGroupMembersFn: _mockGetGroupMembers,
          getUserMetadataFn: _mockGetUserMetadata,
        );

        expect(result.groupId, equals('my-group-id'));
      });

      test('sets accountPubkey correctly', () async {
        final result = await NotificationContentBuilderService.forGroup(
          groupId: 'test-group-id',
          accountPubkey: 'my-account-pubkey',
          isDM: false,
          showReceiverAccountName: false,
          getGroupFn: _mockGetGroup,
          getGroupMembersFn: _mockGetGroupMembers,
          getUserMetadataFn: _mockGetUserMetadata,
        );

        expect(result.accountPubkey, equals('my-account-pubkey'));
      });

      group('when isDM is true', () {
        test('sets isDM to true for direct messages', () async {
          final result = await NotificationContentBuilderService.forGroup(
            groupId: 'test-group-id',
            accountPubkey: 'account-pubkey',
            isDM: true,
            showReceiverAccountName: false,
            getGroupFn: _mockGetGroup,
            getGroupMembersFn: _mockGetGroupMembers,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.isDM, isTrue);
        });

        test('sets groupDisplayName to other member name', () async {
          final result = await NotificationContentBuilderService.forGroup(
            groupId: 'test-group-id',
            accountPubkey: 'account-pubkey',
            isDM: true,
            showReceiverAccountName: false,
            getGroupFn: _mockGetGroup,
            getGroupMembersFn: _mockGetGroupMembers,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.groupDisplayName, 'Alice');
        });

        group('when showReceiverAccountName is false', () {
          test('sets title to other user name', () async {
            final result = await NotificationContentBuilderService.forGroup(
              groupId: 'test-group-id',
              accountPubkey: 'account-pubkey',
              isDM: true,
              showReceiverAccountName: false,
              getGroupFn: _mockGetGroup,
              getGroupMembersFn: _mockGetGroupMembers,
              getUserMetadataFn: _mockGetUserMetadata,
            );

            expect(result.title, equals('Alice'));
          });
        });

        group('when showReceiverAccountName is true', () {
          test('sets title to other user name specifying receiver name', () async {
            final result = await NotificationContentBuilderService.forGroup(
              groupId: 'test-group-id',
              accountPubkey: 'account-pubkey',
              isDM: true,
              showReceiverAccountName: true,
              getGroupFn: _mockGetGroup,
              getGroupMembersFn: _mockGetGroupMembers,
              getUserMetadataFn: _mockGetUserMetadata,
            );

            expect(result.title, equals('Alice (to Bob)'));
          });
        });
      });

      group('when isDM is false', () {
        test('sets isDM to false for group chats', () async {
          final result = await NotificationContentBuilderService.forGroup(
            groupId: 'test-group-id',
            accountPubkey: 'account-pubkey',
            isDM: false,
            showReceiverAccountName: false,
            getGroupFn: _mockGetGroup,
            getGroupMembersFn: _mockGetGroupMembers,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.isDM, isFalse);
        });

        test('sets groupDisplayName to group name', () async {
          final result = await NotificationContentBuilderService.forGroup(
            groupId: 'test-group-id',
            accountPubkey: 'account-pubkey',
            isDM: false,
            showReceiverAccountName: false,
            getGroupFn: _mockGetGroup,
            getGroupMembersFn: _mockGetGroupMembers,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.groupDisplayName, 'Test Group');
        });

        group('when showReceiverAccountName is false', () {
          test('sets title to group name', () async {
            final result = await NotificationContentBuilderService.forGroup(
              groupId: 'test-group-id',
              accountPubkey: 'account-pubkey',
              isDM: false,
              showReceiverAccountName: false,
              getGroupFn: _mockGetGroup,
              getGroupMembersFn: _mockGetGroupMembers,
              getUserMetadataFn: _mockGetUserMetadata,
            );

            expect(result.title, equals('Test Group'));
          });
        });

        group('when showReceiverAccountName is true', () {
          test('sets title to group name specifying receiver name', () async {
            final result = await NotificationContentBuilderService.forGroup(
              groupId: 'test-group-id',
              accountPubkey: 'account-pubkey',
              isDM: false,
              showReceiverAccountName: true,
              getGroupFn: _mockGetGroup,
              getGroupMembersFn: _mockGetGroupMembers,
              getUserMetadataFn: _mockGetUserMetadata,
            );

            expect(result.title, equals('Test Group (to Bob)'));
          });
        });
      });
    });

    group('buildInviteNotification', () {
      const testAccountPubkey = 'test-account-pubkey';

      test('includes correct type in payload', () async {
        final welcome = _createWelcome();

        final result = await NotificationContentBuilderService.buildInviteNotification(
          welcome: welcome,
          accountPubkey: testAccountPubkey,
          showReceiverAccountName: false,
          getUserMetadataFn: _mockGetUserMetadata,
        );

        expect(result.payload['type'], equals('invites_sync'));
      });

      test('includes welcomeId in payload', () async {
        final welcome = _createWelcome(id: 'welcome-123');

        final result = await NotificationContentBuilderService.buildInviteNotification(
          welcome: welcome,
          accountPubkey: testAccountPubkey,
          showReceiverAccountName: false,
          getUserMetadataFn: _mockGetUserMetadata,
        );

        expect(result.payload['welcomeId'], equals('welcome-123'));
      });

      test('includes groupId in payload', () async {
        final welcome = _createWelcome(mlsGroupId: 'group-456');

        final result = await NotificationContentBuilderService.buildInviteNotification(
          welcome: welcome,
          accountPubkey: testAccountPubkey,
          showReceiverAccountName: false,
          getUserMetadataFn: _mockGetUserMetadata,
        );

        expect(result.payload['groupId'], equals('group-456'));
      });

      test('includes accountPubkey in payload', () async {
        final welcome = _createWelcome();

        final result = await NotificationContentBuilderService.buildInviteNotification(
          welcome: welcome,
          accountPubkey: 'my-account-123',
          showReceiverAccountName: false,
          getUserMetadataFn: _mockGetUserMetadata,
        );

        expect(result.payload['accountPubkey'], equals('my-account-123'));
      });

      test('includes correct deepLink with inviteId', () async {
        final welcome = _createWelcome(
          id: 'invite-789',
          mlsGroupId: 'group-456',
        );

        final result = await NotificationContentBuilderService.buildInviteNotification(
          welcome: welcome,
          accountPubkey: testAccountPubkey,
          showReceiverAccountName: false,
          getUserMetadataFn: _mockGetUserMetadata,
        );

        expect(
          result.payload['deepLink'],
          equals('whitenoise://chats/group-456?inviteId=invite-789'),
        );
      });

      test('uses invites as groupKey', () async {
        final welcome = _createWelcome();

        final result = await NotificationContentBuilderService.buildInviteNotification(
          welcome: welcome,
          accountPubkey: testAccountPubkey,
          showReceiverAccountName: false,
          getUserMetadataFn: _mockGetUserMetadata,
        );

        expect(result.groupKey, equals('invites'));
      });

      test('returns notification title', () async {
        final welcome = _createWelcome();

        final result = await NotificationContentBuilderService.buildInviteNotification(
          welcome: welcome,
          accountPubkey: testAccountPubkey,
          showReceiverAccountName: false,
          getUserMetadataFn: _mockGetUserMetadata,
        );

        expect(result.title, isNotEmpty);
      });

      test('returns notification body', () async {
        final welcome = _createWelcome();

        final result = await NotificationContentBuilderService.buildInviteNotification(
          welcome: welcome,
          accountPubkey: testAccountPubkey,
          showReceiverAccountName: false,
          getUserMetadataFn: _mockGetUserMetadata,
        );

        expect(result.body, isNotEmpty);
      });

      test('handles DM invite with empty group name', () async {
        final welcome = _createWelcome(groupName: '');

        final result = await NotificationContentBuilderService.buildInviteNotification(
          welcome: welcome,
          accountPubkey: testAccountPubkey,
          showReceiverAccountName: false,
          getUserMetadataFn: _mockGetUserMetadata,
        );

        expect(result.payload['groupId'], isNotEmpty);
      });

      test('handles group invite with group name', () async {
        final welcome = _createWelcome(groupName: 'My Cool Group');

        final result = await NotificationContentBuilderService.buildInviteNotification(
          welcome: welcome,
          accountPubkey: testAccountPubkey,
          showReceiverAccountName: false,
          getUserMetadataFn: _mockGetUserMetadata,
        );

        expect(result.payload['groupId'], isNotEmpty);
      });

      test('preserves all payload fields', () async {
        final welcome = _createWelcome(
          id: 'test-id',
          mlsGroupId: 'test-group',
        );

        final result = await NotificationContentBuilderService.buildInviteNotification(
          welcome: welcome,
          accountPubkey: testAccountPubkey,
          showReceiverAccountName: false,
          getUserMetadataFn: _mockGetUserMetadata,
        );

        expect(
          result.payload.keys,
          containsAll([
            'type',
            'welcomeId',
            'groupId',
            'accountPubkey',
            'deepLink',
          ]),
        );
      });

      group('when showReceiverAccountName is false', () {
        test('sets title to welcomer name', () async {
          final welcome = _createWelcome();

          final result = await NotificationContentBuilderService.buildInviteNotification(
            welcome: welcome,
            accountPubkey: 'account-pubkey',
            showReceiverAccountName: false,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.title, equals('David'));
        });
      });

      group('when showReceiverAccountName is true', () {
        test('sets title to welcomer name specifying receiver name', () async {
          final welcome = _createWelcome();

          final result = await NotificationContentBuilderService.buildInviteNotification(
            welcome: welcome,
            accountPubkey: 'account-pubkey',
            showReceiverAccountName: true,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.title, equals('David (to Bob)'));
        });
      });
    });

    group('buildMessageNotification', () {
      group('returns notification content with correct structure', () {
        late NotificationContentBuilderService builder;

        setUp(() async {
          builder = await NotificationContentBuilderService.forGroup(
            groupId: 'test-group-id',
            accountPubkey: 'account-pubkey',
            isDM: false,
            showReceiverAccountName: false,
            getGroupFn: _mockGetGroup,
            getGroupMembersFn: _mockGetGroupMembers,
            getUserMetadataFn: _mockGetUserMetadata,
          );
        });

        test('includes title from builder', () async {
          final message = _createChatMessage();

          final result = await builder.buildMessageNotification(
            message: message,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.title, equals('Test Group'));
        });

        test('includes groupKey matching groupId', () async {
          final message = _createChatMessage();

          final result = await builder.buildMessageNotification(
            message: message,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.groupKey, equals('test-group-id'));
        });

        test('includes new_message type in payload', () async {
          final message = _createChatMessage();

          final result = await builder.buildMessageNotification(
            message: message,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.payload['type'], equals('new_message'));
        });

        test('includes groupId in payload', () async {
          final message = _createChatMessage();

          final result = await builder.buildMessageNotification(
            message: message,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.payload['groupId'], equals('test-group-id'));
        });

        test('includes messageId in payload', () async {
          final message = _createChatMessage(id: 'msg-456');

          final result = await builder.buildMessageNotification(
            message: message,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.payload['messageId'], equals('msg-456'));
        });

        test('includes sender pubkey in payload', () async {
          final message = _createChatMessage(pubkey: 'test-sender');

          final result = await builder.buildMessageNotification(
            message: message,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.payload['sender'], equals('test-sender'));
        });

        test('includes correct deepLink format', () async {
          final message = _createChatMessage();

          final result = await builder.buildMessageNotification(
            message: message,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(
            result.payload['deepLink'],
            equals('whitenoise://chats/test-group-id'),
          );
        });

        test('includes accountPubkey in payload', () async {
          final message = _createChatMessage();

          final result = await builder.buildMessageNotification(
            message: message,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.payload['accountPubkey'], equals('account-pubkey'));
        });
      });

      group('when it is a DM', () {
        late NotificationContentBuilderService builder;

        setUp(() async {
          builder = await NotificationContentBuilderService.forGroup(
            groupId: 'dm-group-id',
            accountPubkey: 'account-pubkey',
            isDM: true,
            showReceiverAccountName: false,
            getGroupFn: _mockGetGroup,
            getGroupMembersFn: _mockGetGroupMembers,
            getUserMetadataFn: _mockGetUserMetadata,
          );
        });

        test('shows content directly for text message', () async {
          final message = _createChatMessage(content: 'Hello world');

          final result = await builder.buildMessageNotification(
            message: message,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.body, equals('Hello world'));
        });

        test('shows media emoji and content when both present', () async {
          final media = _createMediaFile();
          final message = _createChatMessage(
            content: 'Check this out',
            mediaAttachments: [media],
          );

          final result = await builder.buildMessageNotification(
            message: message,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.body, equals('\u{1F4F7} Check this out'));
        });

        test('shows media message text when only media present', () async {
          final media = _createMediaFile();
          final message = _createChatMessage(
            content: '',
            mediaAttachments: [media],
          );

          final result = await builder.buildMessageNotification(
            message: message,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.body, contains('\u{1F4F7}'));
        });
      });

      group('with group message', () {
        late NotificationContentBuilderService builder;

        setUp(() async {
          builder = await NotificationContentBuilderService.forGroup(
            groupId: 'group-id',
            accountPubkey: 'account-pubkey',
            isDM: false,
            showReceiverAccountName: false,
            getGroupFn: _mockGetGroup,
            getGroupMembersFn: _mockGetGroupMembers,
            getUserMetadataFn: _mockGetUserMetadata,
          );
        });

        test('includes sender name with text message', () async {
          final message = _createChatMessage(content: 'Group message');

          final result = await builder.buildMessageNotification(
            message: message,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.body, equals('Charlie: Group message'));
        });

        test('includes sender name with media emoji and content', () async {
          final media = _createMediaFile();
          final message = _createChatMessage(
            content: 'Look at this',
            mediaAttachments: [media],
          );

          final result = await builder.buildMessageNotification(
            message: message,
            getUserMetadataFn: _mockGetUserMetadata,
          );

          expect(result.body, equals('\u{1F4F7} Charlie: Look at this'));
        });
      });
    });
  });
}
